#!/bin/bash
set -e

DOCKERFILE='Dockerfile'
IMAGE_REPOSITORY='kaggle'
IMAGE_TAG='latest'
GCR_HOST='gcr.io/mario-318203'
TARGET='base'

usage() {
  cat << EOF
  Usage: $0 [OPTIONS]
  Build a new RUBIK-CUBE Docker image.

  Options:
    build   Build a new image.
    push    Push the image to remote repository(GCR).
    run     Run the specific image with source and target. (default tag is \`latest\`.)
EOF
}

build() {
  local TAG=$1
  local TARGET=$2
  DOCKER_BUILDKIT=1 DOCKER_CLI_EXPERIMENTAL=enabled docker build --compress --squash --target "${TARGET}" -t "${IMAGE_REPOSITORY}:${TAG}" -f $DOCKERFILE .
}

push() {
  local TAG=$1
  gcloud auth configure-docker
  docker tag "${IMAGE_REPOSITORY}:${TAG}" "${GCR_HOST}/${IMAGE_REPOSITORY}:${TAG}"
  docker push "${GCR_HOST}/${IMAGE_REPOSITORY}:${TAG}"
}

run() {
  local TAG=$1
  local MOUNT_OPTION=""

  gcloud auth configure-docker
  docker pull "${GCR_HOST}/${IMAGE_REPOSITORY}:${TAG}"
  docker run -it ${MOUNT_OPTION} -p 8888:8888 --gpus all --shm-size=128G "${GCR_HOST}/${IMAGE_REPOSITORY}:${TAG}"
}

for i in "${@}"; do
  case ${i} in
    -h|--help)
      usage
      exit
      ;;
    -t|--tag)
      shift
      export IMAGE_TAG=${1}
      shift
      ;;
    --target)
      shift
      export TARGET=${1}
      shift
      ;;
    build|push|run)
      export COMMAND=${i}
      shift
      ;;
    -?*)
      usage
      printf 'ERROR: Unknown option: %s\n' "$1" >&2
      exit
      ;;
    *)
      ;;
  esac
done

if [[ ${COMMAND} == "run" ]]; then
  ${COMMAND} "${IMAGE_TAG}"
elif [[ ${COMMAND} == "build" ]]; then
  ${COMMAND} "${IMAGE_TAG}" "${TARGET}"
else
  ${COMMAND} "${IMAGE_TAG}"
fi

set -x
