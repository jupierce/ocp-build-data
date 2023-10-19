#!/bin/bash

set -e
IMAGE_TO_REBUILD="$1"
GO_FROM_IMAGE="$2"

echo "${IMAGE_TO_REBUILD}" | grep "release:"
echo "${GO_FROM_IMAGE}" | grep "builder:"

docker pull "${IMAGE_TO_REBUILD}"
docker pull "${GO_FROM_IMAGE}"

WRAPPER_SCRIPT_NAME="target_go_wrapper.sh"
WRAPPER_SCRIPT=$(realpath ${WRAPPER_SCRIPT_NAME})

BASE="/home/jupierce/projects/goland-builder-migration/wrapper_build_root"
mkdir -p $BASE
pushd ${BASE}

rm -rf extract
mkdir extract

DOCKERFILE="${BASE}/Dockerfile"
cp "${WRAPPER_SCRIPT}" ${BASE}


TARGET_HAS_REAL=0
oc image extract ${IMAGE_TO_REBUILD} --path /usr/bin/go.real:extract
if [[ -f extract/go.real ]]; then
  # The image has a go.real, we are OK to overwrite just the script

  cat <<- EOF > ${DOCKERFILE}
FROM ${IMAGE_TO_REBUILD}
ADD ${WRAPPER_SCRIPT_NAME} /usr/bin/go
RUN chmod +x /usr/bin/go
EOF

else
  # The image does NOT have a go.real, we need to source it

  cat <<- EOF > ${DOCKERFILE}
FROM ${GO_FROM_IMAGE} as go_bin
RUN if [[ ! -f /usr/bin/go.real ]]; then cp \`which go\` /usr/bin/go.real; fi
FROM ${IMAGE_TO_REBUILD}
COPY --from=go_bin /usr/bin/go.real /usr/bin/go.real
ADD ${WRAPPER_SCRIPT_NAME} /usr/bin/go
RUN chmod +x /usr/bin/go
EOF

fi


echo "Wrote ${DOCKERFILE}"


docker build . -f Dockerfile -t rewrapped_target
docker tag rewrapped_target ${IMAGE_TO_REBUILD}
docker run --rm rewrapped_target go version | grep "go version"
if [[ "$?" != "0" ]]; then
  echo "Sanity check failed!"
  exit 1
fi

docker push ${IMAGE_TO_REBUILD}