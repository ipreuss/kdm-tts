# Screenshot Analysis Skill

Analyze screenshots from the Desktop folder with automatic size optimization.

## Workflow

### Step 1: Locate the Screenshot

If a specific file path is provided, use that. Otherwise, find the newest screenshot on Desktop:

```bash
ls -lt /Users/ilja/Desktop/*.png /Users/ilja/Desktop/*.jpg /Users/ilja/Desktop/*.jpeg 2>/dev/null | head -1
```

### Step 2: Check File Size

Before reading, check if the file is larger than 15 MB:

```bash
stat -f%z "/path/to/screenshot.png"
```

If size > 15000000 bytes (15 MB), proceed to Step 3. Otherwise, skip to Step 4.

### Step 3: Convert to JPEG (if needed)

Convert large PNG files to JPEG to reduce size while preserving resolution:

```bash
sips -s format jpeg "/path/to/screenshot.png" --out "/path/to/screenshot.jpg"
```

Use the converted JPEG file for reading.

### Step 4: Read and Analyze

Use the Read tool to view the image file. Claude can analyze images directly.

## Example Usage

**User asks:** "What's in the latest screenshot?"

**Actions:**
1. List Desktop files sorted by time, get newest image
2. Check file size with `stat`
3. If > 15 MB, convert with `sips`
4. Read the file (original or converted)
5. Describe what you see

## Notes

- macOS screenshots are typically saved to Desktop as PNG
- JPEG conversion significantly reduces file size (often 10x) with minimal quality loss
- The 15 MB threshold prevents context overflow when reading large images
- Always report which file you're analyzing to the user
