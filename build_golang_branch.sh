#!/bin/bash

set -e
WRAPPER_SCRIPT=$(realpath target_go_wrapper.sh)
BASE="/home/jupierce/projects/goland-builder-migration"
BRANCH="$1"
OCBD="${BASE}/${BRANCH}"
DZD=/home/jupierce/projects/doozer
WBRANCH="$BRANCH-go-wrapper"

# If we cannot rebuild the builder, specify the existing builder and we will FROM it directly.
EXPLICIT_FROM="$2"

if [[ -z "$BRANCH" ]]; then
  echo "Branch name required."
  exit 1
fi

mkdir -p $BASE
cd $BASE
rm -rf $OCBD
git clone git@github.com:jupierce/ocp-build-data.git $OCBD
cd $OCBD
git remote add upstream git@github.com:openshift-eng/ocp-build-data.git
git fetch --all

pushd $OCBD

git checkout upstream/$BRANCH

METADATA="$OCBD/images/openshift-golang-builder.yml"
DOCKERFILE="$OCBD/images/openshift-golang-builder.Dockerfile"

if [[ ! -f "$METADATA" ]]; then
  echo "file not found: $METADATA"
  exit 1
fi

if [[ ! -f "$DOCKERFILE" ]]; then
  echo "file not found: $DOCKERFILE"
  exit 1
fi

GO_BRANCH=$(cat $METADATA | yq .distgit.branch)

if echo ${GO_BRANCH} | grep null ; then
  GO_BRANCH=$(cat $OCBD/group.yml | yq .branch)
fi

MAJOR=$(cat $OCBD/group.yml | yq .vars.MAJOR)
MINOR=$(cat $OCBD/group.yml | yq .vars.MINOR)

GO_BRANCH=$(echo "$GO_BRANCH" | sed s/\{MAJOR\}/${MAJOR}/g)
GO_BRANCH=$(echo "$GO_BRANCH" | sed s/\{MINOR\}/${MINOR}/g)
echo "Will be using distgit branch: ${GO_BRANCH}"

echo
echo
brew list-tagged --inherit --latest ${GO_BRANCH}-build | grep -e golang-
echo "Enter the go version for ${BRANCH}:"
read GO_VER


echo
echo
echo "Enter RHEL version ${BRANCH}:"
read EL_VER

echo
echo
git checkout -b $BRANCH-go-wrapper
cp $WRAPPER_SCRIPT images/go_wrapper.sh
cp $WRAPPER_SCRIPT go_wrapper.sh

# Do not publish for use by CPaaS
yq -i eval 'del(.additional_tags)' $METADATA
yq -i eval '.image_build_method = "osbs2"' $METADATA
yq -i eval '.content.source.git.branch.target = "'$WBRANCH'"' $METADATA
yq -i eval '.content.source.git.url = "git@github.com:jupierce/ocp-build-data.git"' $METADATA

if [[ -n "${EXPLICIT_FROM}" ]]; then
  echo "FROM ${EXPLICIT_FROM}" > $DOCKERFILE
  yq -i eval 'del(.from)' $METADATA
  yq -i eval ".from.image = \"${EXPLICIT_FROM}\"" $METADATA
fi

cat >> $DOCKERFILE <<'EOF'
COPY go_wrapper.sh /tmp/go_wrapper.sh
RUN /bin/bash -c 'GO_BIN_PATH=`which go`; mv $GO_BIN_PATH $GO_BIN_PATH.real; mv /tmp/go_wrapper.sh $GO_BIN_PATH; chmod +x $GO_BIN_PATH'
EOF

git add $METADATA
git add images/
git add go_wrapper.sh
git commit -m 'Apply consistent compiler args'
git push -f --set-upstream origin "$WBRANCH"

set -o xtrace
$DZD/doozer --group ${BRANCH} --data-path ${OCBD} images:rebase --version v${GO_VER} --release $(date '+%Y%m%d%H%M').el${EL_VER} --push -m 'Force CGO_ENABLED=1'
$DZD/doozer --group ${BRANCH} --data-path ${OCBD} images:build 2>&1 | tee ${BASE}/${BRANCH}.log