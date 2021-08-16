# SRTShift
Shift an SRT file's timestamps by a given amount of time.

# Usage: 
 
 perl ShiftSRT.pl filename.srt '-00:00:01,000'
 
 or
 
 perl ShiftSRT.pl filename.srt '00:00:01,000'
 
 # Samples:
 Running the script with the sample.srt as follows:

 perl ShiftSRT.pl sample.srt '-00:00:03,000'

 generates the sample-resync.srt file if you would like to validate the script is working.
