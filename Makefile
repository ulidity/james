REPO = ulidity/james

build_image:
	@ docker build -t $(REPO):$(VERSION) --build-arg API_TOKEN=$(API_TOKEN) .

tag_latest:
	@ docker tag $(REPO):$(VERSION) $(REPO):latest

publish_image:
	@ docker push $(REPO):$(VERSION)
