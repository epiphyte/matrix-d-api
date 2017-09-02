SRC=$(shell find src/ -name "*.d")
SAMPLE=samples/common.d
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

define sample
dmd $(SRC) $(SAMPLE) samples/$1.d -of$(OUTPUT)/$1
endef

sample: clean
	$(call sample,public)
	$(call sample,chat)
	$(call sample,loginout)
	$(call sample,rooms)
	$(call sample,readonly)
	$(call sample,gentoken)

test: unittest sample

unittest:
	dmd $(SRC) "test/harness.d" -unittest -version=MatrixUnitTest -of$(OUTPUT)/${NAME}
	$(OUTPUT)/$(NAME) > $(OUTPUT)/test.log
	diff -u $(OUTPUT)/test.log test/expected.log

clean:
	mkdir -p $(OUTPUT)
	rm -f $(OUTPUT)/*
