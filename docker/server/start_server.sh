#!/bin/sh

_term() {
  echo "Caught SIGTERM signal! Sending graceful stop to uWSGI through the master-fifo"
  # See details in the uwsgi.ini file and
  # in http://uwsgi-docs.readthedocs.io/en/latest/MasterFIFO.html
  # q means "graceful stop"
  echo q > /tmp/uwsgi-fifo
}

trap _term SIGTERM

# Allow to define dollars in the templates
export DOLLAR='$'
envsubst < /opt/server/uwsgi.ini.template > /opt/server/uwsgi.ini
if [ -f /opt/vendor/uwsgi_exporter ]; then
   /opt/vendor/uwsgi_exporter -listen-address 0.0.0.0:9091 -uwsgi-stats-address unix:///tmp/uwsgi.stats.sock &
fi
uwsgi --ini /opt/server/uwsgi.ini &

# We need to wait to properly catch the signal, that's why uWSGI is started
# in the background. $! is the PID of uWSGI
wait $!
# The container exits with code 143, which means "exited because SIGTERM"
# 128 + 15 (SIGTERM)
# http://www.tldp.org/LDP/abs/html/exitcodes.html
# http://tldp.org/LDP/Bash-Beginners-Guide/html/sect_12_02.html
