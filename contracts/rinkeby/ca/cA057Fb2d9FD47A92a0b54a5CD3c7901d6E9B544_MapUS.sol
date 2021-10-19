// SPDX-License-Identifier: GNU GENERAL PUBLIC LICENSE
pragma solidity ^0.8.0;

import "./MapAbstract.sol";

contract MapUS is MapAbstract {
  // get the total number of cells
  function totalSupply() public pure override returns (uint) {
    return 640;
  }

  // get cell price
  function getCellPrice() public pure override returns (uint) {
    return 0.06 ether;
  }

  constructor(address _address) MapAbstract(_address) {}

  /** get EMC URI */
  function tokenURI(uint256 _index) external pure override returns (string memory) {
    return string(abi.encodePacked('https://api.ethemap.com/token/us-', _uintToString(_index), '.json'));
  }
}