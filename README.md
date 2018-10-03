# vnccontainer
Docker image configuration files to test out running GUIs from docker containers. 
This current version requires running the container in debug mode (run with /bin/bash argument) to configure the environment for X11 port forwarding and setting environmental variables for the MCR R2017b. 
This will eventually be implemented into the phytoshell docker image so that it becomes an option when one of our applications requires an interactive GUI.

## Notes
As of this version [10/03/2018], there are NVIDIA libraries and packages that seem to be required for the MCR to work. 
We still need to test whether this is necessary, or determine which parts are necessary.

This version [10/03/2018] also downgrades phytoshell's version of icommands from 4.1.11 to 4.1.9 in order for the fuse mounting command (irodsFs) to work properly. 
Version 4.1.10 and 4.1.11 have a bug that break the feature in Ubuntu 18.04. 

## Installation
A)  Download un-compiled docker image from GitHub
  1) Clone this repository into desired folder <br />
    ```
    $ git clone https://github.com/jbustamante35/vnccontainer
    ```
  2) Build docker image <br />
    ```
    $ docker build -t [name-for-image] /path/to/Dockerfile
    ```
  3) Run docker image <br />
    ```
    $ docker run --privileged -p 22:22 -it [name-for-image] [verobisty] [codebase] [application-instructions (see Usage)]
    ```

B) Pull pre-compiled docker image from DockerHub
  1) Pull repository from DockerHub with main tag <br />
    ```
    $ docker pull jbustamante35/vnccontainer:main
    ```
  2) Run docker image <br />
    ```
    $ docker run --privileged -p 22:22 -it [name-for-image] [verobisty] [codebase] [application-instructions (see Usage)]
    ```

## Usage
To configure the docker container's server from inside the container, follow these instructions. 
There is currently no implementation to do this from the Dockerfile.
This enables us to use a MATLAB GUI via ssh with X11 forwarding enabled.

### FROM CLIENT
#### Start docker container [ image: vnccontainer | tag: main ]
Open Port 22 and run --privileged option
```
$ docker run --privileged -p 22:22 -it main 0 na b__
```

### INSIDE DOCKER CONTAINER
#### Mount data from iRODS using FUSE [ use icommands 4.1.9 or 4.2.* ]
##### Enter CyVerse login information and path to data folder
---
**Julian's Login Information**

  **Host Name (DNS):** data.cyverse.org <br />
  **Port Number:** 1247 <br />
  **User Name:** jbustamante35 <br />
  **iRODS Zone:** iplant <br />
  **Password:** [ *hint*: my laptop's password ] <br />

---

```
$ cd ~/.irods
$ rm irods_environment.json
$ iinit
$ mkdir ~/data_home
$ irodsFs -o allow_other $HOME/data_home

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
### Setup ssh config file 
---
**Configure ~/.ssh/config**

Host dok <br />
    HostName localhost <br />
    Port 22 <br />
    User root <br />
    ForwardX11 yes <br />
    SendEnv LANG LC_* <br />
    HashKnownHosts yes <br />
    GSSAPIAuthentication yes <br />

---

### SSH into root localhost with X11 forwarding
```
$ ssh -C dok
```
Or run with manual options 
```
$ ssh -CX root@localhost
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
```

### Run phytoMorph kinematics tool to complete testing
```
$ cd /loadingdock/codebase/o/matlab/
$ chmod +x ./iPlant_ver0
$ ./iPlant_ver0
```


