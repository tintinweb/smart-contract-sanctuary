/**
 *Submitted for verification at Etherscan.io on 2021-05-06
*/

pragma solidity ^0.8.0;


contract SolidityTest {
   constructor() public{
   }
   function getResult() public view returns(uint){
      uint a = 1;
      uint b = 2;
      uint result = a + b;
      return result;
   }
   
   function printTest() public view returns (uint){
        address x = 0x21b85A11B0A67B0ac1A9dae1d55f408394BaacF8;
        // address myAddress = this;
        // if (x.balance < 10 && myAddress.balance >= 10) x.transfer(10);
        return x.balance;

   }
}