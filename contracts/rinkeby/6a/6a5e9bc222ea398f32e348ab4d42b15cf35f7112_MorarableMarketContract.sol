// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;

import "./IERC721.sol";

contract MorarableMarketContract {
    struct Item {
        uint256 id;
        address tokenAddress;
        uint256 tokenId;
        address payable seller;
        uint256 askingPrice;
        bool isSold;
    }

    Item[] public itemsForSale;
    mapping (address => mapping (uint256 => bool)) activeItems;

    event itemAdded(uint256 id, uint256 tokenId, address tokenAddress, uint256 askingPrice);
    event itemSold(uint256 id, address buyer, uint256 askingPrice);

    modifier OnlyItemOwner(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.ownerOf(tokenId) == msg.sender);
        _;
    }

    modifier HasTransferApproval(address tokenAddress, uint256 tokenId){
        IERC721 tokenContract = IERC721(tokenAddress);
        require(tokenContract.getApproved(tokenId) == address(this));
        _;
    }

    modifier ItemExists(uint256 id){
        require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find item");
        _;
    }

    modifier IsForSale(uint256 id){
        require(itemsForSale[id].isSold == false, "Item is already sold!");
        _;
    }

    function addItemToMarket(uint256 tokenId, address tokenAddress, uint256 askingPrice) OnlyItemOwner(tokenAddress,tokenId) HasTransferApproval(tokenAddress,tokenId) external returns (uint256){
        require(activeItems[tokenAddress][tokenId] == false, "Item is already up for sale!");
        uint256 newItemId = itemsForSale.length;
        itemsForSale.push(Item(newItemId, tokenAddress, tokenId, payable(msg.sender), askingPrice, false));
        activeItems[tokenAddress][tokenId] = true;

        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAdded(newItemId, tokenId, tokenAddress, askingPrice);
        return newItemId;
    }

    function buyItem(uint256 id) payable external ItemExists(id) IsForSale(id) HasTransferApproval(itemsForSale[id].tokenAddress,itemsForSale[id].tokenId){
        require(msg.value >= itemsForSale[id].askingPrice, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenAddress][itemsForSale[id].tokenId] = false;
        IERC721(itemsForSale[id].tokenAddress).safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId);
        itemsForSale[id].seller.transfer(msg.value);

        emit itemSold(id, msg.sender,itemsForSale[id].askingPrice);
    }
}