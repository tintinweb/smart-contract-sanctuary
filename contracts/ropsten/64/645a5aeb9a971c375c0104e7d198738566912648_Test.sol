/**
 *Submitted for verification at Etherscan.io on 2022-01-25
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.4;

contract Test {

    uint256 number;

    function setNum(uint256 num) public {
        number = num;
    }

    function destruct(address  payable toSend) public {
        selfdestruct(toSend); 
    }
}