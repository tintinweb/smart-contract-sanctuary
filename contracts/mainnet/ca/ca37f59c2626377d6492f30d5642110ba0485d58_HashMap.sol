pragma solidity 0.4.8;

contract HashMap {
    mapping(bytes32 => bytes) map;
    
    function set(bytes _data) public {
        map[keccak256(_data)] = _data;
    }
    
    function get(bytes32 _hash) public constant returns (bytes data) {
        return map[_hash];
    }
}