#!/bin/bash

# TODO(Swift): Remove this after Carthage is fixed for Xcode 12
root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/../" && pwd)"
source "${root_dir}/ci_scripts/hack-carthage-xcode-12.sh"

function info {
  echo "[$(basename "${0}")] [INFO] ${1}"
}

function die {
  echo "[$(basename "${0}")] [ERROR] ${1}"
  exit 1
}

# Verify xcpretty is installed
if ! command -v xcpretty > /dev/null; then
  if [[ "${CI}" != "true" ]]; then
    die "Please install xcpretty: https://github.com/supermarin/xcpretty#installation"
  fi

  info "Installing xcpretty..."
  gem install xcpretty --no-document || die "Executing \`gem install xcpretty\` failed"
fi

# Install test dependencies
info "Installing test dependencies..."

carthage bootstrap --platform iOS --configuration Release --no-use-binaries --cache-builds
carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage failed with status code: ${carthage_exit_code}"
fi

info "Building SDK..."

xcodebuild build-for-testing \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "platform=iOS Simulator,name=iPhone 11,OS=latest" \
  -derivedDataPath build-ci-tests \
  | xcpretty
exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"
