pragma solidity ^0.4.18;

contract DAppTest {

  bool public _is;

  function changeBoolean() public returns (bool success) {
    _is = !_is;
    return true;
  }

}