/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

pragma solidity 0.8.0;

abstract contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) virtual public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) virtual public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) virtual public returns(bool);
  function approve(address _to, uint256 _tokenId) virtual public returns(bool);
  function takeOwnership(uint256 _tokenId) virtual public;

}

contract MyNFT is ERC721 {
  //token名称
  string public name = "MyNFT Token";
  //token symbol
  string public symbol = "MyNFT";
  //总供应量
  uint private _totalSupply = 10000;
  //存放token
  mapping(uint256 => bool) tokenExists;
  //token拥有者
  mapping(uint256 => address) ownerToken;
  //拥有token数量
  mapping(address => uint256) balances;
  mapping(address => mapping(uint256 => int)) ownerTokens;
  //token属性
  struct MyNFTAttr {
   uint256 tokenId;
   uint256 imageId;
  }
  mapping(uint256 => MyNFTAttr) tokens;
  address private admin;
  
  mapping(address => mapping(address => uint256)) allowed;
  
  modifier isAdmin {
      require(msg.sender == admin);
      _;
  }
  
  constructor() {
      admin = msg.sender;
  }
  
  function balanceOf(address _owner) virtual override public view returns (uint256 _balance) {
      return balances[_owner];
  }
  
  function ownerOf(uint256 _tokenId) virtual override public view returns (address _owner) {
      require(tokenExists[_tokenId],"not ownerOf");
      return ownerToken[_tokenId];
  }

  //铸造token
  function mint(uint256 _tokenId,uint256 _imageId) public returns(bool) {
      require(!tokenExists[_tokenId],"token not found");
      tokenExists[_tokenId] = true;
      ownerToken[_tokenId] = msg.sender;
      balances[msg.sender] += 1; 
      tokens[_tokenId] = MyNFTAttr(_tokenId,_imageId);
      ownerTokens[msg.sender][_tokenId] += 1;
      return true;
  }
  
  function totalSupply() public view returns (uint){
    return _totalSupply;
  }
  
  function approve(address _to, uint256 _tokenId) override public returns(bool) {
    require(msg.sender == ownerOf(_tokenId),"not auth");
    require(msg.sender != _to,"address same");
   
    allowed[msg.sender][_to] = _tokenId;
    emit Approval(msg.sender, _to, _tokenId);
    return true;
  }
  
  function transfer(address _to,uint256 _tokenId) override public returns(bool) {
      require(tokenExists[_tokenId],"token not found");
      require(msg.sender == ownerOf(_tokenId),"not ownerOf");
      require(msg.sender != _to,"address same");
      require(_to != address(0),"0 address");
      
      ownerTokens[msg.sender][_tokenId] -= 1;
      ownerTokens[_to][_tokenId] += 1;
      
      ownerToken[_tokenId] = _to;
      
      balances[msg.sender] -= 1;
      balances[_to] += 1;
      
      emit Transfer(msg.sender,_to,_tokenId);
      return true;
  }
  
  function takeOwnership(uint256 _tokenId) override public {
     require(tokenExists[_tokenId],"token not found");
     address oldOwner = ownerOf(_tokenId);
     address newOwner = msg.sender;
     require(newOwner != oldOwner,"address same");
     require(allowed[oldOwner][newOwner] == _tokenId,"not approve");
     balances[oldOwner] -= 1;
     ownerToken[_tokenId] = newOwner;
     balances[newOwner] += 1;
     emit Transfer(oldOwner, newOwner, _tokenId);
  }
}