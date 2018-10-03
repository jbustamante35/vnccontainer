# vnccontainer
Docker image configuration files to test out running GUIs from docker containers. 

## Installation



## Usage
To configure the docker container's server from inside the container, follow these instructions. 
There is currently no implementation to do this from the Dockerfile.
This enables us to use a MATLAB GUI via ssh with X11 forwarding enabled.

### FROM CLIENT
#### Start docker container ['vnccontainer' image, 'main' tag]
Open Port 22 and run --priviledged option
```
$ docker run --priviledged -p 22:22 -it main 0 na b__
```

### INSIDE DOCKER CONTAINER
#### Mount data from iRODS using FUSE [use icommands 4.1.9 or 4.2.*]
##### Enter CyVerse login information and path to data folder
---
**Julian's Login Information**

  Host Name (DNS): data.cyverse.org
  Port Number: 1247
  User Name: jbustamante35
  iRODS Zone: iplant
  Password: [your password for this laptop]

---


```
cd ~/.irods
rm irods_environment.json
iinit
mkdir ~/data_home
irodsFs -o allow_other $HOME/data_home

### Make GUI files executable
chmod +x /loadingdock/codebase/o/matlab/iPlant_ver0
```

### Configure /etc/ssh/sshd_config file in docker container
Port 22
ChallengeResponseAuthentication no
UsePAM yes
PermitRootLogin yes
AllowAgentForwarding yes
X11Forwarding yes
X11UseLocalhost no
PrintMotd no
AcceptEnv LANG LC_*
Subsystem       sftp    /usr/lib/openssh/sftp-server

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
Or do manually
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




