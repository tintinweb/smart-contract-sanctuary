pragma solidity ^0.4.21;

contract test3 {
   struct data {
       uint a;
       uint b;
   }
   
   data[] public arr;
   
   data public globd1;
   data public globd2;
   
   function A() public {
       data storage d;
       globd1 = d;
       arr.push(d);
       globd2 = arr[arr.length -1];
   }
   
   function B() public view returns (uint) {
       return arr.length;
   }
}