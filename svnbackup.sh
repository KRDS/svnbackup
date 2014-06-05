#!/bin/sh
# Usage : ./backup.sh [project_folder] [backup_folder]
#
# Where [project_folder] contains SVN repositories as children folders.
# Will compare the last commit date of each file with the backup in [backup_folder]
# and tar the repo if the backup is older.

backupfolder="$2"
date=`date`

echo "--- Starting SVN Backup - $date ---"
mkdir -p /tmp/svn

# List folders
for i in `find "$1" -type d`; do
	pushd $i > /dev/null
	i=`basename $i`

	# Get full path
	path=`pwd`

	# Get dates of commit and backup
	commitdate=`/usr/local/bin/svn log file://$path -r HEAD | grep "|" | sed -e "s/.*| \([0-9]\{4\}.*\)(.*/\1/g"`
	unixcommitdate=`date -d "$commitdate" +%s`

	bkpdate=`stat $backupfolder/$i.gz -c "%y" 2>/dev/null`

	if [[ $? -ne 0 ]]; then
		unixbkpdate='0'
	else
		unixbkpdate=`date -d "$bkpdate" +%s`
	fi

	echo "$i : Commit $unixcommitdate - Backup $unixbkpdate"

	if [[ "$unixcommitdate" -gt "$unixbkpdate" ]]; then
		rm -fr /tmp/svn/$i
		echo "----> Backup needed for $i.."
		/usr/local/bin/svnadmin hotcopy . /tmp/svn/$i
		tar --remove-files -czf $backupfolder/$i.gz /tmp/svn/$i >/dev/null 2>&1
		rm -fr /tmp/svn/$i
		echo "Done"
	fi

	# Check if backup is needed
	popd > /dev/null
done

date=`date`
echo "--- Finished SVN Backup - $date ---"