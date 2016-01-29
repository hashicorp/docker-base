FROM busybox:1.24.1-glibc

# BusyBox needs root certs enough to connect to HashiCorp APIs.
RUN mkdir -p /system/etc/security/cacerts
ADD config/certs/* /system/etc/security/cacerts/