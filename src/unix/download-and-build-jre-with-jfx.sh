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

JAVAFX_JMODS_URL=https://download2.gluonhq.com/openjfx/${JDK_VERSION}/openjfx-${JDK_VERSION}_${OS}-x64_bin-jmods.zip
JAVAFX_JMODS_FILE=openjfx-${JDK_VERSION}_${OS}-x64_bin-jmods.zip
JAVAFX_JMODS_DIR=javafx-jmods-${JDK_VERSION}
JAVAFX_JMODS_HOME=$(pwd)/${JAVAFX_JMODS_DIR}


# Download JDK package
CURL=$(which curl)
WGET=$(which wget)

echo "Downloading $JDK_URL"
if [[ ! -z ${CURL} ]]; then
    $CURL -o ${JDK_FILE} ${JDK_URL}
elif [[ ! -z ${WGET} ]]; then
    $WGET ${JDK_URL}
else
    echo "Error: no curl or wget found. Cannot download." && exit 2
fi
[[ ! -f ${JDK_FILE} ]] && echo "Error: failed to download ${JDK_FILE}." && exit 3

# Download JAVAFX JMODS package
echo "Downloading $JAVAFX_JMODS_URL"
if [[ ! -z ${CURL} ]]; then
    $CURL -o ${JAVAFX_JMODS_FILE} ${JAVAFX_JMODS_URL}
else
    $WGET ${JAVAFX_JMODS_FILE} ${JAVAFX_JMODS_URL}
fi
[[ ! -f ${JAVAFX_JMODS_FILE} ]] && echo "Error: failed to download ${JAVAFX_JMODS_FILE}." && exit 4


# Extract JDK package
[[ -z $(which unzip) ]] && echo "Error: unzip command not found." && exit 5

if [[ "${EXT}" == "tar.gz" ]]; then
    echo "Extracting ${JDK_FILE}"
    tar zxf ${JDK_FILE}
elif [[ "${EXT}" == "zip" ]]; then
    echo "Extracting ${JDK_FILE}"
    unzip ${JDK_FILE}
else
    echo "Error: unknown file format: ${JDK_FILE_TYPE}" && exit 6
fi
[[ ! -d ${JDK_DIR} ]] && echo "Error: failed to extract ${JDK_FILE}. Directory: ${JDK_DIR} not found." && exit 7

# Extract JAVAFX JMODS package
echo "Extracting ${JAVAFX_JMODS_FILE}"
unzip ${JAVAFX_JMODS_FILE}
[[ ! -d ${JAVAFX_JMODS_DIR} ]] && echo "Error: failed to extract ${JAVAFX_JMODS_FILE}. Directory: ${JAVAFX_JMODS_DIR} not found." && exit 8


# Remove JDK package file
echo "Removing ${JDK_FILE}"
rm -f ${JDK_FILE}

# Remove JAVAFX JMODS package file
echo "Removing ${JAVAFX_JMODS_FILE}"
rm -f ${JAVAFX_JMODS_FILE}


export JDK_HOME=${JDK_HOME}
export PATH=${JDK_HOME}/bin:${PATH}
export JAVAFX_JMODS_HOME=${JAVAFX_JMODS_HOME}

# check if java and jlink exist
JAVA=$JDK_HOME/bin/java
JLINK=$JDK_HOME/bin/jlink
[[ ! -x $JAVA ]] && echo "${JAVA} not found." && exit 9
[[ ! -x $JLINK ]] && echo "${JLINK} not found." && exit 10

if [[ -z $JAVAFX_JMODS_HOME ]]; then
    echo "JAVAFX_JMODS_HOME is not set" && exit 11
fi
if [[ ! -d $JAVAFX_JMODS_HOME ]]; then
    echo "${JAVAFX_JMODS_HOME} not found" && exit 12
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
JRE_PKG="${JRE_NAME}-with-jfx_${OS}-x64.tar.gz"

echo "Packaging Java Runtime to ${JRE_PKG}"
tar -czvf ${JRE_PKG} ${JRE_NAME}


echo "Removing JDK directory: ${JDK_DIR}"
rm -fr ${JDK_DIR}

echo "Removing JAVAFX JMODS directory: ${JAVAFX_JMODS_DIR}"
rm -fr ${JAVAFX_JMODS_DIR}

echo "Removing Java Runtime directory: $(pwd)/${JRE_NAME}"
rm -fr ${JRE_NAME}

echo "Created JRE package: $(pwd)/${JRE_PKG}"
