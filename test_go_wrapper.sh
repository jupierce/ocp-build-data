#!/bin/sh

assert_equal() {
  output="$1"
  comparison="$2"
  if [[ "$output" != "$comparison" ]]; then
    echo "---------------FAIL------------------"
    echo "${BASH_LINENO[*]} Expected \"${comparison}\" but received \"${output}\""
    echo
  else
    echo "${BASH_LINENO[*]} Test OK: ${comparison}"
  fi
}

# Shim should just output results instead of invoking go.
export SHIM_TEST=1
export GO_COMPLIANCE_INFO=1

# Unless OPENSHIFT_CI or __doozer_group=="openshift-*", then the shim should
# not change the command line or environment.
unset CGO_ENABLED
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED= [version]"

unset CGO_ENABLED
assert_equal "$(./target_go_wrapper.sh build -o=something 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED= [build][-o=something]"

# Ensure CGO_ENABLED is not changed
export CGO_ENABLED=1
assert_equal "$(./target_go_wrapper.sh version 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=1 [version]"

# Ensure tags are not changed
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -tags no_openssl,another_tag 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build][-tags][no_openssl,another_tag]"
assert_equal "$(./target_go_wrapper.sh build --tags no_openssl,another_tag 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build][--tags][no_openssl,another_tag]"

# Ensure extldflags are not changed
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -tags no_openssl,another_tag -ldflags '-extldflags "-static"' 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build][-tags][no_openssl,another_tag][-ldflags][-extldflags \"-static\"]"

# Ensure GOEXPERIMENT is not changed
export GOEXPERIMENT="test"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -tags no_openssl,another_tag -ldflags '-extldflags "-static"' 2> /dev/null)" "GOEXPERIMENT=test CGO_ENABLED=0 [build][-tags][no_openssl,another_tag][-ldflags][-extldflags \"-static\"]"
unset GOEXPERIMENT

export GOEXPERIMENT="test"
export OPENSHIFT_CI="true"  # Enable default exemptions for openshift CI
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime,test CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset OPENSHIFT_CI
unset GOEXPERIMENT

export __doozer_group="openshift-4.11"  # Enable default exemptions for openshift
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
# Leave default exemptions for openshift on for the remainder of these tests

export GO_COMPLIANCE_POLICY="exempt_all"
unset CGO_ENABLED
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED= [build]"

export GO_COMPLIANCE_POLICY="exempt_all"
export CGO_ENABLED=1
export GOEXPERIMENT="test"
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=test CGO_ENABLED=1 [build]"
unset GOEXPERIMENT

export GO_COMPLIANCE_POLICY="exempt_all"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"

unset GO_COMPLIANCE_POLICY
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"

export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"
unset GOOS

export GOOS="windows"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"
unset GOOS

export GO_COMPLIANCE_POLICY="none"
export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_POLICY
unset GOOS

export GO_COMPLIANCE_POLICY="none"
export GOOS="windows"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_POLICY
unset GOOS

export GO_COMPLIANCE_POLICY="exempt_darwin"
export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"
unset GO_COMPLIANCE_POLICY

export GO_COMPLIANCE_POLICY="exempt_darwin"
export GOOS="darwin"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"
unset GOOS
unset GO_COMPLIANCE_POLICY

# Test cross compile exemption
export GOARCH="arm64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"
unset GOARCH

export GO_COMPLIANCE_POLICY="exempt_darwin"  # Drops exemption for cross compile
export GOARCH="arm64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_POLICY
unset GOARCH

export GO_COMPLIANCE_POLICY="exempt_arch_amd64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=0 [build]"
unset GO_COMPLIANCE_POLICY

export GOARCH="arm64"
export CGO_ENABLED=1
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=1 [build]"
unset GOARCH

export GOARCH="amd64"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GOARCH

export GO_COMPLIANCE_CGO_ENABLED_INCLUDE="build"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_CGO_ENABLED_INCLUDE

export GO_COMPLIANCE_CGO_ENABLED_INCLUDE="else|build"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_CGO_ENABLED_INCLUDE

export GO_COMPLIANCE_CGO_ENABLED_INCLUDE="else"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=0 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_CGO_ENABLED_INCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="build"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=0 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="else|build"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=0 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="else"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime]"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

# Test -tags=<val>  instead of -tags <val>
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -tags=test 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags=test,strictfipsruntime]"

export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags "-static"' 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime][-ldflags][-extldflags \"-lc\"]"

export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags "-lm -static"' 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime][-ldflags][-extldflags \"-lm -lc\"]"

export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags " -static -lm"' 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime][-ldflags][-extldflags \" -lc -lm\"]"

export CGO_ENABLED=1
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags " -static -lm"' 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime][-ldflags][-extldflags \" -lc -lm\"]"

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="else|build"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags " -static -lm"' 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=0 [build][-tags][strictfipsruntime][-ldflags][-extldflags \" -lc -lm\"]"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE

export GO_COMPLIANCE_CGO_ENABLED_EXCLUDE="build.*operator-lifecycle-manager/util/cpb"
export GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE="build.*operator-lifecycle-manager/util/cpb"
export CGO_ENABLED=0
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags "-static"' -o github.com/operator-framework/operator-lifecycle-manager/util/cpb 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=0 [build][-tags][strictfipsruntime][-ldflags][-extldflags \"-static\"][-o][github.com/operator-framework/operator-lifecycle-manager/util/cpb]"
unset GO_COMPLIANCE_CGO_ENABLED_EXCLUDE
unset GO_COMPLIANCE_DYNAMIC_LINKING_EXCLUDE

export GO_COMPLIANCE_EXCLUDE="build.*operator-lifecycle-manager/util/cpb"
export CGO_ENABLED=0
export GOEXPERIMENT="test"
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags "-static"' -o github.com/operator-framework/operator-lifecycle-manager/util/cpb 2> /dev/null)" "GOEXPERIMENT=test CGO_ENABLED=0 [build][-ldflags][-extldflags \"-static\"][-o][github.com/operator-framework/operator-lifecycle-manager/util/cpb]"
unset GO_COMPLIANCE_EXCLUDE
unset GOEXPERIMENT

export GO_COMPLIANCE_FOD_MODE_EXCLUDE="build.*operator-lifecycle-manager/util/cpb"
export CGO_ENABLED=0
export GOEXPERIMENT="test"
assert_equal "$(./target_go_wrapper.sh build -ldflags '-extldflags "-static"' -o github.com/operator-framework/operator-lifecycle-manager/util/cpb 2> /dev/null)" "GOEXPERIMENT=test CGO_ENABLED=1 [build][-ldflags][-extldflags \"-lc\"][-o][github.com/operator-framework/operator-lifecycle-manager/util/cpb]"
unset GO_COMPLIANCE_FOD_MODE_EXCLUDE
unset GOEXPERIMENT

# Do not apply tags to non build command unless it contains -tags.
assert_equal "$(./target_go_wrapper.sh version -something 5 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [version][-something][5]"

assert_equal "$(./target_go_wrapper.sh build -tags safe_tag,another_safe_tag 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][safe_tag,another_safe_tag,strictfipsruntime]"
assert_equal "$(./target_go_wrapper.sh build --tags safe_tag,another_safe_tag 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][--tags][safe_tag,another_safe_tag,strictfipsruntime]"

assert_equal "$(./target_go_wrapper.sh build -tags no_openssl 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][shim_prevented_no_openssl,strictfipsruntime]"

assert_equal "$(./target_go_wrapper.sh build -tags safe_tag,no_openssl,another_safe_tag 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][safe_tag,shim_prevented_no_openssl,another_safe_tag,strictfipsruntime]"

export GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE="not_build" # Prevent include from matching
assert_equal "$(./target_go_wrapper.sh build -tags safe_tag,no_openssl,another_safe_tag 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][safe_tag,no_openssl,another_safe_tag,strictfipsruntime]"
unset GO_COMPLIANCE_OPENSSL_ENABLED_INCLUDE

export GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE="build"
assert_equal "$(./target_go_wrapper.sh build -tags safe_tag,no_openssl,another_safe_tag 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][safe_tag,no_openssl,another_safe_tag,strictfipsruntime]"
unset GO_COMPLIANCE_OPENSSL_ENABLED_EXCLUDE

export GO_COMPLIANCE_FOD_MODE_INCLUDE="not_build" # Prevent include from matching
assert_equal "$(./target_go_wrapper.sh build -tags safe_tag,no_openssl,another_safe_tag 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=1 [build][-tags][safe_tag,shim_prevented_no_openssl,another_safe_tag]"
unset GO_COMPLIANCE_FOD_MODE_INCLUDE

assert_equal "$(./target_go_wrapper.sh build ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"

assert_equal "$(./target_go_wrapper.sh build -tags 'space delimited tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][space delimited tags strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
assert_equal "$(./target_go_wrapper.sh build --tags 'space delimited tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][--tags][space delimited tags strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"

assert_equal "$(./target_go_wrapper.sh build -tags='space delimited tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags=space delimited tags strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
assert_equal "$(./target_go_wrapper.sh build --tags='space delimited tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][--tags=space delimited tags strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"

assert_equal "$(./target_go_wrapper.sh build -tags='comma,delimited,tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags=comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
assert_equal "$(./target_go_wrapper.sh build --tags='comma,delimited,tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][--tags=comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"

# Remove extraneous quotes from tags
assert_equal "$(./target_go_wrapper.sh build -tags="'comma,delimited,tags'" ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags=comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
assert_equal "$(./target_go_wrapper.sh build -tags "'comma,delimited,tags'" ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][-tags][comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
assert_equal "$(./target_go_wrapper.sh build --tags="'comma,delimited,tags'" ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][--tags=comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
assert_equal "$(./target_go_wrapper.sh build --tags "'comma,delimited,tags'" ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [build][--tags][comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"

# Ignore run command which includes 'build' string.
assert_equal "$(./target_go_wrapper.sh run build.go build 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime CGO_ENABLED=1 [run][build.go][build]"

# Ensure strictfipsruntime is not included in GOEXPERIMENT twice
export GOEXPERIMENT="strictfipsruntime,test"
assert_equal "$(./target_go_wrapper.sh build -tags='comma,delimited,tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT=strictfipsruntime,test CGO_ENABLED=1 [build][-tags=comma,delimited,tags,strictfipsruntime][./cmd/cluster-openshift-apiserver-operator]"
unset GOEXPERIMENT

export GO_COMPLIANCE_FOD_MODE_INCLUDE="not_build" # Prevent include from matching
assert_equal "$(./target_go_wrapper.sh build -tags='space delimited tags' ./cmd/cluster-openshift-apiserver-operator 2> /dev/null)" "GOEXPERIMENT= CGO_ENABLED=1 [build][-tags=space delimited tags][./cmd/cluster-openshift-apiserver-operator]"
unset GO_COMPLIANCE_FOD_MODE_INCLUDE