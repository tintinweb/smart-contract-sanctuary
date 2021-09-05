// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SafeMath.sol";

import "./ERC721Tradable.sol";


contract Land is ERC721Tradable {
  using SafeMath for uint256;

  // Address of the primary sale logic contract
  address public logicContractAddress;

  // Maximum number of land tokens available
  uint256 private _maxSupply;

  // URI for the contract-level metadata
  string private _contractURI;
  // URI for the token metadata
  string private _tokenURI;

  // Add this modifier to all functions which are only accessible by the logic contract
  modifier onlyLogic() {
    require(msg.sender == logicContractAddress, "Unauthorized Access");
    _;
  }

  constructor (
    string memory _name,
    string memory _symbol,
    uint256 _supply,
    string memory _cURI,
    string memory _tURI,
    address _proxyRegistryAddress
  ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
    _maxSupply = _supply;
    _contractURI = _cURI;
    _tokenURI = _tURI;
  }

  // Using a placeholder to conform with the parent contract since it's not actually being used
  function baseTokenURI() override public pure returns (string memory) {
    return "";
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Overriding the getter since all lands share the same token URI while conforming to OpenSea's method signature
  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    return _tokenURI;
  }

  function setContractURI(string memory _cURI) external onlyOwner {
    _contractURI = _cURI;
  }

  function setTokenURI(string memory _tURI) external onlyOwner {
    _tokenURI = _tURI;
  }

  function setLogicContract(address _newAddress) external onlyOwner {
    require(_newAddress != address(0), "Invalid Address");
    logicContractAddress = _newAddress;
  }

  function maximumSupply() external view returns (uint256) {
    return _maxSupply;
  }

  // Mint new tokens to the specified address and token amount
  function mintToken(address _account, uint256 _count) external onlyLogic {
    require(_account != address(0), "Invalid Address");
    require(_maxSupply >= totalSupply() + _count, "All Tokens Have Been Minted");

    for (uint8 i = 0; i < _count; i++) {
      uint256 tokenId = _getNextTokenId();
      _mint(_account, tokenId);
      _incrementTokenId();
    }
  }

  // Burn the last minted token for the specified account
  function burnLastToken(address _account) external onlyLogic {
    require(_account != address(0), "Invalid Address");
    uint256 balance = balanceOf(_account);
    require(balance > 0, "Invalid Balance");

    uint256 tokenId = tokenOfOwnerByIndex(_account, balance - 1);
    _burn(tokenId);
  }
}