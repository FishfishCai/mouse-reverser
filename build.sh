#!/bin/bash
set -e
cd "$(dirname "$0")"
clang -c iohid-bridge.c -o iohid-bridge.o
swiftc reverser.swift iohid-bridge.o -o reverser
rm -f iohid-bridge.o
echo "Built: $(pwd)/reverser"
