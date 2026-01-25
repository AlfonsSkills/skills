#!/bin/bash
# Export Markdown to a long PNG image.
# Usage: ./export_png.sh <md_path> [output_png_path]
# Params:
#   md_path: input Markdown file path
#   output_png_path: output PNG path (optional, default: same name with .png)
# Returns:
#   0 on success, non-zero on error

set -e

MD_PATH="$1"
OUT_PNG="$2"

# Validate input parameters.
if [ -z "$MD_PATH" ]; then
    echo "Error: missing md_path" >&2
    echo "Usage: ./export_png.sh <md_path> [output_png_path]" >&2
    exit 1
fi

if [ ! -f "$MD_PATH" ]; then
    echo "Error: file not found: $MD_PATH" >&2
    exit 1
fi

if [ -z "$OUT_PNG" ]; then
    OUT_PNG="${MD_PATH%.*}.png"
fi

# Check required runtime.
if ! command -v python3 >/dev/null 2>&1; then
    echo "Error: python3 not found. Please install Python 3." >&2
    exit 1
fi

MD_PATH="$MD_PATH" OUT_PNG="$OUT_PNG" python3 - <<'PY'
import os
import sys
import tempfile
from pathlib import Path

# Read parameters passed from shell.
md_path = Path(os.environ["MD_PATH"]).expanduser()
out_png = Path(os.environ["OUT_PNG"]).expanduser()

try:
    import markdown
except Exception:
    print("Error: missing Python package 'markdown'. Install with:", file=sys.stderr)
    print("  python3 -m pip install markdown", file=sys.stderr)
    sys.exit(1)

try:
    from playwright.sync_api import sync_playwright
except Exception:
    print("Error: missing Python package 'playwright'. Install with:", file=sys.stderr)
    print("  python3 -m pip install playwright", file=sys.stderr)
    print("  python3 -m playwright install chromium", file=sys.stderr)
    sys.exit(1)

# Ensure output directory exists.
out_png.parent.mkdir(parents=True, exist_ok=True)

# Convert Markdown to HTML.
md_text = md_path.read_text(encoding="utf-8")
html_body = markdown.markdown(md_text, extensions=["tables", "fenced_code"])

css = """
    :root {
      --text: #111;
      --muted: #666;
      --border: #ddd;
      --bg: #fff;
    }
    body {
      margin: 0;
      background: var(--bg);
      color: var(--text);
      font-family: "PingFang SC", "Noto Sans CJK SC", "Microsoft YaHei", Helvetica, Arial, sans-serif;
      line-height: 1.6;
    }
    .page {
      width: 1200px;
      max-width: 95vw;
      margin: 32px auto 48px;
      padding: 0 8px 24px;
    }
    h1, h2, h3 {
      line-height: 1.25;
      margin: 28px 0 12px;
    }
    h1 { font-size: 28px; }
    h2 { font-size: 22px; }
    h3 { font-size: 18px; color: var(--muted); }
    p { margin: 8px 0; }
    ul { margin: 8px 0 16px 22px; }
    blockquote {
      margin: 12px 0;
      padding: 10px 14px;
      border-left: 4px solid var(--border);
      color: var(--muted);
      background: #fafafa;
    }
    hr { border: none; border-top: 1px solid var(--border); margin: 24px 0; }
    table { width: 100%; border-collapse: collapse; margin: 12px 0 20px; font-size: 15px; }
    th, td { border: 1px solid var(--border); padding: 8px 10px; text-align: left; vertical-align: top; }
    th { background: #f6f6f6; }
    code { background: #f2f2f2; padding: 1px 4px; border-radius: 3px; }
"""

html_full = f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Markdown Export</title>
  <style>{css}</style>
</head>
<body>
  <div class="page">
    {html_body}
  </div>
</body>
</html>
"""

# Render HTML to PNG using Playwright.
with tempfile.TemporaryDirectory() as tmpdir:
    html_path = Path(tmpdir) / "report.html"
    html_path.write_text(html_full, encoding="utf-8")
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page(viewport={"width": 1400, "height": 900})
            page.goto(f"file://{html_path}")
            page.wait_for_timeout(500)
            page.screenshot(path=str(out_png), full_page=True)
            browser.close()
    except Exception as exc:
        msg = str(exc).lower()
        if "executable" in msg or "chromium" in msg:
            print("Error: Playwright browser not installed. Run:", file=sys.stderr)
            print("  python3 -m playwright install chromium", file=sys.stderr)
        else:
            print(f"Error: {exc}", file=sys.stderr)
        sys.exit(1)

print(str(out_png))
PY
