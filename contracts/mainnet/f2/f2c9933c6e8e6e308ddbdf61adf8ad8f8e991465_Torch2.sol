// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.7.6;
pragma abicoder v2;

contract Torch2 {
  address public immutable TARGET = 0x881D40237659C251811CEC9c364ef91dC08D300C;

  function swap(
    string calldata aggregatorId,
    address tokenFrom,
    uint256 amount,
    bytes calldata data
  ) external payable {}
}