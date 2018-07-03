pragma solidity ^0.4.24;

contract ContractName {
    
    mapping (uint => string) public stringIdToString;
    uint public numberOfStrings;
    
    function addString(string message) public returns (uint stringId) {
        stringIdToString[numberOfStrings] = message;
        return numberOfStrings++;
    }
}