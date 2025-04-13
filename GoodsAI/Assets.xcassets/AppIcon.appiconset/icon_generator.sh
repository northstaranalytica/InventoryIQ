#!/bin/bash

# Create InventoryIQ icon (magnifying glass over boxes)
magick -size 1024x1024 xc:white \
  -fill "#4287f5" -draw "roundrectangle 200,200,824,824,50,50" \
  -fill "#1F3A5F" -draw "roundrectangle 300,300,724,724,50,50" \
  -fill "#62A1FF" -draw "roundrectangle 400,400,624,624,50,50" \
  -fill "#4287f5" -draw "circle 512,512 612,512" \
  -fill white -font Helvetica-Bold -pointsize 200 -gravity center \
  -annotate +0+0 "IQ" \
  "AppIcon.png"

echo "InventoryIQ app icon created successfully!"
