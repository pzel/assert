Assert: An ergonomic testing library for Standard ML
====================================================

```
signature ASSERT = sig
  type testresult = (string * bool);
  type tcase;
  type raisesTestExn;
  val It : string -> (unit -> raisesTestExn) -> tcase;
  val T : (unit -> raisesTestExn) -> tcase;
  val Pending : string -> (unit -> raisesTestExn) -> tcase;
  val succeed : string -> raisesTestExn;
  val fail : string -> raisesTestExn;
  val == : (''a * ''a) -> raisesTestExn;
  val eq : (''a -> string) -> (''a * ''a) -> raisesTestExn;

  val =/= : (''a * ''a) -> raisesTestExn;
  val neq : (''a -> string) -> (''a * ''a) -> raisesTestExn;

  val != : (exn * (unit -> 'z)) -> raisesTestExn;
  val =?= : (''a * ''a) -> ''a;

  val runTest : tcase -> testresult;
  val runTests : tcase list -> unit;
  val runTestsWith : tcase list -> string list -> unit;
end
```

___________________________________________________

TLDR: How to use this library (via smlpkg + MLB)
------------------------------------------------

### 0: Have something you want to test

```sml
(* file: mysystem.sml *)
fun adder (x: int, y: int) : int = x + y;
fun welcomer (name: string) : string = "hello, " ^ name;
fun iffy (l: int list) : int = hd(tl(l));

```


### 1: Add this library to your `sml.pkg` dependencies

```
package github.com/you/your-project

require {
    github.com/pzel/assert 0.9.1
}
```


### 2: Load up the assert mlb file in your test runner mlb

```sml
(* file: runtests.mlb *)
$(SML_LIB)/basis/basis.mlb
./lib/github.com/pzel/assert/assert.mlb (* this library *)
./mysystem.sml (* your system under test *)
./runtests.sml (* your test runner *)
```



### 3: Write some tests.

```sml
(* file: runtests.sml *)
val adderTests = [
  It "Adds two numbers" (fn _=> adder(2,2) == 3)
]

fun main () =
    runTestsWith adderTests (CommandLine.arguments());

val _ = main();

```

The function `runTestsWith <list of test cases> <list of parameters>`
is responsible for conducting and exiting the entire test run. Let's
see how it works.


### 4: Run your tests

```shell
% mlton -output runtests ./runtests.mlb  && ./runtests

FAILED Adds two numbers
	left:  ?
	right: ?


TESTS FAILED: 1/1

% echo $?
1
```

### 5: Run your tests and get some output, too

This library used to only target Poly/ML and rely on Poly/ML's magical
polymorphic runtime printing facilities. Unfortunately (for this library), the
Poly/ML runtime no longer carries type information on values, so the
pretty-printing doesn't work, unless we explicitly guide it as to the types
it's supposed to print.

First, let's try to fix the output using Standard SML facilities:

```sml
local
  val op == = Assert.eq Int.toString
in
val adderTests = [
  It "Adds two numbers" (fn _=> adder(2,2) == 3)
]
end

fun main () =
    runTestsWith adderTests (CommandLine.arguments());

val _ = main();
```

As you can see, we're overriding the `==` operator with the result of a partial
application of Assert.eq. We provide `Assert.eq` with a printer for `int`
results, and get back a `==` assertion operator on ints, which will print them
nicely.

```shell
% mlton -output runtests ./runtests.mlb  && ./runtests

FAILED Adds two numbers
	left:  4
	right: 3


TESTS FAILED: 1/1

```

Now, we can tell that the error is in our test case, not the system under test.
When we fix it, we get:


```shell
% mlton -output runtests ./runtests.mlb  && ./runtests
ALL TESTS PASSED: 1/1
% echo $?
0
```


### 6: For Poly/ML Users: Reclaim `Poly.makestring`

Although Poly/ML can't magically select a pretty-printer for any random type at
runtime, it still knows how to print `*anything*`. We just need to inform it
what the type of that anything is.

First, let's add the Poly/ML basis to our runtests mlb file, and use
[polymlb](github.com/vqns/polymlb) build it.

```sml
(* file: runtests.mlb *)
$(SML_LIB)/basis/basis.mlb
$(SML_LIB)/basis/poly.mlb (* new addition *)
./lib/github.com/pzel/assert/assert.mlb
./mysystem.sml
./runtests.sml
```


And now, wherever we partially apply `Assert.eq` to get a specifically-typed
assertion operator, we simply plug in `PolyML.makestring`. Type inference will do it's job and the generated operator will be specialized to our type. `int`s in our case here:

```sml
local
  val op == = Assert.eq PolyML.makestring
in
val adderTests = [
  It "Adds two numbers" (fn _=> adder(2,2) == 3)
]
end

fun main () =
    runTestsWith adderTests (CommandLine.arguments());

```

```
% polymlb -output runtests ./runtests.mlb  && ./runtests

FAILED Adds two numbers
	left:  4
	right: 3

TESTS FAILED: 1/1
```

Of course, we are free to specialize the operator to more involved types, such
as records.

```
local
  val op == = Assert.eq PolyML.makestring
in
val tests = [
  It "can display records too" (fn _=> {a=1, b=2} == {a=2, b=4})
]
end

fun main () =
    runTestsWith tests (CommandLine.arguments());

```


```shell
% ./runtests

FAILED can display records too
	left:  {a = 1, b = 2}
	right: {a = 2, b = 4}


TESTS FAILED: 1/1
````


___________________________________________________

Command-line Arguments
----------------------

`runTestsWith` takes two parameters: a list of test cases and a raw list
of command-line parameters, such as that returned from the Basis function
`CommandLine.arguments ()`.

The following arguments are recognized:

### `--verbose`

Print out all test comparisons, both in successful tests and in failed tests.

```shell

% ./yourTestRunner --verbose


OK Adds two numbers
	left:  4
	right: 4

FAILED Adds negative numbers
	left:  0
	right: 10

ERROR Adds zeroes
	exception Empty


TESTS FAILED: 2/3
```

### `--filter` SUBSTRING

Only run test cases whose name contains SUBSTRING. Using this flag
automatically enables the `--verbose` option.

```shell
% ./runtests --filter numbers

OK Adds two numbers
	left:  4
	right: 4

FAILED Adds negative numbers
	left:  0
	right: 10


TESTS FAILED: 1/2
```


#### `--exclude` SUBSTRING

Remove test cases whose name contains SUBSTRING are from the set of tests
given to `runTestsWith`. This also automatically enables the `--verbose`
option.

```shell
% ./runtests --exclude numbers

ERROR Adds zeroes
	exception Empty


TESTS FAILED: 1/1
```

#### `--filter` SUBSTRING1 `--exclude` SUBSTRING2

If both the `--filter` and `--exclude` flags are used, the filter logic is
applied first, and subsequently, cases matching SUBSTRING2 are excluded from
the cases matching SUBSTRING1. I.e. exclude(SUBSTRING2, filter(SUBSTRING1, allTests)).

```shell
% ./runtests --exclude negative --filter numbers

OK Adds two numbers
	left:  4
	right: 4

ALL TESTS PASSED: 1/1
```


___________________________________________________

Test constructors
-----------------

Create tests with either the `T` function

```
T (fn () => 2 + 2 == 4)
```

Or the `It` function:

```
It "can put two and two together" (fn () => 2 + 2 == 4)
```

Or, if you want to exclude the test from execution:

```
Pending "this is for later" (fn () => a() == b())
```


You can run an individual test with `runTest`:

```
> val t1 = T (fn () => 2 + 2 == 4);
val t1 = TC ("", fn): tcase
> runTest t1;
val it = ("OK \n\t4 = 4\n", true): testresult
```

The `testresult` type is a tuple where the first element is a printable
description of the test result, and the second element indicates success or
failure.

```
> val t2 = T (fn () => "a" ^ "b" == "abc");
val t2 = TC ("", fn): tcase
> runTest t2;
val it = ("FAILED \n\t\"ab\" <> \"abc\"\n", false): testresult
```

You can imperatively run a `testcase list` to get formatted output printed to
stdout, and have the entire SML program exit with a POSIX success code if there
were no failures, and an error code if some tests did not pass.

```
runTests [t1, t2];

FAILED
	"ab" <> "abc"


TESTS FAILED: 1/2

$ echo $?
1
```

___________________________________________________

Assertions
-----------------

Let's take a look at the type of the `It` function above:

```
> Assert.It;
val it = fn: string -> (unit -> Assert.raisesTestExn) -> Assert.tcase
```

It takes a string that describes the test case, and then a function typed
`(unit -> Assert.raisesTestExn)`. How do we obtain such a function? By
embedding within its body one of the assertions offered by the module. They are
listed below.



### succeed (msg : string)

This assertion 'manually' passes a test. For example, in cases where the data
under test doesn't support equality.

```
> val t1 = T (fn () => if Real.==(Real.*(2.0, 2.0), 4.0)
                       then succeed "reals are equal"
                        else fail "reals not equal");
val t1 = TC ("", fn): tcase
> runTest t1;
val it = ("OK \n\treals are equal = reals are equal\n", true): testresult
```

### fail (msg : string)

The counterpart to `succeed`. Makes a test fail when executed.

```
> val t2 = T (fn () => if Real.==(Real.*(2.0, 2.0), 5.0)
                       then succeed "reals are equal"
                       else fail "reals not equal");
val t2 = TC ("", fn): tcase
> runTest t2;
val it = ("FAILED \n\treals not equal <> ~explicit fail~\n", false):
   testresult
```

### (left : ''a) == (right : ''a)
### eq (''a -> string) -> (left : ''a * right : ''a) -> raisesTestExn

Fails the test case if `left` and `right` are not equal. The first element of
the testresult will contain string representations of the data. The default
representation is `"?"`, but this can be overriden by locally redefining `==`
via partial application of `eq`.


```sml
> val t4 = T (fn () => {a="record"} == {a="cd"});
val t4 = TC ("", fn): tcase
> runTest t4;
val it = ("FAILED \n\tleft:  ?\n\tright: ?\n", false): testresult
> print (#1 it);
FAILED
	left:  ?
	right: ?
val it = (): unit
```

Now, using `eq`:

```sml
> let val op == = Assert.eq PolyML.makestring;
# in runTest (T (fn () => {a = "record"} == {a="cd"}))
# end;
val it =
   ("FAILED \n\tleft:  {a = \"record\"}\n\tright: {a = \"cd\"}\n", false):
   testresult
> print (#1 it);
FAILED
	left:  {a = "record"}
	right: {a = "cd"}
val it = (): unit
```


### (left : ''a) =/= (right : ''a)

The inverse of `==`. Will fail the test case if `left` and `right` _are_ equal.
Similarly as with `==`, apply a stringifying function to `Assert.neq` to obtain
a nicer, pretty-printing version.


### (expected : exn) != (f : (unit -> 'z))

Succeeds when `f`, after evaluation, raises exception `exn`. Both the exception
name and message must match. If the function runs successfully, the test case
is counted as a failure.

```
> runTest (T (fn () => (Boom "Aaa!") != (fn () => raise Boom "zzz")));
val it = ("FAILED \n\tBoom \"Aaa!\" <> Boom \"zzz\"\n", false): testresult
> print (#1 it);
FAILED
	Boom "Aaa!" <> Boom "zzz"
val it = (): unit

> runTest (T (fn () => (Boom "Aaa!") != (fn ()=> 2 + 2)));
val it = ("FAILED \n\tBoom \"Aaa!\" <> ~ran successfully~\n", false):
   testresult
> print (#1 it);
FAILED
	Boom "Aaa!" <> ~ran successfully~
val it = (): unit

> runTest (T (fn () => (Boom "Aaa!") != (fn () => raise Boom "Aaa!")));
val it = ("OK \n\tBoom \"Aaa!\" = Boom \"Aaa!\"\n", true): testresult
> print (#1 it);
OK
	Boom "Aaa!" = Boom "Aaa!"
val it = (): unit

```


### (left : ''a) =?= (right : ''a)

This is a classic "assert" function, in the sense that it will simply return
`left` if it's equal to `right`, but if the two operands are *not* equal, it
will fail the entire test case.

Useful for getting around match exhaustiveness warnings when you want
match-based assertions throughout your test, like in Erlang. This approach is
problematic in Standard ML, because "assertively" matching on expected values
will generate "Matches are not exhaustive" messages, like below:

```
  let val ALLGOOD = someOp();
      val foo = worksOnAllGood(ALLGOOD);
      ...
```

If we'd like to get rid of all exhaustiveness warnings, we can use `=?=` to
encode our expectations on the right side of the match, while keeping the left
side non-specific, like so:

```
  let val ag = (someOp() =?= ALLGOOD);
      val foo = worksOnAllGood(ag);
      ...
```

The above will fail the test if `someOp` does not return ALLGOOD. If it does,
it'll bind `ag` to `ALLGOOD` and proceed to evaluate subsequent expressions as
normal.
