// SPDX-License-Identifier: GNU GENERAL PUBLIC LICENSE
pragma solidity ^0.8.0;

import "./MapAbstract.sol";

contract MapUS is MapAbstract {
  // 获取单元格个数
  function _getCellsCount() override internal pure returns (uint) {
    return 640;
  }

  // 获取单元格单价
  function _getCellPrice() override internal pure returns (uint) {
    return 0.06 ether;
  }

  constructor(address _address) MapAbstract(_address) {}

  /** 返回 EMC URI */
  function tokenURI(uint256 _index) external pure override returns (string memory) {
    return string(abi.encodePacked('https://api.ethemap.com/token/us-', _uintToString(_index), '.json'));
  }
}