/**
 *Submitted for verification at BscScan.com on 2021-09-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract ContractA {
    
    uint256 private storedValue;
    address public delegateContract;
    
    enum OPE {Addition, Subtraction}
    
    event ReturnedValue(uint256 _value);
    event ReturnedCalculateValue(uint256 _value);
    
    constructor(uint256 _initialValue, address _contract) {
        storedValue = _initialValue;
        delegateContract = _contract;
    }
    
    function calculateValue(uint256 _value, OPE _operator) external returns (uint256 _storedValue) {
        uint8 _ope = uint8(_operator);
        (bool success, bytes memory data) = delegateContract.delegatecall(abi.encodeWithSignature("calculateValue(uint256, uint8)", _value, _ope));
        
        require(success);
        uint256 result = abi.decode(data, (uint256));

        emit ReturnedCalculateValue(result);

        return result;
    }
    
    function getStoredValue() external returns (uint256 value) {
        (bool success, bytes memory returnedData) = delegateContract.delegatecall(abi.encodeWithSignature("getStoredValue()"));
        
        require(success);
        
        uint256 _returnedValue = abi.decode(returnedData, (uint256));
        
        emit ReturnedValue(_returnedValue);
        return _returnedValue;
    }
}