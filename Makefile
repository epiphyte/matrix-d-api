SRC     := $(shell find src/ -name "*.d")
SAMPLE  := samples/
OUTPUT  := bin
NAME    := matrix-d
FLAGS   := -inline -release -O -boundscheck=off
DMD     := dmd
SAMPLES := public chat loginout rooms readonly gentoken
OUTDIR  := -of$(OUTPUT)/
TESTS   := "test/harness.d" -unittest -version=MatrixUnitTest

all: clean
	$(DMD) $(FLAGS) -c $(SRC) $(OUTDIR)$(NAME).so
	rm -f $(OUTPUT)/*.o

$(SAMPLES):
	$(DMD) $(SRC) $(SAMPLE)common.d $(SAMPLE)$@.d $(OUTDIR)$@

test: unittest $(SAMPLES)

unittest:
	$(DMD) $(SRC) $(TESTS) $(OUTDIR)$(NAME)
	$(OUTPUT)/$(NAME) > $(OUTPUT)/test.log
	diff -u $(OUTPUT)/test.log test/expected.log

clean:
	mkdir -p $(OUTPUT)
	rm -f $(OUTPUT)/*
