/**
 *Submitted for verification at Etherscan.io on 2021-12-02
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Whitelisting {
    event LogAddedToWhitelist(address addr);
    event LogRemovedFromWhitelist(address addr);

    mapping(address => bool) public whitelist;

    constructor() public {}

    function addToWhitelist(address addr_) external {
        whitelist[addr_] = true;
        emit LogAddedToWhitelist(addr_);
    }

    function removeFromWhitelist(address addr_) external {
        whitelist[addr_] = false;
        emit LogRemovedFromWhitelist(addr_);
    }
}