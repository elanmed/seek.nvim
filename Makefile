.PHONY: dev clean test lint format docs deploy

dev:
	mkdir -p ~/.local/share/nvim/site/pack/dev/start/seek.nvim
	stow -d .. -t ~/.local/share/nvim/site/pack/dev/start/seek.nvim seek.nvim

clean:
	rm -rf ~/.local/share/nvim/site/pack/dev

test:
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

lint:
	# https://luals.github.io/#install
	lua-language-server --check=./lua --checklevel=Error

format:
	# https://github.com/JohnnyMorganz/StyLua#usage
	stylua .

docs:
	./deps/ts-vimdoc.nvim/scripts/docgen.sh README.md doc/seek.txt seek
	nvim --headless -c "helptags doc/" -c "qa"

deploy: test lint format docs
