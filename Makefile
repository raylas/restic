test:
	./test.sh

build:
	docker build --no-cache --tag restic .

clean:
	rm -rf /tmp/test-data/ /tmp/test-repo/