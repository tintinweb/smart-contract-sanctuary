// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILand.sol";
import "./IOre.sol";
import "./IMintPass.sol";


contract MintPassMinter is Ownable, ReentrancyGuard {
  // MintPass token contract interface
  IMintPass public mintPass;
  // Land token contract interface
  ILand public land;
  // Ore token contract interface
  IOre public ore;

  // Stores the currently set pass prices
  mapping (uint256 => uint256) private _passPrices;
  // Keeps track of the timestamp of the latest claiming period
  uint256 private _lastClaimTimestamp;

  // Keeps track of the total free pass claimed by landowners
  uint256 public totalFreePassClaimed;
  // Keeps track of the total purchased mint passes
  mapping (uint256 => uint256) public totalPurchasedByPassId;
  // Keeps track of total claimed free passes for land owners
  mapping (uint256 => uint256) public lastClaimTimestampByLandId;

  // The passId used to indicate the free passes claimable by landowners
  uint256 private _freePassId;

  constructor(
    address _ore,
    address _land,
    address _mintPass
  ) {
    ore = IOre(_ore);
    land = ILand(_land);
    mintPass = IMintPass(_mintPass);
  }

  function freePassId() external view returns (uint256) {
    return _freePassId;
  }

  function passPrice(uint256 _passId) external view returns (uint256) {
    require(mintPass.passExists(_passId), "Invalid PassId");
    return _passPrices[_passId];
  }

  // Enable new claiming by updating the ending timestamp to 24 hours after enabled
  function setLastClaimTimestamp(uint256 _timestamp) external onlyOwner {
    _lastClaimTimestamp = _timestamp;
  }

  function lastClaimTimestamp() external view returns (uint256) {
    return _lastClaimTimestamp;
  }

  // Update the token price
  function setPassPrice(uint256 _passId, uint256 _price) external onlyOwner {
    require(mintPass.passExists(_passId), "Invalid PassId");
    _passPrices[_passId] = _price;
  }

  // Set the passId used as landowner's free passes
  function setFreePassId(uint256 _passId) external onlyOwner {
    require(mintPass.passExists(_passId), "Invalid PassId");
    _freePassId = _passId;
  }

  // Generate passes to be used for marketing purposes
  function generatePassForMarketing(uint256 _passId, uint256 _count) external onlyOwner {
    require(_count > 0, "Invalid Amount");
    mintPass.mintToken(msg.sender, _passId, _count);
  }

  // Fetch the total count of unclaimed free passes for the specified landowner account
  function unclaimedFreePass(address _account) external view returns (uint256) {
    uint256 landOwned = land.balanceOf(_account);
    uint256 mintCount = 0;

    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = land.tokenOfOwnerByIndex(msg.sender, i);
      if (_lastClaimTimestamp > block.timestamp &&
        _lastClaimTimestamp > lastClaimTimestampByLandId[tokenId]) {
        mintCount++;
      }
    }

    return mintCount;
  }

  // Handles free passes claiming for the landowners
  function claimFreePass() external nonReentrant {
    require(_freePassId > 0, "Pass Id Not Set");
    uint256 landOwned = land.balanceOf(msg.sender);
    require(landOwned > 0, "Reserved For Land Owners");

    // Iterate through all the land tokens owned to get the mint count and mark them as claimed
    uint256 mintCount = 0;

    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = land.tokenOfOwnerByIndex(msg.sender, i);
      if (_lastClaimTimestamp > block.timestamp &&
        _lastClaimTimestamp > lastClaimTimestampByLandId[tokenId]) {
        mintCount++;
        lastClaimTimestampByLandId[tokenId] = _lastClaimTimestamp;
      }
    }

    require(mintCount > 0, "No Unclaimed Free Passes Found");

    totalFreePassClaimed += mintCount;
    mintPass.mintToken(msg.sender, _freePassId, mintCount);
  }

  // Handles pass purchases using ORE
  function buyPass(uint256 _passId, uint256 _count) external nonReentrant {
    // Check if sufficient funds are sent
    require(mintPass.passExists(_passId), "Invalid PassId");
    require(_passPrices[_passId] > 0, "Price Not Set");
    uint256 totalPrice = _count * _passPrices[_passId];
    require(ore.balanceOf(msg.sender) >= totalPrice, "Insufficient Ore");

    totalPurchasedByPassId[_passId] += _count;

    // Burn the ORE and proceed to mint the passes
    ore.burn(msg.sender, totalPrice);
    mintPass.mintToken(msg.sender, _passId, _count);
  }
}