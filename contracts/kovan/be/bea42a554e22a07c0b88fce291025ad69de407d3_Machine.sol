/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.5 <0.9.0;

contract Machine {
  uint256 public calculateResult;
  address public user;
  address public calculator;

  event Signature(address _address, bytes _signature);

  function addValuesWithDelegateCall(
    address _calculator,
    uint256 a,
    uint256 b
  ) public returns (uint256) {
    emit Signature(_calculator, abi.encodeWithSignature("add(uint8,uint8)", uint8(a), uint8(b)));
    (bool success, bytes memory result) = _calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
    return abi.decode(result, (uint256));
  }

  function addValuesWithCall(
    address _calculator,
    uint256 a,
    uint256 b
  ) public returns (uint256) {
    emit Signature(_calculator, abi.encodeWithSignature("add(uint256,uint256)", a, b));
    (bool success, bytes memory result) = _calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
    return abi.decode(result, (uint256));
  }
}