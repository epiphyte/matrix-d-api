SRC=$(shell find src/ -name "*.d")
SAMPLE=samples/common.d
OUTPUT=bin
NAME=matrix-d
STYLE := $(shell command -v gstyle 2> /dev/null)

.PHONY: all

FLAGS := -inline\
	-release\
	-O\
	-boundscheck=off\

all: clean
	dmd $(FLAGS) -c $(SRC) -of${OUTPUT}/${NAME}.so
	rm -f $(OUTPUT)/*.o

sample: clean
	dmd $(SRC) $(SAMPLE) "samples/loginout.d" -of$(OUTPUT)/loginout
	dmd $(SRC) $(SAMPLE) "samples/rooms.d" -of$(OUTPUT)/loginout

test: sample
	dmd $(SRC) "test/harness.d" -unittest -version=MatrixUnitTest -of$(OUTPUT)/${NAME}
	$(OUTPUT)/$(NAME)
ifdef STYLE
	gstyle
endif

clean:
	mkdir -p $(OUTPUT)
	rm -f $(OUTPUT)/*
