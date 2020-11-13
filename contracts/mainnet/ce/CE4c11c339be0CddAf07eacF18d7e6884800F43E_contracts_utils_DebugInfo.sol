pragma solidity ^0.6.0;

contract DebugInfo {

    mapping (string => uint) public uintValues;
    mapping (string => address) public addrValues;
    mapping (string => string) public stringValues;
    mapping (string => bytes32) public bytes32Values;

    function logUint(string memory _id, uint _value) public {
        uintValues[_id] = _value;
    }

    function logAddr(string memory _id, address _value) public {
        addrValues[_id] = _value;
    }

    function logString(string memory _id, string memory _value) public {
        stringValues[_id] = _value;
    }

    function logBytes32(string memory _id, bytes32 _value) public {
        bytes32Values[_id] = _value;
    }
}
