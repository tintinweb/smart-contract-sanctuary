/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

pragma solidity >0.4.23 <0.6.0;

contract Store {
  event ItemSet(bytes32 key, bytes32 value);

  string public version;
  int public number;
  mapping (bytes32 => bytes32) public items;

  constructor(string memory _version, int _number) public {
    version = _version;
    number = _number;
  }

  function setItem(bytes32 key, bytes32 value) external {
    items[key] = value;
    emit ItemSet(key, value);
  }
}