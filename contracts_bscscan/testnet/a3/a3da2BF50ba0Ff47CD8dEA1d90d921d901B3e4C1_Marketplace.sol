// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IMarketplace.sol";
import "./interfaces/IMaviaNFT.sol";
import "./interfaces/ICreator.sol";
import "./interfaces/IRoyalty.sol";
import "./utils/EmergencyWithdraw.sol";

contract Marketplace is
  OwnableUpgradeable,
  AccessControlUpgradeable,
  ReentrancyGuardUpgradeable,
  EmergencyWithdraw,
  ERC1155HolderUpgradeable,
  IMarketplace
{
  /**
   * priceType: 0 for fixed, 1 for auction dates range, 2 for auction infinity, 3 for rent
   * status: 0 for delist, 1 for listing
   */
  struct TokenSaleInfo {
    uint256 status;
    uint256 amount;
    uint256 priceType;
    uint256 price; // min price for bid
    uint256 buyNowPrice;
    uint256[] bids;
    address[] bidders;
  }

  struct ActiveBid {
    address bidder;
    uint256 marketFeePercentage;
    uint256 royaltyFeePercentage;
    uint256 chargeStatus;
    uint256 amount;
    uint256 price;
  }

  struct ActiveBidRange {
    uint256 startTime;
    uint256 endTime;
  }

  struct SalePrice {
    address seller;
    uint256 amount;
    uint256 price;
    uint256 royaltyPercentage;
  }

  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant ACCEPT_BID_ROLE = keccak256("ACCEPT_BID_ROLE");
  bytes32 public constant CANCEL_BID_ROLE = keccak256("CANCEL_BID_ROLE");

  uint256 private marketFeePercentage; // 1 is 0.01%
  uint256 private chargeStatus; // 0 not charge anyone, 1 charge seller, 2 charge buyer, 3 charge both
  uint256 private bidIncreasePercentage;
  mapping(uint256 => mapping(address => SalePrice)) private salePrice;
  mapping(uint256 => mapping(address => ActiveBid)) private activeBid;
  mapping(uint256 => mapping(address => ActiveBidRange)) private activeBidRange;
  mapping(uint256 => bool) private soldTokens;
  mapping(uint256 => mapping(address => TokenSaleInfo)) private tokenSaleInfo;
  mapping(address => uint256) public bidBalance;
  address public maviaTokenAddress;
  address public maviaNFTAddress;

  event Bid(address indexed _bidder, uint256 _id, uint256 _amount, uint256 _price);
  event CancelBid(address indexed _bidder, uint256 _id, uint256 _amount, uint256 _price);
  event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 _price, uint256 _id);
  event AcceptBid(address indexed _bidder, address indexed _seller, uint256 _amount, uint256 _price, uint256 _id);

  /**
   * @dev Upgradable initializer
   * @param _token address of clash token
   * @param _nft address of mavia NFT
   */
  function __Marketplace_init(address _token, address _nft) public initializer {
    __Ownable_init();
    __AccessControl_init();
    __ReentrancyGuard_init();
    __ERC1155Holder_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    setAddresses(_token, _nft);
    setConfig(2, 300, 1000);
  }

  function setConfig(
    uint256 _chargeStatus,
    uint256 _marketFeePercentage,
    uint256 _bidIncreasePercentage
  ) public {
    require(_marketFeePercentage <= 10000, "Marketplace:setConfig");
    chargeStatus = _chargeStatus;
    marketFeePercentage = _marketFeePercentage;
    bidIncreasePercentage = _bidIncreasePercentage;
  }

  /**
   * @dev get the marketplace fee percentage
   */
  function getConfig()
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (chargeStatus, marketFeePercentage, bidIncreasePercentage);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC1155ReceiverUpgradeable, AccessControlUpgradeable)
    returns (bool)
  {
    return interfaceId == type(IMarketplace).interfaceId || super.supportsInterface(interfaceId);
  }

  /**
   * @dev set token addresses
   * @param _token address of clash token
   * @param _nft address of mavia NFT
   */
  function setAddresses(address _token, address _nft) public onlyOwner {
    require(_token != address(0), "Marketplace:setAddresses");
    require(_nft != address(0), "Marketplace:setAddresses");

    maviaTokenAddress = _token;
    maviaNFTAddress = _nft;
  }

  /**
   * @dev get price of the token
   * @param _id uint256 id of the token
   * @param _owner address owner of the token
   */
  function getSalePrice(uint256 _id, address _owner)
    external
    view
    returns (
      address seller,
      uint256 price,
      uint256 amount
    )
  {
    return (salePrice[_id][_owner].seller, salePrice[_id][_owner].price, salePrice[_id][_owner].amount);
  }

  /**
   * @dev get token sale info
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   */
  function getTokenSaleInfo(uint256 _id, address _owner)
    external
    view
    returns (
      uint256 status,
      uint256 amount,
      uint256 priceType,
      uint256 price,
      uint256 buyNowPrice
    )
  {
    return (
      tokenSaleInfo[_id][_owner].status,
      tokenSaleInfo[_id][_owner].amount,
      tokenSaleInfo[_id][_owner].priceType,
      tokenSaleInfo[_id][_owner].price,
      tokenSaleInfo[_id][_owner].buyNowPrice
    );
  }

  /**
   * @dev get active bid details
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   */
  function getActiveBid(uint256 _id, address _owner)
    external
    view
    returns (
      address bidder,
      uint256 price,
      uint256 amount
    )
  {
    return (activeBid[_id][_owner].bidder, activeBid[_id][_owner].price, activeBid[_id][_owner].amount);
  }

  /**
   * @dev get active bid range
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   */
  function getActiveBidRange(uint256 _id, address _owner) external view returns (uint256 startTime, uint256 endTime) {
    return (activeBidRange[_id][_owner].startTime, activeBidRange[_id][_owner].endTime);
  }

  /**
   * @dev get the bids
   * @param _id uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getBids(uint256 _id, address _owner) external view returns (uint256[] memory bids) {
    return tokenSaleInfo[_id][_owner].bids;
  }

  /**
   * @dev get the bidders
   * @param _id uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getBidders(uint256 _id, address _owner) external view returns (address[] memory bidders) {
    return tokenSaleInfo[_id][_owner].bidders;
  }

  /**
   * @dev add a token fixed price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _amount uint256 amount of the token
   * @param _price price of the token
   */
  function createFixedPrice(
    uint256 _id,
    uint256 _amount,
    uint256 _price
  ) external override {
    enoughTokenAmount(_id, _amount);
    _transferNFTToMarketplace(_id, _amount, msg.sender);

    _createSalePrice(_id, _amount, getRoyaltyFeePercentage(_id), _price, msg.sender);
    tokenSaleInfo[_id][msg.sender] = TokenSaleInfo(1, _amount, 0, _price, 0, new uint256[](0), new address[](0));
  }

  /**
   * @dev add a token bid price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _amount uint256 amount of the token
   * @param _price price of the token
   * @param _buyNowPrice buy now price of the token
   */
  function createBidPrice(
    uint256 _id,
    uint256 _amount,
    uint256 _price,
    uint256 _buyNowPrice
  ) public override {
    enoughTokenAmount(_id, _amount);
    _transferNFTToMarketplace(_id, _amount, msg.sender);
    _createBidPrice(_id, _amount, getRoyaltyFeePercentage(_id), _price, 0, 0, msg.sender);

    tokenSaleInfo[_id][msg.sender] = TokenSaleInfo(
      1,
      _amount,
      2,
      _price,
      _buyNowPrice,
      new uint256[](0),
      new address[](0)
    );
  }

  /**
   * @dev add a token bid range price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _amount uint256 amount of the token
   * @param _price price of the token
   * @param _buyNowPrice buy now price of the token
   * @param _startTime start time of bid
   * @param _endTime end time of bid
   */
  function createBidRangePrice(
    uint256 _id,
    uint256 _amount,
    uint256 _price,
    uint256 _buyNowPrice,
    uint256 _startTime,
    uint256 _endTime
  ) external override {
    enoughTokenAmount(_id, _amount);
    _transferNFTToMarketplace(_id, _amount, msg.sender);
    _createBidPrice(_id, _amount, getRoyaltyFeePercentage(_id), _price, _startTime, _endTime, msg.sender);

    tokenSaleInfo[_id][msg.sender] = TokenSaleInfo(
      1,
      _amount,
      1,
      _price,
      _buyNowPrice,
      new uint256[](0),
      new address[](0)
    );
  }

  /**
   * @dev edit token price for fixed price mode only
   * @param _id uint256 ID of the token.
   * @param _price uint256 token price
   */
  function editPrice(uint256 _id, uint256 _price) external override {
    require(tokenSaleInfo[_id][msg.sender].priceType == 0, "Marketplace:editPrice01");
    require(tokenSaleInfo[_id][msg.sender].status == 1, "Marketplace:editPrice02");
    require(_price > 0, "Marketplace:editPrice03");
    salePrice[_id][msg.sender].price = _price;
    tokenSaleInfo[_id][msg.sender].price = _price;
  }

  /**
   * @dev remove token from sale
   * @param _id uint256 ID of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _id, address _owner) external override {
    require(tokenSaleInfo[_id][_owner].status == 1, "Marketplace:removeFromSale01");
    if (tokenSaleInfo[_id][_owner].priceType == 1 || tokenSaleInfo[_id][_owner].priceType == 2) {
      require(
        activeBid[_id][_owner].bidder == address(0) || activeBid[_id][_owner].bidder == msg.sender,
        "Marketplace:removeFromSale02"
      );
    }
    _removeFromSale(_id, _owner);
  }

  /**
   * @dev purchase a token
   * @param _id uint256 ID of the token
   * @param _amount uint256 amount token to buy
   * @param _owner address owner of the token
   */
  function buy(
    uint256 _id,
    uint256 _amount,
    address _owner
  ) public override nonReentrant {
    require(msg.sender != address(0), "Marketplace:buy01");
    require(_amount > 0, "Marketplace:buy02");
    uint256 buyPrice = (salePrice[_id][_owner].price / salePrice[_id][_owner].amount) * _amount;
    uint256 buyerMarketFee = getBuyerMarketplaceFee(chargeStatus, buyPrice, marketFeePercentage);
    uint256 sellerMarketFee = getSellerMarketplaceFee(chargeStatus, buyPrice, marketFeePercentage);
    uint256 royaltyFee = calculateRoyaltyFee(_id, buyPrice);
    require(
      IERC20(maviaTokenAddress).balanceOf(msg.sender) >= (buyPrice + buyerMarketFee + royaltyFee),
      "Marketplace:buy03"
    );
    require(tokenSaleInfo[_id][_owner].status == 1, "Marketplace:buy04");
    require(tokenSaleInfo[_id][_owner].priceType == 0, "Marketplace:buy05");
    require(_amount <= salePrice[_id][_owner].amount, "Marketplace:buy06");

    // send token to seller & marketplace
    _payoutFromBuyer(_owner, buyPrice, sellerMarketFee, buyerMarketFee);
    totalMarketFee = totalMarketFee + buyerMarketFee + sellerMarketFee;
    _transferRoyaltyFeeFromBuyer(_id, royaltyFee);
    if (IERC1155(maviaNFTAddress).balanceOf(address(this), _id) > 0) {
      _transferNFT(address(this), msg.sender, _id, _amount);
    } else {
      _transferNFT(_owner, msg.sender, _id, _amount);
    }
    markTokenSold(_id, true);
    if (_amount == salePrice[_id][_owner].amount) {
      salePrice[_id][_owner] = SalePrice(address(0), 0, 0, 0);
      _removeFromSale(_id, _owner);
    } else {
      salePrice[_id][_owner].amount = salePrice[_id][_owner].amount - _amount;
      salePrice[_id][_owner].price = salePrice[_id][_owner].price - buyPrice;
    }
    emit Sold(msg.sender, _owner, _amount, buyPrice, _id);
  }

  /**
   * @dev buy now
   * @param _id uint256 ID of the token
   * @param _owner address owner of the token
   */
  function buyNow(uint256 _id, address _owner) external {
    require(msg.sender != address(0), "Marketplace:buyNow01");
    require(tokenSaleInfo[_id][_owner].status == 1, "Marketplace:buyNow02");
    require(
      tokenSaleInfo[_id][_owner].priceType == 1 || tokenSaleInfo[_id][_owner].priceType == 2,
      "Marketplace:buyNow03"
    );

    // Transfer token.
    uint256 buyerMarketFee = getBuyerMarketplaceFee(
      activeBid[_id][_owner].chargeStatus,
      tokenSaleInfo[_id][_owner].buyNowPrice,
      activeBid[_id][_owner].marketFeePercentage
    );
    uint256 sellerMarketFee = getSellerMarketplaceFee(
      activeBid[_id][_owner].chargeStatus,
      tokenSaleInfo[_id][_owner].buyNowPrice,
      activeBid[_id][_owner].marketFeePercentage
    );
    uint256 royaltyFee = (tokenSaleInfo[_id][_owner].buyNowPrice * activeBid[_id][_owner].royaltyFeePercentage) / 10000;
    uint256 requiredCost = tokenSaleInfo[_id][_owner].buyNowPrice + buyerMarketFee + royaltyFee;
    require(requiredCost <= IERC20(maviaTokenAddress).balanceOf(msg.sender), "Marketplace:buyNow04");

    if (activeBid[_id][_owner].bidder != _owner) {
      _refundBid(_id, _owner);
    }
    // send token to seller & marketplace
    _payoutFromBuyer(_owner, tokenSaleInfo[_id][_owner].buyNowPrice, sellerMarketFee, buyerMarketFee);
    totalMarketFee = totalMarketFee + buyerMarketFee + sellerMarketFee;

    _transferNFT(address(this), msg.sender, _id, activeBid[_id][_owner].amount);
    _transferRoyaltyFeeFromBuyer(_id, royaltyFee);
    markTokenSold(_id, true);
    _resetBid(_id, _owner);
    _removeFromSale(_id, _owner);
  }

  /**
   * @dev bid a token
   * @param _id uint256 ID of the token
   * @param _price uint256 price to bid
   * @param _owner address owner of the token
   */
  function bid(
    uint256 _id,
    uint256 _price,
    address _owner
  ) public override nonReentrant {
    require(msg.sender != address(0), "Marketplace:bid01");
    require(tokenSaleInfo[_id][_owner].status == 1, "Marketplace:bid02");
    require(_price > 0, "Marketplace:bid03");

    uint256 buyerMarketFee = getBuyerMarketplaceFee(chargeStatus, _price, activeBid[_id][_owner].marketFeePercentage);
    uint256 royaltyFee = calculateRoyaltyFee(_id, _price);

    // Check that enough ether was sent.
    uint256 requiredCost = _price + buyerMarketFee + royaltyFee;
    require(requiredCost <= IERC20(maviaTokenAddress).balanceOf(msg.sender), "Marketplace:bid04");

    require(
      tokenSaleInfo[_id][_owner].priceType == 1 || tokenSaleInfo[_id][_owner].priceType == 2,
      "Marketplace:bid05"
    );
    ActiveBidRange memory range = activeBidRange[_id][_owner];
    if (tokenSaleInfo[_id][_owner].priceType == 1)
      require(range.startTime < block.timestamp && range.endTime > block.timestamp, "Marketplace:bid06");
    require(_owner != msg.sender, "Marketplace:bid07");

    uint256 minimumBidPrice = _getMinimumBidPrice(activeBid[_id][_owner].price);
    require(_price > activeBid[_id][_owner].price && _price >= minimumBidPrice, "Marketplace:bid08");

    if (activeBid[_id][_owner].bidder != _owner) {
      _refundBid(_id, _owner);
    }

    IERC20(maviaTokenAddress).transferFrom(msg.sender, address(this), requiredCost);
    activeBid[_id][_owner].bidder = msg.sender;
    activeBid[_id][_owner].price = _price;
    tokenSaleInfo[_id][_owner].bids.push(_price);
    tokenSaleInfo[_id][_owner].bidders.push(msg.sender);
    bidBalance[msg.sender] = bidBalance[msg.sender] + requiredCost;

    emit Bid(msg.sender, _id, activeBid[_id][_owner].amount, _price);
  }

  /**
   * @dev accept bid a token
   * @param _id uint256 ID of the token
   * @param _owner address of the token
   */
  function acceptBid(uint256 _id, address _owner) external override nonReentrant {
    require(msg.sender == _owner || hasRole(ACCEPT_BID_ROLE, msg.sender), "Marketplace:acceptBid01");
    require(tokenSaleInfo[_id][_owner].status == 1, "Marketplace:acceptBid02");
    require(
      tokenSaleInfo[_id][_owner].priceType == 1 || tokenSaleInfo[_id][_owner].priceType == 2,
      "Marketplace:acceptBid03"
    );

    ActiveBid memory currentBid = activeBid[_id][_owner];

    // Check that a bid exists.
    require(currentBid.bidder != address(0), "Marketplace:acceptBid04");
    require(currentBid.bidder != _owner, "Marketplace:acceptBid05");

    // Transfer token.
    uint256 buyerMarketFee = currentBid.chargeStatus == 0 || currentBid.chargeStatus == 1
      ? 0
      : (currentBid.price * currentBid.marketFeePercentage) / 10000;
    uint256 sellerMarketFee = currentBid.chargeStatus == 0 || currentBid.chargeStatus == 2
      ? 0
      : (currentBid.price * currentBid.marketFeePercentage) / 10000;
    uint256 royaltyFee = (currentBid.price * currentBid.royaltyFeePercentage) / 10000;
    bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder] - (currentBid.price + buyerMarketFee + royaltyFee);

    // send token to seller & marketplace
    _payoutFromMarketplace(_owner, currentBid.price, sellerMarketFee);
    totalMarketFee = totalMarketFee + buyerMarketFee + sellerMarketFee;

    _transferNFT(address(this), currentBid.bidder, _id, currentBid.amount);

    _transferRoyaltyFeeFromMarketplace(_id, royaltyFee);
    markTokenSold(_id, true);
    _resetBid(_id, _owner);
    _removeFromSale(_id, _owner);

    emit AcceptBid(currentBid.bidder, _owner, currentBid.amount, currentBid.price, _id);
  }

  /**
   * @dev cancel bid a token
   * @param _id uint256 ID of the token
   * @param _owner address owner of the token
   */
  function cancelBid(uint256 _id, address _owner) external override nonReentrant {
    // Check that sender has a current bid.
    require(
      activeBid[_id][_owner].bidder == msg.sender || hasRole(CANCEL_BID_ROLE, msg.sender),
      "Marketplace:cancelBid01"
    );

    // Refund the bidder.
    _refundBid(_id, _owner);
    activeBid[_id][_owner].bidder = _owner;
    activeBid[_id][_owner].price = tokenSaleInfo[_id][_owner].price;

    emit CancelBid(msg.sender, _id, activeBid[_id][_owner].amount, activeBid[_id][_owner].price);
  }

  /**
   * @dev lazy minting buy
   * @param _creator address token owner
   * @param _id uint256 id token
   * @param _amount uint256 amount token
   * @param _buyAmount uint256 buy amount
   * @param _royaltyPercentage uint256 royalty percentage
   * @param _price uint256 price token
   * @param _signature bytes signature
   */
  function lazyMintingBuy(
    address _creator,
    uint256 _id,
    uint256 _amount,
    uint256 _buyAmount,
    uint256 _royaltyPercentage,
    uint256 _price,
    bytes calldata _signature
  ) external {
    IMaviaNFT(maviaNFTAddress).redeem(_creator, _id, _amount, _royaltyPercentage, 0, _price, 0, 0, 0, 1, _signature);

    _createSalePrice(_id, _amount, _royaltyPercentage, _price, _creator);
    tokenSaleInfo[_id][_creator] = TokenSaleInfo(1, _amount, 0, _price, 0, new uint256[](0), new address[](0));

    buy(_id, _buyAmount, _creator);
  }

  /**
   * @dev lazy minting bid
   * @param _creator address token owner
   * @param _id uint256 id token
   * @param _amount uint256 amount token
   * @param _royaltyPercentage uint256 royalty percentage
   * @param _priceType uint256 price type
   * @param _price uint256 price token
   * @param _buyNowPrice uint256 buy now price
   * @param _startTime uint256 start time
   * @param _endTime uint256 end time
   * @param _signature bytes signature
   * @param _bidPrice unit256 bid price
   */
  function lazyMintingBid(
    address _creator,
    uint256 _id,
    uint256 _amount,
    uint256 _royaltyPercentage,
    uint256 _priceType,
    uint256 _price,
    uint256 _buyNowPrice,
    uint256 _startTime,
    uint256 _endTime,
    bytes calldata _signature,
    uint256 _bidPrice
  ) external nonReentrant {
    require(_priceType == 1 || _priceType == 2, "Marketplace:lazyMintingBid01");
    if (_priceType == 1)
      require(_startTime < block.timestamp && _endTime > block.timestamp, "Marketplace:lazyMintingBid02");
    require(_bidPrice >= _price + ((_price * bidIncreasePercentage) / 10000), "Marketplace:lazyMintingBid03");
    uint256 requiredCost = getRequireCost(_bidPrice, _royaltyPercentage);
    require(requiredCost <= IERC20(maviaTokenAddress).balanceOf(msg.sender), "Marketplace:lazyMintingBid04");

    IMaviaNFT(maviaNFTAddress).redeem(
      _creator,
      _id,
      _amount,
      _royaltyPercentage,
      _priceType,
      _price,
      _buyNowPrice,
      _startTime,
      _endTime,
      1,
      _signature
    );
    IMaviaNFT(maviaNFTAddress).setApprovalForAllByMarketplace(_creator, address(this), true);
    IERC1155(maviaNFTAddress).safeTransferFrom(_creator, address(this), _id, _amount, "");

    activeBidRange[_id][_creator] = ActiveBidRange(_startTime, _endTime);
    tokenSaleInfo[_id][_creator] = TokenSaleInfo(
      1,
      _amount,
      _priceType,
      _price,
      _buyNowPrice,
      new uint256[](0),
      new address[](0)
    );
    IERC20(maviaTokenAddress).transferFrom(msg.sender, address(this), requiredCost);
    _setBid(msg.sender, _creator, _id, _amount, _bidPrice);
    tokenSaleInfo[_id][_creator].bids.push(_bidPrice);
    tokenSaleInfo[_id][_creator].bidders.push(msg.sender);
    bidBalance[msg.sender] = bidBalance[msg.sender] + requiredCost;

    emit Bid(msg.sender, _id, _amount, _bidPrice);
  }

  /**
   * @dev lazy minting buy now
   * @param _creator address token owner
   * @param _id uint256 id token
   * @param _amount uint256 amount token
   * @param _royaltyPercentage uint256 royalty percentage
   * @param _priceType uint256 price type
   * @param _price uint256 price token
   * @param _buyNowPrice uint256 buy now price
   * @param _startTime uint256 start time
   * @param _endTime uint256 end time
   * @param _signature bytes signature
   */
  function lazyMintingBuyNow(
    address _creator,
    uint256 _id,
    uint256 _amount,
    uint256 _royaltyPercentage,
    uint256 _priceType,
    uint256 _price,
    uint256 _buyNowPrice,
    uint256 _startTime,
    uint256 _endTime,
    bytes calldata _signature
  ) external nonReentrant {
    require(_priceType == 1 || _priceType == 2, "Marketplace:lazyMintingBuyNow01");
    if (_priceType == 1)
      require(_startTime < block.timestamp && _endTime > block.timestamp, "Marketplace:lazyMintingBuyNow02");
    uint256[3] memory variables;
    variables[0] = getRequireCost(_buyNowPrice, _royaltyPercentage);
    require(variables[0] <= IERC20(maviaTokenAddress).balanceOf(msg.sender), "Marketplace:lazyMintingBuyNow03");

    IMaviaNFT(maviaNFTAddress).redeem(
      _creator,
      _id,
      _amount,
      _royaltyPercentage,
      _priceType,
      _price,
      _buyNowPrice,
      _startTime,
      _endTime,
      1,
      _signature
    );

    variables[1] = getBuyerMarketplaceFee(chargeStatus, _buyNowPrice, marketFeePercentage);
    variables[2] = getSellerMarketplaceFee(chargeStatus, _buyNowPrice, marketFeePercentage);

    totalMarketFee = totalMarketFee + variables[1] + variables[2];
    _transferNFT(_creator, msg.sender, _id, _amount);
    IERC20(maviaTokenAddress).transferFrom(msg.sender, _creator, _buyNowPrice - variables[2]);
    _transferMarketFee(variables[1] + variables[2]);
    _transferRoyaltyFeeFromBuyer(_id, (_buyNowPrice * _royaltyPercentage) / 10000);
    markTokenSold(_id, true);

    emit Sold(msg.sender, _creator, _amount, _buyNowPrice, _id);
  }

  /**
   * @dev create a sale for the token
   * @param _id uint256 ID of the token
   * @param _amount uint256 the price value in wei
   * @param _owner address of the token owner
   */
  function _createSalePrice(
    uint256 _id,
    uint256 _amount,
    uint256 _royaltyPercentage,
    uint256 _price,
    address _owner
  ) private {
    require(_price > 0, "Marketplace:createSalePrice");
    salePrice[_id][_owner] = SalePrice(_owner, _amount, _price, _royaltyPercentage);
  }

  /**
   * @dev create a bid for the token
   * @param _id uint256 ID of the token
   * @param _amount uint256 token amount
   * @param _price uint256 the bid value in wei
   * @param _startTime end time of bid
   * @param _endTime end time of bid
   * @param _owner address of the token owner
   */
  function _createBidPrice(
    uint256 _id,
    uint256 _amount,
    uint256 _royaltyPercentage,
    uint256 _price,
    uint256 _startTime,
    uint256 _endTime,
    address _owner
  ) private {
    require(_price > 0, "Marketplace:createBidPrice");
    activeBid[_id][_owner] = ActiveBid(_owner, marketFeePercentage, _royaltyPercentage, chargeStatus, _amount, _price);
    activeBidRange[_id][_owner] = ActiveBidRange(_startTime, _endTime);
  }

  /**
   * @dev private function to return an existing bid on a token to the
   *      bidder and reset bid.
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _refundBid(uint256 _id, address _owner) private {
    ActiveBid memory currentBid = activeBid[_id][_owner];
    if (currentBid.bidder == address(0)) {
      return;
    }
    //current bidder should not be owner
    if (bidBalance[currentBid.bidder] > 0 && currentBid.bidder != _owner) {
      //subtract bid balance
      uint256 buyerMarketFee = currentBid.chargeStatus == 0 || currentBid.chargeStatus == 1
        ? 0
        : (currentBid.price * currentBid.marketFeePercentage) / 10000;
      uint256 royaltyFee = (currentBid.price * currentBid.royaltyFeePercentage) / 10000;

      bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder] - (currentBid.price + buyerMarketFee + royaltyFee);
      IERC20(maviaTokenAddress).transfer(currentBid.bidder, currentBid.price + buyerMarketFee + royaltyFee);
    }
  }

  /**
   * @dev utility function for calculating the royalty fee for given amount of wei
   * @param _id tokenId
   */
  function getRoyaltyFeePercentage(uint256 _id) private view returns (uint256) {
    return IRoyalty(maviaNFTAddress).getRoyaltyPercentage(_id);
  }

  /**
   * @dev utility function for calculating the royalty fee for given amount of wei
   * @param _id tokenId
   * @param _amount uint256 wei amount
   * @return uint256 wei fee
   */
  function calculateRoyaltyFee(uint256 _id, uint256 _amount) private view returns (uint256) {
    return (_amount * IRoyalty(maviaNFTAddress).getRoyaltyPercentage(_id)) / 10000;
  }

  /**
   * @dev utility function for calculating the marketplace fee for given amount of wei
   * @param _chargeStatus uint256 charge status
   * @param _amount uint256 wei amount
   * @param _marketFeePercentage uint256 market fee percentage
   * @return uint256 wei fee
   */
  function getSellerMarketplaceFee(
    uint256 _chargeStatus,
    uint256 _amount,
    uint256 _marketFeePercentage
  ) private pure returns (uint256) {
    return _chargeStatus == 0 || _chargeStatus == 2 ? 0 : (_amount * _marketFeePercentage) / 10000;
  }

  /**
   * @dev utility function for calculating the marketplace fee for given amount of wei
   * @param _chargeStatus uint256 charge status
   * @param _amount uint256 wei amount
   * @param _marketFeePercentage uint256 market fee percentage
   * @return uint256 wei fee
   */
  function getBuyerMarketplaceFee(
    uint256 _chargeStatus,
    uint256 _amount,
    uint256 _marketFeePercentage
  ) private pure returns (uint256) {
    return _chargeStatus == 0 || _chargeStatus == 1 ? 0 : (_amount * _marketFeePercentage) / 10000;
  }

  function getRequireCost(uint256 _price, uint256 _royaltyPercentage) private view returns (uint256) {
    return
      _price +
      getBuyerMarketplaceFee(chargeStatus, _price, marketFeePercentage) +
      ((_price * _royaltyPercentage) / 10000);
  }

  /**
   * @dev get minimum new bid price
   * @param _price uint256 current bid price
   */
  function _getMinimumBidPrice(uint256 _price) private view returns (uint256) {
    return _price + (_price * bidIncreasePercentage) / 10000;
  }

  /**
   * @dev check whether the ERC1155 token has sold at least once
   * @param _id uint256 token ID
   * @return bool of whether the token has sold
   */
  function hasTokenSold(uint256 _id) external view returns (bool) {
    return soldTokens[_id];
  }

  /**
   * @dev mark a token as sold
   * @param _id uint256 token ID
   * @param _hasSold bool of whether the token should be marked sold or not
   */
  function markTokenSold(uint256 _id, bool _hasSold) private {
    soldTokens[_id] = _hasSold;
  }

  /**
   * @dev Checks that the sender has enough token
   * @param _id uint256 ID of the token
   * @param _amount uint256 amount of the token.
   */
  function enoughTokenAmount(uint256 _id, uint256 _amount) private view {
    uint256 balance = IERC1155(maviaNFTAddress).balanceOf(msg.sender, _id);
    require(balance >= _amount && _amount > 0, "Marketplace:enoughTokenAmount01");
    require(tokenSaleInfo[_id][msg.sender].status == 0, "Marketplace:enoughTokenAmount02");
  }

  function _transferNFTToMarketplace(
    uint256 _id,
    uint256 _amount,
    address _owner
  ) private {
    IMaviaNFT(maviaNFTAddress).setApprovalForAllByMarketplace(_owner, address(this), true);
    IERC1155(maviaNFTAddress).safeTransferFrom(_owner, address(this), _id, _amount, "");
  }

  function _transferNFT(
    address _from,
    address _to,
    uint256 _id,
    uint256 _amount
  ) private {
    IMaviaNFT(maviaNFTAddress).setApprovalForAllByMarketplace(_from, address(this), true);
    IERC1155(maviaNFTAddress).safeTransferFrom(_from, _to, _id, _amount, "");
  }

  /**
   * @dev transfer royalty fee
   * @param _id id nft
   * @param _amount royalty fee
   */
  function _transferRoyaltyFeeFromBuyer(uint256 _id, uint256 _amount) private {
    IERC20(maviaTokenAddress).transferFrom(msg.sender, ICreator(maviaNFTAddress).getCreator(_id), _amount);
  }

  function _transferRoyaltyFeeFromMarketplace(uint256 _id, uint256 _amount) private {
    IERC20(maviaTokenAddress).transfer(ICreator(maviaNFTAddress).getCreator(_id), _amount);
  }

  /**
   * @dev transfer market fee
   * @param _amount market fee
   */
  function _transferMarketFee(uint256 _amount) private {
    IERC20(maviaTokenAddress).transferFrom(msg.sender, address(this), _amount);
  }

  function _payoutFromBuyer(
    address _owner,
    uint256 _price,
    uint256 _sellerMarketFee,
    uint256 _buyerMarketFee
  ) private {
    IERC20(maviaTokenAddress).transferFrom(msg.sender, _owner, _price - _sellerMarketFee);
    _transferMarketFee(_sellerMarketFee + _buyerMarketFee);
  }

  function _payoutFromMarketplace(
    address _owner,
    uint256 _price,
    uint256 _sellerMarketFee
  ) private {
    IERC20(maviaTokenAddress).transfer(_owner, _price - _sellerMarketFee);
  }

  /**
   * @dev remove token from sale
   * @param _id uint256 id of the token.
   * @param _owner owner of the token
   */
  function _removeFromSale(uint256 _id, address _owner) private {
    tokenSaleInfo[_id][_owner] = TokenSaleInfo(0, 0, 0, 0, 0, new uint256[](0), new address[](0));
  }

  /**
   * @dev private function to reset bid by setting bidder and bid to 0.
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _resetBid(uint256 _id, address _owner) private {
    activeBid[_id][_owner] = ActiveBid(address(0), 0, 0, 0, 0, 0);
  }

  /**
   * @dev private function to set a bid.
   * @param _bidder address of the bidder.
   * @param _id uin256 id of the token.
   * @param _owner address of the token owner
   * @param _id uint256 token ID
   * @param _amount uint256 token amount
   * @param _price uint256 bid price
   */
  function _setBid(
    address _bidder,
    address _owner,
    uint256 _id,
    uint256 _amount,
    uint256 _price
  ) private {
    activeBid[_id][_owner] = ActiveBid(
      _bidder,
      marketFeePercentage,
      getRoyaltyFeePercentage(_id),
      chargeStatus,
      _amount,
      _price
    );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EmergencyWithdraw is OwnableUpgradeable {
  event Received(address sender, uint256 amount);
  uint256 internal totalMarketFee;

  /**
   * @dev allow contract to receive ethers
   */
  receive() external payable {
    emit Received(_msgSender(), msg.value);
  }

  /**
   * @dev get the eth balance on the contract
   * @return eth balance
   */
  function getEthBalance() public view onlyOwner returns (uint256) {
    return address(this).balance;
  }

  /**
   * @dev withdraw eth balance
   */
  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  /**
   * @dev get the token balance
   * @param _tokenAddress token address
   */
  function getTokenBalance(address _tokenAddress) public view onlyOwner returns (uint256) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(owner(), getTokenBalance(_tokenAddress));
  }

  /**
   * @dev withdraw token balance
   * @param _tokenAddress token address
   */
  function withdrawMarketFee(address _tokenAddress) external onlyOwner {
    uint256 amount = totalMarketFee;
    totalMarketFee = 0;
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(owner(), amount);
  }

  /**
   * @dev get total market fee
   */
  function getTotalMarketFee() external view onlyOwner returns (uint256) {
    return totalMarketFee;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IRoyalty {
  /**
   * @dev Gets the royalty of the token
   * @param _id uint256 ID of the token
   * @return uint256 royalty percentage
   */
  function getRoyaltyPercentage(uint256 _id) external view returns (uint256);

  /**
   * @dev Sets the royalty of the token
   * @param _id uint256 ID of the token
   * @param _royaltyPercentage uint256 royalty percentage
   */
  function setRoyaltyPercentage(uint256 _id, uint256 _royaltyPercentage) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

interface IMaviaNFT {
  /**
   * @dev Mintable
   */
  function mint(
    address account,
    uint256 id,
    uint256 amount,
    uint256 royaltyPercentage,
    bytes memory data
  ) external; //by MINTER_ROLE

  /**
   * @dev Burnable
   */
  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external; //by BURNER_ROLE

  /**
   * @dev redeem token from account
   * @param _creator address token owner
   * @param _id uint256 id token
   * @param _amount uint256 amount token
   * @param _royaltyFeePercentage uint256 royalty fee percentage
   * @param _price uint256 token price
   * @param _buyNowPrice uint256 token buy now price
   * @param _priceType uint256 price type
   * @param _startTime uint256 start time
   * @param _endTime uint256 end time
   * @param _status uint256 sale status
   * @param _signature bytes signature
   */
  function redeem(
    address _creator,
    uint256 _id,
    uint256 _amount,
    uint256 _royaltyFeePercentage,
    uint256 _price,
    uint256 _buyNowPrice,
    uint256 _priceType,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _status,
    bytes calldata _signature
  ) external;

  /**
   * @dev set approval for all by marketplace
   * @param _creator address of the creator of the token.
   * @param _operator address of operator
   * @param _approved approve status
   */
  function setApprovalForAllByMarketplace(
    address _creator,
    address _operator,
    bool _approved
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMarketplace {
  /**
   * @dev add a token fixed price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _amount uint256 amount of the token
   * @param _price price of the token
   */
  function createFixedPrice(
    uint256 _id,
    uint256 _amount,
    uint256 _price
  ) external;

  /**
   * @dev add a token bid price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _amount uint256 amount of the token
   * @param _price price of the token
   * @param _buyNowPrice buy now price of the token
   */
  function createBidPrice(
    uint256 _id,
    uint256 _amount,
    uint256 _price,
    uint256 _buyNowPrice
  ) external;

  /**
   * @dev add a token bid range price for sale only from token Owner
   * @param _id uint256 id of the token
   * @param _amount uint256 amount of the token
   * @param _price price of the token
   * @param _buyNowPrice buy now price of the token
   * @param _startTime start time of bid
   * @param _endTime end time of bid
   */
  function createBidRangePrice(
    uint256 _id,
    uint256 _amount,
    uint256 _price,
    uint256 _buyNowPrice,
    uint256 _startTime,
    uint256 _endTime
  ) external;

  /**
   * @dev remove token from sale
   * @param _id uint256 ID of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _id, address _owner) external;

  /**
   * @dev edit token price for fixed price mode only
   * @param _id uint256 ID of the token.
   * @param _price uint256 token price
   */
  function editPrice(uint256 _id, uint256 _price) external;

  /**
   * @dev purchase a token
   * @param _id uint256 ID of the token
   * @param _amount uint256 amount token to buy
   * @param _owner address owner of the token
   */
  function buy(
    uint256 _id,
    uint256 _amount,
    address _owner
  ) external;

  /**
   * @dev bid a token
   * @param _id uint256 ID of the token
   * @param _price uint256 price to bid
   * @param _owner address owner of the token
   */
  function bid(
    uint256 _id,
    uint256 _price,
    address _owner
  ) external;

  /**
   * @dev accept bid a token
   * @param _id uint256 ID of the token
   * @param _owner address of the token
   */
  function acceptBid(uint256 _id, address _owner) external;

  /**
   * @dev cancel bid a token
   * @param _id uint256 ID of the token
   * @param _owner address owner of the token
   */
  function cancelBid(uint256 _id, address _owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICreator {
  /**
   * @dev Gets the creator of the token
   * @param _id uint256 ID of the token
   * @return address of the creator
   */
  function getCreator(uint256 _id) external view returns (address);

  /**
   * @dev Sets the creator of the token
   * @param _id uint256 ID of the token
   * @param _creator address of the creator for the token
   */
  function setCreator(uint256 _id, address _creator) external;
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
    }

    function __ERC1155Receiver_init_unchained() internal initializer {
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

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal initializer {
        __ERC165_init_unchained();
        __ERC1155Receiver_init_unchained();
        __ERC1155Holder_init_unchained();
    }

    function __ERC1155Holder_init_unchained() internal initializer {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity ^0.8.0;

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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}