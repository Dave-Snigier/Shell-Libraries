# bash object implimentation using variable namespace
source "$IMAGENOWDIR6$\\script\\lib\\OO-Library.sh"

#### ---- logging portion of script ---- ###

# usage:
# new DILogger working-path completePath importProcessName importProcessStep campusCode csvHeaderString

## class definition ##
class DILogger
	func DILogger
	func finish
	func log
	var completePath
	var importProcessName
	var importProcessStep
	var campusCode
	var csvHeaderString
	var logFileName
	var fullLogPath

## class implimentation ##

# constructor #
DILogger::DILogger() {
	completePath="$2"
	importProcessName="$3"
	importProcessStep="$4"
	campusCode="$5"
	csvHeaderString="$6"

	# build log filename
	# ex: 2012-01-29^UMBOS^Common App^03.csv
	logFileName="$(date +%Y-%m-%d)^${campusCode}^${importProcessName}^${importProcessStep}.csv"
	fullLogPath="${1}\\${logFileName}"

	# if the file hasn't been created yet, create it and write out the header
	if [[ ! -e ${fullLogPath} && ${csvHeaderString} ]]; then
		echo "${csvHeaderString}" > "${logFileName}"
	fi
}

DILogger::finish() {
	cp "${fullLogPath}" "${completePath}"
}

# methods #
DILogger::log() {
	echo "$1" >> "${fullLogPath}"
}
