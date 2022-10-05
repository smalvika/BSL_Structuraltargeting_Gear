#FROM ubuntu:bionic
#FROM dbp2123/afni:0.0.1_20.0.18

######################################################################
# ANTS     #
######################################################################

FROM ubuntu:xenial-20200706
# Prepare environment
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
                    curl \
                    bzip2 \
                    ca-certificates \
                    xvfb \
                    build-essential \
                    autoconf \
                    libtool \
                    pkg-config \
                    git && \
    curl -sSL https://deb.nodesource.com/setup_10.x | bash - && \
    apt-get install -y --no-install-recommends \
                    nodejs && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Installing ANTs 2.3.4 (NeuroDocker build)
ENV ANTSPATH="/usr/lib/ants" \
    PATH="/usr/lib/ants:$PATH"


WORKDIR $ANTSPATH
#$ANTSPATH/antsRegistrationSyN.sh

RUN curl -sSL "https://dl.dropbox.com/s/gwf51ykkk5bifyj/ants-Linux-centos6_x86_64-v2.3.4.tar.gz" \
    | tar -xzC $ANTSPATH --strip-components 1


#################
# FSL  Install
###################
FROM neurodebian:trusty
MAINTAINER Flywheel <support@flywheel.io>


# Install dependencies
RUN echo deb http://neurodeb.pirsquared.org data main contrib non-free >> /etc/apt/sources.list.d/neurodebian.sources.list
RUN echo deb http://neurodeb.pirsquared.org trusty main contrib non-free >> /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-get update \
    && apt-get install -y \
        bc \
        bsdtar \
        curl \
        fsl-5.0-complete \
        jq \
        lsb-core \
        python-pip \
        python3-pip \
        zip


ENV ANTSPATH="/usr/lib/ants" \
    PATH="/usr/lib/ants:$PATH"
COPY --from=0 $ANTSPATH $ANTSPATH

# Make directory for flywheel spec (v0)
ENV FLYWHEEL=/flywheel/v0
RUN mkdir -p ${FLYWHEEL}

# Set ENV variables
ENV FSLBROWSER=/etc/alternatives/x-www-browser
ENV FSLDIR=/usr/share/fsl/5.0
ENV FSLMULTIFILEQUIT=TRUE
ENV FSLOUTPUTTYPE=NIFTI_GZ
ENV FSLTCLSH=/usr/bin/tclsh
ENV FSLWISH=/usr/bin/wish
#ENV LD_LIBRARY_PATH=/usr/lib/fsl/5.0
#ENV PATH=/usr/lib/fsl/5.0:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV POSSUMDIR=/usr/share/fsl/5.0

#ENV FLYWHEEL=/flywheel/v0


COPY antsRegistrationSyN.sh $FLYWHEEL
COPY run $FLYWHEEL/run
COPY Structural_Targeting.sh $FLYWHEEL

COPY STD_MASKS.zip $FLYWHEEL/STD_MASKS.zip
RUN unzip $FLYWHEEL/STD_MASKS.zip -d $FLYWHEEL && rm -rf $FLYWHEEL/__MACOSX && \
    rm $FLYWHEEL/STD_MASKS.zip
COPY BrainTemplates.zip $FLYWHEEL/BrainTemplates.zip
RUN unzip $FLYWHEEL/BrainTemplates.zip -d $FLYWHEEL && rm -rf $FLYWHEEL/__MACOSX && \
    rm $FLYWHEEL/BrainTemplates.zip


RUN chmod +x $FLYWHEEL/run \
             $FLYWHEEL/Structural_Targeting.sh \
             $FLYWHEEL/antsRegistrationSyN.sh

ENTRYPOINT ["/bin/bash"]
