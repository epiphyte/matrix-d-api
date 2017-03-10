SRC=$(shell find src/ -name "*.d")
OUTPUT=bin
NAME=matrix-d
CONFIG=

.PHONY: all

FLAGS := -inline\
	-release\
	-O\
	-boundscheck=off\
	-of${OUTPUT}/${NAME}

all:
	mkdir -p $(OUTPUT)
	rm -f $(OUTPUT)/*
	dmd $(SRC) $(FLAGS) $(CONFIG)
	rm -f $(OUTPUT)/*.o

unittest:
	make CONFIG=-unittest
