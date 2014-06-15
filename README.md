# EC2 YARN Manager

## Setup

### AWS EC2 Images

The manager assumes the environment variable *$HADOOP_CONF_DIR* is available on every node
and that it points to the directory which contains the _masters_ and _slaves_ files used
by Hadoop *master* and *slave* instances.

The manager assumes at this stage that the EC2 path has been setup to allow automatic acceptance
of hosts for SSH.

#### Enabling automatic acceptance of SSH hosts.

If you've not yet enabled this add the following to `~/.ssh/config` file ...

```bash
Host *
    StrictHostKeyChecking no
```

Finally assign the appropriate permissions by running `chmod 600 ~/.ssh/config`. You are welcome
to tighten these restrictions as much as you'd like, the only restriction is each node must be
able to seemlessly SSH into every other node without terminal interaction. 

### Configuration File

Quickly setup the manager by running `cp conf.tempalte.yaml conf.yaml`
followed by `vim conf.yaml` and finally fill in all of the _TODO_ notes.

The following describes the configuration template in more detail.  

```yaml
# Timeout for refresh checking based actions
# such as adding nodes.
:timeout: 1
# Information for establishing SSH connections
# with nodes.
:console:
  # Username of EC2 nodes, e.g. EC2-user
  :user: TODO
  :keys:
    # Username of EC2 nodes, e.g. EC2-user
    - /home/TODO/.ssh/TODO.pem
# Tags for identifying EC2 nodess
:tags:
  :cluster: yarn
  :masters: master
  :slaves: slave
# Scaffolds defining how EC2 nodes are built
:scaffolds:
  :masters:
    :image_id: TODO
    :monitoring_enabled: true
    :key_name: TODO # Name of AWS KeyPair to access nodes.
    :security_groups:
      -ganglia
      -yarn-cluster
    :instance_type: t1.micro
    :block_device_mappings:
      -
        :device_name: /dev/sda1
        :ebs:
          :volume_size: 6
          :volume_type: standard
    # Added after the nodes are made, not supported
    # natively by AWS SDK.
    :tags:
      - Name: yarn-managed-master
      - yarn: master
      - ganglia: node
  :slaves:
    :image_id: TODO
    :monitoring_enabled: true
    :key_name: TODO # Name of AWS KeyPair to access nodes.
    :security_groups:
      - ganglia
      - yarn-cluster
    :instance_type: t1.micro
    :block_device_mappings:
      -
        :device_name: /dev/sda1
        :ebs:
          :volume_size: 6
          :volume_type: standard
    # Added after the node is made, not supported
    # natively by AWS SDK.
    :tags:
      - Name: yarn-managed-slave
      - yarn: slave
      - ganglia: node
```

## Commands

### status
#### --scope [all|masters|slaves], defaults to all

Writes a YAML representation of the all of the nodes discovered by the cluster tag to STDOUT.

Scope option defines values the clusters tag must be (either masters tags, or slaves tags).

### add NUMBER [masters|slaves]

Creates a new set of nodes using either the masters or slaves scaffold in conf.

### refresh

Constructs all new _masters_ and _slaves_ files and uploads them to the master node.
It then uploads _refresh.sh_ and executes it on the master node. 

### interact

Opens a poorly written mini console to execute commands over SSH, does not establish TTY or
stream output from the command back into the console. Output from the command is buffered
and returned in one go.

Use ! to exit the interactive shell.


## Licence

```
The MIT License (MIT)

Copyright (c) 2014 Jack Galilee

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
```