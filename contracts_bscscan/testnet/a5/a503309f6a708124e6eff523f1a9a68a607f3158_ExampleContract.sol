/**
 *Submitted for verification at BscScan.com on 2021-07-22
*/

pragma solidity ^0.6.0;

contract ExampleContract {
  event ReturnValue(address indexed _from, int256 _value);
  function foo(int256 _value) public returns (int256) {
    emit ReturnValue(msg.sender, _value);
    return _value;
  }
}