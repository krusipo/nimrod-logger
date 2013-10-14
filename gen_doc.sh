#!/usr/bin/env bash
nimrod doc logger.nim
~/.cabal/bin/pandoc -f html -t markdown logger.html > README.md