TEMPLATE_NAME ?= janus-webrtc-gateway-docker

build:
	@docker build -t trinhdaiphuc/$(TEMPLATE_NAME) .

build-m1:
	@docker build --platform linux/amd64 -t trinhdaiphuc/$(TEMPLATE_NAME) .

build-nocache:
	@docker build --no-cache -t trinhdaiphuc/$(TEMPLATE_NAME) .

bash: 
	@docker run --net=host -v /home/ubuntu:/ubuntu --name="janus" -it -t trinhdaiphuc/$(TEMPLATE_NAME) /bin/bash

attach: 
	@docker exec -it janus /bin/bash

run: 
	@docker run --net=host --name="janus" -it -t trinhdaiphuc/$(TEMPLATE_NAME)

run-mac-m1:
	@docker run --rm --platform linux/amd64 -p 80:80 -p 8088:8088 -p 8188:8188 --name janus -d trinhdaiphuc/$(TEMPLATE_NAME)

run-hide: 
	@docker run --net=host --name="janus" -it -t trinhdaiphuc/$(TEMPLATE_NAME) >> /dev/null
