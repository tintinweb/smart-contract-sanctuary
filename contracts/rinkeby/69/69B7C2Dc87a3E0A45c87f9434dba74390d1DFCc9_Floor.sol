/**
 *Submitted for verification at Etherscan.io on 2021-05-08
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;



// File: Floor.sol

contract Floor {
  bool _isLastFloor;

  // GOTO_SELECTOR = bytes4(keccak256(byte("withdraw(uint))))
  bytes4 constant GOTO_SELECTOR = 0xed9a7134;

  constructor() {
    _isLastFloor = false;
  }

  function setIsLastFloor(bool flag) public {
    _isLastFloor = flag;
  }

  function isLastFloor() public view returns (bool) {
    return _isLastFloor;
  }

  function isLastFloor(uint256) public returns (bool) {
    _isLastFloor = !_isLastFloor;
    return (_isLastFloor != true);
  }

  function goToTopFloor(uint256 _floor, address elevatorAddress) public {
    (bool result, ) =
      elevatorAddress.call(abi.encodeWithSelector(GOTO_SELECTOR, _floor));
    require(result, "call goTo from elevatorAddress not success");
  }
}