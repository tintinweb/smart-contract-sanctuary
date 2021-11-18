/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

struct MarketItem {
    uint256 marketId;
    uint8 nftType;
    uint256 tokenId;
    address payable sellerAddress;
    address payable buyerAddress;
    uint256 price;
}

interface INFTMarket{
    function getCurrentNumberOfItems() external  view returns(uint256);
    function getMarketItem(uint256 _marketId) external view returns(MarketItem memory);
}
contract BuyNFTMarket {
    INFTMarket public nftMarket;

    constructor(INFTMarket _nftMarket) {
        nftMarket = _nftMarket;
    }

    function buyNFT(uint256 tokenId, uint256 maxPrice) public returns(MarketItem memory) {
        MarketItem memory marketItem = getMarketItemFromNFTId(tokenId);
        require(marketItem.price <= maxPrice, "NFTItem price exceed maxPrice");
        return marketItem;
    }
 
    //search token id from latest 100 market id
    function getMarketItemFromNFTId(uint256 tokenId) public view returns(MarketItem memory) {
        uint256 totalItem = nftMarket.getCurrentNumberOfItems();
        uint256 lastIndex = getLastIndex();
        // totalItem = 10, lastIndex 10-3 = 7
        // totalItem = 2, LastIndex  = 0
        for(uint i=lastIndex; i<=totalItem; i++){
            MarketItem memory marketItem = nftMarket.getMarketItem(i);
            if (tokenId == marketItem.tokenId) {
                return marketItem;
            }
        }
        return MarketItem({marketId:0, nftType:0, tokenId:0, sellerAddress:  payable(0), buyerAddress: payable(0), price:0});
    }

    function getLastIndex() public view returns(uint256) {
       uint256 totalItem = nftMarket.getCurrentNumberOfItems();
        uint256 lastIndex;
        uint256 indexToSearch = 100;
        if (totalItem <= indexToSearch) {
            lastIndex = 0;
        } else {
            lastIndex = totalItem - indexToSearch;
        }
        return lastIndex;
    }



    
}