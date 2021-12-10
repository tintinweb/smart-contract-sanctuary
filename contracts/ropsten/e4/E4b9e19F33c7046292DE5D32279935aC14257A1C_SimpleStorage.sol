/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

pragma solidity ^0.5.1;

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