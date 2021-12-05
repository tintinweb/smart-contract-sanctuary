/**
 *Submitted for verification at Etherscan.io on 2021-12-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract test {

    event OrdersMatched(bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, uint price);

    function callEvent(bytes32 buyHash, bytes32 sellHash, address maker, address taker, uint price) public {
        
        emit OrdersMatched(
            buyHash,
            sellHash,
            maker,
            taker,
            price);
    }
   
}