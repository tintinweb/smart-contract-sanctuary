// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MyContract {
  function num(uint256 _num) external pure returns(uint256) {
    return _num;
  }

  function str(string memory _name) external pure returns(string memory) {
    return string(abi.encodePacked("Hello, ", _name, "!"));
  }
}

