pragma solidity ^0.4.25;

contract AddressToStudent {
  string public constant name = "HSE students";
  string public constant symbol = "hse";
  mapping(address => string) public students;
 
  function nameAddress(string _name) public {
    students[msg.sender] = _name;
  }
  
}