// SPDX-License-Identifier: MIT
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
   * Mapping of command hash to tokenID.
   */
   mapping(bytes32 => uint) private _commands;

  /**
   * Mapping of command to frozen status.
   */
  mapping(uint => bool) private _frozen;

  /**
   * Contract metadata URI.
   */
  string private _contractURI;

  /**
   * Mint fee
   *
   * Defines the price required to register a command.
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
    _commands[0x06e7a5e6cac387364da652310717d5f91789fd895ebf5dc658e0dcd80a2f9a42] = type(uint256).max;

    // Reserved: disconnect
    _commands[0x017399084a6301db582204dd3505f7ead52eb83de2b3c608d8503256263026cf] = type(uint256).max;

    // Reserved: help
    _commands[0xb2c80d57257e1d0beff74263cff0b9289e7baef33d9df9bfb36185ffaf713e5a] = type(uint256).max;

    // Reserved: list
    _commands[0xbe8e25a9981f15070e47df9c1c85829f53ccec91a1340eac095113ab184fae5f] = type(uint256).max;

    // Reserved: mint
    _commands[0x5b4ea791576315f49763e091eb2b21ee4f1789045afc8e036b44288714996993] = type(uint256).max;

    // Reserved: update
    _commands[0xfdcff868f2b2010d7dde03b445b78c840f2a012dd6208aa14b5c673094f0aa31] = type(uint256).max;

    // Reserved: freeze
    _commands[0x1238908b973638e0ad25d4933d8d3a76f918aaa8cbb3bee6bc1d0adcb26cec59] = type(uint256).max;
  }

  /**
   * Command Hash helper.
   *
   * Accepts alphanumeric characters, hyphens, periods, and underscores.
   * Returns a keccak256 hash of the lowercase command.
   */
  function _commandHash(string memory str) private pure returns (bytes32){
    bytes memory b = bytes(str);

    for (uint i; i<b.length; i++){
      bytes1 char = b[i];

      require (
        (char >= 0x30 && char <= 0x39) || //0-9
        (char >= 0x41 && char <= 0x5A) || //A-Z
        (char >= 0x61 && char <= 0x7A) || //a-z
        (char == 0x2D) || //-
        (char == 0x2E) || //.
        (char == 0x5F) //_
      , "Command contains invalid characters.");
    }

    bytes memory bLower = new bytes(b.length);

    for (uint i = 0; i < b.length; i++) {
      if ((uint8(b[i]) >= 65) && (uint8(b[i]) <= 90)) {
        // Uppercase character
        bLower[i] = bytes1(uint8(b[i]) + 32);
      } else {
        bLower[i] = b[i];
      }
    }

    return keccak256(abi.encode(string(bLower)));
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
   * Get frozen status.
   *
   * Returns true if a tokenURI is unable to be updated.
   */
  function frozen(string memory _command) public view returns (bool) {
    bytes32 _cmd = _commandHash(_command);
    uint tokedID = _commands[_cmd];
    require(tokedID > 0, "Command not found.");

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
   * Returns the source code multihash for a command.
   */
  function code(string memory _command) public view returns (string memory) {
    bytes32 _cmd = _commandHash(_command);
    uint tokenID = _commands[_cmd];
    require(tokenID > 0, "Command not found.");

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
    string memory _command,
    string memory _tokenURI
  ) public payable returns (uint) {
    require(block.number >= _launchBlock, "Platform hasn't launched.");
    require(msg.value >= _mintFee, "Requires minimum fee.");

    bytes32 _cmd = _commandHash(_command);
    require(_commands[_cmd] == 0, "Command in use.");

    payable(owner()).transfer(msg.value);

    _updateMintFee();
    _lastMintAt = block.number;

    _tokenIDs.increment();
    uint tokenId = _tokenIDs.current();
    _mint(_receiver, tokenId);
    _setTokenURI(tokenId, _tokenURI);
    _commands[_cmd] = tokenId;

    return tokenId;
  }

  /**
   * Mint a token to the sender.
   *
   * Requires payment of _mintFee.
   */
  function mint(string memory _command, string memory _tokenURI) public payable returns (uint) {
    return mintTo(msg.sender, _command, _tokenURI);
  }

  /**
   * Update a command.
   *
   * Requires ownership of token.
   */
  function update(string memory _command, string memory _tokenURI) public {
    bytes32 _cmd = _commandHash(_command);
    uint tokenID = _commands[_cmd];
    require(tokenID > 0, "Command not found.");
    require(ownerOf(tokenID) == msg.sender, "Only the owner can update the token.");
    require(!_frozen[tokenID], "Token is frozen and cannot be updated.");

    _setTokenURI(tokenID, _tokenURI);
  }

  /**
   * Freeze a command.
   *
   * Requires ownership of token.
   */
  function freeze(string memory _command) public {
    bytes32 _cmd = _commandHash(_command);
    uint tokenID = _commands[_cmd];
    require(tokenID > 0, "Command not found.");
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