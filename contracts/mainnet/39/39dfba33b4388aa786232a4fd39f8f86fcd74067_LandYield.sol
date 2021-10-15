// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILand.sol";


contract LandYield is Ownable, ReentrancyGuard {
  // Land token contract interface
  ILand public landContract;

  address private _treasury;
  address private _admin;

  uint256 private _totalYieldPerLand;
  uint256 private _totalReleasedYield;
  uint256 private _owedTreasuryYield;
  mapping (uint256 => uint256) private _releasedYield;

  // Add this modifier to all functions which are only accessible by the owner or the selected admin
  modifier onlyManager() {
    require(msg.sender == owner() || msg.sender == _admin, "Unauthorized Access");
    _;
  }

  constructor(address _landContractAddress) {
    landContract = ILand(_landContractAddress);
    _treasury = msg.sender;
    _admin = msg.sender;
  }

  function admin() external view returns (address) {
    return _admin;
  }

  function setAdmin(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    _admin = _address;
  }

  function treasury() external view returns (address) {
    return _treasury;
  }

  function setTreasury(address _address) external onlyManager {
    require(_address != address(0), "Invalid Address");
    _treasury = _address;
  }

  function totalYieldPerLand() external view returns (uint256) {
    return _totalYieldPerLand;
  }

  function totalReleasedYield() external view returns (uint256) {
    return _totalReleasedYield;
  }

  function owedTreasuryYield() external view returns (uint256) {
    return _owedTreasuryYield;
  }

  // Called by registered primary token sales contracts for distributing the profits for land owners and treasury
  function distributeSalesYield(uint256 _landYield) external payable nonReentrant {
    require(msg.value > 0, "Insufficient Yield");

    // Calculate and update the total yield per land
    // And also update the yield allocated for the treasury (+ any division remainders)
    uint256 landCount = landContract.maximumSupply();
    _totalYieldPerLand += _landYield / landCount;
    _owedTreasuryYield += (msg.value - _landYield) + (_landYield % landCount);
  }

  function releasedYieldByTokenId(uint256 _tokenId) external view returns (uint256) {
    return _releasedYield[_tokenId];
  }

  // Calculate and return the total amount of owed (land) yield for the specified account
  function totalOwedYieldByAccount(address _account) external view returns (uint256) {
    uint256 landOwned = landContract.balanceOf(_account);
    uint256 totalOwedYield = 0;
    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = landContract.tokenOfOwnerByIndex(_account, i);
      uint256 owedYield = _totalYieldPerLand - _releasedYield[tokenId];

      if (owedYield > 0) {
        totalOwedYield += owedYield;
      }
    }

    return totalOwedYield;
  }

  // Can be called by land owners for withdrawing collected yields
  function releaseForLandOwner() external nonReentrant {
    uint256 landOwned = landContract.balanceOf(msg.sender);
    require(landOwned > 0, "Reserved For Land Owners");

    // Iterate through all owned land tokens and calculate the total unclaimed yield
    uint256 totalOwedYield = 0;
    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = landContract.tokenOfOwnerByIndex(msg.sender, i);
      uint256 owedYield = _totalYieldPerLand - _releasedYield[tokenId];

      if (owedYield > 0) {
        totalOwedYield += owedYield;
        _releasedYield[tokenId] = _totalYieldPerLand;
      }
    }

    require(totalOwedYield > 0, "Insufficient Yield");
    _totalReleasedYield += totalOwedYield;

    payable(msg.sender).transfer(totalOwedYield);
  }

  // Handles yield received as royalties from OpenSea, allocated for the land owners
  receive() external payable {
    require(msg.value > 0, "Insufficient Yield");

    // Update the total yield per land and put the remainder due to integer-division (if any) to the treasury
    uint256 landCount = landContract.maximumSupply();
    _totalYieldPerLand += msg.value / landCount;
    _owedTreasuryYield += msg.value % landCount;
  }

  function releaseForTreasury() external onlyManager nonReentrant {
    require(_owedTreasuryYield > 0, "Insufficient Yield");

    uint256 totalOwedYield = _owedTreasuryYield;
    _owedTreasuryYield = 0;
    _totalReleasedYield += totalOwedYield;

    payable(_treasury).transfer(totalOwedYield);
  }
}