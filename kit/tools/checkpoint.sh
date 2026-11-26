#!/usr/bin/env bash
# Save the current state of everything as a named checkpoint you can go back to.
# Usage: kit/tools/checkpoint.sh "Added the balloon level"
set -euo pipefail
source "$(dirname "$0")/env.sh"; source "$(dirname "$0")/git-common.sh"
tag=$(kit_checkpoint "${1:-Checkpoint}")
kit_say "Saved checkpoint $tag: ${1:-Checkpoint}"
