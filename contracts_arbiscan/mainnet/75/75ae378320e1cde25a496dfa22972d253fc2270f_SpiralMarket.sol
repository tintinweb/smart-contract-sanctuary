// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC721.sol";

abstract contract IImpishSpiral is IERC721 {}

contract SpiralMarket is Ownable, ReentrancyGuard {
  bool public isPaused;

  IImpishSpiral public impishspiral;

  struct Listing {
    // What price is it listed for
    uint256 price;

    // The owner that listed it. If the owner has changed, it can't be sold anymore.
    address owner;
  }

  // Listing of all Tokens that are for sale
  mapping (uint256 => Listing) public forSale;

  // Fee rate in bips (1% = 100 bips)
  uint256 public feeRate  = 0;

  constructor(address _impishspiral) {
    isPaused = false;
    impishspiral = IImpishSpiral(_impishspiral);
  }

  // Modifiers
  modifier whenNotPaused() {
      require(!isPaused, "Paused");
      _;
  }

  // Pause if something goes wrong
  function pauseContract() external onlyOwner {
    isPaused = true;
  }

  event SpiralMarketEvent(uint8 indexed eventType, uint256 indexed tokenId, address indexed owner, uint256 price);
    
  function setFeeRate(uint256 _feeRate) external onlyOwner whenNotPaused {
    require(_feeRate < 10 * 100, "BadFee"); // Fee can't exceed 10%

    feeRate = _feeRate;
  }

  function listSpiral(uint256 tokenId, uint256 price) external whenNotPaused nonReentrant {
    require(price > 0, "NeedPrice");
    require(impishspiral.ownerOf(tokenId) == msg.sender, "TokenNotOwned");
    require(impishspiral.isApprovedForAll(msg.sender, address(this)), "NotApproved");

    // If a listing already exists, it will be overwritten
    forSale[tokenId] = Listing(price, msg.sender);

    emit SpiralMarketEvent(1, tokenId, msg.sender, price);
  }

  // Cancel an existing listing
  function cancelListing(uint256 tokenId) external nonReentrant {
    require(impishspiral.ownerOf(tokenId) == msg.sender, "TokenNotOwned");

    delete forSale[tokenId];

    emit SpiralMarketEvent(2, tokenId, msg.sender, 0);
  }

  function buySpiral(uint256 tokenId) external payable whenNotPaused nonReentrant {
    require(forSale[tokenId].price > 0, "NotListed");

    address seller = forSale[tokenId].owner;

    require(impishspiral.ownerOf(tokenId) == seller, "OwnerChanged");
    require(impishspiral.isApprovedForAll(seller, address(this)), "NotApproved");
    
    // Enough ETH has been sent
    require(msg.value == forSale[tokenId].price, "IncorrectETH");

    // Everything looks fine, settle the token
    // Step 0: Calculate fees
    uint256 fee = (msg.value * feeRate) / (100 * 100);
    uint256 sellerAmount = msg.value - fee;

    // Step 1: Delist the Spiral
    delete forSale[tokenId];

    // Step 2: Transfer the ETH
    (bool success, ) = seller.call{value: sellerAmount}("");
    require(success, "Transfer failed.");

    // Step 3: Transfer the Spiral
    impishspiral.safeTransferFrom(seller, msg.sender, tokenId);

    // Fees remain in the contract, and can be withdrawn with withdrawFees()

    // Emit buy event
    emit SpiralMarketEvent(3, tokenId, msg.sender, msg.value);
  }

  // Is this listing valid? i.e., Is this token listed for sale and is the owner 
  // still selling it?
  function isListingValid(uint256 tokenId) public view returns (bool) {
    if (forSale[tokenId].price == 0) {
      return false;
    }

    if (forSale[tokenId].owner != impishspiral.ownerOf(tokenId)) {
      return false;
    }

    if (!impishspiral.isApprovedForAll(forSale[tokenId].owner, address(this))) {
      return false;
    }

    if (isPaused) {
      return false;
    }

    return true;
  }

  function withdrawFees() external onlyOwner nonReentrant {
    (bool success, ) = owner().call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
}