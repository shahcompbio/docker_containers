# build on top of out base image
FROM shahlab.azurecr.io/scp/python_singlecell_qc:v0.0.1

# Copy the current directory contents into the container at /app
ADD ./app /app

# Install any needed packages specified in requirements.txt
RUN apt-get update && apt-get install -y libltdl7 && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install libc-dev -y && apt-get install build-essential -y && rm -rf /var/lib/apt/lists/
RUN cd /app/mutationseq && python setup.py --boost_source=/app/boost_1_57_0 install
RUN conda install -c conda-forge intervaltree
RUN apt-get update && apt-get install vim -y
# Make port 80 available to the world outside this container
EXPOSE 80

# Define environment variable
ENV NAME scpipeline

# Run app.py when the container launches
CMD ["python"]