/**
 *Submitted for verification at Etherscan.io on 2021-09-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface ERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
    function tokensOfOwner(address user) external returns (uint256[] memory);
    function ownerOf(uint256 tokenId) external returns (address); 
    function isApprovedForAll(address owner, address operator) external returns (bool);
}

contract Market {
    address public tokenERC721Address;
    address public owner;
    uint256 public fee = 500;
    uint256 constant PERCENT_DENOMINATOR = 10000;

    
    struct Item {
        address owner;
        uint256 startPrice;
        uint256 endPrice;
        uint256 startTime;
        uint256 duration;
    }
    
    mapping(uint256 => Item) public listSell;
    
    event PushItem(uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration);
    event Buy(uint256 tokenId);
    
    constructor (address _tokenERC721Address) public {
        tokenERC721Address = _tokenERC721Address;
        owner = msg.sender;
    }
    
    function _computeCurrentPrice (uint256 startPrice, uint256 endPrice, uint256 duration, uint256 timeLateSell) internal pure returns(uint256){
        if (timeLateSell > duration) {
            return endPrice;
        }
        int256 totalPriceChange = int256(endPrice) - int256(startPrice) ;
        
        int256 currentPriceChange = (int256 (timeLateSell) * totalPriceChange) / int256(duration);
        
        int256 currentPrice = int256(startPrice) + currentPriceChange;
        
        return uint256 (currentPrice);
    }
    

    function buy(uint256 tokenId) public payable returns(bool){
        ERC721 tokenERC721 = ERC721(tokenERC721Address);
        address addressOwner = tokenERC721.ownerOf(tokenId);
        
        require(listSell[tokenId].duration > 0, "not exist");
        
        
        uint256 priceItem = _computeCurrentPrice(listSell[tokenId].startPrice, listSell[tokenId].endPrice, listSell[tokenId].duration, now - listSell[tokenId].startTime);
        require(msg.value >= priceItem, "not enough");
        
        uint256 priceOfOwner = (PERCENT_DENOMINATOR - fee) * priceItem / PERCENT_DENOMINATOR;
        
        
        payable(addressOwner).transfer(priceOfOwner);
       
        tokenERC721.transferFrom(addressOwner, msg.sender, tokenId);
        
        
        listSell[tokenId].duration = 0;
        
        emit Buy(tokenId);
        
        return true;
    }
    
    function pushItemSell(uint256 tokenId, uint256 startPrice, uint256 endPrice, uint256 duration) public {
        require(duration > 0, "error time");
        
        ERC721 tokenERC721 = ERC721(tokenERC721Address);
        address addressOwner = tokenERC721.ownerOf(tokenId);
        bool isApprovedForAll = tokenERC721.isApprovedForAll(addressOwner, address(this));
        
        require(msg.sender == addressOwner, "not owner");
        require(isApprovedForAll == true, "not approved");
        
        require(listSell[tokenId].duration == 0, "is exist");

        listSell[tokenId].owner = msg.sender;
        listSell[tokenId].startPrice = startPrice;
        listSell[tokenId].endPrice = endPrice;
        listSell[tokenId].startTime = now;
        listSell[tokenId].duration = duration;
        
        emit PushItem(tokenId, startPrice, endPrice, duration);
    }
    
    
    function removeItemSell(uint256 tokenId) public {
        ERC721 tokenERC721 = ERC721(tokenERC721Address);
        address addressOwner = tokenERC721.ownerOf(tokenId);
        
        require(msg.sender == addressOwner, "not owner");
        
        require(listSell[tokenId].duration > 0, "not exist");
        
        listSell[tokenId].duration = 0;
    }
    
    function withdrawETH() public returns (bool)  {
        require(msg.sender == owner, "not owner");
         
        uint value = address(this).balance;
        payable(owner).transfer(value);
        return true;
    }
    
    function updateFee(uint256 _fee) public {
        require(msg.sender == owner, "not owner");
        fee = _fee;
    }
    
    
    function showListSell(uint256 tokenId) public view returns (Item memory) {
        return listSell[tokenId];
    }
    
      function balanceETH(address _address) public view returns (uint balance) {
        return _address.balance;
    }

    
}