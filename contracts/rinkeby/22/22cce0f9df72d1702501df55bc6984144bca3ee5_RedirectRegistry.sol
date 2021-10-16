/**
 *Submitted for verification at Etherscan.io on 2021-10-16
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract RedirectRegistry {
    mapping(address => address) public redirects;

    event Register(address indexed from, address indexed to);

    function register(address to) external {
        redirects[msg.sender] = to;
        emit Register(msg.sender, to);
    }
}