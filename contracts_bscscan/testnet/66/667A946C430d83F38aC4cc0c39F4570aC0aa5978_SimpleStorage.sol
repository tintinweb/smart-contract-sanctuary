/**
 *Submitted for verification at BscScan.com on 2021-08-22
*/

pragma solidity ^0.6.2;

contract SimpleStorage {
    
    event ValueChanged(string oldValue, string newValue);
    string public value;
    
    constructor(string memory _value) public {
        value = _value;
    }
    
    function setValue(string memory _value) public {
        emit ValueChanged(value, _value);
        value = _value;
    }
}