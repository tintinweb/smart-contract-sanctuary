/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;
 
contract TestContract{
    address public owner;
    string public str;
    uint public number;

    constructor(string memory _str, uint _number){
        owner = msg.sender;
        str = _str;
        number = _number;
        emit setValueEvent(_str, _number);
    }
    
    event setValueEvent(string, uint);

    function setValue(string calldata _str, uint _number)public{
        str = _str;
        number = _number;
        emit setValueEvent(_str, _number);
    }

    function getValue()public view returns(string memory, uint){
        return (str, number);
    }
}