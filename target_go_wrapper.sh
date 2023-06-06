#!/bin/sh

LOG_PREFIX="Go compliance shim [${__doozer_group}][${__doozer_key}]:"
echoerr() {
  echo -n "${LOG_PREFIX} " 1>&2
  cat <<< "$@" 1>&2
}

run_go() {
  if [[ "${SHIM_TEST}" == "1" ]]; then
    echoerr "running with SHIM_TEST=${SHIM_TEST}"
    echo -n "CGO_ENABLED=${CGO_ENABLED} "
    cat <<< "${ARGS[@]}"
  else
    # The Dockerfile must ensure that "go.real" is in the current $PATH
    echoerr "invoking real go binary"
    go.real "${ARGS[@]}"
  fi
}

# Create an array of command line arguments.
ARGS=("$@")

GO_COMPLIANCE_CGO_ENABLED_INCLUDE=${GO_COMPLIANCE_CGO_ENABLED_INCLUDE:-'.*'}
GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE=${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE:-'.*'}
GO_COMPLIANCE_REQUIRE_SYMBOLS_INCLUDE=${GO_COMPLIANCE_REQUIRE_SYMBOLS_INCLUDE:-'.*'}

if [[ -n "${OPENSHIFT_CI}" || "${__doozer_group}" == "openshift"* ]]; then
  GO_COMPLIANCE_POLICY="${GO_COMPLIANCE_POLICY:-exempt_darwin,exempt_cross_compile}"
else
  GO_COMPLIANCE_POLICY="exempt_all"
fi

echoerr "config GO_COMPLIANCE_POLICY=\"${GO_COMPLIANCE_POLICY}\" GO_COMPLIANCE_CGO_ENABLED_INCLUDE=\"${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}\" GO_COMPLIANCE_CGO_ENABLED_EXCLUDE=\"${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}\" GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE=\"${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}\" GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE=\"${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}\" GO_COMPLIANCE_REQUIRE_SYMBOLS_INCLUDE=\"${GO_COMPLIANCE_REQUIRE_SYMBOLS_INCLUDE}\" GO_COMPLIANCE_REQUIRE_SYMBOLS_EXCLUDE=\"${GO_COMPLIANCE_REQUIRE_SYMBOLS_EXCLUDE}\""
echoerr "incoming command line"
echoerr "---------------------"
cat <<< "$@" 1>&2
echoerr "---------------------"
echo 1>&2

echoerr "incoming environment: "
echoerr "---------------------"
env 1>&2
echoerr "---------------------"
echo 1>&2

echoerr "assessment: CGO_ENABLED=${CGO_ENABLED:-1}"
if cat <<< "$@" | grep "-extldflags.*-static" > /dev/null; then
  echoerr "assessment: static linking"
else
  echoerr "assessment: dynamic linking"
fi

EXEMPT="0"
if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_darwin"* ]]; then
  if [[ "$GOOS" == "darwin" ]]; then
    echoerr "skipping forced compliance due to GOOS=${GOOS}"
    EXEMPT="1"
  fi
fi

if [[ "${SHIM_TEST}" == "1" ]]; then
  FOUND_HOST_ARCH="amd64"
else
  FOUND_HOST_ARCH="$(go.real env GOHOSTARCH)"
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_cross_compile"* ]]; then
  if [[ -n "${GOARCH}" && "${FOUND_HOST_ARCH}" != *"${GOARCH}"* ]]; then
    echoerr "skipping forced compliance due to cross-compile ${FOUND_HOST_ARCH} vs ${GOARCH}"
    EXEMPT="1"
  fi
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_arch_${FOUND_HOST_ARCH}"* ]]; then
  echoerr "skipping forced compliance due to FOUND_HOST_ARCH=${FOUND_HOST_ARCH}"
  EXEMPT="1"
fi

if [[ "${GO_COMPLIANCE_POLICY}" == *"exempt_all"* ]]; then
  echoerr "skipping forced compliance due to broad exemption"
  EXEMPT="1"
fi

FORCE_CGO_ENABLED=1
if [[ -n "${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_CGO_ENABLED_INCLUDE}" > /dev/null; then
    FORCE_CGO_ENABLED="1"
  else
    FORCE_CGO_ENABLED="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_CGO_ENABLED_EXCLUDE}" > /dev/null; then
    FORCE_CGO_ENABLED="0"
  fi
fi

FORCE_DYNAMIC=1
if [[ -n "${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_DYNAMIC_LINKING_INCLUDE}" > /dev/null; then
    FORCE_DYNAMIC="1"
  else
    FORCE_DYNAMIC="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE}" > /dev/null; then
    FORCE_DYNAMIC="0"
  fi
fi

FORCE_SYMBOLS=1
if [[ -n "${GO_COMPLIANCE_REQUIRE_SYMBOLS_INCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_REQUIRE_SYMBOLS_INCLUDE}" > /dev/null; then
    FORCE_SYMBOLS="1"
  else
    FORCE_SYMBOLS="0"
  fi
fi

if [[ -n "${GO_COMPLIANCE_REQUIRE_SYMBOLS_EXCLUDE}" ]]; then
  if cat <<< "$@" | grep -E "${GO_COMPLIANCE_REQUIRE_SYMBOLS_EXCLUDE}" > /dev/null; then
    FORCE_SYMBOLS="0"
  fi
fi

echoerr "EXEMPT: ${EXEMPT}"
if [[ "${EXEMPT}" != "1" ]]; then

  echoerr "not exempt: FORCE_CGO_ENABLED=\"${FORCE_CGO_ENABLED}\" FORCE_DYNAMIC=\"${FORCE_DYNAMIC}\""

  if [[ "${FORCE_DYNAMIC}" == "1" || "${FORCE_SYMBOLS}" == "1" ]]; then
    # Compilation with -extldflags "-static" is problematic with
    # CGO_ENABLED=1 because compilation tries to link against
    # static libraries which don't exist. Remove -static flag
    # when detected. This is tricky because extldflags can be simple
    # or something like -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'
    IN_LDFLAGS=0
    ARGS=()  # We need to rebuild the argument list.
    for arg in "$@"; do

      if [[ "${IN_LDFLAGS}" == "1" ]]; then
        # The previous argument was -ldflags. Remove symbol stripping like: -ldflags '-w -s'
        # but note that the ld flags can be complex like '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'
        if [[ "${FORCE_SYMBOLS}" == "1" ]]; then
          pre_arg="${arg}"
          # Seds out -s and -w and then removes trailing whitespace. Note this could leave us with an empty string.
          arg=$(echo "${arg}" | sed 's/-s\([^[:alnum:]]\|$\)/\1/g' | sed 's/-w\([^[:alnum:]]\|$\)/\1/g' | sed -e 's/[[:space:]]*$//'))
          if [[ -z "${arg}" ]]; then
            # If we are left with an empty string, plug in something benign
            arg=
          fi
          if [[ "${pre_arg}" != "${arg}" ]]; then
            echoerr "eliminated stripping of debug symbols"
          fi
        fi
        IN_LDFLAGS=0
      fi

      if [[ "${arg}" == "-ldflags" ]]; then
        IN_LDFLAGS=1
      fi

      # Note that extldflags is a flag embedded within the value of the
      # -ldflags argument. From our script's perspective, it will be part of a single
      # argument, but this argument might look like '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-lm -lstdc++ -static"'.
      if [[ "${arg}" == *"-extldflags"* && "${FORCE_DYNAMIC}" == "1" ]]; then
        # We replace -static with -lc because '-lc' implies to link against stdlib. This is a default
        # and should therefore be benign for virtually any compilation (unless -nostdlib or -nodefaultlibs
        # is specified -- and we don't account for this).
        # Why replace instead of remove? Consider the complex possible scenarios:
        # -ldflags '-extldflags "-static"'   # Removing -extldflags would mean we also need to remove ldflags.
        # -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-static"'  # Would remove extldflags but keep ldflags
        # -ldflags '-X $(REPO_PATH)/pkg/version.Raw=$(VERSION) -extldflags "-static -lm"'  # Would need to remove -static but keep extldflags
        # In any scenario, replacing "-static" with something benign should work without the need for complex logic.
        pre_arg="${arg}"
        arg=$(echo "${arg}" | sed "s/-static/-lc/g")
        if [[ "${pre_arg}" != "${arg}" ]]; then
          echoerr "eliminated static"
        fi
      fi
      ARGS+=("${arg}")
    done
    echoerr "updated command line arguments:"
    echoerr "---------------------"
    cat <<< "$@" 1>&2
    echoerr "---------------------"
  else
    echoerr "skipped static removal because FORCE_DYNAMIC=${FORCE_DYNAMIC}"
  fi

  if [[ "${FORCE_CGO_ENABLED}" == "1" ]]; then
      export CGO_ENABLED="1"
      echoerr "forced CGO_ENABLED=${CGO_ENABLED}"
  fi

fi

run_go "${ARGS[@]}"
