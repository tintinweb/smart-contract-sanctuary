// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.7.3;

import "./Calculator.sol";

contract Machine {    
    uint256 public calculateResult;
    address public user;
    uint256 public machineAddCount;
    address public calculator = address(new Calculator());
    

    event AddedValuesByDelegateCall(uint256 a, uint256 b, bool success);
    event AddedValuesByCall(uint256 a, uint256 b, bool success);
    
    constructor() {
        calculateResult = 0;
        machineAddCount = 0;
    }
    
    function addValuesWithDelegateCall(uint256 a, uint256 b) public returns (uint256) {
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByDelegateCall(a, b, success);
        return abi.decode(result, (uint256));
    }
    
    function addValuesWithCall(uint256 a, uint256 b) public returns (uint256) {
        (bool success, bytes memory result) = calculator.call(abi.encodeWithSignature("add(uint256,uint256)", a, b));
        emit AddedValuesByCall(a, b, success);
        return abi.decode(result, (uint256));
    }
}