pragma solidity ^0.4.23;
contract yytbornregister{
   string private name;
   uint private borndate;
   string public bornplace;
   function setInstructor(string _name, uint _borndate, string _bornplace) public {
       name = _name;
       borndate = _borndate;
       bornplace = _bornplace;
   }
   function getInstructor() public constant returns (string, uint, string) {
       return ( name, borndate, bornplace);
   }
}