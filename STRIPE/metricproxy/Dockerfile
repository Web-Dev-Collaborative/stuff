FROM scratch
MAINTAINER Matthew Pound <mwp@signalfx.com>

COPY ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt
COPY metricproxy /metricproxy

VOLUME /var/log/sfproxy
VOLUME /var/config/sfproxy

CMD ["/metricproxy", "-configfile", "/var/config/sfproxy/sfdbproxy.conf"]
