pragma solidity ^0.4.21;

/// @title Interface for contracts conforming to ERC-721: Non-Fungible Tokens
/// @author MinakoKojima (https://github.com/lychees)
contract ERC721 {
    // Required methods
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) public view returns (address owner);
    function approve(address _to, uint256 _tokenId) public;
    function transfer(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

    // Events
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

    // Optional
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    // function tokensOfOwner(address _owner) external view returns (uint256[] tokenIds);
    // function tokenMetadata(uint256 _tokenId, string _preferredTransport) public view returns (string infoUrl);

    // ERC-165 Compatibility (https://github.com/ethereum/EIPs/issues/165)
    // function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract CryptoThreeKingdoms is ERC721{

  event Bought (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Sold (uint256 indexed _tokenId, address indexed _owner, uint256 _price);
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  address private owner;
  mapping (address => bool) private admins;

  uint256[] private listedTokens;
  mapping (uint256 => address) private ownerOfToken;
  mapping (uint256 => address) private approvedOfToken;

  function CryptoThreeKingdoms() public {
    owner = msg.sender;
    admins[owner] = true;    
  }

  /* Modifiers */
  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  modifier onlyAdmins() {
    require(admins[msg.sender]);
    _;
  }

  /* Owner */
  function setOwner(address _owner) onlyOwner() public {
    owner = _owner;
  }

  function addAdmin(address _admin) onlyOwner() public {
    admins[_admin] = true;
  }

  function removeAdmin(address _admin) onlyOwner() public {
    delete admins[_admin];
  }

  /* Withdraw */
  /*
    NOTICE: These functions withdraw the developer&#39;s cut which is left
    in the contract by `buy`. User funds are immediately sent to the old
    owner in `buy`, no user funds are left in the contract.
  */
  function withdrawAll() onlyAdmins() public {
   msg.sender.transfer(address(this).balance);
  }

  function withdrawAmount(uint256 _amount) onlyAdmins() public {
    msg.sender.transfer(_amount);
  }

  /* ERC721 */

  function name() public view returns (string _name) {
    return "cryptosanguo.pro";
  }

  function symbol() public view returns (string _symbol) {
    return "CSG";
  }

  function totalSupply() public view returns (uint256 _totalSupply) {
    return listedTokens.length;
  }

  function balanceOf (address _owner) public view returns (uint256 _balance) {
    uint256 counter = 0;

    for (uint256 i = 0; i < listedTokens.length; i++) {
      if (ownerOf(listedTokens[i]) == _owner) {
        counter++;
      }
    }

    return counter;
  }

  function ownerOf (uint256 _tokenId) public view returns (address _owner) {
    return ownerOfToken[_tokenId];
  }

  function tokensOf (address _owner) public view returns (uint256[] _tokenIds) {
    uint256[] memory Tokens = new uint256[](balanceOf(_owner));

    uint256 TokenCounter = 0;
    for (uint256 i = 0; i < listedTokens.length; i++) {
      if (ownerOf(listedTokens[i]) == _owner) {
        Tokens[TokenCounter] = listedTokens[i];
        TokenCounter += 1;
      }
    }

    return Tokens;
  }

  function approvedFor(uint256 _tokenId) public view returns (address _approved) {
    return approvedOfToken[_tokenId];
  }

  function approve(address _to, uint256 _tokenId) public {
    require(msg.sender != _to);
    require(ownerOf(_tokenId) == msg.sender);

    if (_to == 0) {
      if (approvedOfToken[_tokenId] != 0) {
        delete approvedOfToken[_tokenId];
        emit Approval(msg.sender, 0, _tokenId);
      }
    } else {
      approvedOfToken[_tokenId] = _to;
      emit Approval(msg.sender, _to, _tokenId);
    }
  }

  /* Transferring a country to another owner will entitle the new owner the profits from `buy` */
  function transfer(address _to, uint256 _tokenId) public {
    require(msg.sender == ownerOf(_tokenId));
    _transfer(msg.sender, _to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(approvedFor(_tokenId) == msg.sender);
    _transfer(_from, _to, _tokenId);
  }

  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    require(_to != address(0));
    require(_to != address(this));

    ownerOfToken[_tokenId] = _to;
    approvedOfToken[_tokenId] = 0;

    emit Transfer(_from, _to, _tokenId);
  }

  /* Read */
  function getListedTokens() public view returns (uint256[] _Tokens) {
    return listedTokens;
  }
  
  function isAdmin(address _admin) public view returns (bool _isAdmin) {
    return admins[_admin];
  }

  /* Issue */  
  function issueToken(uint256 l, uint256 r) onlyAdmins() public {
    for (uint256 i = l; i <= r; i++) {
      if (ownerOf(i) == address(0)) {
        ownerOfToken[i] = msg.sender;
        listedTokens.push(i);
      }
    }      
  }
  function issueTokenAndTransfer(uint256 l, uint256 r, address to) onlyAdmins() public {
    for (uint256 i = l; i <= r; i++) {
      if (ownerOf(i) == address(0)) {
        ownerOfToken[i] = to;
        listedTokens.push(i);
      }
    }      
  }     
  function issueTokenAndApprove(uint256 l, uint256 r, address to) onlyAdmins() public {
    for (uint256 i = l; i <= r; i++) {
      if (ownerOf(i) == address(0)) {
        ownerOfToken[i] = msg.sender;
        approve(to, i);
        listedTokens.push(i);
      }
    }          
  }    
}