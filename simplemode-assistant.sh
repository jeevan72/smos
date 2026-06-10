#!/bin/bash
#======================================================
# SimpleMode OS — Terminal Assistant Launcher
#======================================================

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Activate virtual environment
if [ -f "${PROJECT_DIR}/venv/bin/activate" ]; then
    source "${PROJECT_DIR}/venv/bin/activate"
else
    echo "Virtual environment not found. Run ./setup.sh first."
    exit 1
fi

# Pass profile if it exists
PROFILE_ARG=""
if [ -f "${PROJECT_DIR}/.simplemode-profile" ]; then
    source "${PROJECT_DIR}/.simplemode-profile"
    PROFILE_ARG="--mode ${USER_TYPE:-beginner}"
fi

python3 "${PROJECT_DIR}/assistant/assistant.py" \
    --knowledge "${PROJECT_DIR}/knowledge" \
    ${PROFILE_ARG}
