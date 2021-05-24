#!/bin/bash

# MIT License
# 
# Copyright (c) 2021 M. Choji
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

################################################################################
# This script boots virtual machines and calls ansible playbooks one           #
# at a time.                                                                   #
# This can be useful in case you are experiencing performance issues           #
# while deploying AD-lab.                                                      #
#                                                                              #
# You can pass an index as argument to this script so it will start at the     #
# specified point.                                                             #
# The first index is 0, which relates to "dc" box and "domain_controller.yml"  #
# playbook.                                                                    #
################################################################################

echoerr() {
    printf "\e[0;31m[!]\e[0m %s\n" "$*" >&2
}

echowarn() {
    printf "\e[0;33m[-]\e[0m %s\n" "$*" >&2
}

echook() {
    printf "\e[0;32m[+]\e[0m %s\n" "$*" >&1
}


start_at=0
ansible_con_timeout=30
ansible_inventory="hosts"

if [ $# -gt 0 ]; then
	echook "Starting at task with index $1"
	start_at=$1
fi


vagrant_boxes=("dc" "win_server" "win_workstation" "ubuntu_domain" "ubuntu_outside")
ansible_playbooks=("domain_controller.yml" "win_server.yml" "win_workstation.yml"
"linux_srv_in_domain.yml" "linux_srv_out_domain.yml")

for i in ${!vagrant_boxes[@]}; do
	if [ $i -lt $start_at ]; then
		echowarn "Skipping task for box \"${vagrant_boxes[$i]}\" with playbook\
 \"${ansible_playbooks[$i]}\""
	else
		echook "Running task for box \"${vagrant_boxes[$i]}\" with playbook\
 \"${ansible_playbooks[$i]}\""
		vagrant up ${vagrant_boxes[$i]}
		if [ $? -ne 0 ]; then
			echoerr "Could not boot \"${vagrant_boxes[$i]}\". Exiting..."
			exit 1
		fi
		ansible-playbook -i $ansible_inventory -T $ansible_con_timeout ${ansible_playbooks[$i]}
		if [ $? -ne 0 ]; then
			echoerr "Could not complete playbook \"${ansible_playbooks[$i]}\". Exiting..."
			exit 1
		fi
		vagrant halt ${vagrant_boxes[$i]}
        if [ $? -ne 0 ]; then
            echowarn "Could not halt \"${vagrant_boxes[$i]}\""
		else
			echook "Task completed successfully"
        fi
	fi
done
