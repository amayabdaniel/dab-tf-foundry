.PHONY: fmt validate modules-validate components-validate modules-test test tg-validate-dev clean

fmt:
	terraform fmt -recursive .

validate: modules-validate components-validate

modules-validate:
	@for dir in modules/*/; do \
		echo "==> Validating $$dir"; \
		(cd $$dir && terraform init -backend=false > /dev/null 2>&1 && terraform validate) || exit 1; \
	done

components-validate:
	@for dir in live/_components/*/; do \
		echo "==> Validating $$dir"; \
		(cd $$dir && terraform init -backend=false > /dev/null 2>&1 && terraform validate) || exit 1; \
	done

modules-test:
	@for dir in modules/*/; do \
		echo "==> Testing $$dir"; \
		(cd $$dir && terraform init -backend=false > /dev/null 2>&1 && terraform test) || exit 1; \
	done

test: validate modules-test

tg-validate-dev:
	cd live/dev && terragrunt run-all validate --terragrunt-non-interactive

clean:
	find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".terragrunt-cache" -exec rm -rf {} + 2>/dev/null || true
	find . -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	find . -name "*.zip" -path "*/build/*" -delete 2>/dev/null || true
