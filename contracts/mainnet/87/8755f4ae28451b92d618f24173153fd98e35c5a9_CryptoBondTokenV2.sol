/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

// ----------------------------------------------------------------------------
// --- Crypto Bonds - www.cryptobondtoken.com
// --- Symbol      : Format - {CompanyBondType}
// --- Name        : Crypto Bond Token
// --- Total supply: Generated from minter accounts
// --- @title for 01101101 01111001 01101100 01101111 01110110 01100101
// --- (c) CryptoBondTeam - 2018-2021
// --- @dev pragma solidity version:0.4.24+commit.1d4f565a
// --- SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

pragma solidity ^0.4.24;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {

    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;
    return c;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

interface IERC165 {

  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool);
}

interface ICryptoBondToken {

  function name() external pure returns (string _name);
  function symbol() external pure returns (string _symbol);
  function isWhitelisted(address _creator) external view returns (bool);
  function tokenURI(uint256 _tokenId) external view returns (string);
  function creatorOfToken(uint256 _tokenId) external view returns (address);
  function totalSupply() external view returns (uint256);
}

// ----------------------------------------------------------------------------
// --- Contract IERC721 Receiver
// ----------------------------------------------------------------------------

contract IERC721Receiver {

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  )
    public
    returns(bytes4);
}

// ----------------------------------------------------------------------------
// --- Contract IERC721
// ----------------------------------------------------------------------------

contract IERC721 is IERC165 {

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  function balanceOf(address owner) public view returns (uint256 balance);
  function ownerOf(uint256 tokenId) public view returns (address owner);

  function approve(address to, uint256 tokenId) public;
  function getApproved(uint256 tokenId)
    public view returns (address operator);

  function setApprovalForAll(address operator, bool _approved) public;
  function isApprovedForAll(address owner, address operator)
    public view returns (bool);

  function transferFrom(address from, address to, uint256 tokenId) public;
  function safeTransferFrom(address from, address to, uint256 tokenId)
    public;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes data
  )
    public;
}

// ----------------------------------------------------------------------------
// --- Contract IERC721 Creator
// ----------------------------------------------------------------------------

contract IERC721Creator is IERC721 {

    function tokenCreator(uint256 _tokenId) public view returns (address);
}

// ----------------------------------------------------------------------------
// --- Contract IERC721 Metadata
// ----------------------------------------------------------------------------

contract IERC721Metadata is IERC721 {
  function name() external view returns (string);
  function symbol() external view returns (string);
  function tokenURI(uint256 tokenId) external view returns (string);
}

// ----------------------------------------------------------------------------
// --- Contract IERC721 Enumerable
// ----------------------------------------------------------------------------

contract IERC721Enumerable is IERC721 {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256 tokenId);

  function tokenByIndex(uint256 index) public view returns (uint256);
}

// ----------------------------------------------------------------------------
// --- Library Address
// ----------------------------------------------------------------------------

library Address {

  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }

}

// ----------------------------------------------------------------------------
// --- Contract ERC165
// ----------------------------------------------------------------------------

contract ERC165 is IERC165 {

  bytes4 private constant _InterfaceId_ERC165 = 0x01ffc9a7;
  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor()
    internal
  {
    _registerInterface(_InterfaceId_ERC165);
  }

  function supportsInterface(bytes4 interfaceId)
    external
    view
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  function _registerInterface(bytes4 interfaceId)
    internal
  {
    require(interfaceId != 0xffffffff);
    _supportedInterfaces[interfaceId] = true;
  }
}

// ----------------------------------------------------------------------------
// --- Contract ERC721
// ----------------------------------------------------------------------------

contract ERC721 is ERC165, IERC721 {

  using SafeMath for uint256;
  using Address for address;
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
  mapping (uint256 => address) private _tokenOwner;
  mapping (uint256 => address) private _tokenApprovals;
  mapping (address => uint256) private _ownedTokensCount;
  mapping (address => mapping (address => bool)) private _operatorApprovals;
  bytes4 private constant _InterfaceId_ERC721 = 0x80ac58cd;

  constructor()
    public
  {
    _registerInterface(_InterfaceId_ERC721);
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return _ownedTokensCount[owner];
  }

  function ownerOf(uint256 tokenId) public view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0));
    return owner;
  }

  function approve(address to, uint256 tokenId) public {
    address owner = ownerOf(tokenId);
    require(to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  function getApproved(uint256 tokenId) public view returns (address) {
    require(_exists(tokenId));
    return _tokenApprovals[tokenId];
  }

  function setApprovalForAll(address to, bool approved) public {
    require(to != msg.sender);
    _operatorApprovals[msg.sender][to] = approved;
    emit ApprovalForAll(msg.sender, to, approved);
  }

  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    require(_isApprovedOrOwner(msg.sender, tokenId));
    require(to != address(0));
    _clearApproval(from, tokenId);
    _removeTokenFrom(from, tokenId);
    _addTokenTo(to, tokenId);
    emit Transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  )
    public
  {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    public
  {
    transferFrom(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data));
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }

  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(tokenId);
    return (
      spender == owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(owner, spender)
    );
  }

  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0));
    _addTokenTo(to, tokenId);
    emit Transfer(address(0), to, tokenId);
  }

  function _burn(address owner, uint256 tokenId) internal {
    _clearApproval(owner, tokenId);
    _removeTokenFrom(owner, tokenId);
    emit Transfer(owner, address(0), tokenId);
  }

  function _addTokenTo(address to, uint256 tokenId) internal {
    require(_tokenOwner[tokenId] == address(0));
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
  }

  function _removeTokenFrom(address from, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from);
    _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
    _tokenOwner[tokenId] = address(0);
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = IERC721Receiver(to).onERC721Received(
      msg.sender, from, tokenId, _data);
    return (retval == _ERC721_RECEIVED);
  }

  function _clearApproval(address owner, uint256 tokenId) private {
    require(ownerOf(tokenId) == owner);
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}

// ----------------------------------------------------------------------------
// --- Contract ERC721 Enumerable
// ----------------------------------------------------------------------------

contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {

  mapping(address => uint256[]) private _ownedTokens;
  mapping(uint256 => uint256) private _ownedTokensIndex;
  uint256[] private _allTokens;
  mapping(uint256 => uint256) private _allTokensIndex;
  bytes4 private constant _InterfaceId_ERC721Enumerable = 0x780e9d63;

  constructor() public {
    _registerInterface(_InterfaceId_ERC721Enumerable);
  }

  function tokenOfOwnerByIndex(
    address owner,
    uint256 index
  )
    public
    view
    returns (uint256)
  {
    require(index < balanceOf(owner));
    return _ownedTokens[owner][index];
  }

  function totalSupply() public view returns (uint256) {
    return _allTokens.length;
  }

  function tokenByIndex(uint256 index) public view returns (uint256) {
    require(index < totalSupply());
    return _allTokens[index];
  }

  function _addTokenTo(address to, uint256 tokenId) internal {
    super._addTokenTo(to, tokenId);
    uint256 length = _ownedTokens[to].length;
    _ownedTokens[to].push(tokenId);
    _ownedTokensIndex[tokenId] = length;
  }

  function _removeTokenFrom(address from, uint256 tokenId) internal {
    super._removeTokenFrom(from, tokenId);
    uint256 tokenIndex = _ownedTokensIndex[tokenId];
    uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
    uint256 lastToken = _ownedTokens[from][lastTokenIndex];
    _ownedTokens[from][tokenIndex] = lastToken;
    _ownedTokens[from].length--;
    _ownedTokensIndex[tokenId] = 0;
    _ownedTokensIndex[lastToken] = tokenIndex;
  }

  function _mint(address to, uint256 tokenId) internal {
    super._mint(to, tokenId);
    _allTokensIndex[tokenId] = _allTokens.length;
    _allTokens.push(tokenId);
  }

  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);
    uint256 tokenIndex = _allTokensIndex[tokenId];
    uint256 lastTokenIndex = _allTokens.length.sub(1);
    uint256 lastToken = _allTokens[lastTokenIndex];
    _allTokens[tokenIndex] = lastToken;
    _allTokens[lastTokenIndex] = 0;
    _allTokens.length--;
    _allTokensIndex[tokenId] = 0;
    _allTokensIndex[lastToken] = tokenIndex;
  }
}

// ----------------------------------------------------------------------------
// --- Contract ERC721 Metadata
// ----------------------------------------------------------------------------

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {

  string private _name;
  string private _symbol;
  mapping(uint256 => string) private _tokenURIs;

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;

  constructor(string name, string symbol) public {
    _name = name;
    _symbol = symbol;
    _registerInterface(InterfaceId_ERC721Metadata);
  }

  function name() external view returns (string) {
    return _name;
  }

  function symbol() external view returns (string) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId) external view returns (string) {
    require(_exists(tokenId));
    return _tokenURIs[tokenId];
  }

  function _setTokenURI(uint256 tokenId, string uri) internal {
    require(_exists(tokenId));
    _tokenURIs[tokenId] = uri;
  }

  function _burn(address owner, uint256 tokenId) internal {
    super._burn(owner, tokenId);

    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }
  }
}

// ----------------------------------------------------------------------------
// --- Contract Ownable
// ----------------------------------------------------------------------------

contract Ownable {
  address private _owner;
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  function owner() public view returns(address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// ----------------------------------------------------------------------------
// --- Contract Whitelist
// ----------------------------------------------------------------------------

contract Whitelist is Ownable {

    mapping(address => bool) private whitelistMap;
    bool private whitelistEnabled = true;
    event AddToWhitelist(address indexed _newAddress);
    event RemoveFromWhitelist(address indexed _removedAddress);
    function enableWhitelist(bool _enabled) public onlyOwner {
        whitelistEnabled = _enabled;
    }

    function addToWhitelist(address _newAddress) public onlyOwner {
        _whitelist(_newAddress);
        emit AddToWhitelist(_newAddress);
    }

    function removeFromWhitelist(address _removedAddress) public onlyOwner {
        _unWhitelist(_removedAddress);
        emit RemoveFromWhitelist(_removedAddress);
    }

    function isWhitelisted(address _address) public view returns (bool) {
        if (whitelistEnabled) {
            return whitelistMap[_address];
        } else {
            return true;
        }
    }

    function _unWhitelist(address _removedAddress) internal {
        whitelistMap[_removedAddress] = false;
    }

    function _whitelist(address _newAddress) internal {
        whitelistMap[_newAddress] = true;
    }
}

// ----------------------------------------------------------------------------
// --- Contract ERC721 Group
// ----------------------------------------------------------------------------

contract ERC721Group is ERC721, ERC721Enumerable, ERC721Metadata {

  constructor(string name, string symbol) ERC721Metadata(name, symbol)
    public
  {
  }
}

// ----------------------------------------------------------------------------
// --- Contract CryptoBondTokenV2
// ----------------------------------------------------------------------------

contract CryptoBondTokenV2 is ERC721Group, IERC721Creator, Ownable, Whitelist {

    using SafeMath for uint256;
    mapping(uint256 => address) private tokenCreators;
    uint256 private idCounter;
    ICryptoBondToken private oldCryptoBondToken;
    event TokenURIUpdated(uint256 indexed _tokenId, string  _uri);

    constructor(
      string _name,
      string _symbol,
      address _oldCryptoBondToken
    ) public
    ERC721Group(_name, _symbol)
    {
      oldCryptoBondToken = ICryptoBondToken(_oldCryptoBondToken);
      uint256 oldSupply = oldCryptoBondToken.totalSupply();
      idCounter = oldSupply + 1;
    }

    function initWhitelist(address[] _whitelistees) public onlyOwner {
      for (uint256 i = 0; i < _whitelistees.length; i++) {
        address creator = _whitelistees[i];
        if (!isWhitelisted(creator)) {
          _whitelist(creator);
        }
      }
    }

    modifier onlyTokenOwner(uint256 _tokenId) {
      address owner = ownerOf(_tokenId);
      require(owner == msg.sender, "must be the owner of the token");
      _;
    }

    modifier onlyTokenCreator(uint256 _tokenId) {
      address creator = tokenCreator(_tokenId);
      require(creator == msg.sender, "must be the creator of the token");
      _;
    }

    function addNewToken(string _uri) public {
      require(isWhitelisted(msg.sender), "must be whitelisted to create tokens");
      _createToken(_uri, msg.sender);
    }

    function deleteToken(uint256 _tokenId) public onlyTokenOwner(_tokenId) {
      _burn(msg.sender, _tokenId);
    }

    function updateTokenMetadata(uint256 _tokenId, string _uri)
      public
      onlyTokenOwner(_tokenId)
      onlyTokenCreator(_tokenId)
    {
      _setTokenURI(_tokenId, _uri);
      emit TokenURIUpdated(_tokenId, _uri);
    }

    function tokenCreator(uint256 _tokenId) public view returns (address) {
        return tokenCreators[_tokenId];
    }

    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
      tokenCreators[_tokenId] = _creator;
    }

    function _createToken(string _uri, address _creator) internal returns (uint256) {
      uint256 newId = idCounter;
      idCounter++;
      _mint(_creator, newId);
      _setTokenURI(newId, _uri);
      _setTokenCreator(newId, _creator);
      return newId;
    }
}