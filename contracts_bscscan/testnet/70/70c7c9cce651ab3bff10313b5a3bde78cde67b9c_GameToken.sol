// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./GameMarketplace.sol";

contract GameToken is ERC721Enumerable{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  GameMarketplace private marketplace;
  mapping(uint256 => bool) public activeGames; 
  mapping(uint256 => uint256) public activeGameId; 
  address public ownerAddress;
  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
    uint256 categoryId;
    uint256 gameId;
    string title;
    string rate;
    string description;
  }
  struct ItemPage {
    uint256 total;
    Item[] itemList;
  }
  mapping(uint256 => Item) public Items; //id => Item
  constructor () ERC721("MVPGAMENFT", "MVPGNFT") {
     ownerAddress=msg.sender;
  }
 event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
  function mint(string memory uri,uint256  categoryId,string memory title,
  string memory description,string memory rate,uint256 gameId,address _owner)
    IsOwnerAddress()
  public returns (uint256){    
     require(!activeGames[gameId], "Land is already up for sale");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(_owner, newItemId);
    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri,
      categoryId:categoryId,
      title:title,
      gameId:gameId,
      rate:rate,
      description:description
    });
    activeGames[gameId]=true;
    activeGameId[gameId]=newItemId;
    return newItemId;
  }

  function privateMint(string memory uri,uint256  categoryId,string memory title,
  string memory description,string memory rate,uint256 price,address _owner,uint256 gameId)
  IsOwnerAddress()
   public returns (uint256){
     require(!activeGames[gameId], "Land is already up for sale");
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(_owner, newItemId);
    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri,
      categoryId:categoryId,
      title:title,
      gameId:gameId,
      rate:rate,
      description:description
    });
     price=price*(10 ** 18);
     activeGames[gameId]=true;
      activeGameId[gameId]=newItemId;
      uint256 result=  marketplace.putItemForSale(newItemId,price,_owner);
      approve(address(marketplace), newItemId);
      emit itemAddedForSale(result, newItemId, price);
    return newItemId;
  }
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].uri;
  }
    function tokenTitle(uint256 tokenId) public view  returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].title;
  }
  function tokenCategoryId(uint256 tokenId) public view  returns (uint256 ) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].categoryId;
  }
  function tokenRate(uint256 tokenId) public view  returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].rate;
  }
  function tokenGameId(uint256 tokenId) public view  returns (uint256 ) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].gameId;
  }
    function tokenDescription(uint256 tokenId) public view  returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].description;
  }
    function fetchNFTs(address _owner,uint256 page,uint256 size) public view returns(ItemPage memory) {
        uint itemCount = _tokenIds.current();
        uint myItemCount = 0;
        uint currentIndex = 0;
        uint256 startNum=page*size;
        uint256 count=size;
         for(uint i = 1; i < itemCount+1; i++) {
                if(ownerOf(i) ==_owner&&marketplace.getIsActive(i)) {
                    myItemCount += 1;
                }
            }
       if(startNum>=itemCount)return ItemPage({total:myItemCount,itemList:new Item[](0)}); 
        if(count==0)return ItemPage({total:myItemCount,itemList:new Item[](0)}); 
        if(count>myItemCount-startNum){
          count=myItemCount-startNum;
        }
        Item[] memory ownerItem = new Item[](count);
        for(uint i = 1; i < itemCount+1; i++) {
            if(ownerOf(i) == _owner&&marketplace.getIsActive(i)) {
              if(currentIndex<startNum)
              {
                 currentIndex += 1;
                continue;
              }
                if(currentIndex>=startNum+count)break;
                ownerItem[currentIndex-startNum] = Items[i]; 
                currentIndex += 1;
            }
        } 
        return ItemPage({total:myItemCount,itemList:ownerItem}); 
    }
  function setMarketplace(GameMarketplace market) public {
     require(msg.sender ==ownerAddress, "ERC721URIStorage: Is not owner");
     marketplace = market;
     
  }
   modifier IsOwnerAddress(){
    require(ownerAddress == msg.sender, "ERC721:Is not contract owner");
    _;
  }
 modifier OnlyItemOwner(uint256 tokenId){
    require(ownerOf(tokenId) == msg.sender, "ERC721:Sender does not own the item");
    _;
  }
   function putItemForSale(uint256 tokenId, uint256 price) 
    OnlyItemOwner(tokenId) 
    external 
    returns (uint256){
      price=price*(10 ** 18);
      uint256 result=  marketplace.putItemForSale(tokenId,price,msg.sender);
      approve(address(marketplace), tokenId);
      emit itemAddedForSale(result, tokenId, price);
      return result;
  }
  function getOwner()
  public view returns (address){
      return ownerAddress;
  }
}