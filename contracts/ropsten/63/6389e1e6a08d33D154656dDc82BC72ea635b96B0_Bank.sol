/**
 *Submitted for verification at Etherscan.io on 2021-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Bank  {

    string public name;
    uint public value;
    address owner;
   
    constructor(uint _value) {
        
        value = _value;
        owner = msg.sender;
        
    } 


    function setName(string memory _name, uint _value) public {
            require(msg.sender == owner , 'Tylko Owner reqiure');
            name = _name;
            value = _value;
    }

    function getName() external view returns  (string memory ){ 
            return name;
    }

    function getValue() external view returns (uint){ 
        return value;
    }

}