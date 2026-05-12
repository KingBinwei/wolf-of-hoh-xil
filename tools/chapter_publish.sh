#!/bin/bash
# Chapter publish script — commits, tags, and pushes chapter updates
# Usage: bash tools/chapter_publish.sh <chapter_number> "<description>"
# Example: bash tools/chapter_publish.sh 2 "荒野探索 + 狼同伴系统"

CHAPTER="${1:?Usage: chapter_publish.sh <chapter_number> <description>}"
DESC="${2:?Missing description}"

CHAPTER_TAG="ch${CHAPTER}"
CHAPTER_NAMES=(
  "十二米宽的沥青"
  "荒野中的同类"
  "公路上的博弈"
  "裂痕"
  "血与橡胶"
  "地平线之外"
)
CHAPTER_NAME="${CHAPTER_NAMES[$((CHAPTER - 1))]:-未知章节}"

echo "=== Publishing Chapter ${CHAPTER}: ${CHAPTER_NAME} ==="
echo "Description: ${DESC}"
echo ""

# Stage all changes
git add -A

# Commit with chapter-stamped message
COMMIT_MSG="Chapter ${CHAPTER}: ${CHAPTER_NAME} — ${DESC}"
git commit -m "${COMMIT_MSG}" || { echo "No changes to commit."; exit 0; }

# Tag this chapter release (move tag if exists)
git tag -f "${CHAPTER_TAG}" -m "Chapter ${CHAPTER}: ${CHAPTER_NAME}"

# Push commit and tag
git push origin main
git push origin "${CHAPTER_TAG}" --force

echo ""
echo "=== Chapter ${CHAPTER} published to GitHub ==="
echo "  Commit: $(git rev-parse --short HEAD)"
echo "  Tag:    ${CHAPTER_TAG}"
echo "  URL:    https://github.com/KingBinwei/wolf-of-hoh-xil/releases/tag/${CHAPTER_TAG}"
