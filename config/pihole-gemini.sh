#! /bin/bash
PIHOLEDIR=/etc/pihole
 
LOGFILEPATH="/var/log/pihole-gemini"
 
# List of files to sync
	FILES=(
		'black.list'
		'blacklist.txt'
		'regex.list'
		'whitelist.txt'
		'lan.list'
		'adlists.list'
		'gravity.list'
	)
 
# Full logfile path and name, uncluding timestamp
LOGFILE="${LOGFILEPATH}/pihole-gemini_`date +\%Y\%m\%d`.log"
 
# Flags used to determine script blocks to run.
# RUNUPDATE - 0 = Don't update; 1 = update Pi-holes
RUNUPDATE=0

# RESTART - 0 = Don't restart; 1 = restart
RESTART=0

# RUNGRAVITY - 0 = Don't update gravity; 1 = Update gravity (don't download lists)
RUNGRAVITY=0

# DEFAULT SSH_PORT - This value is only provided here to use the default port of 22 if a port is not defined for the specified ip address
DEFAULTSSH_PORT=22
 
# LOG HEADER START - The following echo commands are for formatting purposes in the log file.
echo "-----------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
echo "`date '+%Y-%m-%d %H:%M:%S'` - Successfully launched as user: $USER" 2>&1 | tee -a $LOGFILE
echo "                                 updating Pi-hole on $SSH_IP"
echo "-----------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
# LOG HEADER - END
 
# SSH CONNECTION TEST - START
echo "`date '+%Y-%m-%d %H:%M:%S'` - Testing SSH Connection to $SSH_USER@$SSH_IP. Please wait." 2>&1 | tee -a $LOGFILE
 
ssh -q -p $SSH_PORT $SSH_USER@$SSH_IP exit
SSHSTATUS=$?
 
	if [ $SSHSTATUS -eq 0 ]; then
		# SSH is up
		echo "`date '+%Y-%m-%d %H:%M:%S'` - SSH Connection to $SSH_USER@$SSH_IP was tested successfully." 2>&1 | tee -a $LOGFILE
		RUNUPDATE=1

	else
		# SSH is down
		echo "* `date '+%Y-%m-%d %H:%M:%S'` - ERROR! Unable to establish SSH connection as $SSH_USER@$SSH_IP on port $SSH_PORT." 2>&1 | tee -a $LOGFILE
		echo "*                       This is a fatal error as SSH is required for this script. Unable to update $SSH_IP on port $SSH_PORT." 2>&1 | tee -a $LOGFILE
		echo "*                       $SSH_IP may be offline, you may have specified the wrong port, or you have not correctly configured your SSH keys." 2>&1 | tee -a $LOGFILE
		echo "*                       $SSH_IP has NOT been updated."
		RUNUPDATE=0
	fi
# SSH CONNECTION TEST - END
 
# UPDATE REMOTE PIHOLE - START
if [ $RUNUPDATE -eq 1 ]; then
	echo "--------------------------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE

	# FILE SYNC - START - This section handles compares the local and remote versions of the files specified in the $FILES variable
				#     and updates the remote files if neccesary.   
	for FILE in ${FILES[@]}
		do
			if [[ -f $PIHOLEDIR/$FILE ]]; then
				echo "`date '+%Y-%m-%d %H:%M:%S'` - Comparing local to remote $FILE and updating if neccesary." 2>&1 | tee -a $LOGFILE

				RSYNC_COMMAND=$(rsync --rsync-path='/usr/bin/sudo /usr/bin/rsync' -aiu -e "ssh -l $SSH_USER@$SSH_IP -p$SSH_PORT" $PIHOLEDIR/$FILE $SSH_USER@$SSH_IP:$PIHOLEDIR)

					if [[ -n "${RSYNC_COMMAND}" ]]; then
						# rsync copied changes so restart

						case $FILE in
							adlists.list)
								# Updating adlists.list requires only a gravity update
								echo "`date '+%Y-%m-%d %H:%M:%S'` - Updated $FILE on $SSH_IP. Gravity will be updated on $SSH_IP." 2>&1 | tee -a $LOGFILE
								RUNGRAVITY=1
							;;

							gravity.list)
								# Updating gravity.list requires only a gravity update
								echo "`date '+%Y-%m-%d %H:%M:%S'` - Updated $FILE on $SSH_IP. Gravity will be updated on $SSH_IP." 2>&1 | tee -a $LOGFILE
								RUNGRAVITY=1
							;;

							*)
								# Updating white and/or black lists (or other files) requires a remote restart but not a gravity update
								echo "`date '+%Y-%m-%d %H:%M:%S'` - Updated $FILE on $SSH_IP. $SSH_IP will be restarted." 2>&1 | tee -a $LOGFILE
								RESTART=1
							;;
						esac

					else
						# no changes so do nothing
						echo "`date '+%Y-%m-%d %H:%M:%S'` - Local file $FILE matches $FILE on $SSH_IP. Remote file was not updated." 2>&1 | tee -a $LOGFILE
					fi

			else
				# file does not exist, skipping
				echo "`date '+%Y-%m-%d %H:%M:%S'` - Local file $FILE does not exist. Skipping." 2>&1 | tee -a $LOGFILE
			fi
		done
    # FILE SYNC - END
 
    # RESTART SSH_IP (IF NEEDED) - START
	if [ $RESTART -eq 1 ]; then
		echo "--------------------------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
		echo "`date '+%Y-%m-%d %H:%M:%S'` - Updated files have been copied to $SSH_IP. Restarting..." 2>&1 | tee -a $LOGFILE

		echo "`date '+%Y-%m-%d %H:%M:%S'` - Sending restart command to pihole container $SSH_IP." 2>&1 | tee -a $LOGFILE

		ssh $SSH_USER@$SSH_IP -p $SSH_PORT "sudo -S docker restart pihole"
		if [ $? -ne 0 ]; then
			echo "* `date '+%Y-%m-%d %H:%M:%S'` - ERROR! - Unable to restart pihole-FTL service on $SSH_IP." 2>&1 | tee -a $LOGFILE

		else
			echo "`date '+%Y-%m-%d %H:%M:%S'` - Successfully restarted pihole-FTL service on $SSH_IP." 2>&1 | tee -a $LOGFILE
		fi
	fi
    # RESTART SSH_IP - END
 
    # UPDATE REMOTE GRAVITY (IF NEEDED) - START
    echo "--------------------------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
	case $RUNGRAVITY in
		0)
			# Gravity did not need updating - do nothing
			echo "`date '+%Y-%m-%d %H:%M:%S'` - Gravity on $SSH_IP did not need updating." 2>&1 | tee -a $LOGFILE
		;;
		1)
			# Gravity needs refreshing, but not a full update - Update gravity without redownloading lists
			echo "`date '+%Y-%m-%d %H:%M:%S'` - Refreshing gravity on $SSH_IP. Lists will not be redownloaded." 2>&1 | tee -a $LOGFILE
			ssh $SSH_USER@$SSH_IP -p $SSH_PORT "sudo -S docker exec -it pihole pihole -g --skip-download"
			if [ $? -ne 0 ]; then
				echo "* `date '+%Y-%m-%d %H:%M:%S'` - ERROR! - Unable to refresh gravity on $SSH_IP." 2>&1 | tee -a $LOGFILE

			else
				echo "`date '+%Y-%m-%d %H:%M:%S'` - Success! Successfully refreshed gravity on $SSH_IP." 2>&1 | tee -a $LOGFILE
			fi
		;;
	esac
    # UPDATE REMOTE GRAVITY - END
 
    # CLEAN OLD LOG FILES - START
	# Check the LOGFILEPATH for outdated log files and delete old logs
	echo "--------------------------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
	echo "`date '+%Y-%m-%d %H:%M:%S'` - Checking ${LOGFILEPATH} for outdated log files." 2>&1 | tee -a $LOGFILE

	look_in="${LOGFILEPATH}/pihole-gemini_*.log"

	del_file=`find $look_in ! -wholename $LOGFILE -daystart -mtime +$LOGKEEPDAYS`
	if [ -z "$del_file" ]; then
		echo "`date '+%Y-%m-%d %H:%M:%S'` - There were no outdated log files to remove." 2>&1 | tee -a $LOGFILE

	else
		echo "`date '+%Y-%m-%d %H:%M:%S'` - Outdated log file(s) found. Removing..." 2>&1 | tee -a $LOGFILE
		sudo find $look_in ! -wholename $LOGFILE -daystart -mtime +$LOGKEEPDAYS -prune -exec rm -rv "{}" \;
		if [ $? -ne 0 ]; then
			echo "`date '+%Y-%m-%d %H:%M:%S'` - ERROR! Unable to remove outdated log files from $LOGFILEPATH." 2>&1 | tee -a $LOGFILE
		else
			echo "`date '+%Y-%m-%d %H:%M:%S'` - Outdated log files successfully cleaned." 2>&1 | tee -a $LOGFILE
		fi
	fi
    # CLEAN OLD LOG FILES - END
 
fi
# UPDATE REMOTE PIHOLE - END
 
# LOG FOOTER - START
    echo "--------------------------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
    echo "`date '+%Y-%m-%d %H:%M:%S'` - Completed update of $SSH_IP" 2>&1 | tee -a $LOGFILE
    echo "--------------------------------------------------------------------------------------------" 2>&1 | tee -a $LOGFILE
# LOG FOOTER - END
 
# END OF SCRIPT