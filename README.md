# From
This repository was built from kernelci/lava-docker

# LAVA Base Image
Install latest version of lava-server

## Running
Here is the command to run the lava-server docker

```
sudo docker run -it -p 69:69 -p 80:80 -p 2022:22 --volume /var/lib/tftpboot:/var/lib/lava/dispatcher/tmp -h <HOSTNAME> --privileged ywangwrs/lava-docker
```
