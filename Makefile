all: build

build: 
	docker build -t velocityorg/docker-gitlab-runner .
