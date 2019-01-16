pragma solidity ^0.4.13;
contract AbstractA {
  address public owner;

  function Ownable() {
  }
  function transferOwnership(address newOwner) {
  }
}
 
contract A is AbstractA {

  function Ownable() {
    owner = msg.sender;
  }
  
  function transferOwnership(address newOwner)  {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}


contract B {
  address public newOwner=0xb6161Fd07022082Fa551A8E65865076701865F30;
  
  function doYourThing(address addressOfA) {
    A my_a = A(addressOfA);
    return my_a.Ownable();
  }
}