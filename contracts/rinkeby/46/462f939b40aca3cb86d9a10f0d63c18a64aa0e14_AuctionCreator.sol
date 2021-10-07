// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

import './Auction.sol';

contract AuctionCreator {
    Auction[] public auctions;
    
    function createAuction() public{
        Auction newAAdress = new Auction(msg.sender);
        auctions.push(newAAdress);
    }
}