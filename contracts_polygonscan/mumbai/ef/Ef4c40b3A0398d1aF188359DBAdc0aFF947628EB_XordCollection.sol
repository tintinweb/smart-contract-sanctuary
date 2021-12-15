// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;


contract XordCollection {

    bool public activeStatus = false;


    constructor() {
        activeStatus = true;
    }

    function flipStatus() public {
        activeStatus = !activeStatus;
    }

    
}