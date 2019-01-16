pragma solidity ^0.4.25;
contract sample {
 uint128 public number = 123;
 
 function get() constant public returns (uint) {
   return number;
 }
}