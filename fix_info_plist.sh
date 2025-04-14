#!/bin/bash
cp InventoryIQ.xcodeproj/project.pbxproj InventoryIQ.xcodeproj/project.pbxproj.bak
sed -i.bak "/Info.plist.*in Resources/d" InventoryIQ.xcodeproj/project.pbxproj
