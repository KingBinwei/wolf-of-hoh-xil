#!/bin/bash
# Auto-push hook: triggers after git commits containing "Chapter" in message
# Reads the last commit message and auto-pushes if it's a chapter commit

LAST_MSG=$(git log -1 --pretty=%B 2>/dev/null)

if echo "$LAST_MSG" | grep -q "^Chapter"; then
    CHAPTER_NUM=$(echo "$LAST_MSG" | grep -oP 'Chapter \K\d+')
    echo "[auto-push] Chapter ${CHAPTER_NUM} commit detected. Pushing to origin..."
    git push origin main 2>&1

    # Tag if chapter number found
    if [ -n "$CHAPTER_NUM" ]; then
        git tag -f "ch${CHAPTER_NUM}" -m "$LAST_MSG" 2>/dev/null
        git push origin "ch${CHAPTER_NUM}" --force 2>&1
        echo "[auto-push] Tagged and pushed: ch${CHAPTER_NUM}"
    fi
    echo "[auto-push] Done."
fi
