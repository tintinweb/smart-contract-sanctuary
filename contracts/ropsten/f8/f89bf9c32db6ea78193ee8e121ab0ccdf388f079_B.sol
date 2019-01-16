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
  address public newOwner;
  
  function doYourThing(address addressOfA) {
    A my_a = A(addressOfA);
    return my_a.transferOwnership(newOwner);
  }
}