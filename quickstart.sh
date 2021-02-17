#!/bin/bash
git submodule init
git submodule update
wget -O c-icap/Glasswall-Rebuild-SDK-Evaluation/Linux/Library/libglasswall.classic.so https://raw.githubusercontent.com/filetrust/Glasswall-Rebuild-SDK-Evaluation/master/Linux/Library/libglasswall.classic.so
docker-compose build --no-cache
docker-compose up -d
