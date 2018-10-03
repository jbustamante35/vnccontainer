# vnccontainer
Docker image configuration files to test out running GUIs from docker containers. 

## Installation



## Usage
To configure the docker container's server from inside the container, follow these instructions. 
There is currently no implementation to do this from the Dockerfile.
This enables us to use a MATLAB GUI via ssh with X11 forwarding enabled.

### FROM CLIENT
#### Start docker container [ image: vnccontainer | tag: main ]
Open Port 22 and run --priviledged option
```
$ docker run --priviledged -p 22:22 -it main 0 na b__
```

### INSIDE DOCKER CONTAINER
#### Mount data from iRODS using FUSE [ use icommands 4.1.9 or 4.2.* ]
##### Enter CyVerse login information and path to data folder
---
**Julian's Login Information**

  Host Name (DNS): data.cyverse.org <br />
  Port Number: 1247 <br />
  User Name: jbustamante35 <br />
  iRODS Zone: iplant <br />
  Password: [ *hint*: my laptop's password ] <br />

---

```
$ cd ~/.irods
$ rm irods_environment.json
$ iinit
$ mkdir ~/data_home
$ irodsFs -o allow_other $HOME/data_home

### Make GUI files executable
$ chmod +x /loadingdock/codebase/o/matlab/iPlant_ver0
```

### Configure sshd config file in docker container
---
**Configure /etc/ssh/sshd_config**

Port 22 <br />
ChallengeResponseAuthentication no <br />
UsePAM yes <br />
PermitRootLogin yes <br />
AllowAgentForwarding yes <br />
X11Forwarding yes <br />
X11UseLocalhost no <br />
PrintMotd no <br />
AcceptEnv LANG LC_* <br />
Subsystem       sftp    /usr/lib/openssh/sftp-server <br />

---

### Set password and restart ssh daemon
#### Password is usually just 'plant'
```
$ passwd
$ service ssh restart
```

### FROM CLIENT
### Setup config file in ~/.ssh/config
Host dok
    HostName localhost
    Port 22
    User root
    ForwardX11 yes
    SendEnv LANG LC_*
    HashKnownHosts yes
    GSSAPIAuthentication yes

### SSH into root localhost with X11 forwarding
```
$ ssh dok
```
Or run with manual options 
```
$ ssh -Y root@localhost
```

### Export proper library path for MCR
```
$ export LD_LIBRARY_PATH=/lib:/lib65:/usr/lib:/usr/local/lib:/usr/local/mcr/v93/runtime/glnxa64:/usr/local/mcr/v93/bin/glnxa64:/usr/local/mcr/v93/sys/os/glnxa64:/usr/local/nvidia/lib:/usr/local/nvidia/lib64
$ export XAPPLRESDIR=/usr/local/mcr/v93/X11/app-defaults
```

### Set new name for libstdc++.so.6 [not compatible with MCR R2017b]
```
$ cd /usr/local/mcr/v93/sys/os/glnxa64
$ mv libstdc++.so.6 libstdc++.so.6.bak
$ cd /loadingdock/o/codebase/matlab
```

### Run phytoMorph kinematics tool to complete testing
```
$ ./iPlant_ver0
```




