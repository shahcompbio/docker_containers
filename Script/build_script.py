import subprocess
from git import Git, Repo
import os

#Tag convertion should go: FOLDER_NAME-Version_Number
#Example: bwa-0.0.1
if __name__ == "__main__":

	#Test Registry. Change to Actual Registry when code is in production
	registry_url = "singlecellcontainers.azurecr.io"
	print os.getcwd()
	repo = Repo(os.getcwd())
	tags = sorted(repo.tags, key=lambda t: t.commit.committed_datetime)
	print (tags[-1])
	folder_name = str(tags[-1]).split('-')[0].lower()
	new_version = str(tags[-1]).split('-')[1]

	try:
		username = os.environ['CLIENT_ID']
		password = os.environ['SECRET_KEY']
	except (KeyError) as e:
		print (e)

	docker_login_cmd = "docker login -u " + username + " -p " + password
	docker_build_cmd = "cd " + folder_name + " ; docker build -t " + folder_name + " ." 
	#docker_tag_cmd = 
	#docker_push_cmd = 
	try:
		subprocess.call(["docker" , "login", "singlecellcontainers.azurecr.io", "-u", username, "--password", password])
		output = subprocess.check_output("{}; {}".format("cd " + folder_name, "docker build -t " + folder_name + " ."), shell=True)

		#############################################################################################
		#         																					#
		# Might be a better way to do this. Don't really feel comfortable using hardcoded numbers   #
		#																							#
		#############################################################################################
		build_id = output.splitlines()[-2].split()[-1] #Build ID is the last string in the second last line of terminal output after running docker build

		subprocess.call(["docker", "tag", build_id, "singlecellcontainers.azurecr.io/scp/" + folder_name + ":" + new_version])
		subprocess.call(["docker", "push", "singlecellcontainers.azurecr.io/scp/" + folder_name + ":" + new_version])
	except OSError as e:
		print (e)
