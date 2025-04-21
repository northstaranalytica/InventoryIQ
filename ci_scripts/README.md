# Xcode Cloud CI Scripts

This directory contains scripts that are run during the Xcode Cloud CI/CD workflow process.

## Scripts

- `ci_post_clone.sh`: Executed after Xcode Cloud clones the repository. This script ensures CocoaPods is installed and runs `pod install` to prepare the workspace for building. 