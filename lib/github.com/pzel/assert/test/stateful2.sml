val _ = addTests "part two" [
    It "can concatenate strings" (fn()=> "a" ^ "a" == "aa")
   ,It "can fail tests strings" (fn()=>
                                     let val op == = Assert.eq (fn x =>x)
                                     in "a" ^ "b" == "aba" end)
  ]
