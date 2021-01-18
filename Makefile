.PHONY: buildpre
buildpre:
	poetry run python buildpre.py

.PHONY: build
build:
	poetry run python build.py clean
	poetry run python build.py build_ext --inplace --force

.PHONY: clean
clean:
	rm -rf build
	rm -rf dist

.PHONY: copy
copy:
	poetry run python buildpre.py

.PHONY: dist
dist: copy
	poetry build

.PHONY: docker
docker:
	docker build -t skgrf .

.PHONY: linux
linux: copy docker
	docker run --rm -v $(shell pwd)/dist:/app/dist:rw skgrf build

.PHONY: docs
docs:
	poetry export --without-hashes --dev -f requirements.txt > docs/requirements.txt && \
	cd docs && \
	poetry run sphinx-build -M html . _build -a && \
	cd .. && \
	open docs/_build/html/index.html

.PHONY: fmt
fmt:
	poetry run isort .
	poetry run black .

.PHONY: publish
publish: clean sdist
	poetry publish

.PHONY: release
release: clean sdist
	ghr -u crflynn -r skgrf -c $(shell git rev-parse HEAD) -delete -b "release" -n $(shell poetry version | tail -c +10) $(shell poetry version | tail -c +10) dist/*.tar.gz

.PHONY: sdist
sdist: copy
	poetry build -f sdist

.PHONY: setup
setup:
	git submodule init
	git submodule update
	asdf install
	poetry install --no-root
	poetry run python buildpre.py
	poetry install

.PHONY: test
test:
	poetry run pytest --cov=skgrf --cov-report=html tests/
	open htmlcov/index.html