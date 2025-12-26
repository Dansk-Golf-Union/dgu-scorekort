# DGU Icon Generation Instructions

This folder contains SVG templates for the DGU Scorekort app icons.

## Files

- `icon-template.svg` - Standard icon (512x512) with circular design
- `icon-maskable-template.svg` - Maskable icon (512x512) with content in safe zone

## Required PNG Files

You need to generate the following PNG files from the SVG templates:

### Standard Icons (from icon-template.svg)
1. `Icon-192.png` - 192x192 pixels
2. `Icon-512.png` - 512x512 pixels

### Maskable Icons (from icon-maskable-template.svg)
3. `Icon-maskable-192.png` - 192x192 pixels
4. `Icon-maskable-512.png` - 512x512 pixels

## How to Generate PNG Files

### Option 1: Using Online Tools
1. Go to https://svgtopng.com/ or https://cloudconvert.com/svg-to-png
2. Upload the SVG file
3. Set the output size (192 or 512 pixels)
4. Download and save with the correct filename

### Option 2: Using Inkscape (Free Desktop App)
1. Install Inkscape: https://inkscape.org/
2. Open the SVG file
3. Go to File → Export PNG Image
4. Set width/height to 192 or 512 pixels
5. Export with the correct filename

### Option 3: Using ImageMagick (Command Line)
```bash
# Generate standard icons
convert icon-template.svg -resize 192x192 Icon-192.png
convert icon-template.svg -resize 512x512 Icon-512.png

# Generate maskable icons
convert icon-maskable-template.svg -resize 192x192 Icon-maskable-192.png
convert icon-maskable-template.svg -resize 512x512 Icon-maskable-512.png
```

### Option 4: Using Chrome/Edge Browser
1. Open the SVG file in Chrome or Edge
2. Right-click → Inspect
3. Run in Console:
```javascript
// For 192px
var canvas = document.createElement('canvas');
canvas.width = 192;
canvas.height = 192;
// ... (code to render and download)
```

## Favicon

For the main favicon, you also need to generate:
- `../favicon.png` - 32x32 or 64x64 pixels from `../favicon.svg`

The SVG favicon will be used by modern browsers, but PNG is provided as fallback.

## Design Specifications

**Colors:**
- DGU Green: `#1B5E20`
- White: `#FFFFFF`

**Design:**
- Green circular background
- White golf flag icon
- White golf ball at the base of the flag pole










