/**
 *Submitted for verification at polygonscan.com on 2022-01-19
*/

// File: nft_main.sol


pragma solidity ^0.8.0;
  interface ERC721Interface {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


contract NFTMARKET {
    uint256 listId;
    ERC721Interface ERC721;
    struct List
    {
        bool status;        
        uint256 price;
        uint256 quantity;
    }
    mapping(uint256=>List) listing;
    
    event Listed(uint256 token_id,uint256 price,uint256 quantity);

    constructor(ERC721Interface _ERC721) public
    {
       ERC721=_ERC721;
    }

    function listToken(uint256 token_id,uint256 _price,uint256 _quantity) public  
    {
        require(msg.sender == ERC721.ownerOf(token_id),"ERC721: caller is not owner of token");
        List memory list = List({
            status:true,
            price:_price,
            quantity:_quantity
        });
        
        listing[token_id] = list;
        emit Listed(token_id,_price,_quantity);
    }



    function buyToken(uint256 token_id) public payable
    {
        require(msg.value==listing[token_id].price,"Insufficient Amount");
        require(listing[token_id].status,"Token Sold");
        require(ERC721.ownerOf(token_id)!=msg.sender,"Self buy not allowed");
        ERC721.transferFrom(ERC721.ownerOf(token_id),msg.sender,token_id);
    }

    function withdrawBalance(address payable walletAddr) public
    {
        walletAddr.transfer(address(this).balance);
    }

}