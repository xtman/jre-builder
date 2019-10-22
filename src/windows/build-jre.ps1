# Environment variable: JDK_HOME must be set. You can uncomment and edit the line below to set JDK_HOME
# $Env:JDK_HOME = "C:\Users\User\Downloads\openjdk-13.0.1"

if (-Not (Test-Path Env:JDK_HOME)) {
    Write-Output "Environment variable: JDK_HOME is not set."
    Exit 1
}

# check if java exists
JAVA="$Env:JDK_HOME\bin\java"
if (-Not (Test-Path $JAVA)) {
    Write-Output "$JAVA does not exist"
    Exit 3
}

# check if jlink exists
JLINK="$Env:JDK_HOME\bin\jlink"
if (-Not (Test-Path $JLINK)) {
    Write-Output "$JLINK does not exist"
    Exit 4
}

# parse Java version
$VERSION_LINE = (java -version 2>&1 | Select-String version)
$NAME = ($VERSION_LINE | %{$_.Line.Split(' ')[0];})
$VERSION = ($VERSION_LINE | %{$_.Line.Split(' ')[2].Replace("`"", "");})
$JRE_NAME = $NAME + "-" + $VERSION + "-jre"

# get all moudles
$MODULES = ""
$JAVA --list-modules | ForEach-Object { 
    $MODULES += ($_ -replace "@.*") + ","
}
$MODULES = ($MODULES -replace ",$")

# build Java Runtime with all the modules
Write-Output "Building JRE to directory: .\$JRE_NAME"
$JLINK --no-header-files --no-man-pages --compress=2 --module-path ${JDK_HOME}\jmods --add-modules ${MODULES} --output ${JRE_NAME}

# package the Java Runtime as ZIP file
$WORD_SIZE = (java -version 2>&1 | Select-String Bit | %{$_.Line.Split(' ')[1].Replace("-Bit", "");})
$JRE_ZIP = $JRE_NAME + "_windows-x" + $WORD_SIZE + ".zip" 

Write-Output "Making JRE package: .\$JRE_ZIP"
Compress-Archive -Path $JRE_NAME -DestinationPath $JRE_ZIP

# remove the Java Runtime directory
Write-Output "Removing diretory: .\$JRE_NAME"
Remove-Item -Recurse -Force -LiteralPath $JRE_NAME

# the final result is the zip file.
Write-Output "Created JRE package: .\$JRE_ZIP"