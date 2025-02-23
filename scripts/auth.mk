auth:
	cd ctrack && mix phx.gen.auth --hashing-lib pbkdf2 --web Auth --live Accounts User users
