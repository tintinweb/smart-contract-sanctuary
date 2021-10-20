/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

//SPDX-License-Identifier: MIT;
pragma solidity ^0.8.0;

contract VerifyMe {
  mapping (uint256 => bool) isNumberTrue;

  bool public isDeployed;
  uint256 public basicNumber;
  address public owner;
  string public phrase;

  constructor(bool _isDeployed, uint256 _basicNumber, string memory _phrase) {
    isDeployed = _isDeployed;
    basicNumber = _basicNumber;
    owner = msg.sender;
    phrase = _phrase;
  }

  function setTrue(uint256 _num) public {
    isNumberTrue[_num] = true;
  }

  function multiply(uint256 _a, uint256 _b) public pure returns (uint256 _c){
    _c = _a * _b;
  }
}