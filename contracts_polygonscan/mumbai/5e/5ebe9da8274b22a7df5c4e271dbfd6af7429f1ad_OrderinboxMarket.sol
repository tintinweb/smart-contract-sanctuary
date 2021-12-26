// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.9.0;
pragma abicoder v2;

import "./MarketCore.sol";

contract OrderinboxMarket is MarketCore {

    function __OrderinboxMarket_init(
        IMarketEscrow escrow,
        IMarketExchange exchange
    ) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ListingCore_init_unchained();
        __MarketListing_init_unchained(escrow, exchange);
        __MarketReserveAuction_init_unchained();
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./IMarketEscrow.sol";

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for a pull payment instead.
 */
abstract contract SendValueWithFallbackPullPayment is ReentrancyGuardUpgradeable, IMarketEscrow {
  using AddressUpgradeable for address payable;
  using SafeMathUpgradeable for uint256;

  mapping(address => uint256) private pendingPayments;

  event PullPaymentPending(address indexed user, uint256 amount);
  event PullPayment(address indexed user, uint256 amount);

  /**
   * @notice Returns how much funds are available for manual withdraw due to failed transfers.
   */
  function getPendingPullPayment(address user) public view override returns (uint256) {
    return pendingPayments[user];
  }

  /**
   * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
   */
  function pullPayment() public override {
    pullPaymentFor(payable(msg.sender));
  }

  /**
   * @notice Allows anyone to manually trigger a PullPayment of funds which originally failed to transfer for a user.
   */
  function pullPaymentFor(address payable user) public override nonReentrant {
    uint256 amount = pendingPayments[user];
    require(amount > 0, "No funds are pending pull");
    pendingPayments[user] = 0;
    user.sendValue(amount);
    emit PullPayment(user, amount);
  }

  /**
   * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
   * which is enough to send to contracts as well.
   */
  function _sendValueWithFallbackPullPaymentWithLowGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackPullPayment(user, amount, 20000);
  }

  /**
   * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
   * which is enough for a 5-way split.
   */
  function _sendValueWithFallbackPullPaymentWithMediumGasLimit(address payable user, uint256 amount) internal {
    _sendValueWithFallbackPullPayment(user, amount, 90000);
  }

  /**
   * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later PullPayment.
   */
  function _sendValueWithFallbackPullPayment(
    address payable user,
    uint256 amount,
    uint256 gasLimit
  ) internal {
    if (amount == 0) {
      return;
    }
    // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = user.call{ value: amount, gas: gasLimit }("");
    if (!success) {
      // Record failed sends for a PullPayment later
      // Transfers could fail if sent to a multisig with non-trivial receiver logic
      // solhint-disable-next-line reentrancy
      pendingPayments[user] = pendingPayments[user].add(amount);
      emit PullPaymentPending(user, amount);
    }
  }

  uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.6.2 <0.9.0;
pragma abicoder v2;

import "./MarketListing.sol";

abstract contract MarketReserveAuction is MarketListing
{
  using SafeMathUpgradeable for uint256;

  uint256 private constant BASIS_POINTS = 10000;

  uint256 private _minPercentIncrementInBasisPoints;
  uint256 private _defaultDuration;           // reserved auction duration
  uint256 private _defaultExtensionDuration;  // reserved auction duration

  // Cap the max duration so that overflows will not occur
  uint256 private constant MIN_DURATION = 1 hours;
  uint256 private constant MAX_DURATION = 1000 days;

  uint256 private constant MIN_EXTENSION_DURATION = 15 minutes;

  event ReserveAuctionConfigUpdated(
    uint256 minPercentIncrementInBasisPoints,
    uint256 defaultDuration,
    uint256 defaultExtensionDuration
  );

  event ReserveAuctionBidPlaced(uint256 indexed listingId, address indexed bidder, uint256 amount, uint256 endTime);

  /**
   * @notice Returns the current configuration for reserve auctions.
   */
  function getReserveAuctionConfig() public view returns (uint256 minPercentIncrementInBasisPoints, uint256 defaultDuration, uint256 defaultExtensionDuration) {
    minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
    defaultDuration = _defaultDuration;
    defaultExtensionDuration = _defaultExtensionDuration;
  }

  function __MarketReserveAuction_init_unchained() internal initializer {
    _defaultDuration = 24 hours; // A sensible default value
    _defaultExtensionDuration = MIN_EXTENSION_DURATION;
  }

  function updateReserveAuctionConfig(uint256 minPercentIncrementInBasisPoints, uint256 defaultDuration, uint256 defaultExtensionDuration) public onlyOwner {
    require(minPercentIncrementInBasisPoints <= BASIS_POINTS, "Min increment must be <= 100%");

    // Cap the max duration so that overflows will not occur
    require(defaultDuration >= MIN_DURATION && defaultDuration <= MAX_DURATION, "Default duration must be between MIN_DURATION and MAX_DURATION");
    require(defaultExtensionDuration >= MIN_EXTENSION_DURATION, "Default extension duration must be >= MIN_EXTENSION_DURATION");
    require(defaultDuration >= defaultExtensionDuration, "Default duration must be >= default extension duration");
    _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
    _defaultDuration = defaultDuration;
    _defaultExtensionDuration = defaultExtensionDuration;

    // We continue to emit unused configuration variables to simplify the subgraph integration.
    emit ReserveAuctionConfigUpdated(minPercentIncrementInBasisPoints, defaultDuration, defaultExtensionDuration);
  }

  /**
   * @notice Creates a reserve auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createReserveAuction(
    LibAsset.Asset memory makeAsset,
    LibAsset.Asset memory takeAsset,
    uint256 startTime,        // When does the listing start accepting offers/bids
    uint256 duration,
    uint256 extensionDuration
  ) public nonReentrant returns (uint) {

    require(duration >= MIN_DURATION && duration <= MAX_DURATION, "Reserve auction duration must be between MIN_DURATION and MAX_DURATION");
    require(extensionDuration >= MIN_EXTENSION_DURATION, "Reserve auction extension duration must be >= MIN_EXTENSION_DURATION");
    require(duration >= extensionDuration, "Reserve auction duration must be >= extension duration");

    return createListing(makeAsset, takeAsset, LibListing.ListingType.RESERVE_AUCTION, startTime, duration, extensionDuration);
  }

  /**
   * @notice Place bid for a reserve auction.
   */
  function placeBid(uint256 listingId, uint256 bidAmount) public payable nonReentrant {
    LibListing.Listing storage listing = listingIdToListing[listingId];
    LibAsset.Asset memory takeAsset = listing.takeAsset;

    require(takeAsset.value != 0, "Listing not found");
    require(listing.listingType == LibListing.ListingType.RESERVE_AUCTION, "Only reserve auctions accept bids");
    require(block.timestamp >= listing.startTime, "Reserve auction hasn't started yet");
    require(listing.endTime == 0 || listing.endTime >= block.timestamp, "Reserve auction is over");
    require(listing.bidder != msg.sender, "You already have an outstanding bid");

    // If this is the first bid, ensure it's >= the take value
    require(takeAsset.value <= bidAmount, "Bid must be at least the reserve price");

    // If this bid outbids another, confirm that the bid is at least x% greater than the last
    require(bidAmount >= _getMinBidAmountForReserveAuction(listing.bid), "Bid amount needs to be higher than the min bid amount");

    // Mark bid asset as escrowed
    _placeBid(listingId, bidAmount);

    if (listing.endTime == 0) {
      // On the first bid, the endTime is now + duration
      listing.endTime = block.timestamp + listing.reserveAuctionDuration;
    } 
    else if (listing.endTime - block.timestamp < listing.reserveAuctionExtensionDuration) {
      // When a bid outbids another, check to see if a time extension should apply.
      listing.endTime = block.timestamp + listing.reserveAuctionExtensionDuration;
    }

    emit ReserveAuctionBidPlaced(listingId, msg.sender, bidAmount, listing.endTime);
  }

  function finalizeReserveAuction(uint256 listingId) public nonReentrant {
    LibListing.Listing memory listing = listingIdToListing[listingId];
    require(listing.listingType == LibListing.ListingType.RESERVE_AUCTION, "Listing is not a reserve auction");

   _finalizeExchangeAndDistributeFunds(listingId);
  }

  /**
   * @notice Returns the minimum amount a bidder must spend to participate in an auction.
   */
  function getMinBidAmount(uint256 listingId) public view returns (uint256) {
    LibListing.Listing memory listing = listingIdToListing[listingId]; // Check if this is a reserve auction listing???

    if (listing.endTime == 0) {
      return listing.takeAsset.value;
    }

    return _getMinBidAmountForReserveAuction(listing.bid);
  }

  /**
   * @dev Determines the minimum bid amount when outbidding another user.
   */
  function _getMinBidAmountForReserveAuction(uint256 currentBidAmount) private view returns (uint256) {
    uint256 minIncrement = currentBidAmount.mul(_minPercentIncrementInBasisPoints) / BASIS_POINTS;
    if (minIncrement == 0) {
      // The next bid must be at least 1 wei greater than the current.
      minIncrement = 1;
    }
    return currentBidAmount.add(minIncrement);
  }


  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.9 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MarketOperatorRole is OwnableUpgradeable {
    mapping (address => bool) operators;

    function __MarketOperatorRole_init() external initializer {
        __MarketOperatorRole_init_unchained();
    }

    function __MarketOperatorRole_init_unchained() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
    }

    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
    }

    modifier onlyOperator() {
        require(operators[_msgSender()], "MarketOperatorRole: caller is not the operator");
        _;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.6.2 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@orderinbox/royalties/contracts/LibPart.sol";
import "@orderinbox/asset/contracts/LibAsset.sol";
import "@orderinbox/transfer-proxy/contracts/transfer/LibTransfer.sol";
import "./LibListing.sol";
import "./ListingCore.sol";
import "./IMarketEscrow.sol";
import "./IMarketExchange.sol";

abstract contract MarketListing is 
  Initializable,
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  ListingCore
{
  using SafeMathUpgradeable for uint256;
  using CountersUpgradeable for CountersUpgradeable.Counter;
  using LibTransfer for address;
  using LibTransfer for LibAsset.Asset;
  
  uint256 private constant BASIS_POINTS = 10000;
  
  IMarketEscrow internal _escrow;
  IMarketExchange internal _exchange;

  // We will keep the asset in escrow until it is sold or auction is finalized!

  mapping(address => mapping(uint256 => uint256)) private nftContractToTokenIdToListingId;
  mapping(uint256 => LibListing.Listing) internal listingIdToListing;

  event ListingCreated(
    uint256 listingId,

    LibListing.ListingType listingType,

    address maker,
    LibAsset.Asset makeAsset,
    LibAsset.Asset takeAsset,
    
    uint256 startTime,

    uint256 auctionDuration,
    uint256 auctionExtensionDuration
  );

  event ListingUpdated(uint256 indexed listingId, LibAsset.Asset takeAsset);
  event ListingCanceled(uint256 indexed listingId);
  event ListingCanceledByAdmin(uint256 indexed listingId, string reason);
  event ListingBidPlaced(uint256 indexed listingId, address indexed bidder, uint256 bidAmount);
  event ListingFinalized(uint256 indexed listingId, uint256 sellerExchangeFee, uint256 sellerOriginFee, uint256 buyerExchangeFee, uint256 buyerOriginFee);

  modifier onlyValidListingConfig(uint256 takeValue) {
    require(takeValue > 0, "Take value must be at least 1 wei");
    _;
  }

  function __MarketListing_init_unchained(
    IMarketEscrow escrow,
    IMarketExchange exchange) internal initializer {
    _escrow = escrow;
    _exchange = exchange;
  }

  /**
   * @notice Returns listing details for a given listingId.
   */
  function getListing(uint256 listingId) public view returns (LibListing.Listing memory) {
    return listingIdToListing[listingId];
  }

  /**
   * @notice Returns the listingId for a given NFT, or 0 if no listing is found.
   * @dev If a listing is canceled, it will not be returned. However the listing may be over and pending finalization.
   */
  function getListingIdFor(address nftContract, uint256 tokenId) public view returns (uint256) {
    return nftContractToTokenIdToListingId[nftContract][tokenId];
  }

  /**
   * @dev Returns the seller that put a given NFT into escrow
   */
  function _getSellerFor(address nftContract, uint256 tokenId)
    internal
    view
    virtual
    returns (address payable)
  {
    uint256 listingId = nftContractToTokenIdToListingId[nftContract][tokenId];
    LibListing.Listing memory listing = listingIdToListing[listingId];
    address payable seller = listing.seller;

    return seller;
  }

  /**
   * @notice Creates a listing for a given NFT. 
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createListing(
    LibAsset.Asset memory makeAsset,
    LibAsset.Asset memory takeAsset,
    LibListing.ListingType listingType,  // We will add start and end dates here?
    uint256 startTime,        // When does the listing start accepting offers/bids
    uint256 duration,         // Only useful in case this is a reserve auction listing
    uint256 extensionDuration // Only useful in case this is a reserve auction listing
  ) internal onlyValidListingConfig(takeAsset.value) returns (uint listingId) {

    require(makeAsset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS || 
            makeAsset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS, "Make asset is not an NFT");

    require(takeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS || 
            takeAsset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS, "Take asset class not supported"); // Should we add 1155 here as it has value??

    // Deposit the asset to escrow
    _depositToEscrow(_msgSender(), makeAsset);

    // Check go live time within a reasonable time frame??

    // Get the make asset contract
    (address token, uint256 tokenId) = abi.decode(makeAsset.assetType.data, (address, uint256));

    // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
    listingId = _getNextAndIncrementListingId();

    nftContractToTokenIdToListingId[token][tokenId] = listingId;

    listingIdToListing[listingId] = LibListing.Listing(
      listingType,

      payable(_msgSender()),
      makeAsset,
      takeAsset,

      payable(address(0)), // bidder is known only after once a bid has been placed
      0, // bid
      0, // bidTotal

      startTime, // This is the go live date... Any bids or purchase requests before this time is not accepted
      0, // endTime is known only after the reserve price is met

      duration,
      extensionDuration,

      0,
      "" // clear data?
    );

    emit ListingCreated(
      listingId,
      listingType,
      _msgSender(),
      makeAsset,
      takeAsset,
      startTime,
      duration,
      extensionDuration
    );
  }

  /**
   * @notice If an listing has been created but has not yet received bids, the configuration
   * such as the takeValue may be changed by the seller.
   */
  function updateListing(uint256 listingId, LibAsset.Asset memory takeAsset) public onlyValidListingConfig(takeAsset.value) nonReentrant {
    LibListing.Listing storage listing = listingIdToListing[listingId];
    require(listing.seller == _msgSender(), "Not your listing");
    require(listing.endTime == 0, "Auction in progress");

    require(takeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS || 
            takeAsset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS, "Asset class not supported"); // Should we add 1155 here as it has value??

    listing.takeAsset = takeAsset;

    emit ListingUpdated(listingId, takeAsset);
  }

  /**
   * @notice If an listinh has been created but has not yet received bids, it may be canceled by the seller.
   * The NFT is returned to the seller from escrow.
   */
  function cancelListing(uint256 listingId) public nonReentrant {
    LibListing.Listing memory listing = listingIdToListing[listingId];
    require(listing.seller == _msgSender(), "Not your listing");
    require(listing.endTime == 0, "Auction in progress");

    _cancelListingAndRefundFunds(listingId);

    emit ListingCanceled(listingId);
  }

  /**
   * @notice Allows Orderinbox to cancel an auction, refunding the bidder and returning the NFT to the seller.
   * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
   */
  function adminCancelListing(uint256 listingId, string memory reason) public nonReentrant onlyOwner {
    require(bytes(reason).length > 0, "Include a reason for this cancellation");
    
    LibListing.Listing memory listing = listingIdToListing[listingId];
    require(listing.takeAsset.value > 0, "Listing not found");

    _cancelListingAndRefundFunds(listingId);

    emit ListingCanceledByAdmin(listingId, reason);
  }

  function _cancelListingAndRefundFunds(uint256 listingId) internal {   
    LibListing.Listing memory listing = listingIdToListing[listingId];
    require(listing.takeAsset.value > 0, "Listing not found");

    // Get the make asset contract
    (address token, uint256 tokenId) = abi.decode(listing.makeAsset.assetType.data, (address, uint256));

    delete nftContractToTokenIdToListingId[token][tokenId];
    delete listingIdToListing[listingId];

    // Anything that was in escrow needs to be sent back to the seller
    _withdrawFromEscrowLowGasLimit(listing.seller, listing.makeAsset);

    // If there was a bid, send it back to the bidder!
    if (listing.bidder != address(0)) {    
      _withdrawFromEscrowMediumGasLimit(listing.bidder, LibAsset.Asset(listing.takeAsset.assetType, listing.bidTotal));
    }
  }

  function _placeBid(uint256 listingId, uint bidAmount) internal returns (uint totalBidAmount) {
    LibListing.Listing storage listing = listingIdToListing[listingId];
    LibAsset.Asset memory takeAsset = listing.takeAsset;
    require(takeAsset.value != 0, "Listing not found");
    require(block.timestamp >= listing.startTime, "Listing is not available for purchases yet");

    uint256 originalBidTotal = listing.bidTotal;
    address payable originalBidder = listing.bidder;

    // We need to calculate the total amount (including the protocol fee and the origin fee)
    // and see if we were sent more than that
    totalBidAmount = _exchange.calculateTotalAmount(bidAmount);

    LibAsset.Asset memory totalTakeAsset = LibAsset.Asset(listing.takeAsset.assetType, totalBidAmount);

    _depositToEscrow(_msgSender(), totalTakeAsset);

    listing.bid = bidAmount;
    listing.bidTotal = totalBidAmount;
    listing.bidder = payable(_msgSender());

    if(originalBidTotal > 0){
      // Refund the previous bidder
      _withdrawFromEscrowLowGasLimit(originalBidder, LibAsset.Asset(listing.takeAsset.assetType, originalBidTotal));
    }

    // Send the overpayment back
    if (takeAsset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS && msg.value > totalBidAmount) {      
      LibAsset.Asset memory refundAsset = LibAsset.Asset(takeAsset.assetType, msg.value.sub(totalBidAmount));

      refundAsset.safeTransferFrom(address(this), _msgSender()); 
    }

    emit ListingBidPlaced(listingId, listing.bidder, bidAmount);
  }

  /**
   * @notice Once an auction or a fixed price listing engs, anyone can settle it.
   * For an auction, this will send the NFT to the highest bidder and distribute funds.
   */
  function _finalizeExchangeAndDistributeFunds(uint256 listingId) internal {
    LibListing.Listing memory listing = listingIdToListing[listingId];
    require(listing.endTime > 0, "Auction has not started");
    require(listing.endTime < block.timestamp, "Auction still in progress");

    // Execute the transfer through the exchange
    _exchange.doTransfers(
      listing.seller,
      listing.makeAsset,
      listing.bidder,
      LibAsset.Asset(listing.takeAsset.assetType, listing.bid)); // this assumes the escrow is at address(this)

    // Get the make asset contract
    (address token, uint256 tokenId) = abi.decode(listing.makeAsset.assetType.data, (address, uint256));

    delete nftContractToTokenIdToListingId[token][tokenId];
    delete listingIdToListing[listingId];

    // Return what was in the escrow!
    // we need to release the funds from the escrow now
    _escrow.unregister(listing.seller, listing.makeAsset);

    // This was part of the escrow, just unregister (no transfer, just remove it)
    _escrow.unregister(listing.bidder, LibAsset.Asset(listing.takeAsset.assetType, listing.bidTotal));

    (uint256 sellerExchangeFee, uint256 buyerExchangeFee) = _exchange.getExchangeFees();
    (uint256 sellerOriginFee, uint256 buyerOriginFee) = _exchange.getOriginFees();

    emit ListingFinalized(listingId, sellerExchangeFee, sellerOriginFee, buyerExchangeFee, buyerOriginFee);
  }  

  function _depositToEscrow(address refundee, LibAsset.Asset memory asset) internal {
    if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
      require(asset.value <= msg.value, "Not enough ETH was sent");

      _escrow.deposit{value: asset.value}(refundee, asset);
    }
    else {
      // Transfer the take asset to escrow!
      // This is using safetransfer, so it checks whether the transfer succeeded internally
      asset.safeTransferFrom(refundee, address(_escrow)); // We do this

      _escrow.register(refundee, asset);
    }
  }

  function _withdrawFromEscrowMediumGasLimit(address refundee, LibAsset.Asset memory asset) internal {
    // In case of ETH, this falls back to pull payment if the transfer cannot succeed
    _escrow.withdraw(refundee, asset, 90000);
  }

  function _withdrawFromEscrowLowGasLimit(address refundee, LibAsset.Asset memory asset) internal {
    // In case of ETH, this falls back to pull payment if the transfer cannot succeed
    _escrow.withdraw(refundee, asset, 20000);
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.6.2 <0.9.0;
pragma abicoder v2;

import "./MarketListing.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@orderinbox/transfer-proxy/contracts/transfer/LibTransfer.sol";
import "./LibListing.sol";

abstract contract MarketFixedPriceListing is MarketListing
{
  event FixedPricePurchase(uint256 indexed listingId, address indexed buyer);

  /**
   * @notice Creates a reserve auction for the given NFT.
   * The NFT is held in escrow until the auction is finalized or canceled.
   */
  function createFixedPriceListing(
    LibAsset.Asset memory makeAsset,
    LibAsset.Asset memory takeAsset,
    uint256 startTime        // When does the listing start accepting offers
  ) public nonReentrant returns (uint) {
    return createListing(makeAsset, takeAsset, LibListing.ListingType.FIXED_PRICE, startTime, 0, 0);
  }

  function purchase(uint256 listingId) public payable nonReentrant {
    LibListing.Listing storage listing = listingIdToListing[listingId];
    require(listing.takeAsset.value != 0, "Listing not found");
    require(block.timestamp >= listing.startTime, "Listing is not available for purchases yet");
    require(listing.listingType == LibListing.ListingType.FIXED_PRICE, "Only fixed price listings can be purchased");

    // Mark asset as escrowed
    _placeBid(listingId, listing.takeAsset.value);

    // Mark this as the bid
    listing.endTime = block.timestamp - 1;

    // Finalize the sale and distribute funds
    _finalizeExchangeAndDistributeFunds(listingId);

    emit FixedPricePurchase(listingId, _msgSender());
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.6.2 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@orderinbox/asset/contracts/LibAsset.sol";
import "@orderinbox/transfer-proxy/contracts/transfer/LibTransfer.sol";
import "./MarketOperatorRole.sol";
import "./IMarketEscrow.sol";
import "./SendValueWithFallbackPullPayment.sol";

abstract contract MarketEscrow is 
  Initializable, 
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  ERC721HolderUpgradeable,
  ERC1155HolderUpgradeable,
  MarketOperatorRole,
  IMarketEscrow,
  SendValueWithFallbackPullPayment
{
  using AddressUpgradeable for address payable;
  using SafeMathUpgradeable for uint256;
  using SafeERC20Upgradeable for IERC20Upgradeable;
  using LibTransfer for LibAsset.Asset;
  using LibAsset for LibAsset.AssetType;
 
  event Deposited(address indexed refundee, LibAsset.Asset asset);
  event Withdrawn(address indexed refundee, LibAsset.Asset asset);
  event Registered(address indexed refundee, LibAsset.Asset asset);
  event Unregistered(address indexed refundee, LibAsset.Asset asset);

  // Keep an map of assets being held in escrow for addresses in each asset type
  mapping(bytes32 => mapping(address => uint256)) private _deposits;

  mapping(address => uint256) private _pendingPayments;

  function __MarketEscrow_init_unchained() internal initializer {
    __Context_init_unchained();
    __Ownable_init_unchained();
    __ERC721Holder_init_unchained();
    __ERC1155Holder_init_unchained();
  } 

  function deposit(address refundee, LibAsset.Asset memory asset) public payable override onlyOperator {
    asset.safeTransferFrom(refundee, address(this));

    _deposits[asset.assetType.hash()][refundee] += asset.value;

    emit Deposited(refundee, asset);
  }

  function withdraw(address refundee, LibAsset.Asset memory asset, uint gasLimit) public override onlyOperator {
    require(_deposits[asset.assetType.hash()][refundee] >= asset.value, "No such asset is in escrow");
     
    // Make sure we subtract the refunded asset first to prevent the reentrancy attacks
    _deposits[asset.assetType.hash()][refundee] -= asset.value;

    // Check if this is an ETH transfer
    if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
      _sendValueWithFallbackPullPayment(payable(refundee), asset.value, gasLimit);
    }
    else {
      asset.safeTransferFrom(address(this), refundee);
    }
      
    emit Withdrawn(refundee, asset);
  }


  function register(address refundee, LibAsset.Asset memory asset) public override onlyOperator {
    _deposits[asset.assetType.hash()][refundee] += asset.value;

    emit Registered(refundee, asset);
  }

  function unregister(address refundee, LibAsset.Asset memory asset) public override onlyOperator {
    require(_deposits[asset.assetType.hash()][refundee] >= asset.value, "No such asset is registered in escrow");
     
    _deposits[asset.assetType.hash()][refundee] -= asset.value;
      
    emit Unregistered(refundee, asset);
  }

  function depositsOf(address refundee, LibAsset.AssetType memory assetType) public view override returns (uint256) {
    return _deposits[assetType.hash()][refundee];
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity >=0.6.2 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./MarketEscrow.sol";
import "./MarketFixedPriceListing.sol";
import "./MarketReserveAuction.sol";

abstract contract MarketCore is 
  Initializable, 
  OwnableUpgradeable,
  ReentrancyGuardUpgradeable,
  MarketFixedPriceListing,
  MarketReserveAuction
{
  function __MarketCore_init_unchained() internal initializer {
//    __MarketReserveAuction_init_unchained();
  }

  uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

/**
 * @notice An abstraction layer for listings.
 * @dev This contract can be expanded with reusable calls and data as more listing types are added.
 */
abstract contract ListingCore {

    using CountersUpgradeable for CountersUpgradeable.Counter;
    
    CountersUpgradeable.Counter private _listingIdTracker;

    function __ListingCore_init_unchained() internal {
        _listingIdTracker.increment(); // start listing ids from 1
    }

    function _getNextAndIncrementListingId() internal returns (uint256) {
      uint256 nextListingId = _listingIdTracker.current();
      _listingIdTracker.increment();
      return nextListingId;
    }

    uint256[256] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.9.0;

import "@orderinbox/exchange/contracts/lib/LibMath.sol";
import "@orderinbox/asset/contracts/LibAsset.sol";

library LibListing {
    using SafeMathUpgradeable for uint;

    enum ListingType { FIXED_PRICE, RESERVE_AUCTION }

    // We will keep the asset in escrow until it is sold or auction is finalized!
    struct Listing {
        ListingType listingType;

        address payable seller;

        // The is is the item being sold
        LibAsset.Asset makeAsset;

        // in the case of a reserve auction, this becomes the reserve price
        LibAsset.Asset takeAsset;

        address payable bidder;
        uint256 bid; 
        uint256 bidTotal;  // Bid + buyer fees that are added on top

        uint256 startTime;
        uint256 endTime;                        // only known once we have the first bid/offer
        uint256 reserveAuctionDuration;
        uint256 reserveAuctionExtensionDuration;

        bytes4 dataType;
        bytes data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import "@orderinbox/asset/contracts/LibAsset.sol";

abstract contract IMarketExchange {

    function getExchangeFees() public virtual view returns (uint256, uint256);
    function getOriginFees() public virtual view returns (uint96, uint96);

    function calculateTotalAmount(uint amount) public virtual returns (uint);

    function doTransfers(
        address payable maker,
        LibAsset.Asset memory makeAsset,
        address payable taker,
        LibAsset.Asset memory takeAsset) public virtual payable;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;

import "@orderinbox/asset/contracts/LibAsset.sol";

abstract contract IMarketEscrow  {
  function depositsOf(address refundee, LibAsset.AssetType memory assetType) public view virtual returns (uint256);

  function deposit(address refundee, LibAsset.Asset memory asset) public payable virtual;
  function withdraw(address refundee, LibAsset.Asset memory asset, uint gasLimit) public virtual;
  
  function register(address refundee, LibAsset.Asset memory asset) public virtual;
  function unregister(address refundee, LibAsset.Asset memory asset) public virtual;

  function getPendingPullPayment(address user) public view virtual returns (uint256);
  function pullPayment() public virtual;
  function pullPaymentFor(address payable user) public virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.9.0;

import "@orderinbox/asset/contracts/LibAsset.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

library LibTransfer {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function transferEth(address to, uint value) internal {
        if(to != address(this)){
            (bool success,) = to.call{ value: value }("");
            require(success, "Failed to transfer ETH");
        }
    }

    event Transfer(LibAsset.Asset asset, address from, address to);

    function safeTransferFrom(
        LibAsset.Asset memory asset,
        address from,
        address to
    ) internal {
        if (asset.assetType.assetClass == LibAsset.ETH_ASSET_CLASS) {
            transferEth(to, asset.value);
        } else if (asset.assetType.assetClass == LibAsset.ERC20_ASSET_CLASS) {
            (address token) = abi.decode(asset.assetType.data, (address));
            // Unfortunately the transferFrom requires allowance to be set, when we don't explicitly
            // set it for self initiated transfers
            // We opened an issue in the OpenZeppelin libraries: https://github.com/OpenZeppelin/openzeppelin-contracts/issues/2817
            if(from == address(this)) {
                IERC20Upgradeable(token).safeTransfer(to, asset.value);
            }
            else {
                IERC20Upgradeable(token).safeTransferFrom(from, to, asset.value);                
            }
        } else if (asset.assetType.assetClass == LibAsset.ERC721_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            require(asset.value == 1, "erc721 value error");           
            IERC721Upgradeable(token).safeTransferFrom(from, to, tokenId);
        } else if (asset.assetType.assetClass == LibAsset.ERC1155_ASSET_CLASS) {
            (address token, uint tokenId) = abi.decode(asset.assetType.data, (address, uint256));
            IERC1155Upgradeable(token).safeTransferFrom(from, to, tokenId, asset.value, "");
        } else {
            require(false, "unknown asset type");           
        }

        emit Transfer(asset, from, to);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.9.0;

library LibPart {
    bytes32 public constant TYPE_HASH = keccak256("Part(address account,uint96 value)");

    struct Part {
        address payable account;
        uint96 value;
    }

    function hash(Part memory part) internal pure returns (bytes32) {
        return keccak256(abi.encode(TYPE_HASH, part.account, part.value));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

library LibMath {
    using SafeMathUpgradeable for uint;

    /// @dev Calculates partial value given a numerator and denominator rounded down.
    ///      Reverts if rounding error is >= 0.1%
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to calculate partial of.
    /// @return partialAmount value of target rounded down.
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorFloor(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding down.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // The absolute rounding error is the difference between the rounded
        // value and the ideal value. The relative rounding error is the
        // absolute rounding error divided by the absolute value of the
        // ideal value. This is undefined when the ideal value is zero.
        //
        // The ideal value is `numerator * target / denominator`.
        // Let's call `numerator * target % denominator` the remainder.
        // The absolute error is `remainder / denominator`.
        //
        // When the ideal value is zero, we require the absolute error to
        // be zero. Fortunately, this is always the case. The ideal value is
        // zero iff `numerator == 0` and/or `target == 0`. In this case the
        // remainder and absolute error are also zero.
        if (target == 0 || numerator == 0) {
            return false;
        }

        // Otherwise, we want the relative rounding error to be strictly
        // less than 0.1%.
        // The relative error is `remainder / (numerator * target)`.
        // We want the relative error less than 1 / 1000:
        //        remainder / (numerator * target)  <  1 / 1000
        // or equivalently:
        //        1000 * remainder  <  numerator * target
        // so we have a rounding error iff:
        //        1000 * remainder  >=  numerator * target
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = remainder.mul(1000) >= numerator.mul(target);
    }

    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (uint256 partialAmount) {
        if (isRoundingErrorCeil(numerator, denominator, target)) {
            revert("rounding error");
        }
        partialAmount = numerator.mul(target).add(denominator.sub(1)).div(denominator);
    }

    /// @dev Checks if rounding error >= 0.1% when rounding up.
    /// @param numerator Numerator.
    /// @param denominator Denominator.
    /// @param target Value to multiply with numerator/denominator.
    /// @return isError Rounding error is present.
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    ) internal pure returns (bool isError) {
        if (denominator == 0) {
            revert("division by zero");
        }

        // See the comments in `isRoundingError`.
        if (target == 0 || numerator == 0) {
            // When either is zero, the ideal value and rounded value are zero
            // and there is no rounding error. (Although the relative error
            // is undefined.)
            return false;
        }
        // Compute remainder as before
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = denominator.sub(remainder) % denominator;
        isError = remainder.mul(1000) >= numerator.mul(target);
        return isError;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.9.0;

library LibAsset {
    bytes4 constant public ETH_ASSET_CLASS = bytes4(keccak256("ETH"));
    bytes4 constant public ERC20_ASSET_CLASS = bytes4(keccak256("ERC20"));
    bytes4 constant public ERC721_ASSET_CLASS = bytes4(keccak256("ERC721"));
    bytes4 constant public ERC1155_ASSET_CLASS = bytes4(keccak256("ERC1155"));

    bytes32 constant ASSET_TYPE_TYPEHASH = keccak256(
        "AssetType(bytes4 assetClass,bytes data)"
    );

    bytes32 constant ASSET_TYPEHASH = keccak256(
        "Asset(AssetType assetType,uint256 value)AssetType(bytes4 assetClass,bytes data)"
    );

    struct AssetType {
        bytes4 assetClass;
        bytes data;
    }

    struct Asset {
        AssetType assetType;
        uint value;
    }

    function hash(AssetType memory assetType) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPE_TYPEHASH,
                assetType.assetClass,
                keccak256(assetType.data)
            ));
    }

    function hash(Asset memory asset) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                ASSET_TYPEHASH,
                hash(asset.assetType),
                asset.value
            ));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}