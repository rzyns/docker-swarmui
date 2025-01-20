ARG IMAGE_BASE="ghcr.io/ai-dock/base-image:v2-cuda-12.4.1-cudnn-devel-22.04"
FROM ${IMAGE_BASE}

LABEL org.opencontainers.image.source=https://github.com/rzyns/docker-swarmui
LABEL org.opencontainers.image.description="SwarmUI Stable Diffusion backend and GUI"
LABEL maintainer="Janusz Dziurzyński <janusz@forserial.org>"

# Dotnet env stuff
ENV \
    # Do not generate certificate
    DOTNET_GENERATE_ASPNET_CERTIFICATE=false \
    # Do not show first run text
    DOTNET_NOLOGO=true \
    # SDK version
    DOTNET_SDK_VERSION=8.0.405 \
    # Enable correct mode for dotnet watch (only mode supported in a container)
    DOTNET_USE_POLLING_FILE_WATCHER=true \
    # Skip extraction of XML docs - generally not useful within an image/container - helps performance
    NUGET_XMLDOC_MODE=skip \
    # PowerShell telemetry for docker image usage
    POWERSHELL_DISTRIBUTION_CHANNEL=PSDocker-DotnetSDK-Ubuntu-24.04

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        git \
        libatomic1 \
        wget \
        dotnet-sdk-8.0 \
        build-essential python3.11 python3.11-venv python3.11-dev ffmpeg libglib2.0-0 libgl1 aria2 \
    && rm -rf /var/lib/apt/lists/*

# Install PowerShell global tool
RUN powershell_version=7.4.6 \
    && curl -fSL --output PowerShell.Linux.x64.$powershell_version.nupkg https://powershellinfraartifacts-gkhedzdeaghdezhr.z01.azurefd.net/tool/$powershell_version/PowerShell.Linux.x64.$powershell_version.nupkg \
    && powershell_sha512='676a69c7a0b03c6a2397a253ce54cb76857d4ddd252f9da7d9fc3d1cb7a62386316b73bd87519061f799fee60cbc39831060b263ebe0f200879c1524e8aea00d' \
    && echo "$powershell_sha512  PowerShell.Linux.x64.$powershell_version.nupkg" | sha512sum -c - \
    && mkdir -p /usr/share/powershell \
    && dotnet tool install --add-source / --tool-path /usr/share/powershell --version $powershell_version PowerShell.Linux.x64 \
    && dotnet nuget locals all --clear \
    && rm PowerShell.Linux.x64.$powershell_version.nupkg \
    && ln -s /usr/share/powershell/pwsh /usr/bin/pwsh \
    && chmod 755 /usr/share/powershell/pwsh \
    # To reduce image size, remove the copy nupkg that nuget keeps.
    && find /usr/share/powershell -print | grep -i '.*[.]nupkg$' | xargs rm

RUN git clone https://github.com/mcmonkeyprojects/SwarmUI.git /SwarmUI

WORKDIR /SwarmUI

RUN    git config --global --add safe.directory '*' \
    && [ -d Models ] && mv Models _Models || true \
    && [ -d Data ] && mv Data _Data || true \
    && [ -d .git/info ] && echo '/start.sh' >> .git/info/exclude

RUN chmod a+x ./launchtools/comfy-install-linux.sh && ./launchtools/comfy-install-linux.sh nv

    # && ln -s /workspace/Models Models \
    # && ln -s /workspace/Data Data

# Expose the port for other containers (to use Swarm as an API if you want
EXPOSE 7801
EXPOSE 6800

COPY ./start.sh /SwarmUI/start.sh

# Set the run file to the launch script
ENTRYPOINT ["bash", "./start.sh"]
