# 🚀 NetBox
Ansible playbooks for managing NetBox resources including infrastructure, IPAM, and DCIM objects. These playbooks provide automated provisioning and removal of NetBox resources with proper dependency management.

## 🔧 Dependencies
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
- [NetBox Ansible Collection](https://galaxy.ansible.com/netbox/netbox)
- NetBox instance with API access
- Valid NetBox API token

## 🏎️ Running the Lab

### Environment Setup
1. Set your NetBox API token:
   ```bash
   export NETBOX_TOKEN="your_api_token_here"
   ```

> [!NOTE]
> For testing at a very small scale, I use [Netbox Cloud (Free Tier)](http://signup.netboxlabs.com/).

1. Configure NetBox settings in `../../inventory/group_vars/netbox_settings.yml`

### Main Playbooks

#### Update NetBox Resources
Add or remove resources from NetBox using YAML configuration files:

```bash
# Add resources to NetBox
ansible-playbook update_netbox.yml -e "netbox_action=add resource_file=lab_network.yml"

# Remove resources from NetBox
ansible-playbook update_netbox.yml -e "netbox_action=remove resource_file=lab_network.yml"
```

#### Clean Slate
Remove all resources from NetBox (use with caution):

```bash
ansible-playbook clean_slate.yml
```