# Laravel Spark on Docker

A Docker PHP environment that facilitates scalable Laravel Spark PHP Apps on Docker

[![License](https://img.shields.io/npm/l/enzyme.svg)](https://www.npmjs.com/package/enzyme) [![Build](https://img.shields.io/circleci/project/github/Premialab/laravel-spark.svg?logo=circleci)](https://circleci.com/gh/Premialab/laravel-spark) [![Latest Version](https://img.shields.io/github/tag-date/premialab/laravel-spark.svg?label=latest%20version&logo=github&logoColor=white)](https://github.com/Premialab/laravel-spark) 
<br/>[![](https://images.microbadger.com/badges/image/premialab/laravel-spark.svg)](https://microbadger.com/images/premialab/laravel-spark "Get your own image badge on microbadger.com") [![dockerhub](https://img.shields.io/badge/image-laravel--spark-orange.svg?logo=docker)](https://hub.docker.com/r/premialab/laravel-spark) [![](https://images.microbadger.com/badges/version/premialab/laravel-spark.svg)](https://microbadger.com/images/premialab/laravel-spark "Get your own version badge on microbadger.com")

## Build

```
docker build --force-rm --no-cache --build-arg DEBIAN_FRONTEND=noninteractive -t premialab/laravel-spark .
```
## Maintenance 

- The Docker image build & publish is automated by CircleCI for tags.
- All packages have handcoded versions in the Dockerfile that need to be bumped manually.

## Sponsors
[![Premialab Logo](https://assets.premialab.com/logo_assets/Full%20Color%20-%20BG%20Blue-NANO.png)](https://premialab.com)

## License
[MIT](/LICENSE.md)
