restart:
	docker-compose up --build -d --force-recreate

deps:
	cd ctrack && mix deps.get && mix ecto.migrate

migrate:
	cd ctrack && mix ecto.setup

run:
	cd ctrack && iex -S mix phx.server
