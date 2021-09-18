// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILand.sol";
import "./ILandCollection.sol";
import "./ILandYield.sol";


contract CartelMinter is Ownable, ReentrancyGuard {
  // Collection token contract interface
  ILandCollection public landCollectionContract;
  // Land token contract interface
  ILand public landContract;
  // LandYield contract interface
  ILandYield public landYieldContract;

  // Used to determine whether minting is open to public
  bool public openForPublic;
  // Stores the currently set token price
  uint256 public tokenPrice;
  // Keeps track of the total minted tokens from public sales
  uint256 public totalMintedForPublic;
  // Keeps track of claimed free mints for land owners
  mapping (uint256 => bool) public claimedMints;

  // Stores the universal groupId tracked by the main Collection
  uint256 public groupId;

  constructor(
    uint256 _groupId,
    uint256 _price,
    address _landCollectionContractAddress,
    address _landContractAddress,
    address _landYieldContract
  ) {
    groupId = _groupId;
    tokenPrice = _price;
    landCollectionContract = ILandCollection(_landCollectionContractAddress);
    landContract = ILand(_landContractAddress);
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

  // Fetch the total count of unclaimed free mints for the specified account
  function unclaimedMintForLandOwner(address _account) external view returns (uint256) {
    uint256 landOwned = landContract.balanceOf(_account);
    uint256 mintCount = 0;
    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = landContract.tokenOfOwnerByIndex(_account, i);
      if (!claimedMints[tokenId]) {
        mintCount++;
      }
    }

    return mintCount;
  }

  function _generateExtraSeed(uint256 count) private view returns (uint256) {
    uint256 seed = 0;

    for (uint256 i = 0; i < count; i++) {
      seed = uint256(
        keccak256(
          abi.encodePacked(
            i,
            count,
            seed,
            totalMintedForPublic
          )
        )
      ) % 1000000000;
    }

    return seed;
  }

  // Handles unclaimed free minting for the land owners
  function mintForLandOwner() external nonReentrant {
    uint256 landOwned = landContract.balanceOf(msg.sender);
    require(landOwned > 0, "Reserved For Land Owners");

    // Iterate through all the land tokens owned to get the mint count and mark them as claimed
    uint256 mintCount = 0;
    uint256 tokenIdSum = 0;
    for (uint256 i = 0; i < landOwned; i++) {
      uint256 tokenId = landContract.tokenOfOwnerByIndex(msg.sender, i);
      if (!claimedMints[tokenId]) {
        mintCount++;
        tokenIdSum += tokenId;
        claimedMints[tokenId] = true;
      }
    }

    // Proceed to mint all unclaimed Cartels for the account
    require(mintCount > 0, "Allocated free mints have been claimed");

    // Get an additional seed on top of the other seeds in the collection contract
    uint256 seed = _generateExtraSeed(mintCount + tokenIdSum);
    landCollectionContract.mintToken(msg.sender, groupId, mintCount, seed);
  }

  // Handles public token purchases
  receive() external payable nonReentrant {
    // Check if the public minting is open
    require(openForPublic, "Public Minting Is Not Available");
    // Check if tokens are still available for sale
    uint256 maxSupply = landCollectionContract.maximumSupply(groupId);
    uint256 totalMinted = landCollectionContract.totalMinted(groupId);
    uint256 remainingTokenCount = maxSupply - totalMinted;
    uint256 totalReservedForPublic = maxSupply - landContract.maximumSupply();
    require(remainingTokenCount > 0 && totalMintedForPublic < totalReservedForPublic, "Sold Out");

    // Check if sufficient funds are sent
    require(msg.value >= tokenPrice, "Insufficient Funds");

    // Update the total count of tokens from the public sales
    totalMintedForPublic++;

    // Minting count is fixed to only 1 per transaction
    uint256 seed = _generateExtraSeed(1 + totalMintedForPublic);
    landCollectionContract.mintToken(msg.sender, groupId, 1, seed);

    // Transfer the funds to the yield contract for land owners and treasury
    (bool success, ) = address(landYieldContract).call{value: tokenPrice}(
      abi.encodeWithSignature("distributeSalesYield()")
    );
    require(success, "Failed To Distribute Sales");

    // Send back any excess funds
    uint256 refund = msg.value - tokenPrice;
    if (refund > 0) {
      payable(msg.sender).transfer(refund);
    }
  }
}