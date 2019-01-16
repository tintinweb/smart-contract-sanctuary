pragma solidity >=0.4.22 <0.6.0;

contract TestTime{
   uint public last;
   uint public counter1;
   uint public counter2;
   
   constructor() public {
        counter1 = 0;
        counter2 = 0;
        last = now;
    }
   
   function op1() public{
      counter1 = counter1 + 1;
      if (now >= last + 5 minutes) {
        op2();
      }
   } 
   function op2() private {
      //
      counter2 = counter2 + 1;
      last = now;
   } 
}