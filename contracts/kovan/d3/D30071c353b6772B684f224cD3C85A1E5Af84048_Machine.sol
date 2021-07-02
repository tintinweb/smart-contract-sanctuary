/**
 *Submitted for verification at Etherscan.io on 2021-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

contract Machine{
    uint256 public calculateResult;
    address public user;
    uint256 public callAmount;
    address public calculatorAddress;

    event AddedValuesByDelegateCall(uint256 a, uint256 b, bool success);
    event AddedValuesByCall(uint256 a, uint256 b, bool success);

    function addValuesWithDlgCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        calculatorAddress = calculator;
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByDelegateCall(a, b, success);
        return abi.decode(result, (uint256));
    }

    function addValuesWithCall(address calculator, uint256 a, uint256 b) public returns (uint256) {
        calculatorAddress = calculator;
        (bool success, bytes memory result) = calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByCall(a, b, success);
        return abi.decode(result, (uint256));
    }
}