#!/bin/bash

LEVEL=${1:-debug}

echo "Tailing logs for subsystem: dev.kazuryy.Armadillo.PacketTunnel (level: $LEVEL)"
echo "Press Ctrl+C to stop"
echo ""

log stream --predicate 'subsystem == "dev.kazuryy.Armadillo" OR subsystem == "dev.kazuryy.Armadillo.PacketTunnel"' --level $LEVEL --style compact
