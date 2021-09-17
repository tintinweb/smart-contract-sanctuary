/**
 *Submitted for verification at Etherscan.io on 2021-09-17
*/

pragma solidity 0.4.24;

contract SetsAndEvents {

  bool state = false;
  uint number = 42;

  event SomethingHappened(address indexed _from, uint _value);

  function getNumber () public constant returns (uint time) {
      return number;
  }

  function addOne() public {
    number++;
  }

  function doSomething(uint value) public {
    emit SomethingHappened(msg.sender, value);
  }

  function noop () public {
    state = ! state;
  }

}