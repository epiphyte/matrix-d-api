SRC=$(shell find src/ -name "*.d")
OUTPUT=bin
NAME=matrix-d

.PHONY: all

FLAGS := -inline\
	-release\
	-O\
	-boundscheck=off\

all: clean
	dmd $(FLAGS) -c $(SRC) -of${OUTPUT}/${NAME}.so
	rm -f $(OUTPUT)/*.o

test: clean
	dmd $(SRC) "test/harness.d" -unittest -version=MatrixUnitTest -of$(OUTPUT)/${NAME}
	$(OUTPUT)/$(NAME)

clean:
	mkdir -p $(OUTPUT)
	rm -f $(OUTPUT)/*
