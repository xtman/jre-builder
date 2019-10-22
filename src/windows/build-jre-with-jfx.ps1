# Environment variables: JDK_HOME and JAVAFX_SDK_HOME must be set. You can uncomment and edit the two lines below to set them.
 $Env:JDK_HOME = "C:\Users\wliu5\Downloads\jdk-13.0.1"
 $Env:JAVAFX_JMODS_HOME = "C:\Users\wliu5\Downloads\javafx-jmods-13.0.1"

if (-Not (Test-Path Env:JDK_HOME)) {
    Write-Error "Error: Environment variable: JDK_HOME is not set."
    Exit 1
}

if (-Not (Test-Path Env:JAVAFX_JMODS_HOME)) {
    Write-Error "Error: Environment variable: JAVAFX_SDK_HOME is not set."
    Exit 2
}

# check if java exists
$JAVA="$Env:JDK_HOME\bin\java.exe"
if (-Not (Test-Path $JAVA)) {
    Write-Error "Error: $JAVA does not exist"
    Exit 3
}

# check if jlink exists
$JLINK="$Env:JDK_HOME\bin\jlink.exe"
if (-Not (Test-Path $JLINK)) {
    Write-Error "Error: $JLINK does not exist"
    Exit 4
}

# 
$Env:PATH = $Env:JDK_HOME + "\bin;" + $Env:PATH

# parse Java version
$VERSION_LINE = (& $JAVA -version 2>&1 | Select-String version)
$NAME = ($VERSION_LINE | %{$_.Line.Split(' ')[0];})
$VERSION = ($VERSION_LINE | %{$_.Line.Split(' ')[2].Replace("`"", "");})
$JRE_NAME = $NAME + "-" + $VERSION + "-jre"

# get all moudles
$MODULES = "javafx.controls"
& $JAVA --list-modules | ForEach-Object { 
    $MODULES += "," + ($_ -replace "@.*")
}

# build Java Runtime with all the modules
Write-Output "Building JRE to directory: .\$JRE_NAME"
& $JLINK --no-header-files --no-man-pages --compress=2 --module-path "$Env:JDK_HOME\jmods;$Env:JAVAFX_JMODS_HOME" --add-modules ${MODULES} --output ${JRE_NAME}

# package the Java Runtime as ZIP file
$WORD_SIZE = (& $JAVA -version 2>&1 | Select-String Bit | %{$_.Line.Split(' ')[1].Replace("-Bit", "");})
$JRE_ZIP = $JRE_NAME + "-with-jfx_windows-x" + $WORD_SIZE + ".zip" 

Write-Output "Making JRE package: .\$JRE_ZIP"
Compress-Archive -Path $JRE_NAME -DestinationPath $JRE_ZIP

# remove the Java Runtime directory
Write-Output "Removing diretory: .\$JRE_NAME"
Remove-Item -Recurse -Force -LiteralPath $JRE_NAME

# the final result is the zip file.
Write-Output "Created JRE package: .\$JRE_ZIP"