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
    require(c >= a, "SafeMath: addition overflow");
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath: subtraction overflow");
    uint256 c = a - b;
    return c;
  }
}
library Counters {
  using SafeMath for uint256;
    struct Counter {
    uint256 _value;
  }
  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }
  function increment(Counter storage counter) internal {
    counter._value += 1;
  }
  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
  }
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
interface iERC721 {
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  //event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  //event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function transferFrom(address from, address to, uint256 tokenId) external;
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) external;
  //function balanceOf(address owner) external view returns (uint256 balance);
  //function approve(address to, uint256 tokenId) external;
  //function getApproved(uint256 tokenId) external view returns (address operator);
  //function setApprovalForAll(address operator, bool _approved) external;
  //function isApprovedForAll(address owner, address operator) external view returns (bool);
}
interface iERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data) external returns (bytes4);
}
contract cERC721 is cERC165, iERC721 {
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;
  mapping (uint256 => address) private _tokenOwner;
  mapping (uint256 => address) private _tokenApprovals;
  mapping (address => Counters.Counter) private _ownedTokensCount;
  mapping (address => mapping (address => bool)) private _operatorApprovals;
  constructor () { supportedInterfaces[0x5b5e139f] = true; }
  function ownerOf(uint256 tokenId) public override view returns (address) {
    address owner = _tokenOwner[tokenId];
    require(owner != address(0), "ERC721: owner query for nonexistent token");
    return owner;
  }
  function transferFrom(address from, address to, uint256 tokenId) public override {
    //require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
    _transferFrom(from, to, tokenId);
  }
  function safeTransferFrom(address from, address to, uint256 tokenId) public override {
    safeTransferFrom(from, to, tokenId, "");
  }
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
    transferFrom(from, to, tokenId);
    require(_checkOnERC721Received(from, to, tokenId, _data), "Fire in the hole.");
  }
  function _exists(uint256 tokenId) internal view returns (bool) {
    address owner = _tokenOwner[tokenId];
    return owner != address(0);
  }
  function _mint(address to, uint256 tokenId) internal {
    require(to != address(0), "Zero gravity.");
    require(!_exists(tokenId), "Already wasted.");
    _tokenOwner[tokenId] = to;
    _ownedTokensCount[to].increment();
    emit Transfer(address(0), to, tokenId);
  }
  function _burn(address owner, uint256 tokenId) internal {
    require(ownerOf(tokenId) == owner, "Now your ships are burned.");
    _clearApproval(tokenId);
    _ownedTokensCount[owner].decrement();
    _tokenOwner[tokenId] = address(0);
    emit Transfer(owner, address(0), tokenId);
  }
  function _burn(uint256 tokenId) internal {
    _burn(ownerOf(tokenId), tokenId);
  }
  function _transferFrom(address from, address to, uint256 tokenId) internal {
    require(ownerOf(tokenId) == from, "Whats Up.");
    require(to != address(0), "Zero gravity.");
    _clearApproval(tokenId);
    _ownedTokensCount[from].decrement();
    _ownedTokensCount[to].increment();
    _tokenOwner[tokenId] = to;
    emit Transfer(from, to, tokenId);
  }
  function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
    if (!to.isContract()) {
      return true;
    }
    bytes4 retval = iERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
    return (retval == 0x150b7a02);
  }
  function _clearApproval(uint256 tokenId) private {
    if (_tokenApprovals[tokenId] != address(0)) {
      _tokenApprovals[tokenId] = address(0);
    }
  }
}
contract MyERC721 is cERC721 {
  struct sIdiot {
    string name;
    uint256 level;
  }
  sIdiot[] public Idiots;
  address public owner;
  constructor () { owner = msg.sender; }
  function mintCard(string memory name, address account) public {
    require(owner == msg.sender);
    uint256 IdiotId = Idiots.length;
    Idiots.push(sIdiot(name, 1));
    _mint(account, IdiotId); // Mint a new card
  }
}