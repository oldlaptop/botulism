#! /bin/sh
#
# An event loop; responds to messages on stdin. Output to stdout.

# Reformat a string (smash all newlines and create new ones at 80 columns) and
# dump it to stdout
writeout ()
{
	printf "%s\n" "${@}" | fold -s | head -n 5
}

# Evaluate and execute a dot-command, given the entire ${MSG} containing it. All
# dot-commands should be documented in the help file (see .help)
cmdeval ()
{
	# Get a full parameter string out of our single ${MSG}
	set -f
	set -- ${1}
	set +f

	allargs="${*}" # most commands need to strip ${0} with ${FOO##"bar"} or so
	case "${1}" in
		".echo")
			writeout "${allargs##".echo "}"
			;;
		".8ball")
			writeout "$(fortune "${PREFIX}/pseudo-fortunes/8ball")"
			;;
		".drink")
			RECIPIENT="${allargs##".drink"}"
			writeout "${MYNICK} slides${RECIPIENT:- ${NICK}} $(fortune "${PREFIX}/pseudo-fortunes/noun-beverage")"
			;;
		".slap")
			VICTIM="${allargs##".slap"}"
			writeout "${MYNICK} $(fortune "${PREFIX}/pseudo-fortunes/verb-slap")${VICTIM:- ${NICK}} with $(fortune "${PREFIX}/pseudo-fortunes/noun-slap")"
			;;
		".dc")
			# Further sanitization. We will hardcode precision, therefore k is
			# unnneeded (and represents a DoS vulnerability, consider something
			# like '100000000000000000k 2v'). Similarly, manual p makes no sense
			# and represents a spam amplification vulnerability (imagine, say,
			# 2vppppppppppppppppppp).
			EXPR=16k "$(printf "%s" "${allargs##'.dc '}" | tr -d 'pk')" p
			writeout "$(printf "%s" "${EXPR}" | dc)"
			;;
		".fortune")
			fortune
			;;
		".playing")
			writeout "$(mpc current)"
			;;
		".playlist")
			mpc playlist | head
			;;
		".define")
			# doesn't permit arbitrary args
			dargs="$(printf "%s" "${allargs##.define }" | tr -d '-')"
			writeout "$(dict -d! "${dargs}" 2>&1)"
			;;
		".dict")
			# permits arbitrary args to dict(1), deliberately
			# unquoted, but no globs for you
			set -f
			dict ${allargs##".dict "} 2>&1| head -n20
			set +f
			;;
		".correct")
			dargs="$(printf "%s" "${allargs##".correct "}" | tr -d '-')"
			writeout "$(dict -m "${dargs}" 2>&1)"
			;;
		".apropos")
			# permits arbitrary args to apropos(1), deliberately
			# unquoted, but no globs for you
			set -f
			apropos ${allargs##".apropos "} 2>&1 | head -n5
			set +f
			;;
		".weather")
			# weather(1) from weather-util is disgustingly slow on
			# some hardware such as my raspberrypi (first run is up
			# to a minute in CPython, and about half that in PyPy).
			# We accordingly run it in the background, so botulism
			# can respond to events while it spins.
			writeout "$(fortune "${PREFIX}/pseudo-fortunes/waiting")"
			weather kmbs & 2>&1
			;;
		".forecast")
			# TODO: It's still slow here, but because of all our
			# postprocessing, it's not convenient to run in the
			# background.
			writeout "$(fortune "${PREFIX}/pseudo-fortunes/waiting")"

			weather -fn kmbs > /tmp/wxlog
			cat | tr '[:upper:]' '[:lower:]' | tail -n $(( $(wc -l < /tmp/wxlog) - 5 )) | head -n20
			                                          # outer $(( ... )) is arithmetic
			rm /tmp/wxlog
			;;
		".help")
			cat "${PREFIX}/help"
			uname -sr
			;;
		".giveup")
			# Another command you don't want in a public channel
			writeout "bye"
			exit 0
			;;
		*)
			writeout "invalid command, $(fortune "${PREFIX}/pseudo-fortunes/lusernames")"
			;;
	esac
}

# Main event loop
while true
do
	# Default values; illegal for real messages because of our sanitization
	DATE="@none@"
	TIME="@none@"
	NICK="@none@"
	MSG="@none@"

	# Get input
	read -r LINE

	# Sanitize input
	set -f
	set -- $(printf "%s" "${LINE}" | tr -cd '.[:alnum:]-+/*%^ ')
	set +f

	# Parse input
	allargs="${*}"

	DATE="${1}"
	TIME="${2}"
	NICK="${3}"
	MSG="${allargs##"${DATE} ${TIME} ${NICK}"}"

	# if message is a dotcommand and is not from the bot
	if [ "${NICK}" != "${MYNICK}" ] && [ "$(echo ${MSG} | grep '^\.')" ]
	then                              # quotes around ${MSG} break it
		cmdeval "${MSG}"
	fi

	# if message is a status message of some kind
	if [ "${NICK}" = "${STATUSNICK}" ]
	then
		# define action type
		ACTION="$(printf "%s" "${MSG}" | grep -o 'has [a-z]*\>')"
		ACTION="${ACTION##"has "}"

		case "${ACTION}" in
			"joined")
				writeout "hello, $(fortune "${PREFIX}/pseudo-fortunes/lusernames")"
				;;
			"left")
				writeout "$(fortune "${PREFIX}/pseudo-fortunes/parting-shots")"
				;;
			"quit")
				writeout "$(fortune "${PREFIX}/pseudo-fortunes/parting-shots")"
				;;
			*)
				;;
		esac
	fi
done
