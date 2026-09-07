@echo off
setlocal
set PRG=%~nx0
set SCRIPT_DIR=%~dp0
set WRAPPER_DIR=%SCRIPT_DIR%.mvn\wrapper
set WRAPPER_JAR=%WRAPPER_DIR%\maven-wrapper.jar

if not exist "%WRAPPER_JAR%" (
  echo Maven Wrapper JAR not found: %WRAPPER_JAR%
  echo Download it into .mvn\wrapper\maven-wrapper.jar and retry.
  exit /b 1
)

"%JAVA_HOME%\bin\java" -jar "%WRAPPER_JAR%" %*
