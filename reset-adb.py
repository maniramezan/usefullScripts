import subprocess

subprocess.call(["adb", "kill-server"])
subprocess.call(["adb", "start-server"])
subprocess.call(["adb", "start-server"])