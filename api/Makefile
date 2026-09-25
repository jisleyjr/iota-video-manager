.PHONY: help clean build rebuild run check dependencies format

help: ## print this help message
	@grep -E '^[/\.a-z%A-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[33m%-20s\033[0m %s\n", $$1, $$2}'

run: ## start the Spring app on assigned port
	./gradlew formatKotlin
	./gradlew bootRun --args='--spring.profiles.active=local'

clean: ## clear the contents of the build directory
	./gradlew clean

build: ## task to designate assembling all outputs, and running linter and all checks
	./gradlew formatKotlin
	./gradlew build

check: ## run all verification tasks such as tests and linting
	./gradlew formatKotlin
	./gradlew check

dependencies: ## install and list dependencies used
	./gradlew -q dependencies

format: ## automatically format the code based upon [ktlint](https://ktlint.github.io/) rules
	./gradlew formatKotlin
