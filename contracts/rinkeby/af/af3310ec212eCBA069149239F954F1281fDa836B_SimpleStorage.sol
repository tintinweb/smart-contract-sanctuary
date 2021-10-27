/**
 *Submitted for verification at Etherscan.io on 2021-10-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleStorage {
    uint public storedData; //Do not set 0 manually it wastes gas!
    
    event setValueUpdatedViaWebjs(
        uint indexed date,
        address indexed from,
        uint valueChangeEventWenjs
    );

    function set(uint x) public {
        storedData = x;
        emit setValueUpdatedViaWebjs(block.number, msg.sender, x);
    }
    
}