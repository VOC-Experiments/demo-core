.PHONY: format format-check
format:
	clang-format -i src/*.c src/*.h

format-check:
	clang-format --dry-run --Werror src/*.c src/*.h
