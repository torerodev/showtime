#!/usr/bin/env python3
import argparse
import os
from netmiko import ConnectHandler
from datetime import datetime
import json
import time
import yaml
import logging
from pathlib import Path

# logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# default output dir
DEFAULT_OUTPUT_DIR = "/home/admin/lab_output"

def load_variables(variables_file='variables.yml'):
    '''
    Load variables from variables.yml file
    '''

    try:
        with open(variables_file, 'r') as f:
            variables = yaml.safe_load(f)
        return variables
    except Exception as e:
        logger.error(f"Failed to load variables: {e}")
        raise

def configure_bgp(device_info, bgp_config):
    '''
    Configure BGP on device using directly connected interfaces
    '''

    commands = [
        f"router bgp {bgp_config['local_as']}",
        f"router-id {bgp_config['loopback_ip']}",
        f"neighbor {bgp_config['neighbor_ip']} remote-as {bgp_config['remote_as']}",
        f"neighbor {bgp_config['neighbor_ip']} maximum-routes 12000",
        f"network {bgp_config['loopback_ip']}/32"
    ]
    
    try:

        # extract output_dir before passing to ConnectHandler
        output_dir = device_info.pop('output_dir', DEFAULT_OUTPUT_DIR)
        session_log = Path(output_dir) / f"session_{device_info['host']}.log"
        device_info['session_log'] = str(session_log)
        
        connection = ConnectHandler(**device_info)
        connection.enable()
        output = connection.send_config_set(commands)
        connection.save_config()
        connection.disconnect()
        return True, output
    except Exception as e:
        logger.error(f"Failed to configure BGP on {device_info['host']}: {e}")
        return False, str(e)

def validate_bgp(device_info):
    '''
    Validate BGP neighbor state and prefix count
    '''

    try:
        # remove output_dir if present as it's not a ConnectHandler parameter
        device_info_copy = device_info.copy()
        device_info_copy.pop('output_dir', None)
        device_info_copy.pop('bgp_config', None)
        
        connection = ConnectHandler(**device_info_copy)
        connection.enable()
        output = connection.send_command("show ip bgp summary | json")
        connection.disconnect()
        
        try:
            bgp_data = json.loads(output)
            neighbors = bgp_data.get("vrfs", {}).get("default", {}).get("peers", {})
            
            if not neighbors:
                return False, {"error": "No BGP neighbors found"}
                
            for neighbor, data in neighbors.items():
                state = data.get("peerState", "")
                prefixes = data.get("prefixReceived", 0)
                return state == "Established" and prefixes > 0, {
                    "neighbor": neighbor,
                    "state": state,
                    "prefixes_received": prefixes,
                    "as_number": data.get("asn", "unknown")
                }
        except json.JSONDecodeError:

            # If json parsing fails, try text output
            output = connection.send_command("show ip bgp summary")
            return False, {"error": "JSON parsing failed", "text_output": output}
            
    except Exception as e:
        logger.error(f"Failed to validate BGP on {device_info['host']}: {e}")
        return False, {"error": str(e)}
    
def test_connectivity(device_info, target_ip):
    '''
    Test connectivity using ping and gather interface and routing status
    '''

    try:
        # remove output_dir if present as it's not a ConnectHandler parameter
        device_info_copy = device_info.copy()
        device_info_copy.pop('output_dir', None)
        device_info_copy.pop('bgp_config', None)
        
        connection = ConnectHandler(**device_info_copy)
        connection.enable()
        
        # check interface status
        intf_status = connection.send_command("show ip interface brief")

        # check routing table
        route_table = connection.send_command("show ip route")

        # ping target
        ping_output = connection.send_command(f"ping {target_ip} repeat 5")

        # check routes
        bgp_routes = connection.send_command("show ip bgp")
        
        connection.disconnect()
        
        # was ping successful?
        ping_success = "5 received" in ping_output or "5 packets received" in ping_output
        return ping_success, {
            "ping_output": ping_output,
            "interface_status": intf_status,
            "route_table": route_table,
            "bgp_routes": bgp_routes
        }
    except Exception as e:
        logger.error(f"Failed to test connectivity from {device_info['host']}: {e}")
        return False, {"error": str(e)}

def main():
    parser = argparse.ArgumentParser(description="Configure and validate BGP between Arista routers")
    parser.add_argument("--variables", default="variables.yml",
                        help="Variables file (default: variables.yml)")
    parser.add_argument("--device", help="Configure specific device only")
    parser.add_argument("--output-dir", default=None,
                        help=f"Custom output directory (default: {DEFAULT_OUTPUT_DIR})")
    args = parser.parse_args()

    # load vars
    try:
        variables = load_variables(args.variables)
    except Exception as e:
        logger.error(f"Failed to load variables: {e}")
        return 1
    
    # determine output dir
    # priority: command-line argument > variables file > default
    if args.output_dir:
        output_dir = args.output_dir
    else:
        output_dir = variables.get('settings', {}).get('output_dir', DEFAULT_OUTPUT_DIR)
    
    # create output directory
    os.makedirs(output_dir, exist_ok=True)
    logger.info(f"Using output directory: {output_dir}")
    
    # filter devices if specified
    if args.device:
        if args.device not in variables['devices']:
            logger.error(f"Device {args.device} not found in variables")
            return 1
        devices_to_process = {args.device: variables['devices'][args.device]}
    else:
        devices_to_process = variables['devices']
    
    # results container
    results = {
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "bgp_configurations": [],
        "bgp_validations": [],
        "connectivity_tests": []
    }

    # configure bgp
    for device_name, device_data in devices_to_process.items():
        logger.info(f"Configuring BGP on {device_name} ({device_data['host']})...")
        
        device_info = device_data.copy()
        if 'bgp_config' in device_info:
            bgp_config = device_info.pop('bgp_config')
        
        device_info['output_dir'] = output_dir
        
        success, output = configure_bgp(device_info, bgp_config)
        results["bgp_configurations"].append({
            "device": device_name,
            "host": device_data["host"],
            "success": success,
            "output": output
        })

    # wait for bgp to converge
    wait_time = variables.get('settings', {}).get('bgp_convergence_wait', 30)
    logger.info(f"Waiting for BGP to converge ({wait_time} seconds)...")
    time.sleep(wait_time)

    # validate bgp and connectivity
    for device_name, device_data in devices_to_process.items():
        logger.info(f"Validating BGP on {device_name} ({device_data['host']})...")
        
        device_info = device_data.copy()
        device_info['output_dir'] = output_dir  # add output_dir to device_info for logging purposes
        
        bgp_ok, bgp_info = validate_bgp(device_info)
        
        # test ping to target loopback
        target_loopback = variables['test_targets'][device_name]['test_loopback']
        logger.info(f"Testing connectivity from {device_name} to {target_loopback}...")
        ping_ok, ping_info = test_connectivity(device_info, target_loopback)
        
        results["bgp_validations"].append({
            "device": device_name,
            "host": device_data["host"],
            "bgp_established": bgp_ok,
            "bgp_details": bgp_info
        })
        results["connectivity_tests"].append({
            "device": device_name,
            "host": device_data["host"],
            "ping_success": ping_ok,
            "ping_details": ping_info
        })

    # display results
    print("\nBGP Configuration and Validation Results:")
    print("=" * 50)
    for config in results["bgp_configurations"]:
        print(f"\nDevice {config['device']} ({config['host']}) BGP Configuration:")
        print(f"Success: {config['success']}")
        if not config['success']:
            print(f"Error: {config['output']}")
        else:
            print(f"Output: {config['output'][:200]}..." if len(config['output']) > 200 else config['output'])
    
    for validation in results["bgp_validations"]:
        print(f"\nDevice {validation['device']} ({validation['host']}) BGP Validation:")
        print(f"BGP Established: {validation['bgp_established']}")
        print(f"Details: {validation['bgp_details']}")
    
    for test in results["connectivity_tests"]:
        print(f"\nDevice {test['device']} ({test['host']}) Connectivity Test:")
        print(f"Ping Successful: {test['ping_success']}")
        if 'error' in test['ping_details']:
            print(f"Error: {test['ping_details']['error']}")
        else:
            print(f"Ping Output: {test['ping_details']['ping_output'][:200]}...")

    # save results
    output_file = os.path.join(output_dir, f"bgp_validation_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json")
    with open(output_file, "w") as f:
        json.dump(results, f, indent=2)
    
    logger.info(f"Results saved to: {output_file}")
    
    # create report that's easy on the eyes
    report_file = os.path.join(output_dir, f"bgp_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt")
    with open(report_file, "w") as f:
        f.write("BGP Lab Configuration Report\n")
        f.write("=" * 30 + "\n\n")
        f.write(f"Timestamp: {results['timestamp']}\n\n")
        
        for validation in results["bgp_validations"]:
            f.write(f"Device: {validation['device']} ({validation['host']})\n")
            f.write(f"BGP Status: {'ESTABLISHED' if validation['bgp_established'] else 'NOT ESTABLISHED'}\n")
            if validation['bgp_established']:
                f.write(f"Neighbor: {validation['bgp_details']['neighbor']}\n")
                f.write(f"Prefixes Received: {validation['bgp_details']['prefixes_received']}\n")
            f.write("\n")
        
        for test in results["connectivity_tests"]:
            f.write(f"Connectivity Test from {test['device']}: {'PASSED' if test['ping_success'] else 'FAILED'}\n")
        
    logger.info(f"Report saved to: {report_file}")

if __name__ == "__main__":
    main()