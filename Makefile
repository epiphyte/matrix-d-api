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

define sample
dmd $(SRC) $(SAMPLE) samples/$1.d -of$(OUTPUT)/$1
endef

sample: clean
	$(call sample,chat)
	$(call sample,loginout)
	$(call sample,rooms)
	$(call sample,readonly)

test: unittest sample style

unittest:
	dmd $(SRC) "test/harness.d" -unittest -version=MatrixUnitTest -of$(OUTPUT)/${NAME}
	$(OUTPUT)/$(NAME) > $(OUTPUT)/test.log
	diff -u $(OUTPUT)/test.log test/expected.log

style:
ifdef STYLE
	gstyle
endif

clean:
	mkdir -p $(OUTPUT)
	rm -f $(OUTPUT)/*
