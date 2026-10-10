CC ?= cc
CFLAGS ?= -O2 -g
CFLAGS += -std=c11 -Wall -Wextra -Wpedantic -Iinclude
LDLIBS += $(shell pkg-config --libs libcurl openssl)
CPPFLAGS += $(shell pkg-config --cflags libcurl openssl)

SOURCES := src/main.c src/util.c src/manifest.c src/repo.c src/package.c src/install.c
OBJECTS := $(SOURCES:.c=.o)

.PHONY: all clean install check
all: build/forge

build/forge: $(OBJECTS)
	@mkdir -p build
	$(CC) $(CFLAGS) $(OBJECTS) -o $@ $(LDLIBS)

src/%.o: src/%.c include/forge.h
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

install: build/forge
	install -Dm755 build/forge "$(DESTDIR)$(HOME)/.local/bin/forge"

check: build/forge
	$(CC) $(CPPFLAGS) $(CFLAGS) tests/test_manifest.c src/manifest.c src/util.c -o build/test_manifest $(LDLIBS)
	./build/test_manifest
	./build/forge --version
	./build/forge help >/dev/null
	./tests/test_manifest.sh ./build/forge

clean:
	rm -f $(OBJECTS) build/forge build/test_manifest
