REPO = ulidity/james
NETWORK = ulidity

DB_HOST = redis
DB_PORT = 6379

build_image:
	@ docker build -t $(REPO):$(VERSION) --build-arg API_TOKEN=$(API_TOKEN) .

tag_latest:
	@ docker tag $(REPO):$(VERSION) $(REPO):latest

publish_image:
	@ docker push $(REPO):$(VERSION)

docker:
	@ docker run -d --network $(NETWORK) \
		-e JAMES_DB_HOST=$(DB_HOST) \
		-e JAMES_DB_PORT=$(DB_PORT) \
		$(REPO):$(VERSION)
