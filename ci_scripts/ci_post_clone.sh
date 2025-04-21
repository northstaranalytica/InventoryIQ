#!/bin/sh

# This script is executed after Xcode Cloud clones the repository.
# It will install CocoaPods and run pod install

set -e
set -o pipefail

# If this is running on Xcode Cloud
if [ "$CI" = "true" ]; then
    echo "Running on Xcode Cloud CI..."
    
    # Check for Homebrew and install if not present
    if ! command -v brew >/dev/null 2>&1; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
        export PATH="/opt/homebrew/bin:$PATH"
    fi
    
    # Update homebrew and install CocoaPods if necessary
    echo "Updating Homebrew and ensuring CocoaPods is installed..."
    brew update || true
    brew install cocoapods || true
    
    # Alternatively, use gem to install CocoaPods
    echo "Installing CocoaPods via gem..."
    gem install cocoapods -v 1.11.3 || true
    
    echo "Pod version:"
    pod --version
    
    # Navigate to the project directory and install pods
    echo "Installing Pods..."
    cd "${CI_WORKSPACE}"
    pod install --verbose
    
    # Double check the xcconfig files exist
    config_file="${CI_WORKSPACE}/Pods/Target Support Files/Pods-InventoryIQ/Pods-InventoryIQ.release.xcconfig"
    if [ -f "$config_file" ]; then
        echo "✅ Pods configured successfully: $config_file exists"
    else
        echo "❌ ERROR: $config_file does not exist after pod install"
        exit 1
    fi
else
    echo "Not running on CI, skipping CI-specific setup"
fi

echo "Post-clone script completed successfully"
exit 0 