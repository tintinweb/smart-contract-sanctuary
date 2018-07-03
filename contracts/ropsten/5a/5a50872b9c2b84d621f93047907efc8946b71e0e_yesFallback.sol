pragma solidity ^0.4.13;

contract yesFallback {
      bool public testBool = false;

  function testMe() public {
      testBool = !testBool;
  }
  
  event TokenFallback(address _from, uint _value, bytes _data);
  function tokenFallback(address _from, uint _value, bytes _data) public  {
   emit TokenFallback(_from, _value, _data);
}

}