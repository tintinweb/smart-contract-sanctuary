// SPDX-License-Identifier: MIT
// https://t3rm.dev
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract t3rm is ERC721URIStorage, Ownable {
  /**
   * Token IDs counter.
   *
   * Provides an auto-incremented ID for each token minted.
   */
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIDs;

  /**
   * Launch block number.
   *
   * Prevents minting until the platform launches.
   */
   uint private _launchBlock;

  /**
   * Mapping of package hash to tokenID.
   */
   mapping(bytes32 => uint) private _packages;

   /**
   * Mapping of tokenID to package hash.
   */
   mapping(uint => string) private _tokens;

   /**
   * Mapping of tokenID to creator.
   */
   mapping(uint => address) private _creators;

  /**
   * Mapping of package to frozen status.
   */
  mapping(uint => bool) private _frozen;

  /**
   * Contract metadata URI.
   */
  string private _contractURI;

  /**
   * Mint fee
   *
   * Defines the price required to register a package.
   */
  uint private _mintFee;

   /**
   * Mint fee floor
   *
   * Defines the lowest price for the minting fee.
   */
  uint private _mintFeeFloor;

  /**
   * List mint at.
   *
   * Internally stores the block numbers for the last mint event.
   * Used to calculate the block delta for price adjustments.
   */
  uint private _lastMintAt;

  /**
   * Update frequency.
   *
   * Defines the frequency for the mint fee adjustment.
   *
   * Example: A value of 500 increases the _mintFee if a new token is
   * minted with fewer than 500 blocks since the previous minting, and
   * decreases the value if more than 500 blocks have been created.
   *
   * This is used to optimize prices to achieve a steady flow of dev.
   */
  uint private _updateFreq;

  /**
   * Update amount.
   *
   * Defines the divisor used in the mint fee rebalancing update.
   *
   * Example: A value of 20 will increase or decrease the _mintFee
   * by 5 percent.
   */
  uint private _updateAmt;

  /**
   * Constructor to deploy the contract.
   *
   * Sets the initial settings for the contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    string memory __contractURI,
    uint __mintFee,
    uint __mintFeeFloor,
    uint __updateFreq,
    uint __updatAmt,
    uint __launchBlock
  ) ERC721(_name, _symbol) {
    _contractURI = __contractURI;
    _mintFee = __mintFee;
    _mintFeeFloor = __mintFeeFloor;
    _updateFreq = __updateFreq;
    _updateAmt = __updatAmt;
    _launchBlock = __launchBlock;

    // Reserved: connect
    _packages[0x06e7a5e6cac387364da652310717d5f91789fd895ebf5dc658e0dcd80a2f9a42] = type(uint256).max;

    // Reserved: disconnect
    _packages[0x017399084a6301db582204dd3505f7ead52eb83de2b3c608d8503256263026cf] = type(uint256).max;

    // Reserved: info
    _packages[0x3820cab827512459062f4d6dd584c03d5f2ec29517c1c68c886f18f041fc4fc7] = type(uint256).max;

    // Reserved: list
    _packages[0xbe8e25a9981f15070e47df9c1c85829f53ccec91a1340eac095113ab184fae5f] = type(uint256).max;

    // Reserved: mint
    _packages[0x5b4ea791576315f49763e091eb2b21ee4f1789045afc8e036b44288714996993] = type(uint256).max;

    // Reserved: update
    _packages[0xfdcff868f2b2010d7dde03b445b78c840f2a012dd6208aa14b5c673094f0aa31] = type(uint256).max;

    // Reserved: freeze
    _packages[0x1238908b973638e0ad25d4933d8d3a76f918aaa8cbb3bee6bc1d0adcb26cec59] = type(uint256).max;
  }

  /**
   * package Hash helper.
   *
   * Accepts lowercase letters, numbers, hyphens, periods, and underscores.
   * Returns a keccak256 hash.
   */
  function _packageHash(string memory str) private pure returns (bytes32) {
    bytes memory b = bytes(str);

    for (uint i; i<b.length; i++){
      bytes1 char = b[i];

      require (
        (char >= 0x30 && char <= 0x39) || //0-9
        (char >= 0x61 && char <= 0x7A) || //a-z
        (char == 0x2D) || //-
        (char == 0x2E) || //.
        (char == 0x5F) //_
      , "package contains invalid characters.");
    }

    return keccak256(abi.encode(string(b)));
  }

  /**
   * Contract metadata URI
   *
   * Provides the URI for the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), _contractURI));
  }

  /**
   * Override for the OpenZeppelin ERC721 baseURI function.
   *
   * All tokenURIs will use a deterministic multihash for the
   * metadata, hosted behind a gateway-agnostic IPFS protocol.
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return "ipfs://";
  }

  /**
   * Get the launch block.
   *
   * Returns the block number when tokens can be minted.
   */
  function launchBlock() public view returns (uint) {
    return _launchBlock;
  }

  /**
   * Get the current total supply of tokens.
   *
   * Returns the total number of tokens minted.
   */
  function totalSupply() public view returns (uint) {
    return _tokenIDs.current();
  }

  /**
   * Get token ID of package.
   *
   * Returns the token ID.
   */
  function token(string memory _package) public view returns (uint) {
    bytes32 _cmd = _packageHash(_package);
    uint tokedID = _packages[_cmd];
    require(tokedID > 0, "package not found.");

    return tokedID;
  }

  /**
   * Get the package string for a tokenID.
   *
   * Returns the registered package.
   */
  function package(uint _tokenId) public view returns (string memory) {
    require(_tokenId <= _tokenIDs.current(), "Token doesn't exist.");

    return _tokens[_tokenId];
  }

  /**
   * Get the creator of a token.
   *
   * Returns the creator's address.
   */
  function creator(uint _tokenId) public view returns (address) {
    require(_tokenId <= _tokenIDs.current(), "Token doesn't exist.");

    return _creators[_tokenId];
  }

  /**
   * Get frozen status.
   *
   * Returns true if a tokenURI is unable to be updated.
   */
  function frozen(string memory _package) public view returns (bool) {
    bytes32 _cmd = _packageHash(_package);
    uint tokedID = _packages[_cmd];
    require(tokedID > 0, "package not found.");

    return _frozen[tokedID];
  }

  /**
   * Get the current mint fee.
   *
   * Returns the current transfer amount required to mint
   * a new token.
   */
  function mintFee() public view returns (uint) {
    return _mintFee;
  }

  /**
   * Get the current mint fee floor price.
   *
   * Returns the lowest price for a token minting.
   */
  function mintFeeFloor() public view returns (uint) {
    return _mintFeeFloor;
  }

  /**
   * Get code
   *
   * Returns the source code multihash for a package.
   */
  function code(string memory _package) public view returns (string memory) {
    bytes32 _cmd = _packageHash(_package);
    uint tokenID = _packages[_cmd];
    require(tokenID > 0, "package not found.");

    return tokenURI(tokenID);
  }

  /**
   * Update the mint fee.
   *
   * Adjusts the mint fee based on the block delta between
   * the last token minted.
   */
  function _updateMintFee() private {
    uint blockDelta = block.number - _lastMintAt;
    blockDelta > _updateFreq
      ? _mintFee -= _mintFee/_updateAmt
      : _mintFee += _mintFee/_updateAmt;

    if (_mintFee < _mintFeeFloor) _mintFee = _mintFeeFloor;
  }

  /**
   * Mint a token to an address.
   *
   * Requires payment of _mintFee.
   */
  function mintTo(
    address _receiver,
    string memory _package,
    string memory _tokenURI
  ) public payable returns (uint) {
    require(block.number >= _launchBlock, "Platform hasn't launched.");
    require(msg.value >= _mintFee, "Requires minimum fee.");

    bytes32 _cmd = _packageHash(_package);
    require(_packages[_cmd] == 0, "package in use.");

    payable(owner()).transfer(msg.value);

    _updateMintFee();
    _lastMintAt = block.number;

    _tokenIDs.increment();
    uint tokenId = _tokenIDs.current();
    _mint(_receiver, tokenId);
    _setTokenURI(tokenId, _tokenURI);
    _packages[_cmd] = tokenId;
    _tokens[tokenId] = _package;
    _creators[tokenId] = msg.sender;

    return tokenId;
  }

  /**
   * Mint a token to the sender.
   *
   * Requires payment of _mintFee.
   */
  function mint(string memory _package, string memory _tokenURI) public payable returns (uint) {
    return mintTo(msg.sender, _package, _tokenURI);
  }

  /**
   * Update a package.
   *
   * Requires ownership of token.
   */
  function update(string memory _package, string memory _tokenURI) public {
    bytes32 _cmd = _packageHash(_package);
    uint tokenID = _packages[_cmd];
    require(tokenID > 0, "package not found.");
    require(ownerOf(tokenID) == msg.sender, "Only the owner can update the token.");
    require(!_frozen[tokenID], "Token is frozen and cannot be updated.");

    _setTokenURI(tokenID, _tokenURI);
  }

  /**
   * Freeze a package.
   *
   * Requires ownership of token.
   */
  function freeze(string memory _package) public {
    bytes32 _cmd = _packageHash(_package);
    uint tokenID = _packages[_cmd];
    require(tokenID > 0, "package not found.");
    require(ownerOf(tokenID) == msg.sender, "Only the owner can freeze the token.");
    require(!_frozen[tokenID], "Already frozen.");

    _frozen[tokenID] = true;
  }

  /**
   * Admin function: Update mint fee.
   *
   * Updates the _mintFee value.
   */
  function adminUpdateMintFee(uint __mintFee) onlyOwner public {
    _mintFee = __mintFee;
  }

  /**
   * Admin function: Update mint fee floor.
   *
   * Updates the _mintFeeFloor value.
   */
  function adminUpdateMintFeeFloor(uint __mintFeeFloor) onlyOwner public {
    _mintFeeFloor = __mintFeeFloor;
    if (_mintFeeFloor > _mintFee) _mintFee = _mintFeeFloor;
  }
}