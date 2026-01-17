# 格式依赖说明

本 skill 支持多种输入格式。以下是各格式所需的依赖工具及安装方法。

## 格式与依赖对照表

| 格式 | 扩展名 | 首选工具 | 备选工具 |
|------|--------|----------|----------|
| PDF | `.pdf` | pdftotext | PyPDF2 |
| Word (新版) | `.docx` | pandoc | python-docx |
| Word (旧版) | `.doc` | antiword | libreoffice |
| HTML | `.html/.htm` | pandoc | w3m / lynx |
| 纯文本 | `.txt/.md` | (无需额外依赖) | - |
| 图片 | `.png/.jpg/.webp` | Agent 视觉能力 | - |

## 安装方法

### macOS (Homebrew)

```bash
# PDF 处理
brew install poppler          # 提供 pdftotext

# Word 和 HTML 处理
brew install pandoc

# 旧版 Word 处理
brew install antiword

# HTML 备选
brew install w3m
```

### Ubuntu/Debian

```bash
# PDF 处理
sudo apt install poppler-utils

# Word 和 HTML 处理
sudo apt install pandoc

# 旧版 Word 处理
sudo apt install antiword

# HTML 备选
sudo apt install w3m
```

### Python 依赖 (可选备选)

```bash
pip install PyPDF2 python-docx
```

## 图片格式说明

图片格式 (`.png`, `.jpg`, `.jpeg`, `.webp`, `.gif`, `.bmp`, `.tiff`) **无需安装额外 OCR 工具**。

本 skill 利用 **AI Agent 的原生视觉能力** 直接分析图片内容：
- Antigravity: 支持 ✅
- Gemini CLI: 支持 ✅
- Claude: 支持 ✅
- Cursor: 支持 ✅

只需将图片路径提供给 Agent，即可自动识别并分析图片中的投研报告内容。

## 缺失依赖处理策略

本 skill 采用 **graceful fallback** 设计，在依赖工具缺失时仍能尽可能正常工作。

### 降级优先级

| 格式 | 优先级 1 | 优先级 2 | 优先级 3 |
|------|----------|----------|----------|
| PDF | pdftotext | PyPDF2 | 报错提示 |
| DOCX | pandoc | python-docx | 报错提示 |
| DOC | antiword | libreoffice | 报错提示 |
| HTML | pandoc | w3m | lynx |

### 处理规则

1. **图片格式**: 无需任何外部依赖
   - 直接将图片路径传递给 Agent
   - Agent 使用视觉能力分析图片内容
   - 脚本仅输出提示信息，不执行实际提取

2. **文本格式**: 多级降级尝试
   - 按优先级依次尝试可用工具
   - 所有工具都不可用时，输出清晰的安装提示

3. **纯文本/Markdown**: 零依赖
   - 直接使用 `cat` 读取，无需额外工具

### 常见问题

**Q: 遇到 `ModuleNotFoundError: No module named 'PIL'` 怎么办？**

A: 这个错误与本 skill 无关。本 skill 的图片处理**不使用 PIL**，而是利用 Agent 视觉能力。如果看到此错误，可能是其他工具或脚本需要 PIL。

**Q: 如何确认我的环境可以处理某种格式？**

A: 运行以下命令检测：

```bash
# 检测 PDF 处理能力
command -v pdftotext && echo "PDF: OK (pdftotext)"
python3 -c "import PyPDF2" 2>/dev/null && echo "PDF: OK (PyPDF2)"

# 检测 DOCX 处理能力
command -v pandoc && echo "DOCX: OK (pandoc)"
python3 -c "from docx import Document" 2>/dev/null && echo "DOCX: OK (python-docx)"

# 检测 HTML 处理能力
command -v pandoc && echo "HTML: OK (pandoc)"
command -v w3m && echo "HTML: OK (w3m)"
```

**Q: 最小安装方案是什么？**

A: 如果只需要处理 PDF 和图片：

```bash
# macOS
brew install poppler

# Ubuntu/Debian  
sudo apt install poppler-utils
```

图片无需安装任何工具，直接使用 Agent 视觉能力即可。
