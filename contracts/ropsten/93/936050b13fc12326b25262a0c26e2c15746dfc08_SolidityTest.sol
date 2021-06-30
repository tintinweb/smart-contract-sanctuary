/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.5.0;
contract SolidityTest {
   uint public storedData; // State variable
   uint public a = 0;
   uint public b = 0;
   constructor() public {
      storedData = 10;   
   }
   function getResult(uint adder1, uint adder2) public view returns(uint){
      uint result = a + b;
      return result; //access the state variable
   }
}