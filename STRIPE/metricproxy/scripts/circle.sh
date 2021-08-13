#!/bin/bash
set -ex

CIRCLEUTIL_TAG="v1.41"
DEFAULT_GOLANG_VERSION="1.8.1"
GO_TESTED_VERSIONS="1.6.1 1.7.1 1.8.1"

export GOLANG_VERSION="1.8.1"
export GOROOT="$HOME/go_circle"
export GOPATH="$HOME/.go_circle"
export GOPATH_INTO="$HOME/lints"
export PATH="$GOROOT/bin:$GOPATH/bin:$GOPATH_INTO:$PATH"
export DOCKER_STORAGE="$HOME/docker_images"
export IMPORT_PATH="github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME"

GO_COMPILER_PATH="$HOME/gover"
SRC_PATH="$GOPATH/src/$IMPORT_PATH"

function docker_url() {
  echo -n "quay.io/signalfx/metricproxy:$(docker_tag)"
}

# Cache phase of circleci
function do_cache() {
  [ ! -d "$HOME/circleutil" ] && git clone https://github.com/signalfx/circleutil.git "$HOME/circleutil"
  (
    cd "$HOME/circleutil"
    git fetch -a -v
    git fetch --tags
    git reset --hard $CIRCLEUTIL_TAG
  )
  . "$HOME/circleutil/scripts/common.sh"
  mkdir -p "$GO_COMPILER_PATH"
  install_all_go_versions "$GO_COMPILER_PATH"
  install_go_version "$GO_COMPILER_PATH" "$DEFAULT_GOLANG_VERSION"
  go get -u github.com/signalfx/gobuild
  go get -u github.com/alecthomas/gometalinter
  mkdir -p "$GOPATH_INTO"
  install_shellcheck "$GOPATH_INTO"
  copy_local_to_path "$SRC_PATH"
  BUILD_VERSION=$(git describe --tags HEAD)
  (
    cd "$SRC_PATH"
    load_docker_images
    LD_FLAGS="-X main.Version=$BUILD_VERSION -X main.BuildDate=$(date --rfc-3339=seconds | sed 's/ /T/') -s -w"
    CGO_ENABLED=0 go build -ldflags "$LD_FLAGS" -v -installsuffix .
    docker build -t "$(docker_url)" .
    cache_docker_image "$(docker_url)" metricproxy
  )
}

# Test phase of circleci
function do_test() {
  . "$HOME/circleutil/scripts/common.sh"
  (
    cd "$SRC_PATH"
    shellcheck install.sh
    shellcheck scripts/circle.sh
    shellcheck metricproxy_initd
    echo -e "# Ignore Header" > /tmp/ignore_header.md
    python -m json.tool < exampleSfdbproxy.conf > /dev/null
  )
  install_go_version "$GO_COMPILER_PATH" "$DEFAULT_GOLANG_VERSION"
  gometalinter --install --update
  gobuild -verbose install
  for GO_VERSION in $GO_TESTED_VERSIONS; do
    install_go_version "$GO_COMPILER_PATH" "$GO_VERSION"
    rm -rf "$GOPATH/pkg"
    go version
    go env
    go tool | grep cover || go get golang.org/x/tools/cmd/cover
    (
      cd "$SRC_PATH"
      go clean -x ./...
      go test -race -timeout 15s ./...
    )
  done
  install_go_version "$GO_COMPILER_PATH" "$GO_VERSION"
  (
    cd "$SRC_PATH"
    go clean -x ./...
    x=$(gobuild list | grep -v ^vendor)
    for y in $x; do
      gobuild check "$y" -verbose -verbosefile "$CIRCLE_ARTIFACTS/gobuildout.$y.txt"
    done
  )
}

# Deploy phase of circleci
function do_deploy() {
  . "$HOME/circleutil/scripts/common.sh"
  (
    if [ "$DOCKER_PUSH" == "1" ]; then
      docker push "$(docker_url)"
    fi
  )
}

function do_all() {
  do_cache
  do_test
  do_deploy
}

case "$1" in
  cache)
    do_cache
    ;;
  test)
    do_test
    ;;
  deploy)
    do_deploy
    ;;
  all)
    do_all
    ;;
  *)
  echo "Usage: $0 {cache|test|deploy|all}"
    exit 1
    ;;
esac
