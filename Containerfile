FROM quay.io/centos-bootc/centos-bootc:stream10
RUN --mount=type=bind,source=build.sh,destination=/build.sh bash /build.sh