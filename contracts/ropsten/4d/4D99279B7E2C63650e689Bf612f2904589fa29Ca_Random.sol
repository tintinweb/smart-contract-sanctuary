/**
 *Submitted for verification at Etherscan.io on 2021-09-12
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;



// File: Random.sol

contract Random {

    constructor () public {}

    function random() public view returns(uint) {
        return uint(blockhash(block.number));
    }
}