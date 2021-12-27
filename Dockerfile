FROM ubuntu:20.04

ENV release=0.20.7

RUN apt-get update -y && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get -y install debhelper-compat rustc libdbus-1-dev libpulse-dev wget libssl-dev git dpkg-dev dh-make debhelper devscripts fakeroot file lintian patch patchutils quilt python

COPY entrypoint.sh entrypoint.sh
RUN ["chmod", "+x", "./entrypoint.sh"] 
ENTRYPOINT [ "./entrypoint.sh" ]

