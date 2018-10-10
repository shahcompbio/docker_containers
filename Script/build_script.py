import subprocess
from git import Git, Repo
import os

#Tag convertion should go: FOLDER_NAME-Version_Number
#Example: bwa-0.0.1
if __name__ == "__main__":

	print os.getcwd()
	repo = Repo(os.getcwd())
	tags = sorted(repo.tags, key=lambda t: t.commit.committed_datetime)
	print (tags[-1])
	folder_name = str(tags[-1]).split('-')[0].lower()
	new_version = str(tags[-1]).split('-')[1]

	try:
		with open (folder_name + "/VERSION", "w") as f:
			f.seek(0)
			f.write(new_version)
			f.truncate()
	except (OSError, IOError) as e:
		print (e)

	'''VERSION_NOT_FOUND = True
	while VERSION_NOT_FOUND:
		try:
			subprocess.call(["ls", "VERSION"])
			with open("VERSION", "r") as version_file:
				data = version_file.read()
				print("Current VERSION is: " + data)
			VERSION_NOT_FOUND = False
		except OSError:
			subprocess.call(["cd", ".."])
	subprocess.call(["ls", "-l"])
	with open("~/" + branch.name + "/" + "VERSION", "r") as version_file:
		data = version_file.read()
	print("Current VERSION is: " + data)
	new_version = input("Please enter the updated VERSION number: ")
	with open("VERSION", "w") as version_file:
		version_file.seek(0)
		version_file.write(str(new_version))
		version_file.truncate()
	print ("New version is %s" % new_version)'''
