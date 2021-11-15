pragma solidity ^0.4.21;

contract InfoContract {
    
   string fName;
   uint age;
   string sex;
   
   function setInfo(string _fName, uint _age,string _sex) public {
       fName = _fName;
       age = _age;
       sex = _sex;
   }
   
   function getInfo() public constant returns (string, uint,string) {
       return (fName, age,sex);
   }   
}

