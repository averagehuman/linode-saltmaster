
include site.properties

PROJECT := linode-saltmaster
VIRTUAL_ENV ?= $(abspath ../.pyenv/$(PROJECT))
PYVERSION ?= 2
PYTHON := $(VIRTUAL_ENV)/bin/python
PIP := $(VIRTUAL_ENV)/bin/pip
ANSIBLE := $(VIRTUAL_ENV)/bin/ansible
ANSIBLE_CONFIG := $(abspath ansible/config)
ANSIBLE_INVENTORY := $(abspath host)

# alternative to '--provider linode' option in vagrant commands
VAGRANT_DEFAULT_PROVIDER := linode

# grep command to get IP address from vagrant output
GREP_IP_ADDRESS := grep -soh -m 1 "[[:space:]]Assigned IP address:[[:space:]][.[:digit:]]*"

# print the ansible inventory given the output from $GREP_IP_ADDRESS
AWK_WRITE_INVENTORY := awk '{print "\nsaltmaster ansible_host=$$4 ansible_port=$(ANSIBLE_SSH_PORT)\n"}'

# grep for ansible_port setting in the ansible inventory and delete any non-digit from output
GREP_INVENTORY_PORT := grep -soh "ansible_port=[[:digit:]]\+" $(ANSIBLE_INVENTORY) | tr -dc '[:digit:]'

# pick up the server ssh port from the ansible inventory file if it exists
# (the inventory is created dynamically by 'make deploy')
LINODE_SSH_PORT := $(shell $(GREP_INVENTORY_PORT))
LINODE_SSH_PORT ?= 22


export VIRTUAL_ENV
export VAGRANT_DEFAULT_PROVIDER
export LINODE_HOSTNAME
export LINODE_API_KEY
export LINODE_SSH_USER
export LINODE_SSH_PORT
export LINODE_SSH_KEY_LOCATION
export LINODE_SERVER_LABEL
export LINODE_IP_ADDRESS
export ANSIBLE_CONFIG

.PHONY: venv deploy provision ssh halt destroy ping

default:
	@echo "sudo make apt"
	@echo "    -> install system dependencies (build-essential, libssl-dev etc.)"
	@echo "make deploy"
	@echo "    -> create a new linode machine via the vagrant-linode plugin"
	@echo "make provision"
	@echo "    -> provision the newly created machine"

apt:
	@apt-get -y install build-essential libssl-dev libffi-dev python-dev

venv:
	@if [ ! -e $(VIRTUAL_ENV) ]; then \
		echo "::::: Creating virtual environment..."; \
		mkdir -p $(abspath $(VIRTUAL_ENV)/..); \
		virtualenv --python=python$(PYVERSION) $(VIRTUAL_ENV) && \
		    $(PIP) install -U pip && \
		    $(PIP) install -r requirements.txt; \
	fi;

deploy: venv
	@echo "::::: Creating linode..."
	@vagrant up --provision-with shell | tee /dev/tty | $(GREP_IP_ADDRESS) |  > $(ANSIBLE_INVENTORY)

provision:
	@echo "::::: Provisioning linode..."
	@. $(VIRTUAL_ENV)/bin/activate && vagrant provision --provision-with ansible

environ:
	@echo "LINODE_HOSTNAME = $(LINODE_HOSTNAME)"
	@echo "LINODE_SSH_PORT = $(LINODE_SSH_PORT)"
	@echo "ANSIBLE_SSH_PORT = $(ANSIBLE_SSH_PORT)"
	
ssh:
	@vagrant ssh

halt:
	@vagrant halt

destroy:
	@vagrant destroy

ping:
	@$(ANSIBLE) all -m ping -u $(LINODE_SSH_USER)
