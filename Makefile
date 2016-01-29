.PHONY: all
all:
	@sh -c "$(CURDIR)/scripts/build.sh"

.PHONY: clean
clean:
	rm -rf pkg
