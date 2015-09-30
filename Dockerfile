FROM odino/docker-node-alpine:latest
COPY . /usr/src/myapp
WORKDIR "/usr/src/myapp"
RUN npm install
CMD bin/hubot -a slack
