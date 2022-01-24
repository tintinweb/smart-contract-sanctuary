/**
 *Submitted for verification at Etherscan.io on 2022-01-24
*/

pragma solidity ^0.5.16;
contract EventExampleWithStudentDetail {
      string fName;
      uint age;

      event Student (
         string fName,
         uint age
      );
   
   function setStudentDetail(string memory _fName, uint _age) payable public {

        fName = _fName;
        age = _age;
        emit Student(_fName, _age);
   }
   
   function getStudentDetail() public view returns (string memory, uint) {
        return (fName, age);
   }
}