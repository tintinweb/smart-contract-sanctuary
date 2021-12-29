/**
 *Submitted for verification at Etherscan.io on 2021-12-28
*/

pragma solidity ^0.4.18;

contract StudentDetail {
    
   string fName;
   uint age;
   
   function setStudentDetail(string _fName, uint _age) public {

        fName = _fName;
        age = _age;
   }
   
   function getStudentDetail() public view returns (string, uint) {
        return (fName, age);
   }
    
}