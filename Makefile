all: copy-path.so

copy-path.so: copy-path.c
	./build.sh

install: copy-path.so
	./install.sh

uninstall:
	./uninstall.sh

clean:
	rm -rf copy-path.so .build

.PHONY: all install uninstall clean
