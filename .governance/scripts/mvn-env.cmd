@echo off
REM ============================================================
REM 项目标准 Maven 执行脚本
REM 用法: .governance\scripts\mvn-env.cmd clean install -DskipTests
REM ============================================================

set JAVA_HOME=D:\ProgramFiles\jdks\graalvm-jdk-21.0.7
set MAVEN_HOME=D:\ProgramFiles\apache-maven-3.9.14
set MVN_SETTINGS=D:\programData\.m2\settings.xml

"%MAVEN_HOME%\bin\mvn" -s "%MVN_SETTINGS%" %*
