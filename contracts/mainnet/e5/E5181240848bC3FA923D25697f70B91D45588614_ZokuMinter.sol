// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";

import "./ILandCollection.sol";
import "./ILandYield.sol";
import "./IMintPass.sol";
import "./ICollectorPool.sol";


contract ZokuMinter is Ownable, ReentrancyGuard {
  // Collection token contract interface
  ILandCollection public landCollection;
  // LandYield contract interface
  ILandYield public landYield;
  // MintPass token contract interface
  IMintPass public mintPass;
  // CollectorPool contract interface
  ICollectorPool public collectorPool;

  // Used to determine whether minting is open to public
  bool public openForPublic;
  // Used to determine whether minting is open to MintPass holders
  bool public openForPass;
  // Stores the currently set token price
  uint256 public tokenPrice;
  // Stores the number of maximum tokens mintable in a single tx
  uint256 public mintLimit;

  // Stores the universal groupId tracked by the main Collection
  uint256 public groupId;

  constructor(
    uint256 _groupId,
    uint256 _price,
    address _landCollection,
    address _landYield,
    address _mintPass,
    address _collectorPool
  ) {
    mintLimit = 15;
    groupId = _groupId;
    tokenPrice = _price;
    landCollection = ILandCollection(_landCollection);
    landYield = ILandYield(_landYield);
    mintPass = IMintPass(_mintPass);
    collectorPool = ICollectorPool(_collectorPool);
  }

  // Only to be used in case there's a need to upgrade the yield contract mid-sales
  function setLandYield(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    landYield = ILandYield(_address);
  }

  // Only to be used in case there's a need to upgrade the collector pool contract mid-sales
  function setCollectorPool(address _address) external onlyOwner {
    require(_address != address(0), "Invalid Address");
    collectorPool = ICollectorPool(_address);
  }

  // Update the state of the public minting
  function setOpenForPublic(bool _state) external onlyOwner {
    require(openForPublic != _state, "Identical State Has Been Set");
    openForPublic = _state;
  }

  // Update the state of the priority minting
  function setOpenForPass(bool _state) external onlyOwner {
    require(openForPass != _state, "Identical State Has Been Set");
    openForPass = _state;
  }

  // Update the token price only if there's a valid reason to do so
  function setTokenPrice(uint256 _price) external onlyOwner {
    require(_price > 0, "Invalid Price");
    tokenPrice = _price;
  }

  // Set maximum mint limit per tx
  function setMintLimit(uint256 _limit) external onlyOwner {
    require(_limit > 0 && _limit <= 20, "Invalid Value For Limit");
    mintLimit = _limit;
  }

  // Accepts optional passTokenIds for priority minting using MintPass tokens (only before public sales)
  function mint(uint256[] calldata _passTokenIds) external payable nonReentrant {
    // Check if tokens are still available for sale
    uint256 maxSupply = landCollection.maximumSupply(groupId);
    uint256 totalMinted = landCollection.totalMinted(groupId);
    uint256 available = maxSupply - totalMinted;
    available = (available > mintLimit ? mintLimit : available);
    require(available > 0, "Sold Out");

    uint256 mintCount;
    uint256 totalSpent = 0;

    if (_passTokenIds.length > 0) {
      // If passTokenIds are specified, check if priority minting is open and calculate actual total prices after discounts
      require(openForPass, "Priority Minting Is Closed");
      mintCount = _passTokenIds.length;
      mintCount = (mintCount > available ? available : mintCount);

      for (uint256 i = 0; i < mintCount; i++) {
        address passOwner;
        uint256 passDiscount;
        (passOwner, , passDiscount) = mintPass.passDetail(_passTokenIds[i]);
        require(passOwner == msg.sender, "Invalid Pass Specified");

        totalSpent += tokenPrice * (100 - passDiscount) / 100;
      }

      require(msg.value >= totalSpent, "Insufficient Funds");

      for (uint256 i = 0; i < mintCount; i++) {
        mintPass.burnToken(_passTokenIds[i]);
      }
    } else {
      require(openForPublic, "Publis Sale Is Closed");
      require(msg.value >= tokenPrice, "Insufficient Funds");
      mintCount = msg.value / tokenPrice;
      mintCount = (mintCount > available ? available : mintCount);
      totalSpent = mintCount * tokenPrice;
    }

    landCollection.mintToken(msg.sender, groupId, mintCount, available);

    if (totalSpent > 0) {
      // Transfer the funds to the yield contract for land owners and treasury, and leave the rest for collectors
      uint256 yield = totalSpent * 85 / 100;
      uint256 treasury = totalSpent * 5 / 100;
      (bool success, ) = address(landYield).call{value: yield + treasury}(
        abi.encodeWithSignature("distributeSalesYield(uint256)", yield)
      );
      require(success, "Failed To Distribute To Yield");

      // Send back any excess funds
      uint256 refund = msg.value - totalSpent;
      if (refund > 0) {
        payable(msg.sender).transfer(refund);
      }
    }
  }

  // Transfers the remaining funds to the collector pool
  function withdraw() external onlyOwner {
    uint256 totalFunds = address(this).balance;
    require(totalFunds > 0, "Insufficient Funds");
    // Send funds via call function for the collector pool funds
    (bool success, ) = address(collectorPool).call{value: totalFunds}("");
    require(success, "Failed To Distribute To Pool");
  }
}