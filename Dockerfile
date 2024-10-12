FROM mongo:latest

# Install Python 3.10 and Git
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Set up SSH
RUN mkdir /var/run/sshd
RUN echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
RUN echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config

# Set root password
ARG ROOT_PASSWORD
RUN echo "root:${ROOT_PASSWORD}" | chpasswd

# Set up Python environment
ENV PYTHONUNBUFFERED=1
RUN ln -s /usr/bin/python3.10 /usr/local/bin/python

# Set up MongoDB
ARG PROJECT_NAME
ENV PROJECT_NAME=${PROJECT_NAME}


# Set MongoDB environment variables
ARG MONGO_INITDB_ROOT_USERNAME
ARG MONGO_INITDB_ROOT_PASSWORD
ENV MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}
ENV MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}

# Expose MongoDB and SSH ports
EXPOSE 27017 22

ENV PATH="/usr/local/bin:${PATH}"


# Set the entrypoint has been created/set in mongo:latest
ENTRYPOINT ["docker-entrypoint.sh"]

# Start MongoDB and SSH
# CMD ["mongod", "--bind_ip_all"]
# CMD ["/usr/sbin/sshd", "-D"]
CMD mongod --bind_ip_all --fork --logpath /var/log/mongod.log && \
    /usr/sbin/sshd -D