/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

pragma solidity ^0.5.16;

contract Coursetro {
    
   string fName;
   
   function setInstructor(string memory  _fName) public {
       fName = _fName;
   }
   
   function getInstructor() public view returns (string memory) {
       return fName;
   }
    
}