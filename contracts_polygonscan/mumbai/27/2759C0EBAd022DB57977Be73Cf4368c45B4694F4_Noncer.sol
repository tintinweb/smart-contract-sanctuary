// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

contract Noncer {
    uint256 nonce;

    function setNonce() external {
        nonce = 0;
    }
}