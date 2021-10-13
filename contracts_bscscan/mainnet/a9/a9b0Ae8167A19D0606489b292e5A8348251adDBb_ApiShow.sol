/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

contract ApiShow {
    function createRent(uint256 tokenId_, uint256 rentDays_, uint256 rentPrice_) external {}
    function rent(uint256 tokenId_, uint256 orderId_, uint256 days_, uint256 price_) external {}
    function renewRent(uint256 tokenId_, uint256 orderId_, uint256 days_, uint256 price_) external {}
    function bid(uint256 tokenId_, uint256 orderId_, uint256 price_) external {}
    function endBid(uint256 tokenId_, uint256 orderId_) external {}
}