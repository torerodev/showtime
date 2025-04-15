![Showtime](./img/showtime.gif)

## Summary
This _project_ leverages the capibilities of [Containerlab](https://containerlab.dev) to build and run _container-based_ labs and uses [torero](https://torero.dev) as a _unified_ execution layer across your automation tools - [Ansible](https://docs.ansible.com/), [OpenTofu](https://opentofu.org/docs/), _Python_, and more. This project is meant to explore the _art of the possible_ as it pertains to scaling automation across _on-premises_ and _public-cloud_ infrastructure.

## 📒 Project Structure
This project contains the following components:
- [library](./library/) contains _ready-to-use_ automations separated by tool _(Ansible, OpenTofu, and Python)_.
- [labs](./labs) holds _purpose-built_ Containerlab topologies to run _automations_ against; each lab has a **1:1** relationship with an import file.
- [imports](./imports) are **.yml** files that _inventory_ a set of automations pertaining to a given lab; these are referenced in _Containerlab_ topology files and get imported to the lab at _runtime_.

## 🚀 Getting Started
Finding examples of automation is great, but doesn't get you very far unless you have _purpose-built_ environments to run the automation against. To get the maximum value out of this project, install and setup [Containerlab](https://containerlab.dev/install/).

> [!NOTE]
> Containerlab is an open-source tool for building ephemeral, container-based networking labs with multi-vendor topologies. Its ephemeral nature means that labs can be easily deployed, tested, and then destroyed, making it ideal for _short-term_ experimentation and continuous integration workflows.

### Running a Basic Lab
Let's start out with setting up a basic lab to demonstrate backing up _configuration_ from an Arista device.

#### Download + Import Arista cEOS
Follow the documentation [here](https://containerlab.dev/manual/kinds/ceos/) to download and install [Arista cEOS](https://www.arista.com/en/support/software-download). Arista requires you to create an account at https://arista.com prior to downloading any images. Once you have the image imported, you can _inspect_ the details:

```bash
docker images # get the image id
docker image inspect image-id-12345 # replace image id with yours
```

#### Clone Showtime Repository
Clone the _showtime_ repository to the machine where you have _Containerlab_ installed and change directories to the _arista-eos-config-backup_ lab:

```bash
git clone https://github.com/torerodev/showtime.git \
  && cd showtime/labs/ansible/arista-eos-config-backup
```