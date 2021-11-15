// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Machine {
    uint256 public calculateResult;
    address public user;
    uint256 public addCount;
    address public calculator;

    event AddedValuesByDelegateCall(uint256 a, uint256 b, bool success);
    event AddedValuesByCall(uint256 a, uint256 b, bool success);

    function addValuesWithDelegateCall(address _calculator, uint256 a, uint b) public returns (uint256) {
        calculator = _calculator;
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByDelegateCall(a, b, success);
        return abi.decode(result, (uint256));
    }

    function addValuesWithCall(address _calculator, uint256 a, uint256 b) public returns (uint256) {
        calculator = _calculator;
        (bool success, bytes memory result) = calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByCall(a, b, success);
        return abi.decode(result, (uint256));
    }
}

