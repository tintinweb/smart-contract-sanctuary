pragma solidity ^0.4.0;
contract VariableAssignment {
    uint storageData;
    function set(uint x) public {
        storageData = x;
    }
    function get() public view returns (uint) {
        return storageData;
    }
}