/**
 *Submitted for verification at polygonscan.com on 2021-06-29
*/

pragma solidity ^0.8.4;

// SPDX-License-Identifier: No License

contract Oracle {
    address public admin;
    uint public rand;
    
    constructor() {
        admin = msg.sender;
    }
    
    function feedRandomness(uint _rand) external {
        require(msg.sender == admin, "only admin is allowed");
        rand = _rand;
    }
}