pragma solidity ^0.4.24;

import "./Roles.sol";
import "./Pausable.sol";
import "./Whitelist.sol";
import "./SafeMath.sol";
import "./ITokenMarketplace.sol";

interface IKODAV2 {
  function ownerOf(uint256 _tokenId) external view returns (address _owner);

  function exists(uint256 _tokenId) external view returns (bool _exists);

  function editionOfTokenId(uint256 _tokenId) external view returns (uint256 tokenId);

  function artistCommission(uint256 _tokenId) external view returns (address _artistAccount, uint256 _artistCommission);

  function editionOptionalCommission(uint256 _tokenId) external view returns (uint256 _rate, address _recipient);

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
}

contract TokenMarketplace is Whitelist, Pausable, ITokenMarketplace {
  using SafeMath for uint256;

  event UpdatePlatformPercentageFee(uint256 _oldPercentage, uint256 _newPercentage);
  event UpdateRoyaltyPercentageFee(uint256 _oldPercentage, uint256 _newPercentage);

  struct Offer {
    address bidder;
    uint256 offer;
  }

  // Min increase in bid amount
  uint256 public minBidAmount = 0.04 ether;

  // Interface into the KODA world
  IKODAV2 public kodaAddress;

  // KO account which can receive commission
  address public koCommissionAccount;

  uint256 public artistRoyaltyPercentage = 50;
  uint256 public platformFeePercentage = 30;

  // Token ID to Offer mapping
  mapping(uint256 => Offer) offers;

  // Explicitly disable sales for specific tokens
  mapping(uint256 => bool) disabledTokens;

  ///////////////
  // Modifiers //
  ///////////////

  modifier onlyWhenOfferOwner(uint256 _tokenId) {
    require(offers[_tokenId].bidder == msg.sender, "Not offer maker");
    _;
  }

  modifier onlyWhenTokenExists(uint256 _tokenId) {
    require(kodaAddress.exists(_tokenId), "Token does not exist");
    _;
  }

  modifier onlyWhenBidOverMinAmount(uint256 _tokenId) {
    require(msg.value >= offers[_tokenId].offer.add(minBidAmount), "Offer not enough");
    _;
  }

  modifier onlyWhenTokenAuctionEnabled(uint256 _tokenId) {
    require(!disabledTokens[_tokenId], "Token not enabled for offers");
    _;
  }

  /////////////////
  // Constructor //
  /////////////////

  // Set the caller as the default KO account
  constructor(IKODAV2 _kodaAddress, address _koCommissionAccount) public {
    kodaAddress = _kodaAddress;
    koCommissionAccount = _koCommissionAccount;
    super.addAddressToWhitelist(msg.sender);
  }

  //////////////////
  // User Actions //
  //////////////////

  function placeBid(uint256 _tokenId)
  public
  payable
  whenNotPaused
  onlyWhenTokenExists(_tokenId)
  onlyWhenBidOverMinAmount(_tokenId)
  onlyWhenTokenAuctionEnabled(_tokenId)
  {
    _refundHighestBidder(_tokenId);

    offers[_tokenId] = Offer(msg.sender, msg.value);

    address currentOwner = kodaAddress.ownerOf(_tokenId);

    emit BidPlaced(_tokenId, currentOwner, msg.sender, msg.value);
  }

  function withdrawBid(uint256 _tokenId)
  public
  whenNotPaused
  onlyWhenTokenExists(_tokenId)
  onlyWhenOfferOwner(_tokenId)
  {
    _refundHighestBidder(_tokenId);

    emit BidWithdrawn(_tokenId, msg.sender);
  }

  function rejectBid(uint256 _tokenId)
  public
  whenNotPaused
  {
    address currentOwner = kodaAddress.ownerOf(_tokenId);
    require(currentOwner == msg.sender, "Not token owner");

    uint256 currentHighestBiddersAmount = offers[_tokenId].offer;
    require(currentHighestBiddersAmount > 0, "No offer open");

    address currentHighestBidder = offers[_tokenId].bidder;

    _refundHighestBidder(_tokenId);

    emit BidRejected(_tokenId, currentOwner, currentHighestBidder, currentHighestBiddersAmount);
  }

  function acceptBid(uint256 _tokenId)
  public
  whenNotPaused
  {
    address currentOwner = kodaAddress.ownerOf(_tokenId);
    require(currentOwner == msg.sender, "Not token owner");

    uint256 winningOffer = offers[_tokenId].offer;
    require(winningOffer > 0, "No offer open");

    address winningBidder = offers[_tokenId].bidder;

    delete offers[_tokenId];

    // Get edition no.
    uint256 editionNumber = kodaAddress.editionOfTokenId(_tokenId);

    _handleFunds(editionNumber, winningOffer, currentOwner);

    kodaAddress.safeTransferFrom(msg.sender, winningBidder, _tokenId);

    emit BidAccepted(_tokenId, currentOwner, winningBidder, winningOffer);

  }

  function _refundHighestBidder(uint256 _tokenId) internal {
    // Get current highest bidder
    address currentHighestBidder = offers[_tokenId].bidder;

    // Get current highest bid amount
    uint256 currentHighestBiddersAmount = offers[_tokenId].offer;

    if (currentHighestBidder != address(0) && currentHighestBiddersAmount > 0) {

      // Clear out highest bidder
      delete offers[_tokenId];

      // Refund it
      currentHighestBidder.transfer(currentHighestBiddersAmount);
    }
  }

  function _handleFunds(uint256 _editionNumber, uint256 _offer, address _currentOwner) internal {

    // Get existing artist commission
    (address artistAccount, uint256 artistCommissionRate) = kodaAddress.artistCommission(_editionNumber);

    // Get existing optional commission
    (uint256 optionalCommissionRate, address optionalCommissionRecipient) = kodaAddress.editionOptionalCommission(_editionNumber);

    _splitFunds(artistAccount, artistCommissionRate, optionalCommissionRecipient, optionalCommissionRate, _offer, _currentOwner);
  }

  function _splitFunds(
    address _artistAccount,
    uint256 _artistCommissionRate,
    address _optionalCommissionRecipient,
    uint256 _optionalCommissionRate,
    uint256 _offer,
    address _currentOwner
  ) internal {

    // Work out total % of royalties to payout = creator royalties + KO commission
    uint256 totalCommissionPercentageToPay = platformFeePercentage.add(artistRoyaltyPercentage);

    // Send current owner majority share of the offer
    uint256 totalToSendToOwner = _offer.sub(
      _offer.div(1000).mul(totalCommissionPercentageToPay)
    );
    _currentOwner.transfer(totalToSendToOwner);

    // Send % to KO
    uint256 koCommission = _offer.div(1000).mul(platformFeePercentage);
    koCommissionAccount.transfer(koCommission);

    // Send to seller minus royalties and commission
    uint256 remainingRoyalties = _offer.sub(koCommission).sub(totalToSendToOwner);

    if (_optionalCommissionRecipient == address(0)) {
      // After KO and Seller - send the rest to the original artist
      _artistAccount.transfer(remainingRoyalties);
    } else {
      _handleOptionalSplits(_artistAccount, _artistCommissionRate, _optionalCommissionRecipient, _optionalCommissionRate, remainingRoyalties);
    }
  }

  function _handleOptionalSplits(
    address _artistAccount,
    uint256 _artistCommissionRate,
    address _optionalCommissionRecipient,
    uint256 _optionalCommissionRate,
    uint256 _remainingRoyalties
  ) internal {
    uint256 _totalCollaboratorsRate = _artistCommissionRate.add(_optionalCommissionRate);
    uint256 _scaledUpCommission = _artistCommissionRate.mul(10 ** 18);

    // work out % of royalties total to split e.g. 43 / 85 = 50.5882353%
    uint256 primaryArtistPercentage = _scaledUpCommission.div(_totalCollaboratorsRate);

    uint256 totalPrimaryRoyaltiesToArtist = _remainingRoyalties.mul(primaryArtistPercentage).div(10 ** 18);
    _artistAccount.transfer(totalPrimaryRoyaltiesToArtist);

    uint256 remainingRoyaltiesToCollaborator = _remainingRoyalties.sub(totalPrimaryRoyaltiesToArtist);
    _optionalCommissionRecipient.transfer(remainingRoyaltiesToCollaborator);
  }

  ///////////////////
  // Query Methods //
  ///////////////////

  function tokenOffer(uint256 _tokenId) external view returns (address _bidder, uint256 _offer, address _owner, bool _enabled, bool _paused) {
    Offer memory offer = offers[_tokenId];
    return (
    offer.bidder,
    offer.offer,
    kodaAddress.ownerOf(_tokenId),
    !disabledTokens[_tokenId],
    paused
    );
  }

  function determineSaleValues(uint256 _tokenId) external view returns (uint256 _sellerTotal, uint256 _platformFee, uint256 _royaltyFee) {
    Offer memory offer = offers[_tokenId];
    uint256 offerValue = offer.offer;
    uint256 fee = offerValue.div(1000).mul(platformFeePercentage);
    uint256 royalties = offerValue.div(1000).mul(artistRoyaltyPercentage);

    return (
    offer.offer.sub(fee).sub(royalties),
    fee,
    royalties
    );
  }

  ///////////////////
  // Admin Actions //
  ///////////////////

  function disableAuction(uint256 _tokenId)
  public
  onlyIfWhitelisted(msg.sender)
  {
    _refundHighestBidder(_tokenId);

    disabledTokens[_tokenId] = true;

    emit AuctionDisabled(_tokenId, msg.sender);
  }

  function enableAuction(uint256 _tokenId)
  public
  onlyIfWhitelisted(msg.sender)
  {
    _refundHighestBidder(_tokenId);

    disabledTokens[_tokenId] = false;

    emit AuctionEnabled(_tokenId, msg.sender);
  }

  function setMinBidAmount(uint256 _minBidAmount) onlyIfWhitelisted(msg.sender) public {
    minBidAmount = _minBidAmount;
  }

  function setKodavV2(IKODAV2 _kodaAddress) onlyIfWhitelisted(msg.sender) public {
    kodaAddress = _kodaAddress;
  }

  function setKoCommissionAccount(address _koCommissionAccount) public onlyIfWhitelisted(msg.sender) {
    require(_koCommissionAccount != address(0), "Invalid address");
    koCommissionAccount = _koCommissionAccount;
  }

  function setArtistRoyaltyPercentage(uint256 _artistRoyaltyPercentage) public onlyIfWhitelisted(msg.sender) {
    emit UpdateRoyaltyPercentageFee(artistRoyaltyPercentage, _artistRoyaltyPercentage);
    artistRoyaltyPercentage = _artistRoyaltyPercentage;
  }

  function setPlatformPercentage(uint256 _platformFeePercentage) public onlyIfWhitelisted(msg.sender) {
    emit UpdatePlatformPercentageFee(platformFeePercentage, _platformFeePercentage);
    platformFeePercentage = _platformFeePercentage;
  }
}