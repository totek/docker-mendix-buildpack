# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.5
FROM ubuntu:bionic
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

#Install dependencies & remove package lists
RUN apt-get -q -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get install -q -y wget curl libpq5 locales python3 python3-distutils libssl1.0.0 libgdiplus libpython2.7 && \
  rm -rf /var/lib/apt/lists/*

#Set Locale to UTF-8 (needed for proper python3 functioning)
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8  

# Build-time variables
ARG BUILD_PATH=project
ARG DD_API_KEY

# Checkout CF Build-pack here
RUN mkdir -p buildpack/.local && \
   (wget -qO- https://github.com/MXClyde/cf-mendix-buildpack/archive/idb.tar.gz \
   | tar xvz -C buildpack --strip-components 1)

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation /buildpack

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Create the build destination
RUN mkdir build cache
COPY $BUILD_PATH build

# Compile the application source code and remove temp files
WORKDIR /buildpack
RUN "/buildpack/compilation" /build /cache && \
  rm -fr /cache /tmp/javasdk /tmp/opt

# Expose nginx port
ENV PORT 80
EXPOSE $PORT

RUN mkdir -p "/.java/.userPrefs/com/mendix/core"
RUN mkdir -p "/root/.java/.userPrefs/com/mendix/core"
RUN ln -s "/.java/.userPrefs/com/mendix/core/prefs.xml" "/root/.java/.userPrefs/com/mendix/core/prefs.xml"

# Start up application
COPY scripts/ /build
WORKDIR /build
RUN chmod u+x startup
ENTRYPOINT ["/build/startup","/buildpack/start.py"]
