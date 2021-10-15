#!/bin/bash
ARGUMENT="$@"
/profiler.sh $(printenv TOOL) $(printenv TOOL_ARGUMENTS) "$(which COMMAND) $ARGUMENT"