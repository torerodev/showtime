![Showtime](./img/showtime.gif)

## Summary
This _project_ leverages the capibilities of [Containerlab](https://containerlab.dev) to build and run _container-based_ labs and uses [torero](https://torero.dev) as a _unified_ execution layer across your automation tools - [Ansible](https://docs.ansible.com/), [OpenTofu](https://opentofu.org/docs/), _Python_, and more. This project is meant to explore the _art of the possible_ as it pertains to scaling automation across _on-premises_ and _public-cloud_ infrastructure.

## 📒 Project Structure
This project contains the following components:
- [library](./library/) contains _ready-to-use_ automations separated by tool _(Ansible, OpenTofu, and Python)_.
- [labs](./labs) holds _purpose-built_ Containerlab topologies to run _automations_ against; each lab has a **1:1** relationship with an import file.
- [imports](./imports) are **.yml** files that _inventory_ a set of automations pertaining to a given lab; these are referenced in _Containerlab_ topology files and get imported to the lab at _runtime_.

## 🛠️ Dependencies
Finding examples of automation is great, but doesn't get you very far unless you have _purpose-built_ environments to run the automation against. To get the maximum value out of this project, you will need to setup the following:

- [Containerlab](https://containerlab.dev/install/) - an open-source tool for building ephemeral, container-based networking labs with multi-vendor topologies. Its ephemeral nature means that labs can be easily deployed, tested, and then destroyed, making it ideal for _short-term_ experimentation and continuous integration workflows.
- [Network OS Images](https://containerlab.dev/manual/kinds/) - network operating system images _(e.g., Cisco, Arista, Juniper, Nokia)_ required to run Containerlab topologies. You must obtain these images directly from the respective vendors, as they are not provided by Containerlab or Itential due to licensing restrictions. You will need to follow different steps for downloading and importing these images depending on the vendor.

## 🚀 Getting Started
Let's start out with running a basic lab to demonstrate backing up _configuration_ from an Arista device.

![topology](./img/topology.png)

### Download + Import Arista cEOS
Follow the documentation [here](https://containerlab.dev/manual/kinds/ceos/) to download and install [Arista cEOS](https://www.arista.com/en/support/software-download). Arista requires you to create an account at https://arista.com prior to downloading any images.

### Clone Showtime Repository
Clone the _showtime_ repository to the machine where you have _Containerlab_ installed and change directories to the _backup-arista_ lab:

```bash
git clone https://github.com/torerodev/showtime.git \
  && cd showtime/labs/ansible/backup-arista \
  && ls -l
```

![clone repo](./img/clone-repo.gif)

### 🔍 Understanding the Topology File
A _topology_ file in Containerlab is a **.yml-based** definition of your virtual network setup, including nodes _(e.g., routers, switches, or hosts)_, their properties, and the links between them. This allows you to describe complex scenarios in a declarative way. Each _topology_ will launch torero as an _automation gateway_ node, and import the _automations_ in scope for a given lab at runtime. To make this easy to track, [import file names](./imports/ansible/backup-arista.yml) match [lab + topology file names](./labs/ansible/backup-arista/backup-arista.clab.yml) minus the required **.clab** suffix.

```yml
---
name: backup-arista  # Lab name matches imports/ansible/backup-arista.yml

mgmt:
  network: backup-arista
  ipv4-subnet: 198.18.1.0/24

topology:
  kinds:
    arista_ceos:
      image: ceos:${CEOS_VERSION:=4.34.1F}  # Use ENV variable to pass version else use default
  
  nodes:
    agw:
      kind: linux
      image: ghcr.io/torerodev/torero-container:${TORERO_VERSION:=latest}
      mgmt-ipv4: 198.18.1.5
      ports:
        - "8001:8000"
        - "8080:8080"
      env:
        ENABLE_SSH_ADMIN: "true"  # Enable simple ssh login with admin:admin 
        ENABLE_API: "true"        # Enable API at runtime
        ENABLE_MCP: "true"        # Enable MCP at runtime
      binds:
        - $PWD/data:/home/admin/data

      # Import automations that are in scope for this lab at runtime
      exec:
        - "runuser -u admin -- torero db import --repository https://github.com/torerodev/showtime.git imports/ansible/backup-arista.yml"

    # spines
    spine1:
      kind: arista_ceos
      startup-config: config/spine1.cfg  # Base config applied to device at startup
      mgmt-ipv4: 198.18.1.11             # Management IP; Assigned based on inventory file
    
    spine2:
      kind: arista_ceos
      startup-config: config/spine2.cfg
      mgmt-ipv4: 198.18.1.12
    
    # leafs
    leaf1:
      kind: arista_ceos
      startup-config: config/leaf1.cfg
      mgmt-ipv4: 198.18.1.21
    
    leaf2:
      kind: arista_ceos
      startup-config: config/leaf2.cfg
      mgmt-ipv4: 198.18.1.22
    
    leaf3:
      kind: arista_ceos
      startup-config: config/leaf3.cfg
      mgmt-ipv4: 198.18.1.23
    
    leaf4:
      kind: arista_ceos
      startup-config: config/leaf4.cfg
      mgmt-ipv4: 198.18.1.24

  links:

    # spine1 to leaf connections
    - endpoints: ["spine1:eth1", "leaf1:eth1"]
    - endpoints: ["spine1:eth2", "leaf2:eth1"]
    - endpoints: ["spine1:eth3", "leaf3:eth1"]
    - endpoints: ["spine1:eth4", "leaf4:eth1"]
    
    # spine2 to leaf connections
    - endpoints: ["spine2:eth1", "leaf1:eth2"]
    - endpoints: ["spine2:eth2", "leaf2:eth2"]
    - endpoints: ["spine2:eth3", "leaf3:eth2"]
    - endpoints: ["spine2:eth4", "leaf4:eth2"]
```

### Deploying the Topology
Use the following command to _deploy_ the topology:

```bash
export CEOS_VERSION=4.34.1F    # Set environment variable to use version of image you imported
export TORERO_VERSION=latest   # Set environment variable to pull specific version from dockerhub

clab deploy -t backup-arista.clab.yml
```

![deploy](./img/deploy.gif)

> [!NOTE]
> Be sure to set environment variable for images that you have imported in your environment. You can do this prior to running the _clab depoy_ command. Example: **export CEOS_VERSION=4.34.1F**. Deploying a topology without setting environment variables will run the topology with the _default values_ set in the topology file.

### 🔌 Connect to torero Node
First, let's connect to the _torero_ node via SSH with the default login _'admin:admin'_

```bash
ssh admin@198.18.1.5
```

### 🏎️ Run the Automation Service
Next, we can run the service:

```bash
torero run service ansible-playbook backup-arista
```

![run automation](./img/run-automation.gif)

## 💡 What's Next?
Thanks for exploring! This project is designed to empower network engineers and automation enthusiasts to experiment with scalable, container-based automation workflows using Containerlab and torero. By combining ephemeral network labs with a unified automation execution layer, the possibilities are endless. We will continue to add _automation examples_ and _labs_ to the project over time.