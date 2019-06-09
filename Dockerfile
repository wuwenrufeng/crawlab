# images
FROM ubuntu:latest

# source files
ADD . /opt/crawlab

# set as non-interactive
ENV DEBIAN_FRONTEND noninteractive

# environment variables
ENV NVM_DIR /usr/local/nvm  
ENV NODE_VERSION 8.12.0
ENV WORK_DIR /opt/crawlab

# install pkg
RUN apt-get update
RUN apt-get install -y curl git net-tools iputils-ping ntp gnupg2

# install mongodb
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4
echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu bionic/mongodb-org/4.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-4.0.list
RUN apt-get update
RUN apt-get install -y mongodb-org
RUN service mongod start

# install python
RUN apt-get install -y python python3 python3-pip 

# install nvm
RUN curl https://raw.githubusercontent.com/creationix/nvm/v0.24.0/install.sh | bash \  
    && . $NVM_DIR/nvm.sh \
    && nvm install v$NODE_VERSION \
    && nvm use v$NODE_VERSION \
    && nvm alias default v$NODE_VERSION
ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules  
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# install frontend
RUN npm install -g yarn pm2 --registry=https://registry.npm.taobao.org
RUN cd /opt/crawlab/frontend && yarn install --registry=https://registry.npm.taobao.org

# install nginx 
RUN apt-get install -y nginx

# install redis
RUN apt-get install -y redis-server
RUN service redis-server start

# python soft link
RUN ln -s /usr/bin/pip3 /usr/local/bin/pip
RUN ln -s /usr/bin/python3 /usr/local/bin/python

# install backend
RUN pip install -U setuptools -i https://pypi.tuna.tsinghua.edu.cn/simple
RUN pip install -r /opt/crawlab/crawlab/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# nginx config & start frontend
RUN cp $WORK_DIR/crawlab.conf /etc/nginx/conf.d
RUN service nginx reload

# start backend
WORKDIR /opt/crawlab/crawlab
ENTRYPOINT cd /opt/crawlab/crawlab/frontend \
	&& npm run build:prod \
	&& python3 $WORK_DIR/manage.py 

EXPOSE 8080
EXPOSE 8000