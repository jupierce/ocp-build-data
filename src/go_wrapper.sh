#!/bin/sh

echoerr() { cat <<< "$@" 1>&2; }

echoerr "ART go wrapper invoked"
echoerr "----"
echoerr "Environment:"
env 1>&2
echoerr "----"
echoerr "Command line arguments:"
cat <<< "$@" 1>&2
echoerr "----"

# Help to sanity check the use of FIPS compliant go builds by
# preventing CGO_ENABLED=0 use except in known exceptions.
if [[ "${CGO_ENABLED}" == "0" ]]; then
    >&2 echo "Preventing compilation because CGO_ENABLED=${CGO_ENABLED}"
    exit 1
fi

# The Dockerfile must ensure that "go.real" is in the current $PATH
go.real "$@"