import subprocess

if __name__ == "__main__":
	curl_command = "curl https://repo.continuum.io/miniconda/Miniconda2-latest-Linux-x86_64.sh -o Miniconda2-latest-Linux-x86_64.sh".split()
	bash_command = "bash Miniconda2-latest-Linux-x86_64.sh -b".split()
	subprocess.call(curl_command)
	code = subprocess.call(bash_command)

