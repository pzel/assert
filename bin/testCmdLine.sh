#!/bin/sh

assert () {
  # xargs collapses all internal whitespace to 1 space
  # & trims leading/trailing whitespace
  a=$(echo "$1" | xargs)
  b=$(echo "$2" | xargs)
  if test "$a" = "$b"
  then
    printf "OK: <$a>\n"
  else
    printf "NG: <$a> is not equal to <$b>\n";
    exit 1
  fi
}



verbose_run=$(./bin/exampleTestSuite --verbose | awk '/OK/ {print} ; END { print NR }')
assert "$verbose_run" "OK asserts on int equality OK asserts on int inequality OK asserts on record equality OK should never run 36"


# filtering automatically sets verbose flag too
filter_run=$(./bin/exampleTestSuite --filter 'record equality' | awk '/OK|FAILED/ {print} ; END { print NR }')
assert "$filter_run" "OK asserts on record equality FAILED fails record equality when values differ TESTS FAILED: 1/2 12"


# exclusion removes tests from run but DOESNT set verbose flag
# Pending tests count as passes, this should probably change
excluded_run=$(./bin/exampleTestSuite --exclude 'fail' | awk '/PASSED/ {print} ; END { print NR }')
assert "$excluded_run" "ALL TESTS PASSED: 4/4 2"


# exclusion is applied after filtering
exclude_filtered_run=$(./bin/exampleTestSuite --filter 'record equality' --exclude 'differ' | awk '/PASSED/ {print} ; END { print NR }')
assert "$exclude_filtered_run" "ALL TESTS PASSED: 1/1 6"


default_run=$(./bin/exampleTestSuite | awk '/TESTS FAILED/ {print} ; END { print NR }')
assert "$default_run" "TESTS FAILED: 4/8 20"


printf "\n\nCOMMAND LINE TESTS PASSED SUCCESSFULLY\n\n"
exit 0

