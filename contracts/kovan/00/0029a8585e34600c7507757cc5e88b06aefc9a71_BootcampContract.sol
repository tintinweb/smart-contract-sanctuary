/**
 *Submitted for verification at Etherscan.io on 2021-09-29
*/

//  SPDX-License-Identifier: UNLICENSED

pragma solidity =0.7.3;
 
contract BootcampContract {
  uint256 number;

  function setNumber(uint256 _num) public {
    number = _num;
  }

  function getNumber() public view returns (uint256) {
    return number;
  }

  function calcOffset(uint256 _offset) public view returns (uint256) {
    return number + _offset;
  }
}