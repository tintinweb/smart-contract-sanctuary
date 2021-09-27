/**
 *Submitted for verification at Etherscan.io on 2021-09-26
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract DelegateCallee {
    uint public num;
    address public sender;
    uint public value;

    function setVars(uint _num) public payable {
        num = _num;
        sender =  msg.sender;
        value = msg.value;
    }

}