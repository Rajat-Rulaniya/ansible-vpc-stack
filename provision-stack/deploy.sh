#!/bin/bash

# Get latest inventory file
ansible-playbook fetch_inventory.yml

# Run the main playbook using the updated inventory
ansible-playbook -i inventory-vpro site.yml
