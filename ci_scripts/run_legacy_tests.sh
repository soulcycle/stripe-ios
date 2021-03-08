#!/bin/bash

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

carthage bootstrap --platform iOS --configuration Release --no-use-binaries --cache-builds --use-xcframeworks
carthage_exit_code="$?"

if [[ "${carthage_exit_code}" != 0 ]]; then
  die "Executing carthage failed with status code: ${carthage_exit_code}"
fi

# Execute tests on legacy devices
# - Skips snapshot tests because they're recorded for a specific device on the newest iOS version only
info "Executing tests on legacy device $1"

if [[ "${CI}" == "true" ]]; then
  test_method="test-without-building"
else
  test_method="test"
fi

xcodebuild ${test_method} \
  -workspace "Stripe.xcworkspace" \
  -scheme "StripeiOS" \
  -configuration "Debug" \
  -sdk "iphonesimulator" \
  -destination "$1" \
  -skip-testing:"StripeiOS Tests/STPAddCardViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPPaymentOptionsViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPShippingAddressViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPShippingMethodsViewControllerLocalizationTests" \
  -skip-testing:"StripeiOS Tests/STPAUBECSDebitFormViewSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPPaymentContextSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPSTPViewWithSeparatorSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPLabeledFormTextFieldViewSnapshotTests" \
  -skip-testing:"StripeiOS Tests/STPLabeledMultiFormTextFieldViewSnapshotTests" \
  ONLY_ACTIVE_ARCH=NO \
  -derivedDataPath build-ci-tests \
  | xcpretty

exit_code="${PIPESTATUS[0]}"

if [[ "${exit_code}" != 0 ]]; then
  die "xcodebuild exited with non-zero status code: ${exit_code}"
fi

info "All good!"
