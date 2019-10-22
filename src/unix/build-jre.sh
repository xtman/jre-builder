#!/bin/bash

# You can uncomment and modify line below to set JDK_HOME
# export JDK_HOME=/Library/Java/JavaVirtualMachines/jdk-13.0.1.jdk/Contents/Home

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
    [[ -z $JAVA ]] && echo "java not found." && exit 1
    [[ -z $JLINK ]] && echo "jlink not found." && exit 2
fi

# parse java version
NAME=$($JAVA -version 2>&1 | grep version | awk '{print $1}')
VERSION=$($JAVA -version 2>&1 | grep version | awk '{print $3}' | tr -d '"')
JRE_NAME=${NAME}-${VERSION}-jre

# get all modules
MODULES=""
for m in $($JAVA --list-modules)
do
    MODULES=${MODULES},${m%%@$VERSION}
done
MODULES=${MODULES##,}

# build Java Runtime with jlink
echo "Building Java Runtime with all modules using jlink"
$JLINK --no-header-files --no-man-pages --compress=2 --module-path ${JDK_HOME}/jmods --add-modules ${MODULES} --output ${JRE_NAME}

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
JRE_PKG="${JRE_NAME}_${OS}-x${WORD_SIZE}.tar.gz"

echo "Packaging Java Runtime to ${JRE_PKG}"
tar -czvf ${JRE_PKG} ${JRE_NAME}

echo "Removing Java Runtime directory: $(pwd)/${JRE_NAME}"
rm -fr ${JRE_NAME}

echo "Created JRE package: $(pwd)/${JRE_PKG}"