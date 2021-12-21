/**
 *Submitted for verification at polygonscan.com on 2021-12-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Test1{

    address public _owner;
    address public inserted_addr;
    address public contract_addr = address(this);

    constructor(){
        _owner = msg.sender;
    }

    function insertAddr(address _addr) public {
        inserted_addr = _addr;
    }

}