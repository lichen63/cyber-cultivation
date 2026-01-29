#!/usr/bin/env python3
"""Remove black background from character.png"""

import os
import sys

# Check if PIL is available, otherwise provide helpful message
try:
    from PIL import Image
except ImportError:
    print("Error: Pillow is not installed.")
    print("\nPlease install it using one of these methods:")
    print("1. Using a virtual environment (recommended):")
    print("   python3 -m venv venv")
    print("   source venv/bin/activate")
    print("   pip install pillow")
    print("   python remove_black_bg.py")
    print("\n2. Using --break-system-packages flag:")
    print("   pip3 install --break-system-packages pillow")
    print("\n3. Using Homebrew:")
    print("   brew install pillow")
    sys.exit(1)

# Open the image
img_path = '/Users/lichenliu/Repos/cyber-cultivation/assets/images/character.png'
img = Image.open(img_path).convert('RGBA')

# Get pixel data
pixels = img.load()
width, height = img.size

# Make black pixels transparent
for y in range(height):
    for x in range(width):
        r, g, b, a = pixels[x, y]
        # If pixel is black or very dark (threshold of 0)
        if r <= 0 and g <= 0 and b <= 0:
            # Make it fully transparent
            pixels[x, y] = (r, g, b, 0)

# Save the modified image
img.save(img_path)
print(f"Black background removed from {img_path}")
