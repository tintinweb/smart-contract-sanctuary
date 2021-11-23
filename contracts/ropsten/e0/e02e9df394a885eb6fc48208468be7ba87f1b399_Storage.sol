/**
 *Submitted for verification at Etherscan.io on 2021-11-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Storage {
    string public data;
    
    constructor(string memory initData) {
        data = initData;
    }
    
    function setData(string memory newData) public {
        data = newData;
    }
}