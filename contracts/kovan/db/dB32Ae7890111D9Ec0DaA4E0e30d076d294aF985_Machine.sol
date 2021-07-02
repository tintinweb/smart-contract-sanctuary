/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

contract Machine {
    uint256 public calculateResult;
    address public user;
    uint256 public callAmount;
    address public calculatorAddress;

    event addByDlgCall(uint256 a, uint256 b, bool success);
    event addByCall(uint256 a, uint256 b, bool success);

    function addValuesWithDelegateCall(address _calculator, uint256 a, uint b) public returns (uint256) {
        calculatorAddress = _calculator;
        (bool success, bytes memory result) = calculatorAddress.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit addByDlgCall(a, b, success);
        return abi.decode(result, (uint256));
    }

    function addValuesWithCall(address _calculator, uint256 a, uint256 b) public returns (uint256) {
        calculatorAddress = _calculator;
        (bool success, bytes memory result) = calculatorAddress.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit addByCall(a, b, success);
        return abi.decode(result, (uint256));
    }
}