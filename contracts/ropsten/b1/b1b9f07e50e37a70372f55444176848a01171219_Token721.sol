/**
 *Submitted for verification at Etherscan.io on 2021-04-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface ERC721{
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
      function safeTransferFrom(address _from, address _to, uint256 _tokenId) external ;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function approve(address _approved, uint256 _tokenId) external payable;
    function setApprovalForAll(address _operator, bool _approved) external;
    function getApproved(uint256 _tokenId) external view returns (address);
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC721Metadata{
     function name() external view returns (string memory);
     function symbol() external view returns (string memory);
     function tokenURI(uint256 _tokenId) external view returns (string memory);
}



contract Token721 is ERC721,ERC721Metadata{
 
    string tokenName ;
    string tokenSymbol ;
    mapping (uint256 => string) tokenUris;
    // uint256 tokenId = 0;
    
    struct Token {
        address mintedBy;
        uint256 mintedAt;
    }
    
    Token[] tokens;
    
    mapping (uint256 => address) private _tokenOwner;
    mapping (uint256 => address) private _tokenApprovals;
    mapping (address => uint256) private _ownedTokensCount;
    mapping (address => mapping (address => bool)) private _operatorApprovals;
    
     event Mint(address owner, uint256 tokenId);
   
    
   constructor (string memory _name, string memory _symbol){
        
        tokenName = _name;
        tokenSymbol = _symbol;
      
     
    }
     function balanceOf(address _owner) external override view returns (uint256){
         
         require(_owner != address(0),"Invalid Owner address");
         return _ownedTokensCount[_owner];
         
     }
     
    function ownerOf(uint256 _tokenId) public override view returns (address){
       
        require(isTokenExist(_tokenId),"Token Not Exist");
         return  _tokenOwner[_tokenId];
    }
   
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external override{
        require(isApprovedOrOwner(msg.sender,_tokenId), "You are not allowed to transfer token");
        transferFrom(_from,_to,_tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public override{
      
        if(_from != address(0)){
            _ownedTokensCount[_from] -= 1;
            delete _tokenApprovals[_tokenId];
        }
        
        _ownedTokensCount[_to] += 1;
        _tokenOwner[_tokenId] = _to;
        
        emit Transfer(_from,_to,_tokenId);
        
    }
    function approve(address _to, uint256 _tokenId) public override payable{
     
        require(ownerOf(_tokenId) == msg.sender, "Only Token Owner can give approval");
        _tokenApprovals[_tokenId]= _to;
        emit Approval(msg.sender,_to,_tokenId);
    }
    function setApprovalForAll(address _operator, bool _approved) external override {
        require(_operator != msg.sender, "Invalid approval address");
        _operatorApprovals[msg.sender][_operator]= _approved;
        emit ApprovalForAll(msg.sender,_operator,_approved);
        
    }
    function getApproved(uint256 _tokenId) public override view returns (address){
        address _owner= _tokenApprovals[_tokenId];
        require(isTokenExist(_tokenId),"Invalid Token Id");
        return _owner;
    }
    function isApprovedForAll(address _owner, address _operator) public override view returns (bool){
        return _operatorApprovals[_owner][_operator];
        
    }
    
    function isTokenExist(uint256 _tokenId) public view returns (bool){
        return _tokenOwner[_tokenId] != address(0);
    }
    
    function isApprovedOrOwner(address _sender, uint256 _tokenId) internal view returns (bool){
        require(isTokenExist(_tokenId),"Invalid Token id");
        address _owner= ownerOf(_tokenId);
        
        return (_owner == _sender || isApprovedForAll(_owner,_sender) || getApproved(_tokenId) == _sender);
        
    }
    
    function _mint(address _owner) internal returns(uint256 tokenId){
        require(_owner != address(0),"Invalid  address" );
        
        Token memory token =Token(_owner, block.timestamp);
        tokens.push(token);
        tokenId = tokens.length - 1 ;
        transferFrom(address(0),_owner,tokenId);
        emit Mint(_owner,tokenId);
        
    }
    
    function mintToken(address owner) external returns (uint256){
        return _mint(owner);
    }
    
    function totalSupply() external view returns (uint256){
        return tokens.length;
    }
    
    function getToken(uint256 tokenId) external view returns(address mintedBy, uint256 mintedAt)
    {
         Token memory token = tokens[tokenId];

            mintedBy = token.mintedBy;
            mintedAt = token.mintedAt;
    }
   
     function name() external view override returns (string memory){
         return tokenName;
         
     }
     function symbol() external view override returns (string memory){
         return tokenSymbol;
     }
     function tokenURI(uint256 _tokenId) external view override returns (string memory){
          require(isTokenExist(_tokenId),"Invalid Token Id");
         return tokenUris[_tokenId];
         
     }
     
     function setTokenUri(uint256 _tokenId,string memory _uri)external {
        require(isTokenExist(_tokenId),"Invalid Token Id");
         tokenUris[_tokenId]= _uri;
     }
}