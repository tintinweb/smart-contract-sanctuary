/**
 *Submitted for verification at Etherscan.io on 2021-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.17;

contract MyContract {
    uint public number = 5;
    uint private number2 = 0;
    
    constructor() public {
        number2 = 5;
    }

    function getNumber() public view returns(uint) {
        return number;
    }
    
    function setNumer(uint _number) public {
        number = _number;
    }
    
    function getNumber2() public view returns(uint) {
        return number2;
    }
    
    function setNumer2(uint _number2) public {
        number2 = _number2;
    }
}