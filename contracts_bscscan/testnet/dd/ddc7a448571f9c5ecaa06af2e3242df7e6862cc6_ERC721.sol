/**
 *Submitted for verification at BscScan.com on 2021-12-23
*/

pragma solidity ^0.4.19;

contract ERC721 {
    string constant author = "  Huanqiu Huang";
   string constant private tokenName = "My ERC721 Token";
   string constant private tokenSymbol = "MET";
   uint256 constant private totalTokens = 1;
   mapping(address => uint) private balances;
   mapping(uint256 => address) private tokenOwners;
   mapping(uint256 => bool) private tokenExists;
   mapping(address => mapping (address => uint256)) private allowed;
   mapping(address => mapping(uint256 => uint256)) private ownerTokens;
   
   mapping(uint256 => string) tokenLinks;

   address owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

   function createToken(address _owner, uint _tokenId, string _uri){
       require(!tokenExists[_tokenId]);
       require(_tokenId <= totalTokens);
        balances[_owner] += 1;
        tokenOwners[_tokenId] = _owner;
        tokenExists[_tokenId] = true;
        ownerTokens[_owner][0] = _tokenId;
        tokenLinks[_tokenId] = _uri;
   }



   function removeFromTokenList(address owner, uint256 _tokenId) private {
     for(uint256 i = 0;ownerTokens[owner][i] != _tokenId;i++){
       ownerTokens[owner][i] = 0;
     }
   }
   function name() public constant returns (string){
       return tokenName;
   }
   function symbol() public constant returns (string) {
       return tokenSymbol;
   }
   function totalSupply() public constant returns (uint256){
       return totalTokens;
   }
   function balanceOf(address _owner) constant returns (uint){
       return balances[_owner];
   }
   function ownerOf(uint256 _tokenId) constant returns (address){
       require(tokenExists[_tokenId]);
       return tokenOwners[_tokenId];
   }
   function approve(address _to, uint256 _tokenId){
       require(msg.sender == ownerOf(_tokenId));
       require(msg.sender != _to);
       allowed[msg.sender][_to] = _tokenId;
       Approval(msg.sender, _to, _tokenId);
   }
   function takeOwnership(uint256 _tokenId){
       require(tokenExists[_tokenId]);
       address oldOwner = ownerOf(_tokenId);
       address newOwner = msg.sender;
       require(newOwner != oldOwner);
       require(allowed[oldOwner][newOwner] == _tokenId);
       balances[oldOwner] -= 1;
       tokenOwners[_tokenId] = newOwner;
       balances[oldOwner] += 1;
       Transfer(oldOwner, newOwner, _tokenId);
   }
   function transfer(address _to, uint256 _tokenId){
       address currentOwner = msg.sender;
       address newOwner = _to;
       require(tokenExists[_tokenId]);
       require(currentOwner == ownerOf(_tokenId));
       require(currentOwner != newOwner);
       require(newOwner != address(0));
       //removeFromTokenList(_tokenId);
       balances[currentOwner] -= 1;
       tokenOwners[_tokenId] = newOwner;
       balances[newOwner] += 1;
       Transfer(currentOwner, newOwner, _tokenId);
   }
   function tokenOfOwnerByIndex(address _owner, uint256 _index) constant returns (uint tokenId){
       return ownerTokens[_owner][_index];
   }
   function tokenMetadata(uint256 _tokenId) constant returns (string infoUrl){
       return tokenLinks[_tokenId];
   }
   event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
   event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
}