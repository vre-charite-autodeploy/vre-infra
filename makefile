# Makefile

# Define the list of stages as variables
STAGES := terraform/pre-install terraform/install terraform/intermediary-install terraform/post-install
MODULES := terraform/modules

# This runs the terraform commands in the required order. Plan-Files are not written out to disk. Apply will create it's own plans.
.PHONY: init-all validate-all apply-all

# Command to run `terraform init` in each stage
init-all:
	@for stage in $(STAGES); do \
		echo "\nRunning 'terraform init' in $$stage..."; \
		(cd $$stage && terraform init) && echo "Successfully initialized $$stage" || echo "Failed to initialize $$stage"; \
	done

# Command to run `terraform validate` in each stage (including modules)
validate-all:
	@for stage in $(STAGES) $(MODULES); do \
		echo "\nRunning 'terraform validate' in $$stage..."; \
		(cd $$stage && terraform validate); \
	done

# Command to run `terraform fmt` in each stage
fmt-all:
	@for stage in $(STAGES) $(MODULES); do \
		echo "\nRunning 'terraform fmt' in $$stage..."; \
		(cd $$stage && terraform fmt -recursive) && echo "Successfully formatted $$stage" || echo "Failed to format $$stage"; \
	done

# Command to run `terraform plan` in each stage
plan-all:
	for stage in $(STAGES); do \
		echo "\nRunning 'terraform plan' in $$stage..."; \
		(cd $$stage && terraform plan && echo "Successfully planned $$stage" || echo "Failed to plan $$stage"); \
	done


# Command to run `terraform apply` in each stage
apply-all:
	@read -p "Are you sure you want to apply changes? (yes/no): " confirm; \
	if [ "$$confirm" = "yes" ]; then \
		for stage in $(STAGES); do \
			echo "\nRunning 'terraform apply' in $$stage..."; \
			(cd $$stage && terraform apply && echo "Successfully applied $$stage" || echo "Failed to apply $$stage"); \
		done; \
	else \
		echo "Apply aborted."; \
	fi

# Check all (runs init-all, fmt-all and validate-all)
check-all: init-all fmt-all validate-all