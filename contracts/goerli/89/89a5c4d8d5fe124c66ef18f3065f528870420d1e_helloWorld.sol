/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

pragma solidity ^0.4.22;

contract helloWorld {
 string a = '';
 function renderHelloWorld () public view returns (string) {
   return a;
 }
 function set(string some) public {
     a=some;
 }
}