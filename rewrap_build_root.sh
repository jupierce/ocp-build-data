#!/bin/bash

set -e
IMAGE_TO_REBUILD="$1"
docker pull "${IMAGE_TO_REBUILD}"

WRAPPER_SCRIPT_NAME="target_go_wrapper.sh"
WRAPPER_SCRIPT=$(realpath ${WRAPPER_SCRIPT_NAME})

BASE="/home/jupierce/projects/goland-builder-migration/wrapper_build_root"
mkdir -p $BASE
DOCKERFILE="${BASE}/Dockerfile"
cp "${WRAPPER_SCRIPT}" ${BASE}

cat <<- EOF > ${DOCKERFILE}
FROM ${IMAGE_TO_REBUILD}
ADD ${WRAPPER_SCRIPT_NAME} /usr/bin/go
RUN chmod +x /usr/bin/go
EOF

echo "Wrote ${DOCKERFILE}"
pushd ${BASE}

docker build . -f Dockerfile -t rewrapped_target
docker tag rewrapped_target ${IMAGE_TO_REBUILD}
docker push ${IMAGE_TO_REBUILD}