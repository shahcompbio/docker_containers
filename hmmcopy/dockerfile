# miniconda image with conda
FROM continuumio/miniconda

# Install basic packages
RUN apt-get update && apt-get install -y libltdl7 && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y software-properties-common gnupg && add-apt-repository -y ppa:neurobin/ppa && apt-get install -y shc
RUN conda update -y conda
RUN conda install -c r r-plyr r-getopt r-data.table
RUN conda install -c bioconda bioconductor-hmmcopy
RUN conda install -c dranew hmmcopy_utils
RUN export GIT_SSL_NO_VERIFY=1 && pip install git+https://dgrewal@svn.bcgsc.ca/bitbucket/scm/sc/single_cell_pipeline.git@master
RUN echo '#!/bin/bash' > /usr/bin/hmmcopy;echo "Rscript $(python -c "import os;import single_cell;print os.path.join(os.path.dirname(single_cell.__file__), \"workflows\", \"hmmcopy\", \"scripts\", \"hmmcopy.R\")") \$*" >> /usr/bin/hmmcopy && chmod u+x /usr/bin/hmmcopy
#RUN printf '#!/bin/bash\n Rscript $(python -c "import os;import single_cell;print os.path.join(os.path.dirname(single_cell.__file__), 'workflows', 'hmmcopy', 'scripts', 'hmmcopy.R')")' > temp.sh;shc -f temp.sh -o /usr/bin/hmmcopy
# Make port 80 available to the world outside this container
EXPOSE 80

# set env name
ENV NAME hmmcopy
# Run python when the container launches
CMD ["hmmcopy"]