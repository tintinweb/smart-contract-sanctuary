/**
 *Submitted for verification at Etherscan.io on 2021-09-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

 contract Calc{
     int public result;
     function add(int a,int b)public returns(int){
         result=a+b;
         return result;
     }
     
     function min(int a,int b)public returns(int){
         result=a-b;
         return result;
     }
     
     function getResult()public view returns(int){
         return result;
     }
     event sign(
  string name,
  uint money
);
     function signEvent() public {
  emit sign("HAO", 10000);
}
     
 }