/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.0;

contract MockOracle {
    uint256 internal price;
    address internal immutable owner;

    constructor() {owner = msg.sender;}
    
    function getLatestPrice() external view returns (uint256) {
        return price;
    }

    function setLatestPrice(uint256 _price) external {
        price = _price;
    }
}