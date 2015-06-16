# NFS safe mutex locking function. Now with 100% fewer race conditions
# requires write access to the directory containing the file to be locked

# bash object implimentation using variable namespace
source "/export/$(hostname -s)/inserver6/script/lib/OO-Library.sh"

# usage:
# new MutexLock objectName file-path

## class definition ##
class MutexLock
	func MutexLock
	func release
	func lock
	func checkExpired
	var fileToBeLocked
	var lockDirectoryPath
	var infoFile
	var expireTime
	var retryTime
	var retryCount
	var retryCounter

## class implimentation ##

# constructor #
# usage: new MutexLock filePathToBeLocked
MutexLock::MutexLock() {
	# check to make sure a file was actually passed
	if [[ -z ${1} ]]; then
		echo "usage: new MutexLock filePathToBeLocked"
	fi
	fileToBeLocked="$(readlink --canonicalize "${1}")"
	lockDirectoryPath="${fileToBeLocked}_lock"
	infoFile="${lockDirectoryPath}/lock_info.txt"
}

## -- Methods -- ##
# usage: MutexLock.checkExpired expirationTime(seconds) [errorEmail]
MutexLock::checkExpired() {
	expireTime=${1}
	# get timestamp from lock directory if it exists
	# TODO
	if (( $(date +%s -r ${lockDirectoryPath}) + ${expireTime} < $(date +%s) )); then
		return 0
	else
		if [[ $2 ]]; then
			# send email to alert admins
			mailx -s "Exclusive lock on ${fileToBeLocked} has expired" \
			"${$2}" \
<<EOF
Exclusive lock on ${fileToBeLocked} has expired
Please investigate the reason for the failure and delete the lock directory
to continue running the process.

Information from the locking process follows:

$(cat "${infoFile}")
EOF

		fi
		return 1
	fi
}

# usage: MutexLock.lock retryCount
MutexLock::lock() {
	retryCount=${1:-1} # set default retries to one (single shot) if not passed
	retryTime=5
	retryCounter=0
	while (( ${retryCounter} < ${retryCount} )); do
		if mkdir "${lockDirectoryPath}" ; then
			# create lockfile
			echo \
"Locking process information
============================
date: $(date --iso-8601=seconds)
PID: ${$}
Process Name: ${BASH_SOURCE}" > "${infoFile}"
			return 0
		else
			retryCounter=$((retryCounter + 1))
		fi
		sleep ${retryTime}
	done
	# fall through error logic when the number of retries is exceeded
	echo "Failed to lock ${fileToBeLocked}. Tried ${retryCount} times."
	return 1
}

# usage: MutexLock.release
MutexLock::release() {
	rm -rf "${lockDirectoryPath}"
}
