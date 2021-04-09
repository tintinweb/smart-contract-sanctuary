/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.6.0;
// SPDX-License-Identifier: GPL-3.0-or-later

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract MolAuction {
  
    address public commons;
    address public gamma;
    
    struct auction {
        uint256 bid;
        uint256 reserve;
        address payable bidder;
        address creator;
        uint256 startBlock;
    }
    
    mapping(uint256 => auction) public auctions;
    
    // **************
    // EVENT TRACKING
    // **************
    event CreateAuction(uint256 tokenId, address indexed creator, uint256 reserve, uint256 createdAt);
    event UpdateAuctionReserve(uint256 reserve);
    event UpdateBid(uint256 bid, address indexed bidder);
    event WithdrawBid(uint256 tokenId);
    event AcceptBid(uint256 tokenId, uint256 price, address indexed buyer, address indexed creator);
    
    constructor (address _commons, address _gamma) public {
        commons = _commons;
        gamma = _gamma;
    }
    
    function createAuction(uint256 _tokenId, address _creator, uint256 _reserve) public {
        auctions[_tokenId].creator = _creator;
        auctions[_tokenId].reserve = _reserve;
        auctions[_tokenId].startBlock = block.number;
        
        emit CreateAuction(_tokenId, auctions[_tokenId].creator, auctions[_tokenId].reserve, auctions[_tokenId].startBlock);
    }
    
    function updateAuctionReserve(uint256 _tokenId, uint256 _reserve) public {
        auctions[_tokenId].reserve = _reserve;
        
        emit UpdateAuctionReserve(auctions[_tokenId].reserve);
    }
    
    function bid(uint256 _tokenId) public payable {
        require(msg.value > auctions[_tokenId].bid, 'You must bid higher than the existing bid!');
        
        (bool success, ) = auctions[_tokenId].bidder.call{value: auctions[_tokenId].bid}("");
        require(success, "!transfer");        
        
        auctions[_tokenId].bid = msg.value;
        auctions[_tokenId].bidder = msg.sender;
        
        emit UpdateBid(msg.value, msg.sender);
    }
    
    function withdrawBid(uint256 _tokenId) public {
        require(msg.sender == auctions[_tokenId].bidder, 'No bids to withdraw!');
    
        (bool success, ) = auctions[_tokenId].bidder.call{value: auctions[_tokenId].bid}("");
        require(success, "!transfer");
        
        emit WithdrawBid(_tokenId);
    }
    
    function acceptBid(uint256 _tokenId) public {
        require(msg.sender == auctions[_tokenId].creator, '!creator');
        
        uint256 price = auctions[_tokenId].bid;
        address payable buyer = auctions[_tokenId].bidder;
        
        auctions[_tokenId].bid = 0;
        auctions[_tokenId].bidder = address(0);        
        
        (bool success, ) = auctions[_tokenId].creator.call{value: price}("");
        require(success, "!transfer");
        
        IERC721(gamma).transferFrom(commons, buyer, _tokenId);
        
        emit AcceptBid(_tokenId, price, buyer, auctions[_tokenId].creator);
    }
}