#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# SECURITY GATE 설치 스크립트
# 사용법: bash install_hooks.sh (프로젝트 루트에서 실행)
# ══════════════════════════════════════════════════════════════════════════════

set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
CYN='\033[0;36m'
BLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${BLD}${CYN}SECURITY GATE 설치 — SECURITY_MASTER v1.0${NC}"
echo ""

# Git 저장소 확인
if [[ ! -d ".git" ]]; then
  echo -e "${RED}오류: 프로젝트 루트(git 저장소)에서 실행하세요${NC}"
  exit 1
fi

HOOKS_DIR=".git/hooks"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/hooks"

# pre-commit 설치
cp "$SOURCE_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"
echo -e "${GRN}✅ pre-commit hook 설치됨${NC}"

# .gitignore에 .env 추가
if [[ -f ".gitignore" ]]; then
  if ! grep -q "^\.env$" .gitignore; then
    echo "" >> .gitignore
    echo "# 시크릿 — SECURITY_MASTER v1.0 PART 12" >> .gitignore
    echo ".env" >> .gitignore
    echo ".env.local" >> .gitignore
    echo ".env.production" >> .gitignore
    echo -e "${GRN}✅ .gitignore에 .env 추가됨${NC}"
  else
    echo -e "${GRN}✅ .gitignore 이미 .env 포함${NC}"
  fi
fi

echo ""
echo -e "${BLD}설치 완료. 이제부터 git commit 시 자동 보안 검사 실행됩니다.${NC}"
echo -e "수동 실행: ${CYN}bash .git/hooks/pre-commit${NC}"
echo ""
