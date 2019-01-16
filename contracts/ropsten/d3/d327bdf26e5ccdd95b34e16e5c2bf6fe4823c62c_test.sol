pragma solidity ^0.4.25;


contract test {
    mapping (bytes32 => string) public arrayStr;

    function setArray(string key, string value) public returns(string) {
        arrayStr[keccak256(key)] = value;
        return arrayStr[keccak256(key)];
    }

    function getArray(string key) public returns(string) {
        return arrayStr[keccak256(key)];
    }

    string public contractName = "Teste array";
}