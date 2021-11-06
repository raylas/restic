test:
	./test.sh

build:
	docker build --no-cache --tag restic .

clean:
	rm -rf $(pwd)/test-data/ $(pwd)/test-repo/