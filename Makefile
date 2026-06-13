.PHONY: test test-polymlb test-mlton test-cmdline-interface
LIBDIR := lib/github.com/pzel/assert

test: test-polymlb test-mlton test-cmdline-interface

test-mlton: $(shell find $(LIBDIR) | grep .sml$$)
	mlton -output ./bin/runTests.mlton $(LIBDIR)/test/runTests-mlton.mlb \
	&& ./bin/runTests.mlton --exclude MLTON

test-polymlb: $(shell find $(LIBDIR) | grep .sml$$)
	polymlb -output ./bin/runTests.poly $(LIBDIR)/test/runTests.mlb \
	&& ./bin/runTests.poly

test-cmdline-interface: bin/exampleTestSuite
	./bin/testCmdLine.sh

bin/exampleTestSuite: $(shell find  $(LIBDIR) | grep sml$$)
	mlton -output $@ $(LIBDIR)/test/exampleTestSuite.mlb
