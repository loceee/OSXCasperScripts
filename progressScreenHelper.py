#!/usr/bin/python
# progresScreenHelper.py
# the most bodacious progress screen's best friend - https://github.com/jason-tratta/ProgressScreen
#
# progress screen interacts via applescript, which isn't the most fun thing from a jamf policy
# progresScreenHelper is here to halp.
#
# put it in jamf
# call it from a policy at the start of your build policies
# Policy: Start Build
# progressScreenHelper.py
# --start
# /Library/Management/Images/ProgresScreen/build/index.html
# --fullscreen
# --hidequit
# --buildtime 600
#
# Policy: Install Apps
# Package: App.pkg Install
#
# Policy: Build - Half way there
# progressScreenHelper.py
# --progress 50
#
# Policy: Install Moar Apps
# Package: App_2.pkg Install
#
# Policy: Build - Almost done
# progressScreenHelper.py
# --progress 95
#
# Policy: Build - Done
# progressScreenHelper.py
# --progress 100
# --end


import sys
import os
import argparse
import shlex
import subprocess
import argparse

progress_screen_app = "/Library/Management/bin/ProgressScreen.app"
prefs = "/tmp/.progressscreen_helper"

def getArguments():
	'''
	get the arguments from command line
	'''
	parser = argparse.ArgumentParser()
	parser.add_argument("jamf-arguments", nargs="*", help='toss in all the jamf arguments in here')
	parser.add_argument('--start', nargs='?', const='_empty_', metavar='[html_path]', help='start ProgressScreen with [html_path]')
	parser.add_argument('--fullscreen', action='store_true', help='set fullscreen mode')
	parser.add_argument('--hidequit', action='store_true', help='hide the quit button')
	parser.add_argument('--buildtime', nargs=1, metavar='[build_time_secs]', type=int, help='set [build_time_secs] for progress bar')
	parser.add_argument('--progress', nargs=1, metavar='[progress_percentage]', type=int, help='set [progress_percentage] (based on build_time_sec) for progress bar')
	parser.add_argument('--waypoints', nargs=4, metavar='[app.pkg]', help='set waypoints to [app1.pkg] [app2.pkg] [app3.pkg] [app4.pkg]')
	parser.add_argument('--end', action='store_true', help='quit the app and remove temp file')

	if len(sys.argv[1:])==0:
	    parser.print_help()
	    parser.exit()
	args = parser.parse_known_args()[0]
	return args

def sendAppleScript(command):
	'''
	send Apple script to command to ProgressScreen
	'''
	osa_full_command = shlex.split("""osascript -e 'tell application "ProgressScreen"' -e '%s' -e 'end tell'""" % command)
	subprocess.check_output(osa_full_command)


def tellProgressScreen(command, setting):
	'''
	tell progress screen to do any of it's tricks - ref.. https://github.com/jason-tratta/ProgressScreen
	'''
	# if we've been passed a boolean, make it a string to be passto osa_script
	if isinstance(setting, bool):
	 	setting = "True"
	applescript = "set %s of every configuration to %s" % (command, setting)
	sendAppleScript(applescript)

def errorHander(error, type):
	'''
	type - anything or ='stop' to break execution
	'''
	print "%s: %s" % (type, error)
	if type == "STOP":
		sys.exit(1)

def main():
	args = getArguments()

	if args.start:
		html_path = args.start
		if html_path == "_empty_":
			errorHander("i expected and html file", "STOP")
		if not os.path.exists(html_path):
			errorHander("couldn't find: %s" % html_path, "STOP")
		# i couldn't figure out quoting passing this to sendAppleScript -derp
		osa_full_command = shlex.split("""osascript -e 'tell application "ProgressScreen"' -e 'set htmlURL of every configuration to "%s"' -e 'end tell'""" % html_path)
		subprocess.check_output(osa_full_command)


	if args.fullscreen:
		tellProgressScreen("fullscreen", True)

	if args.hidequit:
		tellProgressScreen("hideQuitButton", True)

	if args.buildtime:
		build_time = args.buildtime[0]
		with open(prefs, 'w') as f:
			f.write(str(build_time))
		tellProgressScreen("buildTime", build_time)

	if args.progress:
		progress_percentage = args.progress[0]
		# read the build time from previous policy
		if os.path.isfile(prefs):
			with open (prefs, 'r') as f:
				build_time = int(f.read().replace('\n', ''))
		# or set it as a default
		else:
			build_time = 10000
		current_time = (progress_percentage * build_time) / 100
		tellProgressScreen("currentTime", current_time)

	if args.waypoints:
		tellProgressScreen("useWayPointMethod", True)
		tellProgressScreen("wayPointOne", args.waypoints[1])
		tellProgressScreen("wayPointTwo", args.waypoints[2])
		tellProgressScreen("wayPointThree", args.waypoints[3])
		tellProgressScreen("wayPointFour", args.waypoints[4])

	if args.end:
		if os.path.isfile(prefs):
			os.remove(prefs)
		subprocess.check_output(['killall','ProgressScreen'])

if __name__ == "__main__":
    main()
