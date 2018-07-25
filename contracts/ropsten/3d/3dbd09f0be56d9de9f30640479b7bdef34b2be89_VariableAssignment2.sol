pragma solidity ^0.4.0;
contract VariableAssignment2 {
    uint storageData;
    function set() public {
        storageData = 5;
    }
    function get() public view returns (uint) {
        return storageData;
    }
}