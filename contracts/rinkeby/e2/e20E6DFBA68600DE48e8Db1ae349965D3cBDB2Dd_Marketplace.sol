// SPDX-License-Identifier: GPL-3.0
// OptiMarket Contract v1.0 (Development Pre-Production)

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Marketplace is IERC721Receiver, ReentrancyGuard, AccessControlEnumerable {
  using SafeERC20 for IERC20;

  enum TYPE_OF_LISTING {
    PURCHASE,
    DUTCH
  }
  struct Listing {
    uint256 price;
    uint256 timestamp;
    uint256 tokenId;
    bool accepted;
    TYPE_OF_LISTING listingType;
    uint256 decreaseTime;
    //100 means 1%
    uint256 decreasePercentage;
    uint256 minPrice;
    uint256 maxPrice;
  }

  struct Offer {
    uint256 price;
    uint256 timestamp;
    uint256 expiration;
    bool accepted;
    address buyer;
  }

  enum EXPIRATION {
    ONE_DAY,
    THREE_DAYS,
    ONE_WEEK,
    TWO_WEEKS,
    ONE_MONTH,
    THREE_MONTHS,
    SIX_MONTHS
  }

  bytes32 public constant HIGH_ROLE = keccak256("HIGH_ROLE");
  bytes32 public constant LOW_ROLE = keccak256("LOW_ROLE");
  bytes32 public constant EMERGENCY_ROLE = keccak256("EMERGENCY_ROLE");

  bytes4 ERC721EnumHash =
    bytes4(keccak256("totalSupply()")) ^
      bytes4(keccak256("tokenOfOwnerByIndex(address,uint256)")) ^
      bytes4(keccak256("tokenByIndex(uint256)"));

  // Fees are out of 1000, to theoretically allow for 0.1 - 0.9% fees in
  // the future.
  uint256 public devFee = 10; // 1%
  uint256 public totalEscrowedAmount = 0;

  // WETH.
  IERC20 public weth;

  address public devAddress = 0x0000000000000000000000000000000000000000;

  address public featuredCollection = 0x0000000000000000000000000000000000000000;

  address public emergencyAddress = 0x4206900000000000000000000000000000000000;

  bool public tradingPaused = false;
  bool public feesOn = true;
  bool public delistAfterAcceptingOffer = true;
  bool public clearBidsAfterAcceptingOffer = false;
  uint256 public maxAllowedOffers = 10;

  mapping(address => bool) private collectionTradingEnabled;
  mapping(address => mapping(uint256 => Listing[])) private listings;
  mapping(address => mapping(uint256 => Offer[])) private offers;
  mapping(address => address) public collectionOwners;
  mapping(address => uint256) private totalInEscrow;
  mapping(address => uint256) private collectionOwnerFees;
  mapping(address => uint256[]) private listedTokensByCollection;

  event TokenListed(
    address indexed _token,
    uint256 indexed _id,
    uint256 indexed _price,
    uint256 _timestamp,
    TYPE_OF_LISTING _listingType,
    uint256 _decreaseTime,
    uint256 _decreasePercentage,
    uint256 _minPrice,
    uint256 _maxPrice
  );
  event TokenDelisted(address indexed _token, uint256 indexed _id, uint256 _timestamp);
  event TokenPurchased(
    address indexed _oldOwner,
    address indexed _newOwner,
    uint256 indexed _price,
    address _collection,
    uint256 _tokenId
  );
  event BidPlaced(address indexed _token, uint256 indexed _id, uint256 indexed _price, address _buyer, uint256 _timestamp); //solhint-disable
  event BidCancelled(address indexed _token, uint256 indexed _id, uint256 indexed _price, address _buyer, uint256 _timestamp); //solhint-disable
  event BidChanged(
    address indexed _token,
    uint256 indexed _id,
    uint256 indexed _price,
    uint256 _oldPrice,
    address _buyer,
    uint256 _timestamp
  ); //solhint-disable
  event EscrowReturned(address indexed _user, uint256 indexed _price);
  event TradingPausedChanged(bool _paused);
  event TradingCollectionTrading(address indexed _ca, bool _value);
  event ChangedCollectionOwner(address indexed _ca, address _newOwner);
  event ChangedDevFee(uint256 _newFee);
  event ChangedMaxOffers(uint256 _newMaxOffers);
  event ChangedDevAddress(address _newAddress);
  event ChangedEmergencyAddress(address _newAddress);
  event ChangedCollectionOwnerFee(address indexed _ca, uint256 _fee);
  event ChangedFeaturedCollection(address _newCollection);
  event ChangedFeesOn(bool _value);
  event ChangedDelistAfterAcceptingOffer(bool _value);
  event ChangedClearBidsAfterAcceptingOffer(bool _value);
  event RecoveredToken(address indexed _token, uint256 _amount);
  event RecoveredETH(address indexed _to, uint256 _amount);
  event ClearedAllBids(address indexed _ca, uint256 _tokenId);
  event ClearedAllListings(address indexed _ca, uint256 _tokenId);
  event AddedMoneyToEscrow(address indexed _owner, uint256 _amount);
  event ReceivedETH(address indexed _sender, uint256 _amount);
  error AlreadyPlaced(address _bidder);

  constructor() {
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(HIGH_ROLE, msg.sender);
    _setupRole(LOW_ROLE, msg.sender);
    _setupRole(EMERGENCY_ROLE, msg.sender);

    _setupRole(EMERGENCY_ROLE, 0x72346dd4abD04B933750Ff7eA8bD6A067d2d8216);
    _setupRole(HIGH_ROLE, 0x0f7eD6502Edc60f57ec0c23f7BaCd0392d65788C);
    _setupRole(LOW_ROLE, 0xd8255695454436b812064bfe9a2F4D774047A3ea);
  }

  /**********************
   * External functions *
   *********************/

  // LISTINGS
  /**
   * @notice Public wrapper around token delisting, requiring ownership to delist
   * @param _ca collection's address
   * @param _tokenId the token id that we want to delist
   */
  function delistToken(address _ca, uint256 _tokenId) external nonReentrant {
    require(msg.sender == IERC721(_ca).ownerOf(_tokenId), "Only the owner of a token can delist it.");
    _delistToken(_ca, _tokenId);
  }

  /**
   * @notice Lists a token at the specified price point.
   *         It can choose to list as a normal purchase or as a dutch auction
   * @dev it needs approvalForAll done by the user beforehand to manage his nfts of that collection
   * @param _ca collection's address that the token is part of
   * @param _tokenId token id that needs to be listed
   * @param _price the price it needs to be listed on (only if it's normal purchase)
   * @param _listingType it can be either PURCHASE(0) or DUTCH (1)
   * @param _decreaseTime the interval that the price decreases for dutch auctions
   * @param _decreasePercentage the percantage that the price decreases after each interval for dutch auctions
   * @param _minPrice minimum price that the token can be bought in case the auction is dutch
   * @param _maxPrice the starting price point that the token is listed with in case it's dutch auction
   */
  function listToken(
    address _ca,
    uint256 _tokenId,
    uint256 _price,
    TYPE_OF_LISTING _listingType,
    uint256 _decreaseTime,
    uint256 _decreasePercentage,
    uint256 _minPrice,
    uint256 _maxPrice
  ) external nonReentrant {
    IERC721 _nft = IERC721(_ca);
    require(msg.sender == _nft.ownerOf(_tokenId), "Only the owner of a token can list it.");
    require(collectionOwners[_ca] != address(0), "This collection is not listed yet.");

    require(_price > 0, "Cannot set price to 0.");
    require(_nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to handle this users tokens.");

    if (_listingType == TYPE_OF_LISTING.DUTCH) {
      require(_decreasePercentage > 0 && _decreaseTime > 0 && _minPrice < _maxPrice && _minPrice > 0, "Dutch params are wrong"); //solhint-disable
    }

    listings[_ca][_tokenId].push(
      Listing(_price, block.timestamp, _tokenId, false, _listingType, _decreaseTime, _decreasePercentage, _minPrice, _maxPrice)
    );

    listedTokensByCollection[_ca].push(_tokenId);

    emit TokenListed(
      _ca,
      _tokenId,
      _price,
      block.timestamp,
      _listingType,
      _decreaseTime,
      _decreasePercentage,
      _minPrice,
      _maxPrice
    );
  }

  /**
   * @notice Allows a buyer to buy at the listed price if it's normal purchase
   *         or at a certain price based on the time he purchases in case of a dutch auction.
   * @dev it needs weth approval for the token's price
   * @param _ca collection's address
   * @param _tokenId the token id that needs to be purchased
   */
  function purchaseListing(address _ca, uint256 _tokenId) external nonReentrant {
    require(!tradingPaused, "Marketplace trading is disabled.");
    require(collectionTradingEnabled[_ca], "Trading for this collection is not enabled.");
    IERC721 _nft = IERC721(_ca);

    address newOwner = msg.sender;
    // get current NFT owner, verify approval
    address oldOwner = _nft.ownerOf(_tokenId);

    uint256 price = getCurrentListingPrice(_ca, _tokenId);

    require(weth.allowance(msg.sender, address(this)) >= price, "The Marketplace is not approved for this amount");
    require(weth.balanceOf(msg.sender) >= price, "The user does not have enough funds.");
    require(price > 0, "This token is not currently listed.");

    require(_nft.isApprovedForAll(oldOwner, address(this)), "Marketplace not approved to transfer this NFT.");

    // fees calculation
    (uint256 devFeeAmount, uint256 collectionOwnerFeeAmount, uint256 remainder) = calculateAmounts(_ca, price);

    uint256 oldOwnerEthBalance = weth.balanceOf(oldOwner);

    markListingAsAccepted(_ca, _tokenId);
    _delistToken(_ca, _tokenId);

    _nft.safeTransferFrom(oldOwner, newOwner, _tokenId);
    weth.safeTransferFrom(msg.sender, oldOwner, remainder);

    // checks
    require(_nft.ownerOf(_tokenId) == newOwner, "NFT was not successfully transferred.");
    require(weth.balanceOf(oldOwner) >= (oldOwnerEthBalance + remainder), "Funds were not successfully sent.");

    emit TokenPurchased(oldOwner, newOwner, price, _ca, _tokenId);

    // fees
    if (feesOn) {
      weth.safeTransferFrom(msg.sender, collectionOwners[_ca], collectionOwnerFeeAmount);
      weth.safeTransferFrom(msg.sender, devAddress, devFeeAmount);
    }
  }

  /**
   * @notice Creates an offer for a certain token, it does not check if it's listed.
   *         Escrowed bid, meaning bidder weth is transferred to marketplace contract.
   * @dev it needs weth approval for the token's price
   * @param _ca collection's address
   * @param _tokenId the token that it bids for
   * @param _price the price that it wants to bid for this token
   * @param _expirationOption expiration time for this offer
   */
  function escrowedBid(
    address _ca,
    uint256 _tokenId,
    uint256 _price,
    EXPIRATION _expirationOption
  ) external nonReentrant {
    require(msg.sender != IERC721(_ca).ownerOf(_tokenId), "Can not bid on your own NFT.");
    require(_price > 0, "Cannot bid a price of 0.");

    require(weth.allowance(msg.sender, address(this)) >= _price, "The Marketplace is not approved for this amount");
    require(weth.balanceOf(msg.sender) >= _price, "The buyer did not send enough money for an escrowed bid.");
    uint256 length = offers[_ca][_tokenId].length;
    require(length < maxAllowedOffers, "This NFT has reached max allowed offers");
    for (uint256 i; i < length; i++) {
      Offer memory offer = offers[_ca][_tokenId][i];
      if (offer.buyer == msg.sender) revert AlreadyPlaced(msg.sender);
    }
    totalEscrowedAmount += _price;
    totalInEscrow[msg.sender] += _price;
    offers[_ca][_tokenId].push(Offer(_price, block.timestamp, getExpiration(_expirationOption), false, msg.sender));
    weth.safeTransferFrom(msg.sender, address(this), _price);

    emit BidPlaced(_ca, _tokenId, _price, msg.sender, block.timestamp);
  }

  /**
   * @notice Cancel an offer (escrowed or not). Could have gas issues if there's
   *      too many offers...
   */

  /**
   * @notice Deletes a bid. If it's escrowed then the weth is transferred back to the bidder
   * @param _ca collection's address
   * @param _tokenId the token that it bids for
   * @param _price the price that it wants to bid for this token
   */
  function cancelBid(
    address _ca,
    uint256 _tokenId,
    uint256 _price
  ) external nonReentrant {
    Offer[] storage _offers = _getOffers(_ca, _tokenId);

    for (uint256 i = 0; i < _offers.length; i++) {
      if (_offers[i].price == _price && _offers[i].buyer == msg.sender && !_offers[i].accepted) {
        //solhint-disable
        delete offers[_ca][_tokenId][i];
        returnEscrowedFunds(msg.sender, _price);

        emit BidCancelled(_ca, _tokenId, _price, msg.sender, block.timestamp);
        return;
      }
    }

    revert("No cancellable offer found.");
  }

  /**
   * @notice Accepts a bid. If it's escrowed then the weth is from the marketplace address to the seller
   * @dev it needs nft approval for all for the Marketplace contract so it can transfer the nft
   *
   * @param _ca collection's address
   * @param _tokenId the token that it will be accepted
   * @param _price the price of the bid that gets accepted
   * @param _from the bidder
   */
  function acceptBid(
    address _ca,
    uint256 _tokenId,
    uint256 _price,
    address _from
  ) external nonReentrant {
    IERC721 _nft = IERC721(_ca);

    require(msg.sender == _nft.ownerOf(_tokenId), "Only the owner of this NFT can accept an offer.");
    require(_nft.isApprovedForAll(msg.sender, address(this)), "Marketplace not approved to transfer this NFT.");
    require(!tradingPaused, "Marketplace trading is disabled.");
    require(collectionTradingEnabled[_ca], "Trading for this collection is not enabled.");

    Offer[] storage _offers = _getOffers(_ca, _tokenId);

    require(_offers.length > 0, "No offers");
    uint256 correctIndex = 999999999999999999;

    for (uint256 i = _offers.length - 1; i >= 0; i--) {
      Offer memory currentOffer = _offers[i];
      if (
        currentOffer.price == _price &&
        currentOffer.buyer == _from &&
        currentOffer.accepted == false &&
        currentOffer.expiration > block.timestamp
      ) {
        correctIndex = i;
        break;
      }
      if (i == 0) break;
    }

    require(correctIndex != 999999999999999999, "Matching offer not found...");

    // Actually perform trade
    address oldOwner = msg.sender;
    address newOwner = _from;

    // Clean up data structures
    _offers[correctIndex].accepted = true;

    if (clearBidsAfterAcceptingOffer) {
      _clearAllBids(_ca, _tokenId);
    }

    if (delistAfterAcceptingOffer && isListed(_ca, _tokenId)) {
      _delistToken(_ca, _tokenId);
    }

    escrowedPurchase(_nft, _ca, _tokenId, _price, oldOwner, newOwner);
  }

  /** @notice Searches for previous bid on a certain token.
   *          Deletes current offer. Then inputs new.
   *          Refunds or takes weth from user.
   *          Renews expiration time from the moment changeBid is executed.
   * @param _ca collection's address
   * @param _tokenId the token that it bids for
   * @param _newPrice the new price that user wants to adjust their bid for this token
   * @param _expirationOption expiration time for this offer
   */
  function changeBid(
    address _ca,
    uint256 _tokenId,
    uint256 _newPrice,
    EXPIRATION _expirationOption
  ) external nonReentrant {
    Offer[] storage _offers = _getOffers(_ca, _tokenId);

    for (uint256 i = 0; i < _offers.length; i++) {
      if (_offers[i].buyer == msg.sender) {
        uint256 oldPrice = _offers[i].price;
        uint256 priceDiff = 0;
        bool isMore = false;

        if (_newPrice > oldPrice) {
          isMore = true;
          priceDiff = _newPrice - oldPrice;
        } else {
          priceDiff = oldPrice - _newPrice;
        }

        delete offers[_ca][_tokenId][i];

        offers[_ca][_tokenId].push(Offer(_newPrice, block.timestamp, getExpiration(_expirationOption), false, msg.sender));

        emit BidChanged(_ca, _tokenId, _newPrice, oldPrice, msg.sender, block.timestamp);

        if (isMore) {
          require(weth.allowance(msg.sender, address(this)) >= priceDiff, "The Marketplace is not approved for this amount");
          require(weth.balanceOf(msg.sender) >= priceDiff, "The buyer balance isn't high enough for an escrowed bid.");

          totalEscrowedAmount += priceDiff;
          totalInEscrow[msg.sender] += priceDiff;
          weth.safeTransferFrom(msg.sender, address(this), priceDiff);
        } else if (priceDiff != 0) {
          returnEscrowedFunds(msg.sender, priceDiff);
        }
        return;
      }
    }
    revert("No active offer found.");
  }

  /***************************
   * External view functions *
   **************************/
  /**
   * @notice Getter for all listings of a unique token.
   * @param _ca collection's address
   * @param _tokenId the token id
   * @return an array of Listings for a specific token
   */
  function getTokenListingHistory(address _ca, uint256 _tokenId) external view returns (Listing[] memory) {
    return listings[_ca][_tokenId];
  }

  /**
   * @notice Getter for all bids on a unique token.
   * @param _ca collection's address
   * @param _tokenId the token id
   * @return an array of Offer for a specific token
   */
  function getOffers(address _ca, uint256 _tokenId) external view returns (Offer[] memory) {
    return offers[_ca][_tokenId];
  }

  /**
   * @notice Getter for total escrowed weth in the Marketplace
   * @return A uint256 representing the amount of WETH
   */
  function getMarketEscrow() external view returns (uint256) {
    return totalEscrowedAmount;
  }

  /**
   * @notice Getter retrieving a collection's owner
   * @param _ca collection's address
   * @return An address representing the owner
   */
  function getCollectionOwner(address _ca) external view returns (address) {
    return collectionOwners[_ca];
  }

  /**
   * @notice Getter retrieving a user's escrowed amount in the Marketplace
   * @param _user user address
   * @return A uint256 representing the amount of WETH
   */
  function checkEscrowAmount(address _user) external view returns (uint256) {
    return totalInEscrow[_user];
  }

  /**
   * @notice Method used to check if trading is enabled for a specific collection
   * @param _ca collection's address
   * @return A bool
   */
  function isCollectionTrading(address _ca) external view returns (bool) {
    return collectionTradingEnabled[_ca];
  }

  /**
   * @notice Getter retrieving the dev fee, 1% = 10
   * @return A uint256 representing the fee
   */
  function getDevFee() external view returns (uint256) {
    return devFee;
  }

  /**
   * @notice Getter retrieving the collection fee, 1% = 100
   * @param _ca collection's address
   * @return A uint256 representing the fee
   */
  function getCollectionFee(address _ca) public view returns (uint256) {
    return collectionOwnerFees[_ca];
  }

  /**
   * @notice Getter retrieving the collection fee + dev fee, 1% = 100
   * @param _ca collection's address
   * @return A uint256 representing the fee
   */
  function getTotalFee(address _ca) external view returns (uint256) {
    return devFee + getCollectionFee(_ca);
  }

  /**
   * @notice Clearing all bids for a token
   * @dev Protected with HIGH_ROLE
   * @param _ca collection's address
   * @param _tokenId token id that needs to be cleared
   */
  function clearAllBids(address _ca, uint256 _tokenId) external onlyRole(HIGH_ROLE) {
    _clearAllBids(_ca, _tokenId);
  }

  /**
   * @notice Clearing all listings for a token
   * @dev Protected with HIGH_ROLE
   * @param _ca collection's address
   * @param _tokenId token id that needs to be cleared
   */
  function clearAllListings(address _ca, uint256 _tokenId) external onlyRole(HIGH_ROLE) {
    delete listings[_ca][_tokenId];
    emit ClearedAllListings(_ca, _tokenId);
  }

  /**
   * @notice Start trading for the whole Marketplace
   * @dev Protected with HIGH_ROLE
   */
  function startTrading() external onlyRole(HIGH_ROLE) {
    require(tradingPaused, "Market is already open.");
    tradingPaused = false;
    emit TradingPausedChanged(false);
  }

  /**
   * @notice Stop trading for the whole Marketplace
   * @dev Protected with EMERGENCY_ROLE
   */
  function stopTrading() external onlyRole(EMERGENCY_ROLE) {
    require(!tradingPaused, "Market already halted.");
    tradingPaused = true;
    emit TradingPausedChanged(true);
  }

  /**
   * @notice Sets collection trading enabled or disabled
   * @dev Protected with LOW_ROLE
   * @param _ca collection's address
   * @param _value true or false
   */
  function setCollectionTrading(address _ca, bool _value) external onlyRole(LOW_ROLE) {
    require(collectionTradingEnabled[_ca] != _value, "Already set to that value.");
    collectionTradingEnabled[_ca] = _value;
    emit TradingCollectionTrading(_ca, _value);
  }

  /**
   * @notice Sets collection owner, the one who will receive the fees
   * @dev Protected with LOW_ROLE
   * @param _ca collection's address
   * @param _owner the owner of the collection
   */
  function setCollectionOwner(address _ca, address _owner) external onlyRole(LOW_ROLE) {
    collectionOwners[_ca] = _owner;
    emit ChangedCollectionOwner(_ca, _owner);
  }

  /**
   * @notice Sets the dev fee
   * @dev Protected with HIGH_ROLE
   * @param _fee 1% = 10
   */
  function setDevFee(uint256 _fee) external onlyRole(HIGH_ROLE) {
    require(_fee <= 100, "Max 10% fee");
    devFee = _fee;
    emit ChangedDevFee(_fee);
  }

  /**
   * @notice Sets the collection owner's fee
   * @dev Protected with LOW_ROLE
   * @param _ca collection's address
   * @param _fee 1% = 100
   */
  function setCollectionOwnerFee(address _ca, uint256 _fee) external onlyRole(LOW_ROLE) {
    require(_fee <= 1000, "Max 10% fee");
    collectionOwnerFees[_ca] = _fee;
    emit ChangedCollectionOwnerFee(_ca, _fee);
  }

  /**
   * @notice Sets dev address
   * @dev Protected with HIGH_ROLE
   * @param _address dev address
   */
  function setDevAddress(address _address) external onlyRole(HIGH_ROLE) {
    require(_address != address(0), "Can not be address 0");
    devAddress = _address;
    emit ChangedDevAddress(_address);
  }

  /**
   * @notice Sets emergencyAddress address
   * @dev Protected with HIGH_ROLE
   * @param _address dev address
   */
  function setEmergencyAddress(address _address) external onlyRole(HIGH_ROLE) {
    require(_address != address(0), "Can not be address 0");
    emergencyAddress = _address;
    emit ChangedEmergencyAddress(_address);
  }

  /**
   * @notice Sets feature collection address
   * @dev Protected with LOW_ROLE
   * @param _ca collection's address
   */
  function setFeaturedCollection(address _ca) external onlyRole(LOW_ROLE) {
    featuredCollection = _ca;
    emit ChangedFeaturedCollection(_ca);
  }

  /**
   * @notice Sets if fees are on or not
   * @dev Protected with HIGH_ROLE
   * @param _value true or false
   */
  function setFeesOn(bool _value) external onlyRole(HIGH_ROLE) {
    feesOn = _value;
    emit ChangedFeesOn(_value);
  }

  /**
   * @notice Sets if delisting after accepting offer is enabled
   * @dev Protected with HIGH_ROLE
   * @param _value true or false
   */
  function setDelistAfterAcceptingOffer(bool _value) external onlyRole(HIGH_ROLE) {
    delistAfterAcceptingOffer = _value;
    emit ChangedDelistAfterAcceptingOffer(_value);
  }

  /**
   * @notice Sets if we clear or not all bids after accepting offer
   * @dev Protected with HIGH_ROLE
   * @param _value true or false
   */
  function setClearBidsAfterAcceptingOffer(bool _value) external onlyRole(HIGH_ROLE) {
    clearBidsAfterAcceptingOffer = _value;
    emit ChangedClearBidsAfterAcceptingOffer(_value);
  }

  /**
   * @notice Sets weth token address
   * @dev Protected with HIGH_ROLE
   * @param _wethToken weth address
   */
  function setWeth(address _wethToken) external onlyRole(HIGH_ROLE) {
    weth = IERC20(_wethToken);
  }

  /**
   * @notice Sets the max allowed offers
   * @dev Protected with LOW_ROLE
   * @param _newMaxOffers the new max number of offers a token can receive
   */
  function setMaxOffers(uint256 _newMaxOffers) external onlyRole(LOW_ROLE) {
    maxAllowedOffers = _newMaxOffers;
    emit ChangedMaxOffers(_newMaxOffers);
  }

  /**
   * @notice Recover any ERC20 token from Marketplace address. Transfer to emergency address
   * @dev Protected with EMERGENCY_ROLE. This is emergency only.
   * @param _token the token address that needs to be recovered
   * @param _amount the amount
   */
  function recoverToken(address _token, uint256 _amount) external onlyRole(EMERGENCY_ROLE) {
    require(emergencyAddress != address(0), "Can not be address 0");
    IERC20(_token).safeTransfer(emergencyAddress, _amount);
    emit RecoveredToken(_token, _amount);
  }

  /**
   * @notice Recover any NFT from Marketplace address. Transfer to emergency address
   * @dev Protected with EMERGENCY_ROLE. This is emergency only.
   * @param _token the nft address
   * @param _tokenId the id of the token
   */
  function recoverNFT(address _token, uint256 _tokenId) external onlyRole(EMERGENCY_ROLE) {
    require(emergencyAddress != address(0), "Can not be address 0");
    IERC721(_token).safeTransferFrom(address(this), emergencyAddress, _tokenId);
    emit RecoveredToken(_token, _tokenId);
  }

  /********************
   * Public functions *
   *******************/

  /**
   * @notice Required in order to receive ERC 721's.
   */
  function onERC721Received(
    address,
    address,
    uint256,
    bytes memory
  ) public virtual override returns (bytes4) {
    return this.onERC721Received.selector;
  }

  /**
   * @notice Checks if a token is listed already
   * @param _ca collection's address
   * @param _tokenId the id of the token
   * @return a bool
   */
  function isListed(address _ca, uint256 _tokenId) public view returns (bool) {
    uint256 index = listings[_ca][_tokenId].length;

    if (index == 0) {
      return false;
    }

    return listings[_ca][_tokenId][index - 1].price != 0;
  }

  /**
   * @notice Gets the current listing price of a token
   * @param _ca collection's address
   * @param _tokenId the id of the token
   * @return a uint256 representing the price in weth
   */
  function getCurrentListingPrice(address _ca, uint256 _tokenId) public view returns (uint256) {
    Listing memory listing = getCurrentListing(_ca, _tokenId);

    if (listing.listingType == TYPE_OF_LISTING.PURCHASE) return listing.price;

    uint256 price = listing.maxPrice;
    uint256 decreaseIntervals = (block.timestamp - listing.timestamp) / listing.decreaseTime;

    for (uint256 i; i < decreaseIntervals; i++) {
      uint256 priceDecrease = (price * (listing.decreasePercentage / 100)) / 100;
      if (priceDecrease < price) price -= priceDecrease;
    }

    if (listing.minPrice > price) price = listing.minPrice;
    return price;
  }

  /**
   * @notice Gets the current listing object for a token
   * @param _ca collection's address
   * @param _tokenId the id of the token
   * @return a Listing representing the current listing of this token
   */
  function getCurrentListing(address _ca, uint256 _tokenId) public view returns (Listing memory) {
    uint256 numListings = getNumberOfListings(_ca, _tokenId);

    require(numListings > 0, "No listings for this token.");

    return listings[_ca][_tokenId][numListings - 1];
  }

  /**
   * @notice Gets listed tokens of a specific collection
   * @param _ca collection's address
   * @return an array of token ids that are listed into marketplace
   */
  function getActiveListings(address _ca) external view returns (uint256[] memory) {
    return listedTokensByCollection[_ca];
  }

  /**
   * @notice Gets user's nfts for a specific collection.
   *         The collection needs to support ERC721Enumerable or have totalSupply() method
   * @param _ca collection's address
   * @param _owner owner's address
   * @return an array of token ids that the user has
   */
  function getUserNFTs(address _owner, address _ca) external view returns (uint256[] memory) {
    require(_owner != address(0), "User Address cant be 0");
    require(_ca != address(0), "Collection Address cant be 0");

    bool isERC721Enum = IERC721(_ca).supportsInterface(ERC721EnumHash);

    IERC721Enumerable _nft = IERC721Enumerable(_ca);
    uint256 userTokenMax = _nft.balanceOf(_owner);
    uint256[] memory userNFTs = new uint256[](userTokenMax);
    if (isERC721Enum) {
      uint256 tokenId = 0;

      if (userTokenMax != 0) {
        for (uint256 i = 0; i < userTokenMax; i++) {
          tokenId = _nft.tokenOfOwnerByIndex(_owner, i);
          userNFTs[i] = tokenId;
        }
      }
      return userNFTs;
    } else {
      uint256 tokenMax = _nft.totalSupply();
      uint256 j = 0;
      if (tokenMax > 0) {
        for (uint256 i = 0; i < tokenMax; i++) {
          if (_nft.ownerOf(i) == _owner) userNFTs[j++] = i;
        }
      }
      return userNFTs;
    }
  }

  /**********************
   * Internal functions *
   *********************/
  /**
   * @notice gets offers for a specific token
   * @param _ca collection's address
   * @param _tokenId token id
   * @return an array of Offer
   */
  function _getOffers(address _ca, uint256 _tokenId) internal view returns (Offer[] storage) {
    return offers[_ca][_tokenId];
  }

  /*********************
   * Private functions *
   ********************/
  /**
   * @notice Delists a token from being traded
   * @param _ca collection's address
   * @param _tokenId token id
   */
  function _delistToken(address _ca, uint256 _tokenId) private {
    Listing memory listing = listings[_ca][_tokenId][listings[_ca][_tokenId].length - 1];
    listings[_ca][_tokenId].push(
      Listing(
        0,
        block.timestamp,
        _tokenId,
        false,
        listing.listingType,
        listing.decreaseTime,
        listing.decreasePercentage,
        listing.minPrice,
        listing.maxPrice
      )
    );

    uint256 listedTokens = listedTokensByCollection[_ca].length;

    for (uint256 i = 0; i < listedTokens; i++) {
      if (listedTokensByCollection[_ca][i] == _tokenId) {
        listedTokensByCollection[_ca][i] = listedTokensByCollection[_ca][listedTokens - 1];
        listedTokensByCollection[_ca].pop();
        break;
      }
    }

    emit TokenDelisted(_ca, _tokenId, block.timestamp);
  }

  /**
   * @notice Calculates the fees and the remaining price for a specific collection
   * @param _ca collection's address
   * @param _amount the price that we want to substract the fees
   * @return devFeeAmount dev fee
   * @return collectionOwnerFeeAmount collection fee
   * @return remainder the remaining amount
   */
  function calculateAmounts(address _ca, uint256 _amount)
    private
    view
    returns (
      uint256 devFeeAmount,
      uint256 collectionOwnerFeeAmount,
      uint256 remainder
    )
  {
    devFeeAmount = (_amount * devFee) / 1000;
    collectionOwnerFeeAmount = (_amount * collectionOwnerFees[_ca]) / 1000;
    remainder = _amount - (devFeeAmount + collectionOwnerFeeAmount);
  }

  /**
   * @notice How many listings a token has
   * @param _ca collection's address
   * @param _tokenId token id
   * @return a uint256 representing the length
   */
  function getNumberOfListings(address _ca, uint256 _tokenId) private view returns (uint256) {
    return listings[_ca][_tokenId].length;
  }

  /**
   * @notice Marks a listing as accepted
   * @param _ca collection's address
   * @param _tokenId token id
   */
  function markListingAsAccepted(address _ca, uint256 _tokenId) private {
    Listing memory current = getCurrentListing(_ca, _tokenId);

    current.accepted = true;

    uint256 index = getNumberOfListings(_ca, _tokenId);

    if (index != 0) {
      listings[_ca][_tokenId][index - 1] = current;
    }
  }

  /**
   * @notice Returns the escrowed funds for a user
   * @param _user user's address
   * @param _amount the amount that needs to be returned
   */
  function returnEscrowedFunds(address _user, uint256 _amount) private {
    require(totalEscrowedAmount >= _amount, "Not enough funds to return escrow. Theoretically impossible.");
    require(totalInEscrow[_user] >= _amount, "Not enough funds to return escrow. Theoretically impossible.");

    totalEscrowedAmount -= _amount;
    totalInEscrow[_user] -= _amount;

    weth.safeTransfer(_user, _amount);

    emit EscrowReturned(_user, _amount);
  }

  /**
   * @notice Makes an escrow purchase. It transfers funds deposited previously by the user.
   * @param _nft the token address
   * @param _ca collection address
   * @param _tokenId token id that it is bought
   * @param _price the price that is bought
   * @param _oldOwner old owner of the token
   * @param _newOwner new owner of the token
   */
  function escrowedPurchase(
    IERC721 _nft,
    address _ca,
    uint256 _tokenId,
    uint256 _price,
    address _oldOwner,
    address _newOwner
  ) private {
    require(totalInEscrow[_newOwner] >= _price, "Buyer does not have enough money in escrow.");
    require(totalEscrowedAmount >= _price, "Escrow balance too low.");

    uint256 oldOwnerEthBalance = weth.balanceOf(_oldOwner);
    // fees calculation
    (uint256 devFeeAmount, uint256 collectionOwnerFeeAmount, uint256 remainder) = calculateAmounts(_ca, _price);

    totalInEscrow[_newOwner] -= _price;
    totalEscrowedAmount -= _price;

    _nft.safeTransferFrom(_oldOwner, _newOwner, _tokenId);
    weth.safeTransfer(_oldOwner, remainder);

    // checks
    require(weth.balanceOf(_oldOwner) >= (oldOwnerEthBalance + remainder), "Funds were not successfully sent.");
    require(_nft.ownerOf(_tokenId) == _newOwner, "NFT was not successfully transferred.");

    emit TokenPurchased(_oldOwner, _newOwner, _price, _ca, _tokenId);

    // fees
    if (feesOn) {
      weth.safeTransfer(collectionOwners[_ca], collectionOwnerFeeAmount);
      weth.safeTransfer(devAddress, devFeeAmount);
    }
  }

  /**
   * @notice Clear all bids of a token
   * @param _ca collection's address
   * @param _tokenId token id
   */
  function _clearAllBids(address _ca, uint256 _tokenId) internal {
    delete offers[_ca][_tokenId];
    emit ClearedAllBids(_ca, _tokenId);
  }

  function getExpiration(EXPIRATION _expirationOption) internal view returns (uint256) {
    if (_expirationOption == EXPIRATION.ONE_DAY) {
      return block.timestamp + 1 days;
    } else if (_expirationOption == EXPIRATION.THREE_DAYS) {
      return block.timestamp + 3 days;
    } else if (_expirationOption == EXPIRATION.ONE_WEEK) {
      return block.timestamp + 7 days;
    } else if (_expirationOption == EXPIRATION.TWO_WEEKS) {
      return block.timestamp + 14 days;
    } else if (_expirationOption == EXPIRATION.ONE_MONTH) {
      return block.timestamp + 30 days;
    } else if (_expirationOption == EXPIRATION.THREE_MONTHS) {
      return block.timestamp + 90 days;
    } else if (_expirationOption == EXPIRATION.SIX_MONTHS) {
      return block.timestamp + 180 days;
    }
    revert("Invalid expiration");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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
interface IERC165 {
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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.0 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}