pragma solidity ^0.4.25;

// File: contracts/MyValues.sol

contract MyValues {

    mapping(bytes32 => uint) private uintValues;

    function getUint(bytes32 record) public view returns(uint) {
        return uintValues[record];
    }

    function putUint(bytes32 record, uint value) public {
        uintValues[record] = value;
    }

    mapping(bytes32 => string) private stringValues;

    function getString(bytes32 record) public view returns(string) {
        return stringValues[record];
    }

    function putString(bytes32 record, string value) public {
        stringValues[record] = value;
    }
    
    mapping(bytes32 => bool) private boolValues;

    function getBool(bytes32 record) public view returns(bool) {
        return boolValues[record];
    }

    function putBool(bytes32 record, bool value) public {
        boolValues[record] = value;
    }
}