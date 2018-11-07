#########################################################################################
# Dockerfile for Ubuntu 18.04 with MATLAB, R, Python, Octave, and Julia
#
# This docker file will configure a linux environment into which a variety of 
# computational programming languages will be installed and configured for
# stand-alone programs to be executed.  
#
# Notes: 
# The Matlab Compiler Runtime allows stand-alone matlab routines (such
# as those created with Matlab's deploytool) to be executed. 
# Additionally, the MCR requires the environment variables LD_LIBRARY_PATH and XAPPLRESDIR to 
# be set to the following:
#       $ export LD_LIBRARY_PATH=/lib:/lib65:/usr/lib:/usr/local/lib:/usr/local/mcr/v93/runtime/glnxa64:/usr/local/mcr/v93/bin/glnxa6    4:/usr/local/mcr/v93/sys/os/glnxa64                                                                                                
#       $ export XAPPLRESDIR=/usr/local/mcr/v93/X11/app-defaults
# This overwrites the default method in which Ubuntu 18.04 finds it's libraries (LD_LIBRARY_PATH is 
# not set in typical environments). MCR applications are still able to run with no issues, but 
# many commands that require these libraries will be unusable. 
# 
# The installed version of R (3.2.2) contains a bug where it requires libreadline.so.6, whereas
# Ubuntu 18.04 only contains libreadline.so.7 (found in /lib/x86_64-linux-gnu/). This was fixed
# by simply setting the following soft link (see installRfromConda.sh line 4):
#       $ ln -s /lib/x86_64-linux-gnu/libreadline.so.7 /lib/x86_64-linux-gnu/libreadline.so.6
#
# Installing Anaconda typically requires user prompts, but the "yes" program allowed us to 
# bypass this. As a result, however, this meant the installation directory was set to 
# /yes/anaconda3, rather than the default ~/anaconda3. The installRfromConda.sh script 
# sets the conda command's home appropriately to /yes/bin/conda to correct for this.
#
# Octave requires the X11 DISPLAY environment variable to be set (in order to run GUI features). 
# When octave programs are run, the DISPLAY environment variable is set to:
#       $ export DISPLAY=0.0
# This seems to alleviate the problem enough to run scripts in Ubuntu 18.04, but we have not
# run enough tests to confirm this.
#
# This Docker image currently supports the following versions of each language:
#       MATLAB Runtime Compiler R2017b v93
#       R 3.2.2 (installed from Anaconda)
#       Python 3.6.5 (default) | Anaconda3-5.2.0 (conda 4.5.11)
#       GNU Octave 4.2.2
#       Julia 1.0.0
#        
# Instructions for Building and Deployment to DockerHub:
# build environment into Docker image
#       docker build -t phytoshell /path/to/dockerfile
#
# tag to DockerHub repository
#       docker tag phytoshell:latest [DHusername]/[DHrepo]:phytoshell
#
# push image to DockerHub repository
#       docker push [DHusernam]/[DHrepo]:phytoshell
#
# Authors
#       Nathan Miller, Senior Scientist (ndmill@gmail.com)
#       Julian Bustamante, Graduate Researcher (jbustamante@wisc.edu)
#########################################################################################

FROM ubuntu:18.04
RUN apt-get -qq update -y && apt-get -qq upgrade -y

# Update packages and install basic utilities and iRODS dependencies
RUN \
    apt-get -qq install -y \
    apt-utils bzip2 unzip wget xorg tzdata curl \
    libnspr4 libnss3 libnss3-dev libnss3-tools libjpeg62 libasound2 \
    libfuse2 libssl1.0.0 libgconf-2-4 ;

# Install iRODS commands
RUN \
    #curl ftp://ftp.renci.org/pub/irods/releases/4.1.11/ubuntu14/irods-icommands-4.1.11-ubuntu14-x86_64.deb -o irods-icommands.deb ; \
    curl ftp://ftp.renci.org/pub/irods/releases/4.1.9/ubuntu14/irods-icommands-4.1.9-ubuntu14-x86_64.deb -o irods-icommands.deb ; \
    dpkg -i irods-icommands.deb ;

# Install MATLAB 2017b MCR
RUN \
    mkdir /mcr-install /cvmfs /de-app-work ; \
    curl ssd.mathworks.com/supportfiles/downloads/R2017b/deployment_files/R2017b/installers/glnxa64/MCR_R2017b_glnxa64_installer.zip -o mcr2017b.zip ; \
    unzip -q mcr2017b.zip -d /mcr-install ; \	
    /mcr-install/install -destinationFolder /usr/local/mcr -agreeToLicense yes -mode silent ;
    
# Install anaconda to run python2.7/3.7 with dependencies
RUN \
    curl https://repo.anaconda.com/archive/Anaconda3-5.2.0-Linux-x86_64.sh -o anaconda3.sh && \ 
    yes "yes" | bash anaconda3.sh && \
    bash ~/.bashrc ;

# Install R from Anaconda
ADD installRfromConda.sh /
RUN \
    chmod +x installRfromConda.sh && \
    ./installRfromConda.sh ;

# Install Julia
RUN \
    curl https://julialang-s3.julialang.org/bin/linux/x64/1.0/julia-1.0.0-linux-x86_64.tar.gz -o julia.tar.gz ; \
    tar -xzf julia.tar.gz -C /usr/local/ ; \
    ln -s /usr/local/julia-1.0.0/bin/julia /usr/local/bin/julia ;

# Install Octave
RUN apt-get -qq install -y octave ;



# Set-up VNC capabilities
RUN \
    apt-get update -y && apt-get upgrade -y ; \
    apt-get -qq install -y \
    python-pip python3-pip \ 
    xvfb python3-pytest x11vnc git firefox ; \
    pip install --upgrade pip ; 
ENV DISPLAY :0
EXPOSE 22

RUN \
    mkdir ~/.vnc ; \
    x11vnc -storepasswd plant$ ~/.vnc/passwd ; \
    apt-get -qq install -y \
    xutils x11-utils x11-common x11-session-utils x11-apps \
    libx11-6 dbus-x11 \
    openssh-server ssh openssh-known-hosts \
    locate mlocate less vim ;

# Delete installation files
RUN rm -rf irods-icommands.deb mcr2017b.zip /mcr-install anaconda3.sh installRfromConda.sh ;

# Add wrapper, config, and test scripts
# Reading imaTest charts in MATLAB
ADD eSFRdefaultColorReference.mat /usr/local/bin/
ADD eSFRdefaultGrayReference.mat /usr/local/bin/

# Debugging scripts to test languages from /bin/bash
ADD langtest/ /usr/local/langtest/

# Default anonymous login for iRODS for configOSG.sh
ADD irods_environment.json /root/.irods/

# Parse lines of input_ticket.list for configOSG.sh
ADD evalTicket.sh /usr/local/bin/
ADD ticketParser.sh /usr/local/bin/

# Extract arguments from config.json file for configOSG.sh
ADD configOSG.sh /usr/local/bin/
ADD parseConfig.sh /usr/local/bin/

# Entrypoint for Docker image
ADD runner /usr/local/bin/
ADD wrapper /usr/bin/

# Make shell scripts executable
RUN chmod +x /usr/local/bin/evalTicket.sh
RUN chmod +x /usr/local/bin/ticketParser.sh
RUN chmod +x /usr/local/bin/parseConfig.sh
RUN chmod +x /usr/local/bin/configOSG.sh
RUN chmod +x /usr/local/bin/runner
RUN chmod +x /usr/bin/wrapper

# Create original and alternate codebases for configOSG.sh
RUN mkdir -p /sampleimages/maizeseedling/ /loadingdock/userdata/datain /loadingdock/userdata/dataout /loadingdock/codebase/o /loadingdock/codebase/a
WORKDIR /loadingdock
ADD {Plot_2435}{Experiment_80}{Planted_3-4-2018}{SeedSource_16B-7567-7}{SeedYear_2016}{Genotype_CML069}{Treatment_Control}{PictureDay_16}.nef /sampleimages/maizeseedling/

# ENTRYPOINT
ADD output_ticket.list /loadingdock
ADD input_ticket.list /loadingdock
ADD config.json /loadingdock
ENTRYPOINT ["/usr/bin/wrapper"]


# Install NVIDIA libraries
#RUN \
#    curl http://archive.ubuntu.com/ubuntu/pool/universe/g/gnupg/gnupg-curl_1.4.20-1ubuntu3_amd64.deb -o gnupg-curl.deb ; \
#    dpkg -i gnupg-curl.deb ; \
#    apt-get -qq install -y vim less sudo locate mlocate ;
#
#RUN \ 
#    apt-get -qq install -y --no-install-recommends ca-certificates apt-transport-https && \
#    rm -rf /var/lib/apt/lists/* && \
#    NVIDIA_GPGKEY_SUM=d1be581509378368edeec8c1eb2958702feedf3bc3d17011adbf24efacce4ab5 && \
#    NVIDIA_GPGKEY_FPR=ae09fe4bbd223a84b2ccfce3f60f4b3d7fa2af80 && \
#    apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub && \
#    apt-key adv --export --no-emit-version -a $NVIDIA_GPGKEY_FPR | tail -n +5 > cudasign.pub && \
#    #echo "$NVIDIA_GPGKEY_SUM  cudasign.pub" | sha256sum -c --strict - && rm cudasign.pub && \
#    echo "deb https://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list
#
### Replace all version 8.0.61 with version 10.0.130
##ENV CUDA_VERSION 8.0.61
#ENV CUDA_VERSION 10.0.130
#
##ENV CUDA_PKG_VERSION 8-0=$CUDA_VERSION-1
#ENV CUDA_PKG_VERSION 10-0=$CUDA_VERSION-1
#RUN apt-get update && apt-get install -y --no-install-recommends \
#    cuda-nvrtc-$CUDA_PKG_VERSION \
#    cuda-nvgraph-$CUDA_PKG_VERSION \
#    cuda-cusolver-$CUDA_PKG_VERSION \
#    #cuda-cublas-8-0=8.0.61.2-1 \
#    cuda-cublas-10-0=10.0.130-1 \
#    cuda-cufft-$CUDA_PKG_VERSION \
#    cuda-curand-$CUDA_PKG_VERSION \
#    cuda-cusparse-$CUDA_PKG_VERSION \
#    cuda-npp-$CUDA_PKG_VERSION \
#    cuda-cudart-$CUDA_PKG_VERSION && \
#    #ln -s cuda-8.0 /usr/local/cuda && \
#    ln -s cuda-10.0 /usr/local/cuda && \
#    rm -rf /var/lib/apt/lists/*
#
## nvidia-docker 1.0
#LABEL com.nvidia.volumes.needed="nvidia_driver"
#LABEL com.nvidia.cuda.version="${CUDA_VERSION}"
#
#RUN echo "/usr/local/nvidia/lib" >> /etc/ld.so.conf.d/nvidia.conf && \
#    echo "/usr/local/nvidia/lib64" >> /etc/ld.so.conf.d/nvidia.conf
#
#ENV PATH /usr/local/nvidia/bin:/usr/local/cuda/bin:${PATH}
#ENV LD_LIBRARY_PATH /usr/local/nvidia/lib:/usr/local/nvidia/lib64
#
## nvidia-container-runtime
#ENV NVIDIA_VISIBLE_DEVICES all
#ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
#ENV NVIDIA_REQUIRE_CUDA "cuda>=8.0"

# downgrade icommands 
ADD irods-icommands-4.1.9-cv-64bit-ubuntu-14.deb /
RUN dpkg -i /irods-icommands-4.1.9-cv-64bit-ubuntu-14.deb ;

#  
