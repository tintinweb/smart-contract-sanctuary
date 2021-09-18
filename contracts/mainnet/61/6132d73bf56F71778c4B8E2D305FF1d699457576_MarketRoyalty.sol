// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";


contract MarketRoyalty is Ownable, ReentrancyGuard {
  // LandYield address
  address public landYield;
  // Artist Escrow address
  address public artistEscrow;

  constructor(
    address _landYield,
    address _artist
  ) {
    landYield = _landYield;
    artistEscrow = _artist;
  }

  function setLandYield(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    landYield = _address;
  }

  function setArtistEscrow(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    artistEscrow = _address;
  }

  receive() external payable {}

  // Split 50/50 between the artists escrow and land owners' yield
  function withdraw() external onlyOwner nonReentrant {
    uint256 totalFunds = address(this).balance;
    require(totalFunds > 0, "Insufficient Funds");

    uint256 escrowShare = totalFunds / 2;
    uint256 yieldShare = totalFunds - escrowShare;

    // Send funds via call function due to additional gas required for yield processing
    (bool success, ) = address(landYield).call{value: yieldShare}("");
    require(success, "Failed To Process Withdrawal");

    // Send the other half for artists escrow funds
    payable(artistEscrow).transfer(escrowShare);
  }
}