/**
 *Submitted for verification at Etherscan.io on 2021-02-08
*/

pragma solidity 0.5.0;

contract SimpleContract {
    
   uint age;
   
   function setVal(uint _age) public {
       age = _age;
   }
   
   function getVal() public view returns (uint) {
       return age;
   }
    
}