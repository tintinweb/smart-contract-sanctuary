/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.6;

contract ERC721 {
    
   string  private tokenName = "My ERC721 Token";
   string  private tokenSymbol = "MET";
   uint256  private totalTokens = 1000000;
   mapping(address => uint256) private balances;
   mapping(uint256 => address) private tokenOwners;
   mapping(uint256 => bool) private tokenExists;
   mapping(address => mapping (address => uint256)) private allowed;
   mapping(address => mapping(uint256 => uint256)) private ownerTokens;
   mapping(uint256 => string) tokenLinks;
   
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
   
   function removeFromTokenList(address owner, uint256 _tokenId) private {
     for(uint256 i = 0;ownerTokens[owner][i] != _tokenId;i++){
       ownerTokens[owner][i] = 0;
     }
   }
   
   function name() public view returns (string memory){
       return tokenName;
   }
   
   function symbol() public view returns (string memory) {
       return tokenSymbol;
   }
   
   function totalSupply() public view returns (uint256){
       return totalTokens;
   }
   
   function balanceOf(address _owner) public view returns (uint){
       return balances[_owner];
   }
   
   function ownerOf(uint256 _tokenId) public view returns (address) {
       require(tokenExists[_tokenId]);
       return tokenOwners[_tokenId];
   }
   
   function approve(address _to, uint256 _tokenId) public {
       require(msg.sender == ownerOf(_tokenId));
       require(msg.sender != _to);
       allowed[msg.sender][_to] = _tokenId;
       emit Approval(msg.sender, _to, _tokenId);
   }
   
   function takeOwnership(uint256 _tokenId) public {
       require(tokenExists[_tokenId]);
       address oldOwner = ownerOf(_tokenId);
       address newOwner = msg.sender;
       require(newOwner != oldOwner);
       require(allowed[oldOwner][newOwner] == _tokenId);
       balances[oldOwner] -= 1;
       tokenOwners[_tokenId] = newOwner;
       balances[oldOwner] += 1;
       emit Transfer(oldOwner, newOwner, _tokenId);
   }
   
   function transfer(address _to, uint256 _tokenId) public {
       address currentOwner = msg.sender;
       address newOwner = _to;
       require(tokenExists[_tokenId]);
       require(currentOwner == ownerOf(_tokenId));
       require(currentOwner != newOwner);
       require(newOwner != address(0));
       removeFromTokenList(msg.sender, _tokenId);
       balances[currentOwner] -= 1;
       tokenOwners[_tokenId] = newOwner;
       balances[newOwner] += 1;
       emit Transfer(currentOwner, newOwner, _tokenId);
   }
   
   function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint tokenId) {
       return ownerTokens[_owner][_index];
   }
   
   function tokenMetadata(uint256 _tokenId) public view returns (string memory infoUrl){
       return tokenLinks[_tokenId];
   }
}