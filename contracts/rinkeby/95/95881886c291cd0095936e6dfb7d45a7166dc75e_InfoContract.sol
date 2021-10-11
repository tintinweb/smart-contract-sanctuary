/**
 *Submitted for verification at Etherscan.io on 2021-10-11
*/

pragma solidity ^0.4.21;

contract InfoContract {
    string fName;
    uint age;
   
    function getInfo() public view returns (string, uint) {
       return (fName, age);
    }
   
    event coordinate(string indexed name,uint indexed age);
    function setInfo(string _fName, uint _age) public {
       fName = _fName;
       age = _age;
       emit coordinate(_fName, _age);
   }
}