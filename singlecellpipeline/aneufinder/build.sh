et -ex
# SET THE FOLLOWING VARIABLES
# docker hub username
USERNAME=$CLIENT_ID
# image name
IMAGE=$(basename $PWD)
docker build -t $USERNAME/$IMAGE:latest .