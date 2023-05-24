#!/bin/sh

echoerr() { cat <<< "$@" 1>&2; }

if [[ -n "${__doozer}" ]]; then
  echoerr "ART go wrapper invoked"
  echoerr "----"

  if [[ "${NO_CGO_CHECK}" != "1"  ]]; then
    echoerr "Environment:"
    env 1>&2
    echoerr "----"
    echoerr "Command line arguments:"
    cat <<< "$@" 1>&2
    echoerr "----"


    if [[ "${CGO_ENABLED}" == "0" ]]; then
        echoerr "Preventing compilation because CGO_ENABLED=${CGO_ENABLED}"
        exit 1
    fi

  fi

  echoerr "Invoking actual go binary"
fi

# The Dockerfile must ensure that "go.real" is in the current $PATH
go.real "$@"