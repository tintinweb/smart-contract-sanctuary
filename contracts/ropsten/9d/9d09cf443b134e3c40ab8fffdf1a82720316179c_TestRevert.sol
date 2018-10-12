pragma solidity ^0.4.25;


contract TestRevert {
    
  uint foo;
    
  function withdraw(bool b) public {
      if(b == true) {
          revert();
      } else {
          foo = 314;
      }

  }
}