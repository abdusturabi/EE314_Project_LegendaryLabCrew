from PIL import Image
import numpy as np

def rgb_to_rrrgggbb(r, g, b):
    r3 = (r >> 5) & 0x07  # Top 3 bits
    g3 = (g >> 5) & 0x07  # Top 3 bits
    b2 = (b >> 6) & 0x03  # Top 2 bits
    return (r3 << 5) | (g3 << 2) | b2  # Pack into 8 bits

def png_to_mif_with_white_transparency(png_path, mif_path):
    img = Image.open(png_path).convert('RGBA')
    width, height = img.size
    pixels = np.array(img)
    print(width)
    print(height)
    depth = width * height

    with open(mif_path, 'w') as f:
        f.write(f"WIDTH=8;\nDEPTH={depth};\n\n")
        f.write("ADDRESS_RADIX=UNSIGNED;\nDATA_RADIX=HEX;\n\n")
        f.write("CONTENT\nBEGIN\n")

        addr = 0
        for y in range(height):
            for x in range(width):
                r, g, b, a = pixels[y, x]
                if a < 128:
                    # Transparent pixel → White
                    r, g, b = 255, 255, 255
                color = rgb_to_rrrgggbb(r, g, b)
                f.write(f"{addr} : {color:02X};\n")
                addr += 1

        f.write("END;\n")

    print(f"✅ MIF file saved to: {mif_path}")

# Example usage
png_to_mif_with_white_transparency("heart.png", "heart.mif")