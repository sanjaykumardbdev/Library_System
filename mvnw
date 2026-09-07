#!/usr/bin/env sh
# ----------------------------------------------------------------------------
# Apache Maven Wrapper
# ----------------------------------------------------------------------------
PRG="$(basename "$0")"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

JAVA_EXE=${JAVA_HOME:+"$JAVA_HOME/bin/java"}
if [ -z "$JAVA_EXE" ]; then
  JAVA_EXE=java
fi

WRAPPER_DIR="$SCRIPT_DIR/.mvn/wrapper"
WRAPPER_JAR="$WRAPPER_DIR/maven-wrapper.jar"

if [ ! -f "$WRAPPER_JAR" ]; then
  echo "Maven Wrapper JAR not found: $WRAPPER_JAR"
  echo "Please run the script to download the wrapper or ensure .mvn/wrapper/maven-wrapper.jar exists."
  exit 1
fi

exec "$JAVA_EXE" -jar "$WRAPPER_JAR" "$@"
