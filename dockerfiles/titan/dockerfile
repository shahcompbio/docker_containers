# miniconda image with conda
FROM continuumio/miniconda

# Install basic packages
RUN apt-get update && apt-get install -y libltdl7 && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y software-properties-common gnupg && add-apt-repository -y ppa:neurobin/ppa && apt-get install -y shc
RUN conda update -y conda
RUN conda install -c r r-plyr r-getopt r-data.table
RUN conda install -c bioconda bioconductor-iranges bioconductor-rsamtools bioconductor-genomeinfodb bioconductor-hmmcopy bioconductor-geneplotter && conda install -c dranew bioconductor-titan
# Make port 80 available to the world outside this container
EXPOSE 80

# set env name
ENV NAME hmmcopy
# Run python when the container launches
CMD ["hmmcopy"]