#!/bin/bash

JDK_VERSION=13.0.1

if [[ "$OSTYPE" == "linux-gnu" ]]; then
    OS=linux
    EXT=tar.gz
    JDK_DIR=jdk-${JDK_VERSION}
    JDK_HOME=$(pwd)/${JDK_DIR}
elif [[ "$OSTYPE" == "darwin"* ]]; then
    OS=osx
    EXT=tar.gz
    JDK_DIR=jdk-${JDK_VERSION}.jdk
    JDK_HOME=$(pwd)/${JDK_DIR}/Contents/Home
elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    OS=windows
    EXT=zip
    JDK_DIR=jdk-${JDK_VERSION}
    JDK_HOME=$(pwd)/${JDK_DIR}
else
    echo "Error: unsupported OS type: ${OSTYPE}" && exit 1
fi

JDK_URL="https://download.java.net/java/GA/jdk${JDK_VERSION}/cec27d702aa74d5a8630c65ae61e4305/9/GPL/openjdk-${JDK_VERSION}_${OS}-x64_bin.${EXT}"
JDK_FILE=${JDK_URL##*/}

# Download JDK
CURL=$(which curl)
WGET=$(which wget)
if [[ ! -z ${CURL} ]]; then
    echo $JDK_URL
    $CURL -o ${JDK_FILE} ${JDK_URL}
elif [[ ! -z ${WGET} ]]; then
    $WGET ${JDK_URL}
else
    echo "Error: no curl or wget found. Cannot download." && exit 2
fi

[[ ! -f ${JDK_FILE} ]] && echo "Error: failed to download ${JDK_FILE}." && exit 3

# Extract JDK package
if [[ "${EXT}" == "tar.gz" ]]; then
    echo "Extracting ${JDK_FILE}"
    tar zxf ${JDK_FILE}
elif [[ "${EXT}" == "zip" ]]; then
    [[ -z $(which unzip) ]] && echo "Error: unzip command not found. Cannot extract ${JDK_FILE}" && exit 4
    echo "Extracting ${JDK_FILE}"
    unzip ${JDK_FILE}
else
    echo "Error: unknown file format: ${JDK_FILE_TYPE}" && exit 5
fi

[[ ! -d ${JDK_DIR} ]] && echo "Error: failed to extract ${JDK_FILE}. Directory: ${JDK_DIR} not found." && exit 6

# Remove JDK package file
echo "Removing ${JDK_FILE}"
rm -f ${JDK_FILE}

export JDK_HOME=${JDK_HOME}
export PATH=${JDK_HOME}/bin:${PATH}


# check if java and jlink exist
JAVA=$JDK_HOME/bin/java
JLINK=$JDK_HOME/bin/jlink
[[ ! -x $JAVA ]] && echo "${JAVA} not found." && exit 7
[[ ! -x $JLINK ]] && echo "${JLINK} not found." && exit 8


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
JRE_PKG="${JRE_NAME}_${OS}-x64.tar.gz"

echo "Packaging Java Runtime to ${JRE_PKG}"
tar -czvf ${JRE_PKG} ${JRE_NAME}

echo "Removing Java Runtime directory: ${JRE_NAME}"
rm -fr ${JRE_NAME}

echo "Removing JDK directory: ${JDK_DIR}"
rm -fr ${JDK_DIR}

echo "Created JRE package: $(pwd)/${JRE_PKG}"
