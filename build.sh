#!/bin/env bash

PATH=$PATH:/home/meta/rbin

set -x

odin build . && echo "OK"
