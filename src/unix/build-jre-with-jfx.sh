#!/bin/bash

# You can uncomment and modify the three lines below to set JDK_HOME, JAVAFX_SDK_HOME and JAVAFX_JMODS_HOME
# export JDK_HOME=/Library/Java/JavaVirtualMachines/jdk-13.0.1.jdk/Contents/Home
# export JAVAFX_JMODS_HOME=/opt/javafx-jmods-13.0.1

# check if java and jlink exist
if [[ ! -z $JDK_HOME ]]; then
    export PATH=$JDK_HOME/bin:$PATH
    JAVA=$JDK_HOME/bin/java
    JLINK=$JDK_HOME/bin/jlink
    [[ ! -x $JAVA ]] && echo "${JAVA} not found." && exit 1
    [[ ! -x $JLINK ]] && echo "${JLINK} not found." && exit 1
else
    JAVA=$(which java)
    JLINK=$(which jlink)
    [[ -z $JAVA ]] && echo "java not found." && exit 2
    [[ -z $JLINK ]] && echo "jlink not found." && exit 2
fi

if [[ -z $JAVAFX_JMODS_HOME ]]; then
    echo "JAVAFX_JMODS_HOME is not set" && exit 3
fi
if [[ ! -d $JAVAFX_JMODS_HOME ]]; then
    echo "${JAVAFX_JMODS_HOME} not found" && exit 4
fi

# parse java version
NAME=$($JAVA -version 2>&1 | grep version | awk '{print $1}')
VERSION=$($JAVA -version 2>&1 | grep version | awk '{print $3}' | tr -d '"')
JRE_NAME=${NAME}-${VERSION}-jre

# get all modules including javafx modules
MODULES="javafx.controls"
for m in $($JAVA --list-modules)
do
    MODULES=${MODULES},${m%%@$VERSION}
done

# build Java Runtime with jlink
echo "Building Java Runtime with all modules (including javafx) using jlink"
$JLINK --no-header-files --no-man-pages --compress=2 --module-path ${JDK_HOME}/jmods:${JAVAFX_JMODS_HOME} --add-modules ${MODULES} --output ${JRE_NAME}

# package the Java Runtime as .tar.gz 
WORD_SIZE=$($JAVA -version 2>&1 | grep Bit | awk '{print $2}' | tr -d '\-Bit')
if [[ "$OSTYPE" == "linux-gnu" ]]; then
    OS=linux
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS=osx
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS=windows
elif [[ "$OSTYPE" == "freebsd"* ]]; then
    OS=freebsd
else
    OS=unknown
fi
JRE_PKG="${JRE_NAME}-with-jfx_${OS}-x${WORD_SIZE}.tar.gz"

echo "Packaging Java Runtime to ${JRE_PKG}"
tar -czvf ${JRE_PKG} ${JRE_NAME}

echo "Removing Java Runtime directory: $(pwd)/${JRE_NAME}"
rm -fr ${JRE_NAME}

echo "Created JRE package: $(pwd)/${JRE_PKG}"
