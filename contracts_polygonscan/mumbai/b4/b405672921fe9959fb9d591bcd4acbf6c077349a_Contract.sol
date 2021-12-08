/**
 *Submitted for verification at polygonscan.com on 2021-12-07
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Contract {
    
    struct WL {
        address addr;
        string twitter;
    }

    mapping(address => bool) private whitelisted;
    WL[] private whitelist;

    function registerYourTwitterUsernameForWhitelist(string memory tag) public {
        if (!whitelisted[msg.sender]) {
            whitelist.push(WL(msg.sender, tag));
            whitelisted[msg.sender] = true;
        }
    }

    function getWL() public view returns(WL[] memory) {
        return whitelist;
    }
}