#!/bin/bash

#logging function used in dotman project - takes any input and logs it to a file
com_log() {
  echo "$@" >> /tmp/dotman.log
}
