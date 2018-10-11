import subprocess
from git import Git, Repo
import os

#Taken from StackOverflow LOL
def get_immediate_subdirectories(a_dir):
    return [name for name in os.listdir(a_dir)
            if os.path.isdir(os.path.join(a_dir, name))]

#Tag convertion should go: FOLDER_NAME-Version_Number
#Example: bwa-0.0.1
if __name__ == "__main__":
	#Test Registry. Change to Actual Registry when code is in production
	registry_url = "singlecellcontainers.azurecr.io"

	#Gets the tags from the repository
	list_of_all_dirs = get_immediate_subdirectories(os.getcwd())
	repo = Repo(os.getcwd())
	tags = sorted(repo.tags, key=lambda t: t.commit.committed_datetime)

	#Checks for tag formatting
	if(len(str(tags[-1]).split('-')) == 2):
		folder_name = str(tags[-1]).split('-')[0].lower()
		new_version = str(tags[-1]).split('-')[1]
	else:
		print ("Incorrectly formatted tag. Exiting script...")
		quit()

	#Checks for directory existence corresponding to tag prefix
	if(folder_name not in list_of_all_dirs):
		print ("Tag does not correspond to any folder. Exiting script...")
		quit()

	try:
		username = os.environ['CLIENT_ID']
		password = os.environ['SECRET_KEY']
	except (KeyError) as e:
		print (e)

	#TODO Error Handling: How to handle if login credentials are invalid?
	#Runs the docker commands
	try:
		code = subprocess.call(["docker" , "login", registry_url, "-u", username, "--password", password])
		if(code != 0):
			print ("Invalid login credentials. Exiting script...")
			quit()

		subprocess.call("{}; {}".format("cd " + folder_name, "docker build -t " + folder_name + " ."), shell=True)
		subprocess.call(["docker", "tag", folder_name, registry_url + "/scp/" + folder_name + ":" + new_version])
		subprocess.call(["docker", "push", registry_url + "/scp/" + folder_name + ":" + new_version])
	except OSError as e:
		print (e)
