CC=clang++
CXXFLAGS=-std=c++17 -Wall -Wextra
LDFLAGS=-framework ApplicationServices -framework CoreFoundation

all: macro

macro: macro.mm
	$(CC) $(CXXFLAGS) -o macro macro.mm $(LDFLAGS)

clean:
	rm -f macro
