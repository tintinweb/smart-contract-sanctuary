pragma solidity ^0.4.21;

contract Test3 {
   struct Data {
       uint a;
       uint b;
   }
   
   Data[] public arr;
   
   Data public globd1;
   Data public globd2;
   
   function first() public {
       Data storage d;
       globd1 = d;
   }
   
   function second() public {
       Data storage d;
       d = globd1;
       arr.push(d);
   }
   
   function third() public {
       globd2 = arr[arr.length -1];
   }
   
   
   function len() public view returns (uint) {
       return arr.length;
   }
}