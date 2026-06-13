val passingTests = [
  It "asserts on int equality" (fn() => 3 + 3 == 6),
  It "asserts on int inequality" (fn() => 3 + 3 =/= 7),
  It "asserts on record equality" (fn() => {a=1} == {a=1}),
  Pending "should never run" (
    fn()=> String.sub("", 234) == #"X") (* will not be eval'd *)
];

val failingTests = [
  It "fails int equality when not equal" (fn () => 3 + 2 == 4),
  It "fails int inequality when equal" (fn () => 2 + 2 =/= 4),
  It "fails record equality when values differ"
     (fn ()=> {a = "a", b=2} == {a = "A", b=3}),
  It "explicit failure test" (fn ()=> fail("this should never happen"))
];

fun main () =
    runTestsWith (passingTests @ failingTests) (CommandLine.arguments())

(* the default is to test with mlton *)
val _ = main ();
