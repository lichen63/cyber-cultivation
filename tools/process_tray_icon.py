import os
from PIL import Image

def process_icon():
    source_path = 'assets/images/icon.jpeg'
    dest_path = 'assets/images/tray_icon.png'
    
    if not os.path.exists(source_path):
        print(f"Error: {source_path} not found.")
        return

    # Open the image
    img = Image.open(source_path).convert('RGBA')
    
    # Resize first to 44x44 (high quality)
    img = img.resize((44, 44), Image.Resampling.LANCZOS)
    
    # Get pixel data
    pixels = img.load()
    width, height = img.size
    
    # Get background color from top-left pixel
    bg_color = pixels[0, 0]
    bg_r, bg_g, bg_b, _ = bg_color
    
    print(f"Detected background color: RGB({bg_r}, {bg_g}, {bg_b})")
    
    # Threshold for color matching
    threshold = 30
    
    # Process pixels
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            
            # Calculate distance from background color
            dist = ((r - bg_r) ** 2 + (g - bg_g) ** 2 + (b - bg_b) ** 2) ** 0.5
            
            if dist < threshold:
                # Make it fully transparent
                pixels[x, y] = (0, 0, 0, 0)
    
    # Save as PNG
    img.save(dest_path, 'PNG')
    print(f"Processed icon saved to {dest_path}")

if __name__ == '__main__':
    process_icon()
