pragma solidity ^0.4.23;

contract yyttrace{
    
   string public gs1;
   uint public sellor;
   string public place ;
   
   function setInstructor(string _gs1, uint _sellor, string _place) public {
       gs1 = _gs1;
       sellor = _sellor;
       place = _place;
   }
   
   function getInstructor() public constant returns (string, uint, string) {
       return ( gs1, sellor, place);
   }
    
}