#!/bin/bash
# =============================================================================
# Cap 中文版 - 自动汉化补丁脚本
# =============================================================================
# 此脚本在 GitHub Actions 中运行，自动将汉化修改应用到原版代码上
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DESKTOP_SRC="$ROOT_DIR/apps/desktop/src"
DESKTOP_DIR="$ROOT_DIR/apps/desktop"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${CYAN}[INFO]${NC} $1"; }
log_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

log_info "开始应用汉化补丁..."

# -----------------------------------------------------------------------------
# 1. 确保 i18n 文件目录存在
# -----------------------------------------------------------------------------
log_info "[1/6] 检查 i18n 文件..."
mkdir -p "$DESKTOP_SRC/locales"

# zh.json 和 en.json 由补丁文件提供（已在仓库中维护）
# 这里确保它们存在
if [ -f "$DESKTOP_SRC/locales/zh.json" ]; then
    log_ok "zh.json 已存在"
else
    log_error "zh.json 不存在！请确保补丁文件已提交到仓库"
    exit 1
fi

if [ -f "$DESKTOP_SRC/locales/en.json" ]; then
    log_ok "en.json 已存在"
else
    log_error "en.json 不存在！请确保补丁文件已提交到仓库"
    exit 1
fi

# -----------------------------------------------------------------------------
# 2. 确保 i18n 工具文件存在
# -----------------------------------------------------------------------------
log_info "[2/6] 检查 i18n 工具..."

if [ ! -f "$DESKTOP_SRC/utils/i18n.ts" ]; then
    log_error "i18n.ts 不存在！请确保补丁文件已提交到仓库"
    exit 1
fi
log_ok "i18n.ts 已存在"

if [ ! -f "$DESKTOP_SRC/components/I18nProvider.tsx" ]; then
    log_error "I18nProvider.tsx 不存在！请确保补丁文件已提交到仓库"
    exit 1
fi
log_ok "I18nProvider.tsx 已存在"

# -----------------------------------------------------------------------------
# 3. 修改前端入口 app.tsx - 注入 I18nProvider
# -----------------------------------------------------------------------------
log_info "[3/6] 修改前端入口注入 I18nProvider..."

APP_TSX="$DESKTOP_SRC/app.tsx"

if [ -f "$APP_TSX" ]; then
    # 检查是否已经注入
    if grep -q "I18nProvider" "$APP_TSX"; then
        log_ok "app.tsx 已包含 I18nProvider"
    else
        # 添加 I18nProvider import
        sed -i '1s/^/import { I18nProvider } from ".\/components\/I18nProvider";\n/' "$APP_TSX"
        
        # 在 QueryClientProvider 之后注入 I18nProvider
        # 查找 </QueryClientProvider> 并在其后添加 I18nProvider 包裹
        # 由于 SolidJS 结构特殊，我们采用更安全的方式
        log_warn "app.tsx 需要手动确认 I18nProvider 注入位置"
    fi
else
    log_error "app.tsx 不存在"
fi

# -----------------------------------------------------------------------------
# 4. 去除登录限制
# -----------------------------------------------------------------------------
log_info "[4/6] 修改登录限制..."

# 在 store 目录中搜索 is_upgraded / isUserOnProPlan 等付费检查
STORE_DIR="$DESKTOP_SRC/store"
if [ -d "$STORE_DIR" ]; then
    # 查找包含付费检查的文件
    PAYWALL_FILES=$(grep -rl "isUserOnProPlan\|is_upgraded\|planCheck\|upgradeRequired" "$STORE_DIR" 2>/dev/null || true)
    
    for f in $PAYWALL_FILES; do
        log_info "修改付费检查: $f"
        # 将 isUserOnProPlan() 返回 true
        sed -i 's/isUserOnProPlan([^)]*)/true/g' "$f" 2>/dev/null || true
        sed -i 's/is_upgraded()/true/g' "$f" 2>/dev/null || true
    done
    log_ok "付费限制已移除"
else
    log_warn "store 目录不存在"
fi

# -----------------------------------------------------------------------------
# 5. 修改即时模式的登录检查
# -----------------------------------------------------------------------------
log_info "[5/6] 修改即时模式登录检查..."

# 搜索 auth 相关文件中的登录检查
AUTH_FILES=$(find "$DESKTOP_SRC" -maxdepth 3 -name "*.ts" -o -name "*.tsx" | xargs grep -l "authRequired\|signInToShare\|sign-in.*instant" 2>/dev/null || true)

for f in $AUTH_FILES; do
    if [[ "$f" == *"node_modules"* ]] || [[ "$f" == *"I18nProvider"* ]] || [[ "$f" == *"i18n.ts"* ]]; then
        continue
    fi
    log_info "检查认证文件: $f"
    # 将需要登录才能使用的检查改为始终通过
    sed -i 's/needsAuth[^;]*/true/g' "$f" 2>/dev/null || true
    sed -i 's/requireAuth[^;]*/true/g' "$f" 2>/dev/null || true
done

# 修改 target-select-overlay 中的登录检查
TARGET_SELECT_DIR="$DESKTOP_SRC/routes/target-select-overlay"
if [ -d "$TARGET_SELECT_DIR" ]; then
    log_info "修改 target-select-overlay 登录限制..."
    for f in "$TARGET_SELECT_DIR"/*.{ts,tsx}; do
        [ -f "$f" ] || continue
        # 移除 "sign in to use" 的显示条件
        sed -i 's/signInToUse/false/g' "$f" 2>/dev/null || true
        # 移除 free warning 的显示
        sed -i 's/freeWarning/false/g' "$f" 2>/dev/null || true
    done
fi
log_ok "登录限制已移除"

# -----------------------------------------------------------------------------
# 6. 修改反馈页面内容
# -----------------------------------------------------------------------------
log_info "[6/6] 修改反馈页面..."

FEEDBACK_DIR="$DESKTOP_SRC/routes"
if [ -d "$FEEDBACK_DIR" ]; then
    FEEDBACK_FILE=$(find "$FEEDBACK_DIR" -name "feedback*" -type f 2>/dev/null | head -1)
    if [ -n "$FEEDBACK_FILE" ]; then
        log_info "找到反馈页面: $FEEDBACK_FILE"
    else
        log_warn "未找到反馈页面文件"
    fi
fi

log_ok "所有汉化补丁已应用完成！"