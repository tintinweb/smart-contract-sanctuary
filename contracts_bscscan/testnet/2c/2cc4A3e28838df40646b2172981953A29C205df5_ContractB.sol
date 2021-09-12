/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractA {
    
    uint256 private storedValue;
    address public delegateContract;
    
    enum OPE {Addition, Subtraction}
    
    constructor(uint256 _initialValue, address _contract) {
        storedValue = _initialValue;
        delegateContract = _contract;
    }
    
    function calculateValue(uint256 _value, OPE _operator) external returns (uint256) {
        uint8 _ope = uint8(_operator);
        (bool success, bytes memory data) = delegateContract.delegatecall(abi.encodeWithSignature("calculateValue(uint256, uint8)", _value, _ope));
        
        require(success);
        return abi.decode(data, (uint256));
    }
    
    function getStoredValue() external returns (uint256 value) {
        (bool success, bytes memory returnedData) = delegateContract.delegatecall(abi.encodeWithSignature("getStoredValue()"));
        
        require(success);
        return abi.decode(returnedData, (uint256));
    }
}

contract ContractB {
    
    uint256 private storedValue;
    
    enum OPE {Addition, Subtraction}
    
    constructor() {}
    
    function calculateValue(uint256 _value, uint8 _operator) external returns (uint256 returnedValue) {
        OPE _iOperator = OPE(_operator);
        
        if(_iOperator == OPE.Addition) {
            return storedValue += _value;
        }
        else if(_iOperator == OPE.Subtraction) {
            if(storedValue > _value) {
                return storedValue -= _value;
            }
            else 
                return 0;
        }
    }
    
    function getStoredValue() external view returns (uint256 value) {
        return storedValue;
    }
}