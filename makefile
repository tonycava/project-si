deploy:
	yarn install --production --modules-folder ./dist/node_modules
	rm -rf ./dist/.bin
	yarn build
	cd infra && terraform apply -auto-approve

destroy:
	cd infra && terraform destroy -auto-approve