#!/bin/bash

set -e

# 4.15
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.19-openshift-4.15 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.19-openshift-4.15
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.20-openshift-4.15 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.20-openshift-4.15
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.19-openshift-4.15 registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.19-openshift-4.15
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.20-openshift-4.15 registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.20-openshift-4.15

# 4.14
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.19-openshift-4.14 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.19-openshift-4.14
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.20-openshift-4.14 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.20-openshift-4.14
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.19-openshift-4.14 registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.19-openshift-4.14
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.20-openshift-4.14 registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.20-openshift-4.14

# 4.13
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.19-openshift-4.13 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.19-openshift-4.13
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-9-release-golang-1.19-openshift-4.13 registry.ci.openshift.org/ocp/builder:rhel-9-golang-1.19-openshift-4.13

# 4.12
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.19-openshift-4.12 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.19-openshift-4.12

# 4.11
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.18-openshift-4.11 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.18-openshift-4.11

# 4.10
# FIXED!
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-7-release-openshift-4.10 registry.ci.openshift.org/ocp/builder:rhel-7-golang-1.16-openshift-4.10
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.17-openshift-4.10 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.17-openshift-4.10

# 4.9
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-7-release-openshift-4.9 registry.ci.openshift.org/ocp/builder:rhel-7-golang-1.16-openshift-4.9
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.16-openshift-4.9 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.16-openshift-4.9

# 4.8
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-7-release-openshift-4.8 registry.ci.openshift.org/ocp/builder:rhel-7-golang-1.16-openshift-4.8
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.16-openshift-4.8 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.16-openshift-4.8

# 4.7
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-7-release-openshift-4.7 registry.ci.openshift.org/ocp/builder:rhel-7-golang-1.15-openshift-4.7
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.15-openshift-4.7 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.15-openshift-4.7

# 4.6
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-7-release-openshift-4.6 registry.ci.openshift.org/ocp/builder:rhel-7-golang-1.15-openshift-4.6
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.14-openshift-4.6 registry.ci.openshift.org/ocp/builder:rhel-8-golang-openshift-4.6
./rewrap_build_root.sh registry.ci.openshift.org/openshift/release:rhel-8-release-golang-1.15-openshift-4.6 registry.ci.openshift.org/ocp/builder:rhel-8-golang-1.15-openshift-4.6