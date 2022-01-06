// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MVPToken.sol";
import "./ArtToken.sol";

contract ArtMarketplace {
 MVPToken private mvpToken;
 ArtToken private token;
  struct ItemForSale {
    uint256 id;
    uint256 tokenId;
    address payable seller;
    address  buyer;
    uint256 price;
    uint256 createTime;
    bool isSold;
    string uri;//metadata url
    string title;
    string description;
    string category;
  }
  struct ItemForSalePage {
    uint256 total;
    ItemForSale[] itemList;
  }
  
  ItemForSale[] public itemsForSale;
  mapping(uint256 => bool) public activeItems; // tokenId => ativo?

  // event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
  event itemSold(uint256 id, address buyer, uint256 price);

  constructor(ArtToken _token,MVPToken _mvpToken) {
      token = _token;
      mvpToken = _mvpToken;
  }

  modifier OnlyItemOwner(uint256 tokenId,address seller){
    require(token.ownerOf(tokenId) == seller, "Sender does not own the item");
    _;
  }

  modifier HasTransferApproval(uint256 tokenId){
    require(token.getApproved(tokenId) == address(this), "Market is not approved");
    _;
  }

  modifier ItemExists(uint256 id){
    require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find item");
    _;
  }

  modifier IsSeller(uint256 id){
    require(id < itemsForSale.length && itemsForSale[id].seller == msg.sender, "Could not buy");
    _;
  }
  modifier IsForSale(uint256 id){
    require(!itemsForSale[id].isSold, "Item is already sold");
    _;
  }

  function putItemForSale(uint256 tokenId, uint256 price,address seller) 
    OnlyItemOwner(tokenId,seller) 
    external 
    returns (uint256){
      require(!activeItems[tokenId], "Item is already up for sale");

      uint256 newItemId = itemsForSale.length;
      string memory uri=token.tokenURI(tokenId);
      string memory category=token.tokenTitle(tokenId);
      string memory title=token.tokenCategory(tokenId);
      string memory description=token.tokenDescription(tokenId);
      itemsForSale.push(ItemForSale({
        id: newItemId,
        tokenId: tokenId,
        seller: payable(seller),
        buyer: address(0x0),
        price: price,
        createTime: block.timestamp,
        isSold: false,
        uri: uri,
        category:category,
        description:description,
        title:title
      }));
      activeItems[tokenId] = true;
      assert(itemsForSale[newItemId].id == newItemId);
      // emit itemAddedForSale(newItemId, tokenId, price);
      return newItemId;
  }

  function buyItem(uint256 id) 
    ItemExists(id)
    IsForSale(id)
    HasTransferApproval(itemsForSale[id].tokenId)
    payable 
    external {
      require(mvpToken.balanceOf(msg.sender) >= itemsForSale[id].price, "Not enough funds sent");
      require(msg.sender != itemsForSale[id].seller);

      itemsForSale[id].isSold = true;
      itemsForSale[id].buyer = msg.sender;
      activeItems[itemsForSale[id].tokenId] = false;
      token.safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId);
      // token.Items[itemsForSale[id].tokenId].creator=itemsForSale[id].seller;
      // itemsForSale[id].seller.transfer(msg.value);
      mvpToken.transferFrom(msg.sender,itemsForSale[id].seller,itemsForSale[id].price);
      emit itemSold(id, msg.sender, itemsForSale[id].price);
    }

  function totalItemsForSale() external view returns(uint256) {
    return itemsForSale.length;
  }
    function getIsActive(uint256 tokenId) external view returns(bool) {
    return  !activeItems[tokenId];
  }
   function removeItemsForSale(uint256 id) external  returns(bool) {
      require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find item");
     delete  itemsForSale[id];
     delete activeItems[itemsForSale[id].tokenId] ;
     return true;
  }
   function itemOderList(uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
        uint256 itemCount = itemsForSale.length;
        uint256 myItemCount = 0;
        uint256 currentIndex = 0;
        uint256 startNum=page*size;
        uint256 count=size;
         for(uint i = 0; i < itemCount; i++) {
                if(itemsForSale[i].isSold == false) {
                    myItemCount += 1;
                }
            }
        // looping over the number of items created (if number has not been sold populate the array)
        if(startNum>=itemCount)return ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count==0)return ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count>myItemCount-startNum){
          count=myItemCount-startNum;
        }

        ItemForSale[] memory orderList = new ItemForSale[](count);
        
        for(uint i = 0; i < itemCount; i++) {
            if(itemsForSale[i].isSold == false) {
                if(currentIndex<startNum)
              {
                 currentIndex += 1;
                continue;
              }
                if(currentIndex>=startNum+count)break;
                orderList[currentIndex-startNum] = itemsForSale[i]; 
                currentIndex += 1;
            }
        } 
         return  ItemForSalePage({total:myItemCount,itemList:orderList}); 
    }
    function myOderList(address _owner,uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
        uint itemCount = itemsForSale.length;
        uint myItemCount = 0;
        uint currentIndex = 0;
        uint256 startNum=page*size;
        uint256 count=size;
         for(uint i = 0; i < itemCount; i++) {
                if(itemsForSale[i].isSold == false&&itemsForSale[i].seller==_owner) {
                    myItemCount += 1;
                }
            }
        if(startNum>=itemCount)return ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count==0)return ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count>myItemCount-startNum){
          count=myItemCount-startNum;
        }
        // looping over the number of items created (if number has not been sold populate the array)
        ItemForSale[] memory orderList = new ItemForSale[](count);
        for(uint i = 0; i < itemCount; i++) {
            if(itemsForSale[i].isSold == false&&itemsForSale[i].seller==_owner) {
                if(currentIndex<startNum)
              {
                 currentIndex += 1;
                continue;
              }
                if(currentIndex>=startNum+count)break;
                orderList[currentIndex-startNum] = itemsForSale[i]; 
                currentIndex += 1;
            }
        } 
        return ItemForSalePage({total:myItemCount,itemList:orderList}); 
    }
       function myOderLogList(address _owner,uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
        uint itemCount = itemsForSale.length;
        uint myItemCount = 0;
        uint currentIndex = 0;
        uint256 startNum=page*size;
        uint256 count=size;
         for(uint i = 0; i < itemCount; i++) {
                if(itemsForSale[i].seller==_owner||itemsForSale[i].buyer==_owner) {
                    myItemCount += 1;
                }
            }
        if(startNum>=itemCount)return ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count==0)return ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count>myItemCount-startNum){
          count=myItemCount-startNum;
        }

        ItemForSale[] memory orderList = new ItemForSale[](count);
        for(uint i =1; i <= itemCount; i++) {
            if(itemsForSale[itemCount-i].seller==_owner||itemsForSale[itemCount-i].buyer==_owner) {
                if(currentIndex<startNum)
              {
                 currentIndex += 1;
                continue;
              }
                if(currentIndex>=startNum+count)break;
                orderList[currentIndex-startNum] = itemsForSale[itemCount-i]; 
                currentIndex += 1;
            }
        } 
        return ItemForSalePage({total:myItemCount,itemList:orderList});
    }
    function itemLogList(uint256 tokenId) public view returns(ItemForSale[] memory) {
        uint itemCount = itemsForSale.length;
        uint myItemCount = 0;
        uint currentIndex = 0;
         for(uint i = 0; i < itemCount; i++) {
                if(itemsForSale[i].tokenId==tokenId) {
                    myItemCount += 1;
                }
            }
        // looping over the number of items created (if number has not been sold populate the array)
        ItemForSale[] memory orderList = new ItemForSale[](myItemCount);
        for(uint i = 0; i < itemCount; i++) {
            if(itemsForSale[i].tokenId==tokenId) {
                orderList[currentIndex] = itemsForSale[i]; 
                currentIndex += 1;
            }
        } 
        return orderList; 
    }
    function priceOderList(uint256 startPrice,uint256 endPrice,uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
        uint itemCount = itemsForSale.length;
        startPrice=startPrice*(10 ** 18);
        endPrice=endPrice*(10 ** 18);
        uint myItemCount = 0;
        uint currentIndex = 0;
        uint256 startNum=page*size;
        uint256 count=size;
         for(uint i = 0; i < itemCount; i++) {
                if(itemsForSale[i].isSold == false&&
               itemsForSale[i].price>=startPrice&&itemsForSale[i].price<=endPrice) {
                    myItemCount += 1;
                }
            }
        if(startNum>=itemCount) return  ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
         if(count==0) return  ItemForSalePage({total:myItemCount,itemList:new ItemForSale[](0)}); 
        if(count>myItemCount-startNum){
          count=myItemCount-startNum;
        }
        // looping over the number of items created (if number has not been sold populate the array)
        ItemForSale[] memory orderList = new ItemForSale[](count);
        for(uint i = 0; i < itemCount; i++) {
            if(itemsForSale[i].isSold == false&&
             itemsForSale[i].price>=startPrice&&itemsForSale[i].price<=endPrice) {
               if(currentIndex<startNum)
              {
                 currentIndex += 1;
                continue;
              }
                if(currentIndex>=startNum+count)break;
                orderList[currentIndex-startNum] = itemsForSale[i]; 
                currentIndex += 1;
            }
        } 
       
        return  ItemForSalePage({total:myItemCount,itemList:orderList}); 
    }
}

//TODO:
// - don't support bidding
// - the user can't withdraw the item