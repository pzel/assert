exception TestExn of string;

fun identity a = a;

structure Opaque = struct
datatype t = T of real
val x : t = T 0.0
val y : t = T 1.0
fun op == (T a, T b) = Real.==(a,b)
fun toString (T a) = "T "^Real.toString a
end : sig type t
          val x : t
          val y : t
          val == : (t * t) -> bool
          val toString : t -> string
      end;

val passingTests = [
  It "asserts on int equality" (fn()=> 3 + 3 == 6),
  It "asserts on int inequality" (fn()=> 3 + 3 =/= 7),
  It "asserts on record equality" (fn()=> {a=1} == {a=1}),
  It "succeeds explicitly" (fn()=> succeed "all good"),
  It "can assert multiple times in the test body" (
    fn()=>
       let val x = (2 =?= 2 + 0);
           val y = (3 =?= x + 1);
       in
         x + y == 5
       end),
  It "can assert that a specific exception was raised" (
    fn()=>
       TestExn("hello") != (fn()=> raise TestExn("hello"))),
  Pending "can mark test as pended" (
    fn()=> String.sub("", 234) == #"X") (* will not be eval'd *)
];

val explicitShowPassingTests = [
  It "can assert with a specific printer (int)" (
    fn()=> Assert.eq Int.toString (3+3, 6)),
  It "can assert with a specific printer (string)" (
    fn()=> Assert.eq identity ("ab" ^ "c", "abc")),
  It "can assert with a specific printer (record)" (
    fn()=> let fun show(re as {a: int, b: string}) = Int.toString a ^b
             in Assert.eq show ({a= 1, b="b"}, {a=1, b="b"})
             end),
  It "can === with a specific printer (int)" (
    fn()=> (3+3 === 6) Int.toString),

  It "can =//= with a specific printer (int)" (
    fn()=> (3+3 =//= 33) Int.toString),

  It "can assert with a specific equality check and printer (int ref)" (
    fn()=> Assert.equal Opaque.== Opaque.toString (Opaque.x, Opaque.x)),

  It "can assert with a specific unequality check and printer (int ref)" (
    fn()=> Assert.unequal Opaque.== Opaque.toString (Opaque.x, Opaque.y))
]

val failingTests = [
  It "fails int equality when not equal" (fn()=> 3 + 2 == 4),
  It "fails int inequality when equal" (fn()=> 2 + 2 =/= 4),
  It "fails record inequality when values differ" (fn()=> {a = "a", b=2} == {a = "A", b=2}),
  It "can fail explicitly" (fn()=> fail "not good"),
  It "can fail assertion with a specific equality check and printer (int ref)" (
    fn()=> Assert.equal Opaque.== Opaque.toString (Opaque.x, Opaque.y)),
  It "can fail assertion with a specific unequality check and printer (int ref)" (
    fn()=> Assert.unequal Opaque.== Opaque.toString (Opaque.x, Opaque.x)),
  It "a failing assertion anywhere in the fun body fails the test" (
    fn()=>
       let val x = 2 =?= 2 + 0
           val y = (30 =??= x + 1) (fn _ => "y is not equal")
       in
         x + y == hd [] (* will not be evaluated,
                           the test fails at (30 =?= ...) *)
       end),
  It "a failing assertion prints anywhere in the fun body fails the test" (
    fn()=>
       let val x = 2 =?= 2 + 0
           val y = (30 =??= x + 1) Int.toString
       in
         x + y == hd [] (* will not be evaluated,
                           the test fails at (30 =?= ...) *)
       end),

  It "an exeption raised during eval results in a failed test" (
    fn()=>
       let val x = hd ([] : int list) in x + 2 == 3 end),
  T(fn()=> Subscript != (fn()=> tl(tl[1]))),
  T(fn()=> Empty != (fn()=> hd [1])),
  (*
    It ("This test fails on MLTON due to " ^
      "different handling of exn equality")
     (fn()=> TestExn("wrong message") != (fn()=> raise TestExn("hello"))),
   *)
  It "shows exception type" (fn()=> TestExn("Not this exception type") != (fn()=> hd [])),
  T(fn()=> fail("this should never happen"))
];

val explicitShowFailingTests = [
  It "can assert with a specific printer (int)" (
    fn()=> Assert.eq Int.toString (3+3, 7)),
  It "can assert with a specific printer (string)" (
    fn()=> Assert.eq identity ("ab" ^ "c", "abcd")),
  It "can assert with a specific printer (record)" (
    fn()=> let fun show(re as {a: int, b: string}) = Int.toString a ^ b;
             in Assert.eq show ({a= 1, b="b"}, {a=10, b="hello"})
             end),
  It "can === with a specific printer (int)" (
    fn()=> (3+3 === 8) Int.toString),
  It "can =//= with a specific printer (int)" (
    fn()=> (3+3 =//= 6) Int.toString)
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
