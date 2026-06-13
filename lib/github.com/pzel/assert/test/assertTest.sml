exception TestExn of string;

fun mkFin (db: testresult list ref) : (testresult list -> unit) =
    fn (testresults) => ignore (db := testresults) ;

fun identity a = a;

val passingTests = [
  It "asserts on int equality" (fn() => 3 + 3 == 6),
  It "asserts on int inequality" (fn() => 3 + 3 =/= 7),
  It "asserts on record equality" (fn() => {a=1} == {a=1}),
  It "succeeds explicitly" (fn() => succeed "all good"),
  It "can assert multiple times in the test body" (
    fn () =>
       let val x = (2 =?= 2 + 0);
           val y = (3 =?= x + 1);
       in
         x + y == 5
       end),
  It "can assert that a specific exception was raised" (
    fn () =>
       TestExn("hello") != (fn()=> raise TestExn("hello"))),
  Pending "can mark test as pended" (
    fn()=> String.sub("", 234) == #"X") (* will not be eval'd *)
];

val explicitShowPassingTests = [
  It "can assert with a specific printer (int)" (
    fn () => Assert.eq Int.toString (3+3, 6)),
  It "can assert with a specific printer (string)" (
    fn () => Assert.eq identity ("ab" ^ "c", "abc")),
  It "can assert with a specific printer (record)" (
    fn () => let fun show(re as {a: int, b: string}) = Int.toString a ^b
             in Assert.eq show ({a= 1, b="b"}, {a=1, b="b"})
             end)
]

val failingTests = [
  It "fails int equality when not equal" (fn () => 3 + 2 == 4),
  It "fails int inequality when equal" (fn () => 2 + 2 =/= 4),
  It "fails record inequality when values differ" (fn ()=> {a = "a", b=2} == {a = "A", b=2}),
  It "can fail explicitly" (fn() => fail "not good"),
  It "a failing assertion anywhere in the fun body fails the test" (
    fn() =>
       let val x = (2 =?= 2 + 0);
           val y = (30 =?= x + 1);
       in
         x + y == hd [] (* will not be evaluated,
                           the test fails at (30 =?= ...) *)
       end),
  It "an exeption raised during eval results in a failed test" (
    fn() =>
       let val x = hd ([] : int list) in x + 2 == 3 end),
  T(fn ()=> Subscript != (fn()=> tl(tl[1]))),
  T(fn ()=> Empty != (fn()=> hd [1])),
  (*
    It ("This test fails on MLTON due to " ^
      "different handling of exn equality")
     (fn ()=> TestExn("wrong message") != (fn()=> raise TestExn("hello"))),
   *)
  It "shows exception type" (fn ()=> TestExn("Not this exception type") != (fn()=> hd [])),
  T(fn ()=> fail("this should never happen"))
];

val explicitShowFailingTests = [
  It "can assert with a specific printer (int)" (
    fn () => Assert.eq Int.toString (3+3, 7)),
  It "can assert with a specific printer (string)" (
    fn () => Assert.eq identity ("ab" ^ "c", "abcd")),
  It "can assert with a specific printer (record)" (
    fn () => let fun show(re as {a: int, b: string}) = Int.toString a ^ b;
             in Assert.eq show ({a= 1, b="b"}, {a=10, b="hello"})
             end)
];



fun assertPassedTests results =
    List.all(
      fn (tr) =>
         if #2 tr
         then (print ("Expected success:\n"
                      ^ (#1 tr)
                      ^ "\n"); true)
         else (print ("Unexpected success:\n"
                      ^ (#1 tr)
                      ^ "\n"); false))
            results

fun assertFailedTests results =
    List.all(
      fn (tr) =>
         if not (#2 tr)
         then (print ("Expected failure:\n"
                      ^ (#1 tr)
                      ^ "\n"); true)
         else (print ("Unexpected failure:\n"
                      ^ (#1 tr)
                      ^ "\n"); false))
            results

fun main () =
    let
      val runAll = map Assert.runTest
      val goodTests = passingTests @ explicitShowPassingTests
      val badTests = failingTests @ explicitShowFailingTests
      val passed = assertPassedTests (runAll goodTests)
      val failed = assertFailedTests (runAll badTests)
    in
      if passed andalso failed
      then (print "OK\n"; OS.Process.exit(OS.Process.success))
      else (print "NG\n"; OS.Process.exit(OS.Process.failure))
    end
