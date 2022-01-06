// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721URIStorage.sol";
import "./Counters.sol";
import "./ArtMarketplace.sol";

contract ArtToken is ERC721Enumerable{
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  ArtMarketplace private marketplace;
  address public ownerAddress;
  struct Item {
    uint256 id;
    address creator;
    string uri;//metadata url
    string category;
    string title;
    string description;
  }
  struct ItemPage {
    uint256 total;
    Item[] itemList;
  }
  mapping(uint256 => Item) public Items; //id => Item

  constructor () ERC721("ArtToken", "ARTK") {
     ownerAddress=msg.sender;
  }
 event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
  function mint(string memory uri,string memory category,string memory title,string memory description) public returns (uint256){
    _tokenIds.increment();
    uint256 newItemId = _tokenIds.current();
    _safeMint(msg.sender, newItemId);
    // approve(marketplace, newItemId);

    Items[newItemId] = Item({
      id: newItemId, 
      creator: msg.sender,
      uri: uri,
      category:category,
      title:title,
      description:description
    });

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
  function tokenCategory(uint256 tokenId) public view  returns (string memory) {
    require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");
    return Items[tokenId].category;
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
     function setMarketplace(ArtMarketplace market) public {
     require(msg.sender ==ownerAddress, "ERC721URIStorage: Is not owner");
     marketplace = market;
     
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

}