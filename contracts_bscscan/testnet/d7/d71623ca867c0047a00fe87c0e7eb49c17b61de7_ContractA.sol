/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractA {
    
    uint256 public storedValue;
    
    enum Operator {Addition, Subtraction}
    
    constructor(uint256 _initialValue) {
        storedValue = _initialValue;
    }
    
    function calculateValue(address _contract, uint256 _value, Operator _operator) external returns (uint256) {
        (bool success, bytes memory data) = _contract.delegatecall(abi.encodeWithSignature("calculateValue(uint256, uint8)", _value, uint8(_operator)));
        
        require(success);
        return abi.decode(data, (uint256));
    }
}