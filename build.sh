#!/bin/bash
set -e
cd "$(dirname "$0")"
clang -c iohid-bridge.c -o iohid-bridge.o
swiftc mouse-reverser.swift iohid-bridge.o -o mouse-reverser
rm -f iohid-bridge.o
echo "Built: $(pwd)/mouse-reverser"
