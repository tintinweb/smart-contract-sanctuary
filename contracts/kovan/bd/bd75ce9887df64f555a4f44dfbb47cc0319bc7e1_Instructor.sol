/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

pragma solidity >=0.7.0 <0.9.0;

contract Instructor {
    
   bytes16 fName;
   uint age;
   
   event InstructorUpdated(bytes16 name, uint age);
   
   function setInstructor(bytes16 _fName, uint _age) public {
       fName = _fName;
       age = _age;
       
       emit InstructorUpdated(fName, age);
   }
   
   function getInstructor() public view returns (bytes16, uint) {
       return (fName, age);
   }   
}