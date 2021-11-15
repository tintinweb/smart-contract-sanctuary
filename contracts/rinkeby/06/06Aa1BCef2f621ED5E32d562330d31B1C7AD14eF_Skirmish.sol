// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

contract Skirmish {
  mapping(address => uint256) public balance;

  function trainUnits() external payable {
    balance[msg.sender] += msg.value;
  }

  function attack(address _target, uint256 _units) external {
    uint256 targetBalance = balance[_target];
    uint256 available = balance[msg.sender];
    require(_units <= available, "Not enough troops");

    if (_units >= targetBalance) {
      balance[_target] = 0;
      balance[msg.sender] -= targetBalance;
    } else {
      balance[_target] -= _units;
      balance[msg.sender] -= _units;
    }
  }
}

