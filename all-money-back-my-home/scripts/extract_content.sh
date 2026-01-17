#!/bin/bash
# 多格式内容提取器
# 用法: ./extract_content.sh <file_path> [output_path]
# 
# 支持格式:
#   - PDF (.pdf): 使用 pdftotext 或 PyPDF2
#   - Word (.docx): 使用 pandoc 或 python-docx
#   - 图片 (.png/.jpg/.jpeg/.webp): 需使用 Agent 视觉能力
#   - 纯文本 (.txt/.md): 直接读取
#   - HTML (.html/.htm): 使用 pandoc 或 w3m

set -e

FILE_PATH="$1"
OUTPUT_PATH="${2:-/tmp/content_extract_$(date +%s).txt}"

# 参数检查
if [ -z "$FILE_PATH" ]; then
    echo "错误: 请提供文件路径" >&2
    echo "用法: ./extract_content.sh <file_path> [output_path]" >&2
    exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "错误: 文件不存在: $FILE_PATH" >&2
    exit 1
fi

# 获取小写扩展名
FILE_EXT="${FILE_PATH##*.}"
FILE_EXT_LOWER=$(echo "$FILE_EXT" | tr '[:upper:]' '[:lower:]')

# ============================================================
# PDF 提取函数
# ============================================================
extract_pdf() {
    local input="$1"
    local output="$2"
    
    # 优先使用 pdftotext
    if command -v pdftotext &> /dev/null; then
        if pdftotext "$input" "$output" 2>/dev/null && [ -s "$output" ]; then
            echo "$output"
            return 0
        fi
    fi
    
    # 备选: 使用 Python PyPDF2
    python3 << EOF
import sys
try:
    import PyPDF2
    reader = PyPDF2.PdfReader('$input')
    text = ''.join([page.extract_text() or '' for page in reader.pages])
    with open('$output', 'w', encoding='utf-8') as f:
        f.write(text)
    print('$output')
except ImportError:
    print('错误: 请安装 pdftotext 或 PyPDF2', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'错误: {e}', file=sys.stderr)
    sys.exit(1)
EOF
}

# ============================================================
# DOCX 提取函数
# ============================================================
extract_docx() {
    local input="$1"
    local output="$2"
    
    # 优先使用 pandoc
    if command -v pandoc &> /dev/null; then
        if pandoc -f docx -t plain "$input" -o "$output" 2>/dev/null; then
            echo "$output"
            return 0
        fi
    fi
    
    # 备选: 使用 python-docx
    python3 << EOF
import sys
try:
    from docx import Document
    doc = Document('$input')
    text = '\n'.join([para.text for para in doc.paragraphs])
    with open('$output', 'w', encoding='utf-8') as f:
        f.write(text)
    print('$output')
except ImportError:
    print('错误: 请安装 pandoc 或 python-docx', file=sys.stderr)
    sys.exit(1)
except Exception as e:
    print(f'错误: {e}', file=sys.stderr)
    sys.exit(1)
EOF
}

# ============================================================
# DOC 提取函数 (旧版 Word)
# ============================================================
extract_doc() {
    local input="$1"
    local output="$2"
    
    # 使用 antiword
    if command -v antiword &> /dev/null; then
        if antiword "$input" > "$output" 2>/dev/null && [ -s "$output" ]; then
            echo "$output"
            return 0
        fi
    fi
    
    # 备选: 使用 libreoffice 转换
    if command -v libreoffice &> /dev/null; then
        local tmp_dir=$(mktemp -d)
        if libreoffice --headless --convert-to txt --outdir "$tmp_dir" "$input" 2>/dev/null; then
            local txt_file="$tmp_dir/$(basename "${input%.*}").txt"
            if [ -f "$txt_file" ]; then
                mv "$txt_file" "$output"
                rm -rf "$tmp_dir"
                echo "$output"
                return 0
            fi
        fi
        rm -rf "$tmp_dir"
    fi
    
    echo "错误: 请安装 antiword 或 libreoffice 来提取 .doc 文件" >&2
    exit 1
}

# ============================================================
# HTML 提取函数
# ============================================================
extract_html() {
    local input="$1"
    local output="$2"
    
    # 优先使用 pandoc
    if command -v pandoc &> /dev/null; then
        if pandoc -f html -t plain "$input" -o "$output" 2>/dev/null; then
            echo "$output"
            return 0
        fi
    fi
    
    # 备选: 使用 w3m
    if command -v w3m &> /dev/null; then
        if w3m -dump "$input" > "$output" 2>/dev/null && [ -s "$output" ]; then
            echo "$output"
            return 0
        fi
    fi
    
    # 备选: 使用 lynx
    if command -v lynx &> /dev/null; then
        if lynx -dump -nolist "$input" > "$output" 2>/dev/null && [ -s "$output" ]; then
            echo "$output"
            return 0
        fi
    fi
    
    echo "错误: 请安装 pandoc、w3m 或 lynx 来提取 HTML 文件" >&2
    exit 1
}

# ============================================================
# 主路由逻辑
# ============================================================
case "$FILE_EXT_LOWER" in
    pdf)
        extract_pdf "$FILE_PATH" "$OUTPUT_PATH"
        ;;
    docx)
        extract_docx "$FILE_PATH" "$OUTPUT_PATH"
        ;;
    doc)
        extract_doc "$FILE_PATH" "$OUTPUT_PATH"
        ;;
    png|jpg|jpeg|webp|gif|bmp|tiff)
        # 图片格式：输出提示信息，由 Agent 视觉能力直接分析
        echo "[IMAGE] 文件: $FILE_PATH"
        echo "[IMAGE] 图片格式无需文本提取，请使用 Agent 视觉能力直接分析图片内容"
        echo "[IMAGE] 支持: Antigravity, Gemini, Claude 等具备视觉能力的 AI Agent"
        exit 0
        ;;
    txt|md)
        # 纯文本直接复制
        cat "$FILE_PATH" > "$OUTPUT_PATH"
        echo "$OUTPUT_PATH"
        ;;
    html|htm)
        extract_html "$FILE_PATH" "$OUTPUT_PATH"
        ;;
    *)
        echo "错误: 不支持的文件格式: .$FILE_EXT_LOWER" >&2
        echo "支持的格式: pdf, docx, doc, png, jpg, jpeg, webp, txt, md, html, htm" >&2
        exit 1
        ;;
esac
