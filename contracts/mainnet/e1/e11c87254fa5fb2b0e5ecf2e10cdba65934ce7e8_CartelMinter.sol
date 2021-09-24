// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILandCollection.sol";
import "./ILandYield.sol";


// Replacement for the original minter for the public sale functionality due to gas optimizations
// Since landowners minting is no longer handled here, any related functions or variables have been removed
contract CartelMinter is Ownable, ReentrancyGuard {
  // Collection token contract interface
  ILandCollection public landCollectionContract;
  // LandYield contract interface
  ILandYield public landYieldContract;

  // Used to determine whether minting is open to public
  bool public openForPublic;
  // Stores the currently set token price
  uint256 public tokenPrice;
  // Stores the number of maximum tokens mintable in a single tx
  uint256 public mintLimit;

  // Stores the universal groupId tracked by the main Collection
  uint256 public groupId;

  constructor(
    uint256 _groupId,
    uint256 _price,
    address _landCollectionContractAddress,
    address _landYieldContract
  ) {
    mintLimit = 7;
    groupId = _groupId;
    tokenPrice = _price;
    landCollectionContract = ILandCollection(_landCollectionContractAddress);
    landYieldContract = ILandYield(_landYieldContract);
  }

  // Only to be used in case there's a need to upgrade the yield contract mid-sales
  function setLandYieldContract(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    landYieldContract = ILandYield(_address);
  }

  // Update the state of the public minting (open/closed)
  function toggleOpenForPublic(bool _state) external onlyOwner {
    openForPublic = _state;
  }

  // Update the token price
  function setTokenPrice(uint256 _price) external onlyOwner {
    tokenPrice = _price;
  }

  function setMintLimit(uint256 _limit) external onlyOwner {
    require(_limit > 0 && _limit <= 10, "Invalid Value For Limit");
    mintLimit = _limit;
  }

  function totalMintedForPublic() external view returns (uint256) {
    return landCollectionContract.totalMinted(groupId);
  }

  function _generateExtraSeed(uint256 count) private pure returns (uint256) {
    uint256 seed = 0;
    uint256 loopCount = count % 4 + 2;

    for (uint256 i = 0; i < loopCount; i++) {
      seed = uint256(
        keccak256(
          abi.encodePacked(
            i,
            count,
            seed
          )
        )
      ) % 1000000000;
    }

    return seed;
  }

  // Handles public token purchases
  receive() external payable nonReentrant {
    // Check if the public minting is open
    require(openForPublic, "Public Minting Is Not Available");
    // Check if tokens are still available for sale
    uint256 maxSupply = landCollectionContract.maximumSupply(groupId);
    uint256 totalMinted = landCollectionContract.totalMinted(groupId);
    uint256 remainingTokenCount = maxSupply - totalMinted;
    require(remainingTokenCount > 0, "Sold Out");

    // Check if sufficient funds are sent
    require(msg.value >= tokenPrice, "Insufficient Funds");

    // Minting count per transaction is limited to the mint limit set by the owner
    uint256 mintCount = msg.value / tokenPrice;
    mintCount = (mintCount > mintLimit ? mintLimit : mintCount);
    mintCount = (mintCount > remainingTokenCount ? remainingTokenCount : mintCount);
    uint256 seed = _generateExtraSeed(mintCount + remainingTokenCount);
    landCollectionContract.mintToken(msg.sender, groupId, mintCount, seed);

    // Transfer the funds to the yield contract for land owners and treasury
    uint256 totalSpent = mintCount * tokenPrice;
    (bool success, ) = address(landYieldContract).call{value: totalSpent}(
      abi.encodeWithSignature("distributeSalesYield()")
    );
    require(success, "Failed To Distribute Sales");

    // Send back any excess funds
    uint256 refund = msg.value - totalSpent;
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }
}