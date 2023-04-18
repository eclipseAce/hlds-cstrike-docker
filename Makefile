.PHONY: build
build:
	docker build -f Dockerfile -t "hlds-cstrike:alpha" .
