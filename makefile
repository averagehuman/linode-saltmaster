
# ###################################################################################
#
# Example .linode
# ---------------
#
# LINODE_API_KEY := <SECRET API KEY>
# LINODE_SSH_USER := $(USER)
# LINODE_SSH_KEY_LOCATION := ~/.ssh/linode.key
# ANSIBLE_SSH_PORT := <OPTIONAL ALTERNATIVE SSHD PORT>
#
# ###################################################################################

include .linode

ENVIRONMENT ?= dev
HOST ?= saltmaster

HOSTNAME := $(ENVIRONMENT)-$(HOST)

VIRTUAL_ENV ?= $(abspath ../.pyenv/linode-ansible)
PYVERSION ?= 2
PYTHON := $(VIRTUAL_ENV)/bin/python
PIP := $(VIRTUAL_ENV)/bin/pip

ANSIBLE := $(VIRTUAL_ENV)/bin/ansible
ANSIBLE_CONFIG := $(abspath ansible/config)

# the inventory file is written dynamically after the initial deploy
ANSIBLE_INVENTORY := $(abspath ansible/hosts/$(HOSTNAME))

# restart sshd on this port after first deploy of a machine
ANSIBLE_SSH_PORT ?= 5675

SALTMASTER_PLAYBOOK := $(abspath ansible/saltmaster.yml)
ANSIBLE_PLAYBOOK ?= SALTMASTER_PLAYBOOK

export VIRTUAL_ENV
export HOSTNAME
export LINODE_API_KEY
export LINODE_SSH_USER
export LINODE_SSH_KEY_LOCATION
export ANSIBLE_CONFIG
export ANSIBLE_INVENTORY
export ANSIBLE_PLAYBOOK
export ANSIBLE_SSH_PORT

# the initial vagrant command to create a linode machine
VAGRANT_UP := vagrant up --provider linode --provision-with shell 

# grep 'vagrant status' to see if the machine exists or not
GREP_LINODE_IS_ACTIVE := vagrant status | grep -soh "^Linode is active" >/dev/null 2>&1

# grep command to get IP address from vagrant output
GREP_IP_ADDRESS := grep -soh -m 1 "[[:space:]]Assigned IP address:[[:space:]][.[:digit:]]*"

# print the ansible inventory given the output from $GREP_IP_ADDRESS
AWK_WRITE_INVENTORY := awk '{print "\n$(HOSTNAME) ansible_host="$$4" ansible_port=$(ANSIBLE_SSH_PORT)\n"}'

# check if linode is created or not
LINODE_IS_ACTIVE_CMD = $$($(GREP_LINODE_IS_ACTIVE) && echo $$?)

# If the machine has been created, then the shell provisioner will have updated
# the ssh port to be $(ANSIBLE_SSH_PORT), otherwise set it to the default 22.
LINODE_SSH_PORT_CMD = $$($(GREP_LINODE_IS_ACTIVE) && echo $(ANSIBLE_SSH_PORT) || echo 22)

# once the inventory file is written then we can grep it rather than invoking vagrant
GREP_ANSIBLE_HOST_IP := grep -s "\bansible_host=" $(ANSIBLE_INVENTORY) | grep -Eo "([0-9]{1,3}\.){3}[0-9]{1,3}"
GREP_ANSIBLE_HOST_PORT := grep -Eo "ansible_port=[0-9]+" $(ANSIBLE_INVENTORY) | tr -cd '[[:digit:]]'

.PHONY: apt venv deploy provision-saltmaster status ssh halt destroy ping debug environ

default:
	@echo "sudo make apt"
	@echo "    -> install (local) system dependencies required for ansible provisioner (build-essential, libssl-dev etc.)"
	@echo "make deploy"
	@echo "    -> create a new linode machine and update and reload its sshd config"
	@echo "make provision-saltmaster"
	@echo "    -> provision the newly created machine as a saltmaster"

apt:
	@apt-get -y install build-essential libssl-dev libffi-dev python-dev python-apt

venv:
	@if [ ! -e $(VIRTUAL_ENV) ]; then \
		echo "::::: Creating virtual environment..."; \
		mkdir -p $(abspath $(VIRTUAL_ENV)/..); \
		virtualenv --python=python$(PYVERSION) $(VIRTUAL_ENV) && \
		    $(PIP) install -U pip && \
		    $(PIP) install -r requirements.txt; \
	fi;

deploy: venv
	@if [ $(LINODE_IS_ACTIVE_CMD) ]; then \
		echo "Linode is created and active. Run a provision target to complete the deployment, eg. make provision-saltmaster"; \
		exit 2; \
	else \
	    if [ -e "$(ANSIBLE_INVENTORY)" ]; then \
		    echo "Refusing to run 'make deploy' because it will overwrite the Ansible inventory."; \
			echo " --> If the inventory is from a previous obsolete deploy then delete it. If it is "; \
			echo " --> for a current deploy then there must have been an error as you shouldn't need"; \
			echo " --> to run 'make deploy' more than once. If you really want to continue, then"; \
			echo " --> remove inventory file '$(ANSIBLE_INVENTORY)' and try again."; \
			exit 2; \
		else \
			echo "::::: Deploying linode..."; \
			$(VAGRANT_UP) | tee /dev/tty | $(GREP_IP_ADDRESS) | $(AWK_WRITE_INVENTORY) > $(ANSIBLE_INVENTORY); \
		fi; \
	fi

debug:
	@echo "ssh $(LINODE_SSH_USER)@$$($(GREP_ANSIBLE_HOST_IP)) -p $(ANSIBLE_SSH_PORT)"

provision-saltmaster:
	@echo "::::: Provisioning linode..."
	@echo "PLAYBOOK = $(SALTMASTER_PLAYBOOK)"
	@echo "INVENTORY = $(ANSIBLE_INVENTORY)"
	@. $(VIRTUAL_ENV)/bin/activate && LINODE_SSH_PORT=$(ANSIBLE_SSH_PORT) ANSIBLE_PLAYBOOK=$(SALTMASTER_PLAYBOOK) vagrant provision --provision-with ansible

status:
	@LINODE_SSH_PORT=$(LINODE_SSH_PORT_CMD) vagrant status

ssh:
	@if [ ! -e $(ANSIBLE_INVENTORY) ]; then \
		LINODE_SSH_PORT=$(LINODE_SSH_PORT_CMD) vagrant ssh; \
	else \
		ssh $(LINODE_SSH_USER)@$$($(GREP_ANSIBLE_HOST_IP)) -p $(ANSIBLE_SSH_PORT); \
	fi

stop:
	@vagrant halt

start:
	@LINODE_SSH_PORT=$(LINODE_SSH_PORT_CMD) vagrant up

destroy:
	@vagrant destroy

ping:
	@$(ANSIBLE) all -m ping -u $(LINODE_SSH_USER)

environ:
	@echo "LINODE_HOSTNAME = $(HOSTNAME)"
	@echo "LINODE_SSH_PORT = $(LINODE_SSH_PORT_CMD)"
	@echo "ANSIBLE_SSH_PORT = $(ANSIBLE_SSH_PORT)"
	
