// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721Tradable.sol";


contract LandCollection is ERC721Tradable {
  struct Group {
    // Maximum supplies of each group (Immutable)
    uint256 maxSupply;
    // Addresses of the logic contract responsible for minting of each group (Immutable)
    address minter;
    // Stores the displayed name for each group
    string name;
    // Base URIs used for generating the token URIs based on the groupId
    string baseTokenURI;
  }

  // URI for the contract-level metadata
  string private _contractURI;

  // Stores the info for token groups
  mapping (uint256 => Group) private _groups;
  // Total minted count of each group
  mapping (uint256 => uint256) private _totalMinted;

  // Used as a part of the semi-random seeds
  uint256 private _nonce = 0;
  // Stores the last generated seed for generating the next seed
  uint256 private _lastSeed = 0;
  // Used to determine the next tokenId to be used when minting a new token
  mapping(uint256 => mapping (uint256 => uint256)) private _tokenSeeds;
  // Used for extracting group and member identifiers from tokenId
  uint256 private _idSeparator = 100000;

  // Add this modifier to all functions which are only accessible by the assigned minter
  modifier onlyMinter(uint256 _groupId) {
    require(msg.sender == _groups[_groupId].minter, "Unauthorized Access");
    _;
  }

  // Add this modifier to all functions which require valid groupId
  modifier isValidGroup(uint256 _groupId) {
    require(_groups[_groupId].maxSupply > 0, "Invalid Group Specified");
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

  function baseTokenURI(uint256 _groupId)
    public view isValidGroup(_groupId)
    returns (string memory)
  {
    return _groups[_groupId].baseTokenURI;
  }

  // Should only be changed when there's an issue with the currently set IPFS gateway
  function setBaseTokenURI(uint256 _groupId, string memory _uri)
    external isValidGroup(_groupId) onlyOwner
  {
    _groups[_groupId].baseTokenURI = _uri;
  }

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    uint256 groupId = _tokenId / _idSeparator;
    uint256 memberId = _tokenId % _idSeparator;
    require(_groups[groupId].maxSupply > 0, "Invalid TokenID Specified");
    return string(abi.encodePacked(baseTokenURI(groupId), Strings.toString(memberId)));
  }

  function contractURI() public view returns (string memory) {
    return _contractURI;
  }

  // Should only be changed when there's a critical change to the contract metadata
  function setContractURI(string memory _cURI) external onlyOwner {
    _contractURI = _cURI;
  }

  function minter(uint256 _groupId)
    external view isValidGroup(_groupId)
    returns (address)
  {
    return _groups[_groupId].minter;
  }

  function groupName(uint256 _groupId)
    external view isValidGroup(_groupId)
    returns (string memory)
  {
    return _groups[_groupId].name;
  }

  // Update the displayed group name when absolutely needed
  function setGroupName(uint256 _groupId, string memory _name)
    external isValidGroup(_groupId) onlyOwner
  {
    _groups[_groupId].name = _name;
  }

  function createGroup(
    uint256 _groupId,
    string memory _name,
    uint256 _maxSupply,
    address _minter,
    string memory _baseTokenURI
  ) external onlyOwner {
    require(_groupId >= 1000 && _groupId <= 9999, "Invalid Group ID");
    require(_groups[_groupId].maxSupply == 0, "Group Has Been Added");
    require(_minter != address(0), "Invalid Address");
    require(_maxSupply > 0, "Invalid Max Supply");
    _groups[_groupId] = Group(_maxSupply, _minter, _name, _baseTokenURI);
  }

  function maximumSupply(uint256 _groupId)
    external view isValidGroup(_groupId)
    returns (uint256)
  {
    return _groups[_groupId].maxSupply;
  }

  function totalMinted(uint256 _groupId)
    external view isValidGroup(_groupId)
    returns (uint256)
  {
    return _totalMinted[_groupId];
  }
  
  // Generate and keep track of a new seed
  function _generateTokenId(uint256 _groupId, uint256 _seed) private returns (uint256) {
    uint256 loopCount = ((_seed + _nonce) % 3) + 1;
    uint256 lastTokenId = (totalSupply() == 0 ? _seed : tokenByIndex(totalSupply() - 1));

    for (uint256 i = 0; i < loopCount; i++) {
      _lastSeed = uint256(
        keccak256(
          abi.encodePacked(
            _groupId,
            _nonce,
            _lastSeed,
            totalSupply(),
            _seed,
            lastTokenId
          )
        )
      ) % 1000000000;
    }

    _nonce += _lastSeed;
    _nonce %= 1000000000;

    // Determine the tokenId by considering various variables 
    uint256 remainingCount = _groups[_groupId].maxSupply - _totalMinted[_groupId];
    uint256 seedIndex = (_lastSeed % remainingCount) + 1;
    uint256 chosen = (_tokenSeeds[_groupId][seedIndex] > 0 ?
      _tokenSeeds[_groupId][seedIndex] : seedIndex);
    uint256 tail = (_tokenSeeds[_groupId][remainingCount] > 0 ?
      _tokenSeeds[_groupId][remainingCount] : remainingCount);

    // Swap out the chosen tokenId to the end/tail of the list
    // and reduce the remaining number of mintable tokens to make sure that all tokenIds are unique
    _tokenSeeds[_groupId][seedIndex] = tail;
    _tokenSeeds[_groupId][remainingCount] = chosen;

    // Pad with groupId to get the actual tokenId
    return (_groupId * _idSeparator) + chosen;
  }

  // Mint a new token to the specified address, token groupId, token count, and additional seed 
  function mintToken(
    address _account,
    uint256 _groupId,
    uint256 _count,
    uint256 _seed
  ) external onlyMinter(_groupId) {
    require(_account != address(0), "Invalid Address");
    require(
      _groups[_groupId].maxSupply >= _totalMinted[_groupId] + _count,
      "All Tokens Have Been Minted"
    );

    uint256 seed = _seed;
    for (uint256 i = 0; i < _count; i++) {
      uint256 tokenId = _generateTokenId(_groupId, seed);
      _totalMinted[_groupId]++;
      seed += tokenId;
      _mint(_account, tokenId);
    }
  }
}