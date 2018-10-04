# miniconda image with conda
FROM continuumio/miniconda

# Install basic packages
RUN apt-get update && apt-get install -y libltdl7 && rm -rf /var/lib/apt/lists/*
RUN conda update -y conda
RUN conda install -c conda-forge readline=6.2 
RUN conda install -c dranew -c bioconda bioconductor-aneufinder bioconductor-bsgenome.hsapiens.ucsc.hg19
# Make port 80 available to the world outside this container
EXPOSE 80

# set env name
ENV NAME samtools

# Run python when the container launches
CMD ["samtools"]