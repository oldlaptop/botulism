#! /bin/sh
#
# Spawn event loops for each joined IRC channel. TODO: handle spawning ii

IRCDIR="${HOME}/botulism-irc"
SERVER="localhost"
CHANNELS="#chat"
MYNICK="botulism"
STATUSNICK="--" # actually -!-, but we sanitize the !

export MYNICK STATUSNICK

# Make sure our path is complete
export PATH="${PATH}:/usr/games"

# botulism installation directory, cwd by default
export PREFIX="$(pwd)"

EVLOOP_PIDS=

# Kill all event loops
die()
{
	for process in ${EVLOOP_PIDS}
	do
		kill ${process}
	done
}

# Spawn event loops on all channels
for channel in ${CHANNELS}
do
	# One watching the channel, one watching the server. TODO: It would be
	# nicer, in theory, for there to be one process reading server messages
	# and dumping output to each channel, perhaps using tee? As it stands
	# now, multiple channels haven't really been tested in the first place.
	tail -fn1 "${IRCDIR}/${SERVER}/${channel}/out" | sh "${PREFIX}/evloop.sh" > "${IRCDIR}/${SERVER}/${channel}/in" &
	EVLOOP_PIDS="${EVLOOP_PIDS} $!"
	tail -fn1 "${IRCDIR}/${SERVER}/out" | sh "${PREFIX}/evloop.sh" > "${IRCDIR}/${SERVER}/${channel}/in" &
	EVLOOP_PIDS="${EVLOOP_PIDS} $!"
done

# Idle, waiting to be SIGTERMed
trap die EXIT
wait

# All event loops are dead
printf "%s" "$0: all event loops died, terminating"
