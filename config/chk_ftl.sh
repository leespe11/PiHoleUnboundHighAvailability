#!/bin/bash
# Keepalived health check: exit 0 if the pihole container is running
# and pihole-FTL is alive inside it, exit 1 otherwise.
CONTAINER="pihole"

# Container must exist and be running
RUNNING=$(/usr/bin/docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null)
if [ "$RUNNING" != "true" ]; then
    exit 1
fi

# pihole-FTL must be running inside the container
# ([p] keeps grep from matching its own process)
if /usr/bin/docker exec "$CONTAINER" ps ax 2>/dev/null | grep -q '[p]ihole-FTL'; then
    exit 0
else
    exit 1
fi