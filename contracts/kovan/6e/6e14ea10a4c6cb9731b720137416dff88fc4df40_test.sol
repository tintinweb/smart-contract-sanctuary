/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

contract test {

    event OrdersMatched(bytes32 buyHash, bytes32 sellHash, address indexed maker, address indexed taker, uint price);

    function callEvent() public {
        emit OrdersMatched(
            keccak256("Buy ORder"),
            keccak256("Sell ORder"),
            0xfC48055f896bA8A8424839D7E29B9cAf80184B74,
            0x70Eff610dD4Ee242a921D0331983f8DDbDdB0960,
            200);
    }
   
}