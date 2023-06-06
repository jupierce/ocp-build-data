#!/bin/sh

assert_equal() {
  output="$1"
  comparison="$2"
  if [[ "$output" != "$comparison" ]]; then
    echo "${BASH_LINENO[*]} Expected \"${comparison}\" but received \"${output}\""
  else
    echo "${BASH_LINENO[*]} Test OK: ${comparison}"
  fi
}

export SHIM_TEST=1

assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"

export OPENSHIFT_CI="true"  # Enable default exemptions for openshift CI
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset OPENSHIFT_CI

export __doozer_group="openshift-4.11"  # Enable default exemptions for openshift
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
# Leave default exemptions for openshift on for the remainder of these tests

export GO_COMPLIANCE_POLICY="exempt_all"
unset CGO_ENABLED
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED= version"

export GO_COMPLIANCE_POLICY="exempt_all"
export CGO_ENABLED=1
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"

export GO_COMPLIANCE_POLICY="exempt_all"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"

unset GO_COMPLIANCE_POLICY
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"

export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GOOS

export GO_COMPLIANCE_POLICY="none"
export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GO_COMPLIANCE_POLICY
unset GOOS

export GO_COMPLIANCE_POLICY="exempt_darwin"
export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GO_COMPLIANCE_POLICY

export GO_COMPLIANCE_POLICY="exempt_darwin"
export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GOOS
unset GO_COMPLIANCE_POLICY

export GOARCH="arm64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GOARCH

export GO_COMPLIANCE_POLICY="exempt_darwin"  # Drops exemption for cross compile
export GOARCH="arm64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GO_COMPLIANCE_POLICY
unset GOARCH

export GO_COMPLIANCE_POLICY="exempt_arch_amd64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GO_COMPLIANCE_POLICY

export GOARCH="arm64"
export CGO_ENABLED=1
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GOARCH

export GOARCH="amd64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GOARCH

export GO_COMPLIANCE_CGO_ENABLED_INCLUDE="version"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GO_COMPLIANCE_CGO_ENABLED_INCLUDE

export GO_COMPLIANCE_CGO_ENABLED_INCLUDE="else|version"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GO_COMPLIANCE_CGO_ENABLED_INCLUDE

export GO_COMPLIANCE_CGO_ENABLED_INCLUDE="else"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GO_COMPLIANCE_CGO_ENABLED_INCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="version"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="else|version"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=0 version"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="else"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "CGO_ENABLED=1 version"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version -ldflags '-extldflags "-static"' 2> /dev/null)" "CGO_ENABLED=1 version -ldflags -extldflags \"-lc\""

export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version -ldflags '-extldflags "-lm -static"' 2> /dev/null)" "CGO_ENABLED=1 version -ldflags -extldflags \"-lm -lc\""

export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version -ldflags '-extldflags " -static -lm"' 2> /dev/null)" "CGO_ENABLED=1 version -ldflags -extldflags \" -lc -lm\""

export CGO_ENABLED=1
assert_equal "$(./target_go_wrapper.sh version -ldflags '-extldflags " -static -lm"' 2> /dev/null)" "CGO_ENABLED=1 version -ldflags -extldflags \" -lc -lm\""

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="else|version"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh version -ldflags '-extldflags " -static -lm"' 2> /dev/null)" "CGO_ENABLED=0 version -ldflags -extldflags \" -lc -lm\""
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE
