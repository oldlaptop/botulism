#! /bin/sh
#
# Spawn event loops for each joined IRC channel. TODO: handle spawning ii

IRCDIR="${HOME}/botulism-irc"
SERVER="localhost"
CHANNELS="#chat"

export MYNICK="botulism"
export STATUSNICK="--" # actually -!-, but we sanitize the !

# Make sure our path is complete
PATH="${PATH}:/usr/games"

# Spawn event loops on all channels
for channel in ${CHANNELS}
do
	# One watching the channel, one watching the server. TODO: It would be
	# nicer, in theory, for there to be one process reading server messages
	# and dumping output to each channel, perhaps using tee? As it stands
	# now, multiple channels haven't really been tested in the first place.
	tail -fn1 "${IRCDIR}/${SERVER}/${channel}/out" | sh evloop.sh > "${IRCDIR}/${SERVER}/${channel}/in" &
	tail -fn1 "${IRCDIR}/${SERVER}/out" | sh evloop.sh > "${IRCDIR}/${SERVER}/${channel}/in" &
done
