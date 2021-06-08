/**
 *Submitted for verification at Etherscan.io on 2021-06-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;
library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}
library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    uint256 c = a - b;
    return c;
  }
}
library R2D2 {
  function random() public view returns (uint256) {
    //return uint8(uint256(keccak256(block.timestamp, block.difficulty))%251);
    return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 289;
  }
}
interface iERC721
{
  event Transfer( address indexed _from, address indexed _to, uint256 indexed _tokenId );
  event Approval( address indexed _owner, address indexed _approved, uint256 indexed _tokenId );
  event ApprovalForAll( address indexed _owner, address indexed _operator, bool _approved );
  function ownerOf( uint256 _tokenId ) external view returns (address);
  function balanceOf( address _owner ) external view returns (uint256);
  function transferFrom( address _from, address _to, uint256 _tokenId ) external;
  function safeTransferFrom( address _from,  address _to, uint256 _tokenId, bytes calldata _data ) external;
  function safeTransferFrom( address _from, address _to, uint256 _tokenId ) external;
  function approve( address _approved, uint256 _tokenId ) external;
  function getApproved( uint256 _tokenId ) external view returns (address);
  function isApprovedForAll( address _owner, address _operator ) external view returns (bool);
  function setApprovalForAll( address _operator, bool _approved ) external;
}
interface iERC721Meta
{
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function payload() external view returns (string memory _payload);
  function tokenURI(uint256 _tokenId) external view returns (string memory);
}
interface iERC721Receiver
{
  function onERC721Received( address _operator, address _from, uint256 _tokenId, bytes calldata _data ) external returns(bytes4);
}
interface iERC165
{
  function supportsInterface( bytes4 _interfaceID ) external view returns (bool);
}
contract cERC165 is iERC165
{
  mapping(bytes4 => bool) internal supportedInterfaces;
  constructor() { supportedInterfaces[0x01ffc9a7] = true; }
  function supportsInterface( bytes4 _interfaceID ) external override view returns (bool) { return supportedInterfaces[_interfaceID]; }
}
contract NFToken is iERC721, cERC165
{
  using Address for address;
  using SafeMath for uint256;
  mapping (uint256 => address) internal idToOwner;
  mapping (uint256 => address) internal idToApproval;
  mapping (address => uint256) private ownerToNFTokenCount;
  mapping (address => mapping (address => bool)) internal ownerToOperators;
  modifier canOperate( uint256 _tokenId ) {
    address tokenOwner = idToOwner[_tokenId];
    require( tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], "frozen" );
    _;
  }
  modifier canTransfer( uint256 _tokenId ) {
    address tokenOwner = idToOwner[_tokenId];
    require( tokenOwner == msg.sender || idToApproval[_tokenId] == msg.sender || ownerToOperators[tokenOwner][msg.sender], "frozen" );
    _;
  }
  modifier validNFToken( uint256 _tokenId ) {
    require(idToOwner[_tokenId] != address(0), "invalid");
    _;
  }
  constructor() { supportedInterfaces[0x80ac58cd] = true; }
  function ownerOf( uint256 _tokenId ) external override view returns (address _owner) {
    _owner = idToOwner[_tokenId];
    require(_owner != address(0), "invalid");
  }
  function balanceOf( address _owner ) external override view returns (uint256) {
    require(_owner != address(0), "zero");
    return _getOwnerNFTCount(_owner);
  }
  function transferFrom( address _from, address _to, uint256 _tokenId ) external override canTransfer(_tokenId) validNFToken(_tokenId)  {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, "whoru");
    require(_to != address(0), "zero");
    _transfer(_to, _tokenId);
  }
  function safeTransferFrom( address _from, address _to, uint256 _tokenId ) external override {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }
  function safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes calldata _data ) external override {
    _safeTransferFrom(_from, _to, _tokenId, _data);
  }
  function approve( address _approved, uint256 _tokenId ) external override canOperate(_tokenId) validNFToken(_tokenId) {
  	address tokenOwner = idToOwner[_tokenId];
    require(_approved != tokenOwner, "whoru");
    idToApproval[_tokenId] = _approved;
    emit Approval(tokenOwner, _approved, _tokenId);
  }
  function getApproved( uint256 _tokenId ) external override view validNFToken(_tokenId) returns (address) {
    return idToApproval[_tokenId];
  }
  function isApprovedForAll( address _owner, address _operator ) external override view returns (bool) {
    return ownerToOperators[_owner][_operator];
  }
  function setApprovalForAll( address _operator, bool _approved ) external override {
    ownerToOperators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }
  function _mint( address _to, uint256 _tokenId ) internal virtual {
    require(_to != address(0), "zero");
    require(idToOwner[_tokenId] == address(0), "already");
    _addNFToken(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }
  function _burn( uint256 _tokenId ) internal virtual validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(tokenOwner, _tokenId);
    emit Transfer(tokenOwner, address(0), _tokenId);
  }
  function _transfer( address _to, uint256 _tokenId ) internal {
    address from = idToOwner[_tokenId];
    _clearApproval(_tokenId);
    _removeNFToken(from, _tokenId);
    _addNFToken(_to, _tokenId);
    emit Transfer(from, _to, _tokenId);
  }
  function _clearApproval( uint256 _tokenId ) private { delete idToApproval[_tokenId]; }
  function _safeTransferFrom( address _from, address _to, uint256 _tokenId, bytes memory _data ) private canTransfer(_tokenId) validNFToken(_tokenId) {
    address tokenOwner = idToOwner[_tokenId];
    require(tokenOwner == _from, "whoru");
    require(_to != address(0), "zero");
    _transfer(_to, _tokenId);
    if (_to.isContract()) {
      bytes4 retval = iERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
      require(retval == 0x150b7a02, "receipt");
    }
  }
  function _removeNFToken( address _from, uint256 _tokenId ) internal virtual {
    require(idToOwner[_tokenId] == _from, "whoru");
    ownerToNFTokenCount[_from].sub(1);
    delete idToOwner[_tokenId];
  }
  function _addNFToken( address _to, uint256 _tokenId ) internal virtual {
    require(idToOwner[_tokenId] == address(0), "already");
    idToOwner[_tokenId] = _to;
    ownerToNFTokenCount[_to].add(1);
  }
  function _getOwnerNFTCount( address _owner ) internal virtual view returns (uint256) {
    return ownerToNFTokenCount[_owner];
  }
}
contract NFTokenMeta is NFToken, iERC721Meta {
  string internal nftName;
  string internal nftSymbol;
  string internal nftPayload;
  mapping (uint256 => string) internal idToUri;
  constructor() { supportedInterfaces[0x5b5e139f] = true; }
  function name() external override view returns (string memory _name) { _name = nftName; }
  function symbol() external override view returns (string memory _symbol) { _symbol = nftSymbol; }
  function payload() external override view returns (string memory _payload) { _payload = nftPayload; }
  function tokenURI( uint256 _tokenId ) external override view validNFToken(_tokenId) returns (string memory) { return idToUri[_tokenId]; }
  function _burn( uint256 _tokenId ) internal override virtual { super._burn(_tokenId); delete idToUri[_tokenId]; }
  function _setTokenUri( uint256 _tokenId, string memory _uri ) internal validNFToken(_tokenId) { idToUri[_tokenId] = _uri; }
}
contract OwnEnemy
{
  address public owner;
  event OwnershipTransferred( address indexed prevOwner, address indexed newOwner );
  constructor() { owner = msg.sender; }
  modifier onlyOwner() { require(msg.sender == owner, "whoru"); _; }
  function transferOwnership( address _newOwner ) public onlyOwner {
    require(_newOwner != address(0), "zero");
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}
contract InstaPayNFT is NFTokenMeta, OwnEnemy {
  constructor() { nftName = "InstaPay NFT"; nftSymbol = "IPNFT";  }
  function mint( address _to, uint256 _tokenId, string calldata _uri ) external onlyOwner { 
    super._mint(_to, _tokenId); super._setTokenUri(_tokenId, _uri);
  }
}