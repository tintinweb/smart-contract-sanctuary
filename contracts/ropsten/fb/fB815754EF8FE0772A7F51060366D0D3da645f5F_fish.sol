/**
 *Submitted for verification at Etherscan.io on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract fish {

  mapping (address => uint) public fishColors;

  string public name;
  string public symbol;
  
  constructor() {
    name = "Fish Testing";
    symbol = "FSH";
  }

  function mintNFT(address _owner, uint _color) public {
    fishColors[_owner] = _color;
  }

  function getFishColor(address _check) public view returns (uint _color) {
    return fishColors[_check];
  }

}