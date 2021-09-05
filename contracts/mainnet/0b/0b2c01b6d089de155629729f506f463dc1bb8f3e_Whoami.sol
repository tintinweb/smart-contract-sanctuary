// SPDX-License-Identifier: MIT
// https://t3rm.dev
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Counters.sol";

contract Whoami is ERC721Enumerable, Ownable {
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
   * Total identities.
   *
   * Defines the total number of available identities to be
   * recovered by the system.
   *
   */
  uint private _totalIdentities;

  /**
   * Constructor to deploy the contract.
   *
   * Sets the initial settings for the contract.
   */
  constructor(
    string memory _name,
    string memory _symbol,
    uint __mintFee,
    uint __mintFeeFloor,
    uint __updateFreq,
    uint __updatAmt,
    uint __launchBlock,
    uint __totalIdentities
  ) ERC721(_name, _symbol) {
    _mintFee = __mintFee;
    _mintFeeFloor = __mintFeeFloor;
    _updateFreq = __updateFreq;
    _updateAmt = __updatAmt;
    _launchBlock = __launchBlock;
    _totalIdentities = __totalIdentities;
  }

  /**
   * Contract metadata URI
   *
   * Provides the URI for the contract metadata.
   */
  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseURI(), "contract"));
  }

  /**
   * Override for the OpenZeppelin ERC721 baseURI function.
   *
   * All tokenURIs will use a t3rm.dev whoami base.
   */
  function _baseURI() internal view virtual override returns (string memory) {
    return "https://t3rm.dev/whoami/";
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
   * Total identities.
   *
   * Returns the maximum allowed identities.
   */
  function totalIdentities() public view returns (uint) {
    return _totalIdentities;
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
  function mintTo(address _receiver) public payable returns (uint) {
    require(block.number >= _launchBlock, "Platform hasn't launched.");
    require(msg.value >= _mintFee, "Requires minimum fee.");
    require(totalSupply() < _totalIdentities, "Max supply reached.");

    payable(owner()).transfer(msg.value);

    _updateMintFee();
    _lastMintAt = block.number;

    _tokenIDs.increment();
    uint tokenId = _tokenIDs.current();
    _mint(_receiver, tokenId);

    return tokenId;
  }

  /**
   * Mint a token to the sender.
   *
   * Requires payment of _mintFee.
   */
  function mint() public payable returns (uint) {
    return mintTo(msg.sender);
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

  /**
   * Admin function: Update total identities.
   *
   * Updates the _mintFeeFloor value.
   */
  function adminUpdateTotalIdentities(uint __totalIdentities) onlyOwner public {
    _totalIdentities = __totalIdentities;
  }
}