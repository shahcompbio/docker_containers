SERVER=$1
NAME=$2
VER=$3



cd $NAME && docker build -t ${SERVER}/scp/${NAME}:${VER} . --no-cache && docker push ${SERVER}/scp/${NAME}:${VER}
