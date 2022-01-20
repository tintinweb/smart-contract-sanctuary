// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MVPToken.sol";
import "./GameToken.sol";
import "./GameMarket.sol";

contract GameMarketplace is GameMarket {
 MVPToken private mvpToken;
 GameToken private token;

  event itemSold(uint256 id, address buyer, uint256 price);

  constructor(GameToken _token,MVPToken _mvpToken) {
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


  function putItemForSale(uint256 tokenId, uint256 price,address seller) 
    OnlyItemOwner(tokenId,seller) 
    external 
    returns (uint256){
      require(!activeItems[tokenId], "Item is already up for sale");

      uint256 newItemId = itemsForSale.length;
      string memory uri=token.tokenURI(tokenId);
      uint256  gameId=token.tokenGameId(tokenId);
      string memory title=token.tokenTitle(tokenId);
      string memory description=token.tokenDescription(tokenId);
      uint256  categoryId=token.tokenCategoryId(tokenId);
      itemsForSale.push(ItemForSale({
        id: newItemId,
        categoryId: categoryId,
        tokenId: tokenId,
        seller: payable(seller),
        buyer: address(0x0),
        price: price,
        createTime: block.timestamp,
        isSold: false,
        uri: uri,
        gameId:gameId,
        description:description,
        title:title
      }));
      activeItems[tokenId] = true;
      activeGameId[gameId]=newItemId;
      assert(itemsForSale[newItemId].id == newItemId);
      return newItemId;
  }

  function buyItem(uint256 id) 
    ItemExists(id)
    IsForSale(id)
    HasTransferApproval(itemsForSale[id].tokenId)
    payable 
    external {
      require(mvpToken.balanceOf(msg.sender) >= itemsForSale[id].price, "Not enough funds sent");
      require(msg.sender != itemsForSale[id].seller,"Can't buy your own NFT!");

      itemsForSale[id].isSold = true;
      itemsForSale[id].buyer = msg.sender;
      activeItems[itemsForSale[id].tokenId] = false;
      token.safeTransferFrom(itemsForSale[id].seller, msg.sender, itemsForSale[id].tokenId);
      mvpToken.transferFrom(msg.sender,itemsForSale[id].seller,itemsForSale[id].price);
      emit itemSold(id, msg.sender, itemsForSale[id].price);
    }


   function soldOut(uint256 id) external  returns(bool) {
     require(id < itemsForSale.length && itemsForSale[id].id == id, "Could not find order");
     require(msg.sender == itemsForSale[id].seller,"You're not the seller!");
     require(!itemsForSale[id].isSold,"It's already sold!");
     itemsForSale[id].isSold=true;
     activeItems[itemsForSale[id].tokenId] = false;
     return true;
  }
  function itemOrderList(uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
      return orderQueryList(address(0x0),page,size,0,0);
  }
   function myOrderList(address _owner,uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
    return orderQueryList(_owner,page,size,0,0);
  }
 function categoryOrderList(uint256  categoryId,uint256 page,uint256 size) public view returns(ItemForSalePage memory) {
    return orderQueryList(address(0x0),page,size,categoryId,1);
  }
  function addBlindBoxOrder(uint256 categoryId,string memory uuid,uint256 price)    
    payable 
    external  
    returns(uint256 ) {
     uint256 newItemId = BlindBoxOrders.length;
     address ownerAddress=token.getOwner();
     mvpToken.transferFrom(msg.sender,ownerAddress,price*(10 ** 18));
     BlindBoxOrders.push(BlindBoxOrder({
        id: newItemId,
        buyer: msg.sender,
        categoryId: categoryId,
        uuid: uuid,
        price: price,
        createTime: block.timestamp
      }));
      return newItemId;
  }
}