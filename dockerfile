# miniconda image with conda
FROM continuumio/miniconda

# Install basic packages
RUN apt-get update && apt-get install -y libltdl7 && rm -rf /var/lib/apt/lists/*
RUN conda update -y conda
RUN conda install -c bioconda bwa
# Make port 80 available to the world outside this container
EXPOSE 80

# set env name
ENV NAME bwa

# Run python when the container launches
CMD ["bwa"]