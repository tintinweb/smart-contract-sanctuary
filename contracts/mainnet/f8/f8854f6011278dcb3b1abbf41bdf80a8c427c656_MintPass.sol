// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";


contract MintPass is ERC721Tradable {
  struct Pass {
    // Amount of discount when using the pass
    uint256 discount;
    // Base URIs used for generating the token URIs based on the passId
    string baseTokenURI;
    // Used for checking if the pass is valid/active
    bool active;
  }

  // URI for the contract-level metadata
  string private _contractURI;

  mapping (address => bool) public minters;
  mapping (address => bool) public burners;

  // Map between the passId to the pass data
  mapping (uint256 => Pass) private _passDetails;
  // Map between the tokenId to the passId
  mapping (uint256 => uint256) private _passes;

  // Tracks the total number of minted and burnt passes for each type in circulation
  mapping (uint256 => uint256) public mintedCounts;
  mapping (uint256 => uint256) public burntCounts;

  // Add this modifier to all functions which are only accessible by the minters
  modifier onlyMinter() {
    require(minters[msg.sender], "Unauthorized Access");
    _;
  }

  // Add this modifier to all functions which are only accessible by the burners
  modifier onlyBurner() {
    require(burners[msg.sender], "Unauthorized Access");
    _;
  }

  // Add this modifier to all functions which require valid passId
  modifier isValidPass(uint256 _passId) {
    require(_passDetails[_passId].active, "Invalid Pass Specified");
    _;
  }

  constructor (
    string memory _name,
    string memory _symbol,
    string memory _cURI,
    address _proxyRegistryAddress
  ) ERC721Tradable(_name, _symbol, _proxyRegistryAddress) {
    _contractURI = _cURI;
  }

  // Add/remove the specified address to the minter groups
  function setMinter(address _address, bool _state) external onlyOwner {
    require(_address != address(0), "Invalid Address");

    if (minters[_address] != _state) {
      minters[_address] = _state;
    }
  }

  // Add/remove the specified address to the burner groups
  function setBurner(address _address, bool _state) external onlyOwner {
    require(_address != address(0), "Invalid Address");

    if (burners[_address] != _state) {
      burners[_address] = _state;
    }
  }

  function baseTokenURI(uint256 _passId)
    public view isValidPass(_passId)
    returns (string memory)
  {
    return _passDetails[_passId].baseTokenURI;
  }

  function setBaseTokenURI(uint256 _passId, string memory _uri)
    external isValidPass(_passId) onlyOwner
  {
    _passDetails[_passId].baseTokenURI = _uri;
  }

  function discount(uint256 _passId)
    external view isValidPass(_passId)
    returns (uint256)
  {
    return _passDetails[_passId].discount;
  }

  function setDiscount(uint256 _passId, uint256 _discount)
    external isValidPass(_passId) onlyOwner
  {
    _passDetails[_passId].discount = _discount;
  }

  function passExists(uint256 _passId) external view returns (bool) {
    return _passDetails[_passId].active;
  }

  function passDetail(uint256 _tokenId) external view returns (address, uint256, uint256) {
    require(_passDetails[_passes[_tokenId]].active, "Invalid TokenId Specified");

    address owner = ownerOf(_tokenId);
    uint256 passId = _passes[_tokenId];
    uint256 passDiscount = _passDetails[passId].discount;

    return (owner, passId, passDiscount);
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    uint256 passId = _passes[_tokenId];
    require(_passDetails[passId].active, "Invalid TokenID Specified");
    return string(baseTokenURI(passId));
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Should only be changed when there's a critical change to the contract metadata
  function setContractURI(string memory _cURI) external onlyOwner {
    _contractURI = _cURI;
  }

  function registerPass(
    uint256 _passId,
    uint256 _discount,
    string memory _baseTokenURI
  ) external onlyOwner {
    require(_passId >= 1, "Invalid Pass ID");
    require(!_passDetails[_passId].active, "Pass Has Been Registered");
    require(_discount <= 100, "Invalid Discount");

    _passDetails[_passId] = Pass(_discount, _baseTokenURI, true);
  }

  function tokenIdsByOwner(address _address) external view returns (uint256[] memory) {
    uint256 owned = balanceOf(_address);
    uint256[] memory tokenIds = new uint256[](owned);

    for (uint256 i = 0; i < owned; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_address, i);
    }

    return tokenIds;
  }
  
  // Mint a new pass token to the specified address
  function mintToken(
    address _account,
    uint256 _passId,
    uint256 _count
  ) external onlyMinter {
    require(_account != address(0), "Invalid Address");
    require(_count > 0, "Invalid Mint Count");
    require(_passDetails[_passId].active, "Invalid Pass Specified");

    mintedCounts[_passId] += _count;

    for (uint256 i = 0; i < _count; i++) {
      uint256 tokenId = _getNextTokenId();
      _incrementTokenId();

      _passes[tokenId] = _passId;
      _mint(_account, tokenId);
    }
  }

  // Burn the specified pass tokenId
  function burnToken(uint256 _tokenId) external onlyBurner {
    uint256 passId = _passes[_tokenId];
    require(_passDetails[passId].active, "Invalid Pass Specified");

    burntCounts[passId]++;

    _burn(_tokenId);
  }
}