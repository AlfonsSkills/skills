#!/bin/bash
# PDF文本提取脚本
# 用法: ./extract_pdf.sh <pdf_path> [output_path]

PDF_PATH="$1"
OUTPUT_PATH="${2:-/tmp/pdf_extract_$(date +%s).txt}"

if [ -z "$PDF_PATH" ]; then
    echo "错误: 请提供PDF文件路径" >&2
    echo "用法: ./extract_pdf.sh <pdf_path> [output_path]" >&2
    exit 1
fi

if [ ! -f "$PDF_PATH" ]; then
    echo "错误: 文件不存在: $PDF_PATH" >&2
    exit 1
fi

# 优先使用 pdftotext
if command -v pdftotext &> /dev/null; then
    pdftotext "$PDF_PATH" "$OUTPUT_PATH" 2>/dev/null
    if [ $? -eq 0 ] && [ -s "$OUTPUT_PATH" ]; then
        echo "$OUTPUT_PATH"
        exit 0
    fi
fi

# 备选: 使用 Python PyPDF2
python3 << EOF
import sys
try:
    import PyPDF2
    reader = PyPDF2.PdfReader('$PDF_PATH')
    text = ''.join([page.extract_text() or '' for page in reader.pages])
    with open('$OUTPUT_PATH', 'w', encoding='utf-8') as f:
        f.write(text)
    print('$OUTPUT_PATH')
except ImportError:
    print('错误: 请安装 pdftotext 或 PyPDF2', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'错误: {e}', file=sys.stderr)
    sys.exit(1)
EOF
