#!/bin/bash

# Update the bundle identifier in the project file
find . -name "project.pbxproj" -exec sed -i '' 's/com\.nsa\.goodsai/com\.nsa\.fetchly/g' {} \;

# Display completion message
echo "Bundle identifier updated from com.nsa.goodsai to com.nsa.fetchly"
echo ""
echo "IMPORTANT: The following manual steps are still required:"
echo "1. Open the project in Xcode"
echo "2. Go to the project settings"
echo "3. Verify that the Display Name is set to 'InventoryIQ'"
echo "4. Verify that the Bundle Identifier is set to 'com.nsa.inventoryiq'"
echo "5. Clean and build the project"
echo ""
echo "NOTE: This script does not rename the project structure or files."
echo "Only the app display name and bundle identifier have been updated."
