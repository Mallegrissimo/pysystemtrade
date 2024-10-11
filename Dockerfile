FROM ubuntu:22.04

ARG PROJECT_NAME
ARG POSTGRES_PORT

RUN apt-get update && apt-get install -y \
    python3-minimal \
    python3-pip \
    postgresql-client \
    openssh-server \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set up SSH
RUN mkdir /var/run/sshd
RUN echo "root:password" | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

WORKDIR /app

COPY requirements.txt .

RUN pip3 install --no-cache-dir -r requirements.txt

COPY . .

# Use the PROJECT_NAME argument
ENV PROJECT_NAME=$PROJECT_NAME

EXPOSE 22 $POSTGRES_PORT

CMD ["/usr/sbin/sshd", "-D"]