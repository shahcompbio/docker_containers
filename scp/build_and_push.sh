SERVER=$1
NAME=$2
VER=$3



cd $NAME && docker build -t ${SERVER}/singlecellpipeline/${NAME}:${VER} .  && docker push ${SERVER}/singlecellpipeline/${NAME}:${VER}
