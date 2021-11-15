// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./INafterMarketAuction.sol";
import "./INafterRoyaltyRegistry.sol";
import "./IMarketplaceSettings.sol";
import "./Payments.sol";
import "./INafter.sol";

contract NafterMarketAuction is
  Initializable,
  OwnableUpgradeable,
  AccessControlUpgradeable,
  Payments,
  INafterMarketAuction
{
  using SafeMath for uint256;
  /////////////////////////////////////////////////////////////////////////
  // Structs
  /////////////////////////////////////////////////////////////////////////

  // The active bid for a given token, contains the bidder, the marketplace fee at the time of the bid, and the amount of wei placed on the token
  struct ActiveBid {
    address payable bidder;
    uint8 marketplaceFee;
    uint256 amount;
    uint8 paymentMode;
  }

  struct ActiveBidRange {
    uint256 startTime;
    uint256 endTime;
  }

  // The sale price for a given token containing the seller and the amount of wei to be sold for
  struct SalePrice {
    address payable seller;
    uint256 amount;
    uint8 paymentMode;
  }

  /////////////////////////////////////////////////////////////////////////
  // State Variables
  /////////////////////////////////////////////////////////////////////////

  // Marketplace Settings Interface
  IMarketplaceSettings public iMarketplaceSettings;

  // Creator Royalty Interface
  INafterRoyaltyRegistry public iERC1155CreatorRoyalty;

  // Nafter contract
  INafter public nafter;
  //erc1155 contract
  IERC1155 public erc1155;

  // Mapping from ERC1155 contract to mapping of tokenId to sale price.
  mapping(uint256 => mapping(address => SalePrice)) private salePrice;
  // Mapping of ERC1155 contract to mapping of token ID to the current bid amount.
  mapping(uint256 => mapping(address => ActiveBid)) private activeBid;
  mapping(uint256 => mapping(address => ActiveBidRange)) private activeBidRange;

  mapping(address => uint256) public bidBalance;
  // A minimum increase in bid amount when out bidding someone.
  uint8 public minimumBidIncreasePercentage; // 10 = 10%
  uint8 public feeConfig;
  mapping(address => uint256) public nafterBidBalance;

  /////////////////////////////////////////////////////////////////////////////
  // Events
  /////////////////////////////////////////////////////////////////////////////
  event Sold(address indexed _buyer, address indexed _seller, uint256 _amount, uint256 _tokenId);

  // event SetSalePrice(uint256 _amount, uint256 _tokenId);

  event Bid(address indexed _bidder, uint256 _amount, uint256 _tokenId);

  // event SetInitialBidPriceWithRange(
  //   uint256 _bidAmount,
  //   uint256 _startTime,
  //   uint256 _endTime,
  //   address _owner,
  //   uint256 _tokenId
  // );
  event AcceptBid(
    address indexed _bidder,
    address indexed _seller,
    uint256 _amount,
    uint256 _tokenId,
    uint8 _paymentMode
  );

  event CancelBid(address indexed _bidder, uint256 _amount, uint256 _tokenId);

  /////////////////////////////////////////////////////////////////////////
  // Constructor
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Initializes the contract setting the market settings and creator royalty interfaces.
   * @param _iMarketSettings address to set as iMarketplaceSettings.
   * @param _iERC1155CreatorRoyalty address to set as iERC1155CreatorRoyalty.
   * @param _nafter address of the nafter contract
   */
  function __NafterMarketAuction_init(
    address _iMarketSettings,
    address _iERC1155CreatorRoyalty,
    address _nafter,
    address _nafterToken
  ) public initializer {
    __Ownable_init();
    __PullPayment_init();
    __AccessControl_init();
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

    // Set iMarketSettings
    iMarketplaceSettings = IMarketplaceSettings(_iMarketSettings);

    // Set iERC1155CreatorRoyalty
    iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_iERC1155CreatorRoyalty);

    nafter = INafter(_nafter);
    erc1155 = IERC1155(_nafter);
    nafterToken = IERC20(_nafterToken);
    minimumBidIncreasePercentage = 10;
    feeConfig = 3;
  }

  // /////////////////////////////////////////////////////////////////////////
  // // Get owner of the token
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev get owner of the token
  //  * @param _tokenId uint256 ID of the token
  //  * @param _owner address of the token owner
  //  */
  // function isOwnerOfTheToken(uint256 _tokenId, address _owner) public view returns (bool) {
  //   return erc1155.balanceOf(_owner, _tokenId) > 0;
  // }

  /////////////////////////////////////////////////////////////////////////
  // Get token sale price against token id
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get the token sale price against token id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getSalePrice(uint256 _tokenId, address _owner) external view returns (address payable, uint256) {
    return (salePrice[_tokenId][_owner].seller, salePrice[_tokenId][_owner].amount);
  }

  /**
   * @dev get the token sale price against token id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function currentSalePrice(uint256 _tokenId, address _owner)
    external
    view
    returns (
      address payable,
      uint256,
      uint8
    )
  {
    return (
      salePrice[_tokenId][_owner].seller,
      salePrice[_tokenId][_owner].amount,
      salePrice[_tokenId][_owner].paymentMode
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // get active bid against tokenId
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get active bid against token Id
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getActiveBid(uint256 _tokenId, address _owner)
    external
    view
    returns (
      address payable,
      uint8,
      uint256
    )
  {
    // ActiveBid memory ab = activeBid[_tokenId][_owner];
    return (
      activeBid[_tokenId][_owner].bidder,
      activeBid[_tokenId][_owner].marketplaceFee,
      activeBid[_tokenId][_owner].amount
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // has active bid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev has active bid
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function hasTokenActiveBid(uint256 _tokenId, address _owner) external view override returns (bool) {
    if (activeBid[_tokenId][_owner].bidder == _owner || activeBid[_tokenId][_owner].bidder == address(0)) return false;

    return true;
  }

  // /////////////////////////////////////////////////////////////////////////
  // // get bid balance of user
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev get bid balance of user
  //  * @param _user address of the user
  //  */
  // function getBidBalance(address _user) external view returns (uint256) {
  //   return bidBalance[_user];
  // }

  // /////////////////////////////////////////////////////////////////////////
  // // get nafter bid balance of user
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev get nafter bid balance of user
  //  * @param _user address of the user
  //  */
  // function getNafterBidBalance(address _user) external view returns (uint256) {
  //   return nafterBidBalance[_user];
  // }

  /////////////////////////////////////////////////////////////////////////
  // get active bid range against token id
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev get active bid range against token id
   * @param _tokenId uint256 ID of the token
   */
  function getActiveBidRange(uint256 _tokenId, address _owner) external view returns (uint256, uint256) {
    return (activeBidRange[_tokenId][_owner].startTime, activeBidRange[_tokenId][_owner].endTime);
  }

  /////////////////////////////////////////////////////////////////////////
  // withdrawMarketFunds
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Admin function to withdraw market funds
   * Rules:
   * - only owner
   */
  function withdrawMarketFunds() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  /////////////////////////////////////////////////////////////////////////
  // seNafter
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Admin function to set the marketplace settings.
   * Rules:
   * - only owner
   * - _address != address(0)
   * @param _nafter address of the IMarketplaceSettings.
   */
  function setData(
    address _nafter,
    address _royalty,
    address _token,
    address _marketplaceSettings,
    uint8 _percentage,
    uint8 _feeConfig
  ) public onlyOwner {
    nafter = INafter(_nafter);
    erc1155 = IERC1155(_nafter);
    iERC1155CreatorRoyalty = INafterRoyaltyRegistry(_royalty);
    nafterToken = IERC20(_token);
    iMarketplaceSettings = IMarketplaceSettings(_marketplaceSettings);
    minimumBidIncreasePercentage = _percentage;
    feeConfig = _feeConfig;
  }

  // /////////////////////////////////////////////////////////////////////////
  // // Modifiers (as functions)
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev Checks that the token owner is approved for the ERC1155Market
  //  * @param _owner address of the token owner
  //  */
  // function ownerMustHaveMarketplaceApproved(address _owner) internal view {
  //   require(erc1155.isApprovedForAll(_owner, address(this)), "no approved");
  // }

  /**
   * @dev Checks that the token is owned by the sender
   * @param _tokenId uint256 ID of the token
   */
  function senderMustBeTokenOwner(uint256 _tokenId) internal view {
    require(
      erc1155.balanceOf(msg.sender, _tokenId) > 0 ||
        msg.sender == address(nafter) ||
        hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
      "owner"
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // setSalePrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
   * @param _tokenId uint256 ID of the token
   * @param _amount uint256 wei value that the item is for sale
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setSalePrice(
    uint256 _tokenId,
    uint256 _amount,
    address _owner,
    uint8 _paymentMode
  ) external override {
    // The sender must be the token owner
    senderMustBeTokenOwner(_tokenId);

    // if (_amount == 0) {
    //   // Set not for sale and exit
    //   _resetTokenPrice(_tokenId, _owner);
    //   // emit SetSalePrice(_amount, _tokenId);
    //   return;
    // }

    salePrice[_tokenId][_owner] = SalePrice(payable(_owner), _amount, _paymentMode);
    nafter.setPrice(_amount, _tokenId, _owner);
    // emit SetSalePrice(_amount, _tokenId);
  }

  /**
   * @dev restore data from old contract, only call by owner
   * @param _oldAddress address of old contract.
   * @param _oldNafterAddress get the token ids from the old nafter contract.
   * @param _startIndex start index of array
   * @param _endIndex end index of array
   */
  function restore(
    address _oldAddress,
    address _oldNafterAddress,
    uint256 _startIndex,
    uint256 _endIndex
  ) external onlyOwner {
    NafterMarketAuction oldContract = NafterMarketAuction(_oldAddress);
    INafter oldNafterContract = INafter(_oldNafterAddress);

    for (uint256 i = _startIndex; i < _endIndex; i++) {
      uint256 tokenId = oldNafterContract.getTokenId(i);

      address[] memory owners = oldNafterContract.getOwners(tokenId);
      for (uint256 j = 0; j < owners.length; j++) {
        address owner = owners[j];
        (address payable sender, uint256 amount) = oldContract.getSalePrice(tokenId, owner);
        salePrice[tokenId][owner] = SalePrice(sender, amount, 0);

        (address payable bidder, uint8 marketplaceFee, uint256 bidAmount) = oldContract.getActiveBid(tokenId, owner);
        activeBid[tokenId][owner] = ActiveBid(bidder, marketplaceFee, bidAmount, 0);
        uint256 serviceFee = bidAmount.mul(marketplaceFee).div(100);
        bidBalance[bidder] = bidBalance[bidder].add(bidAmount.add(serviceFee));

        (uint256 startTime, uint256 endTime) = oldContract.getActiveBidRange(tokenId, owner);
        activeBidRange[tokenId][owner] = ActiveBidRange(startTime, endTime);
      }
    }

    minimumBidIncreasePercentage = oldContract.minimumBidIncreasePercentage();
  }

  // /////////////////////////////////////////////////////////////////////////
  // // safeBuy
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev Purchase the token with the expected amount. The current token owner must have the marketplace approved.
  //  * @param _tokenId uint256 ID of the token
  //  * @param _amount uint256 wei amount expecting to purchase the token for.
  //  * @param _owner address of the token owner
  //  * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
  //  */
  // function safeBuy(
  //   uint256 _tokenId,
  //   uint256 _amount,
  //   address _owner,
  //   uint8 _paymentMode
  // ) external payable {
  //   // Make sure the tokenPrice is the expected amount
  //   require(salePrice[_tokenId][_owner].amount == _amount, "wrong amount");
  //   buy(_tokenId, _owner, _paymentMode);
  // }

  /////////////////////////////////////////////////////////////////////////
  // buy
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Purchases the token if it is for sale.
   * @param _tokenId uint256 ID of the token.
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function buy(
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) public payable {
    uint256 amount = tokenPriceFeeIncluded(_tokenId, _owner);
    uint8 priceType = nafter.getPriceType(_tokenId, _owner);
    require(priceType == 0, "only fixed sale");
    require(nafter.getIsForSale(_tokenId, _owner) == true, "not sale");
    SalePrice memory sp = salePrice[_tokenId][_owner];
    require(sp.paymentMode == _paymentMode, "wrong payment mode");
    // Check that enough ether was sent.
    if (_paymentMode == 0) {
      require(msg.value >= amount, "no correct price");
    }

    // The owner of the token must have the marketplace approved
    // ownerMustHaveMarketplaceApproved(_owner);

    // Transfer token.
    erc1155.safeTransferFrom(_owner, msg.sender, _tokenId, 1, "");

    // if the buyer had an existing bid, return it
    if (_addressHasBidOnToken(msg.sender, _tokenId, _owner)) {
      _refundBid(_tokenId, _owner);
    }

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), sp.amount);
    }
    Payments.payout(
      sp.amount,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      nafter.getServiceFee(_tokenId),
      iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(_tokenId),
      iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
      payable(_owner),
      payable(owner()),
      iERC1155CreatorRoyalty.tokenCreator(_tokenId),
      _paymentMode,
      feeConfig
    );

    // Set token as sold
    iMarketplaceSettings.markERC1155Token(_tokenId, true);

    //remove from sale after buy
    if (erc1155.balanceOf(_owner, _tokenId) == 0) {
      // Wipe the token price.
      _resetTokenPrice(_tokenId, _owner);
      nafter.removeFromSale(_tokenId, _owner);
    }

    emit Sold(msg.sender, _owner, sp.amount, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // tokenPrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Gets the sale price of the token
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return uint256 sale price of the token
   */
  function tokenPrice(uint256 _tokenId, address _owner) external view returns (uint256) {
    return salePrice[_tokenId][_owner].amount;
  }

  /////////////////////////////////////////////////////////////////////////
  // tokenPriceFeeIncluded
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Gets the sale price of the token including the marketplace fee.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return uint256 sale price of the token including the fee.
   */
  function tokenPriceFeeIncluded(uint256 _tokenId, address _owner) public view returns (uint256) {
    if (feeConfig == 2 || feeConfig == 3)
      return
        salePrice[_tokenId][_owner].amount.add(
          salePrice[_tokenId][_owner].amount.mul(nafter.getServiceFee(_tokenId)).div(100)
        );

    return salePrice[_tokenId][_owner].amount;
  }

  /////////////////////////////////////////////////////////////////////////
  // setInitialBidPriceWithRange
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev set initial bid with range
   * @param _bidAmount uint256 value in wei to bid.
   * @param _startTime end time of bid
   * @param _endTime end time of bid
   * @param _owner address of the token owner
   * @param _tokenId uint256 ID of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setInitialBidPriceWithRange(
    uint256 _bidAmount,
    uint256 _startTime,
    uint256 _endTime,
    address _owner,
    uint256 _tokenId,
    uint8 _paymentMode
  ) external override {
    senderMustBeTokenOwner(_tokenId);

    activeBid[_tokenId][_owner] = ActiveBid(payable(_owner), nafter.getServiceFee(_tokenId), _bidAmount, _paymentMode);
    activeBidRange[_tokenId][_owner] = ActiveBidRange(_startTime, _endTime);

    // emit SetInitialBidPriceWithRange(_bidAmount, _startTime, _endTime, _owner, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // bid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Bids on the token, replacing the bid if the bid is higher than the current bid. You cannot bid on a token you already own.
   * @param _newBidAmount uint256 value in wei to bid.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function bid(
    uint256 _newBidAmount,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) external payable {
    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3
        ? _newBidAmount.add(_newBidAmount.mul(nafter.getServiceFee(_tokenId)).div(100))
        : _newBidAmount;
      require(msg.value >= amount, "no correct price");
    }
    require(nafter.getIsForSale(_tokenId, _owner) == true, "not for sale");
    //Check bid range
    uint8 priceType = nafter.getPriceType(_tokenId, _owner);

    require(priceType == 1 || priceType == 2, "no fixed sale");
    if (priceType == 1)
      require(
        activeBidRange[_tokenId][_owner].startTime < block.timestamp &&
          activeBidRange[_tokenId][_owner].endTime > block.timestamp,
        "cant place bid"
      );

    uint256 currentBidAmount = activeBid[_tokenId][_owner].amount;
    require(
      _newBidAmount >= currentBidAmount.add(currentBidAmount.mul(minimumBidIncreasePercentage).div(100)),
      "high minimum percentage"
    );
    require(activeBid[_tokenId][_owner].paymentMode == _paymentMode, "wrong payment");

    // Refund previous bidder.
    _refundBid(_tokenId, _owner);
    //transfer naft tokens to contracts
    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _newBidAmount);
    }
    // Set the new bid.
    _setBid(_newBidAmount, payable(msg.sender), _tokenId, _owner, _paymentMode);
    nafter.setBid(_newBidAmount, msg.sender, _tokenId, _owner);
    emit Bid(msg.sender, _newBidAmount, _tokenId);
  }

  // /////////////////////////////////////////////////////////////////////////
  // // safeAcceptBid
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev Accept the bid on the token with the expected bid amount.
  //  * @param _tokenId uint256 ID of the token
  //  * @param _amount uint256 wei amount of the bid
  //  * @param _owner address of the token owner
  //  */
  // function safeAcceptBid(
  //   uint256 _tokenId,
  //   uint256 _amount,
  //   address _owner
  // ) external {
  //   // Make sure accepting bid is the expected amount
  //   require(activeBid[_tokenId][_owner].amount == _amount, "wrong amount");
  //   acceptBid(_tokenId, _owner);
  // }

  /////////////////////////////////////////////////////////////////////////
  // acceptBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Accept the bid on the token.
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function acceptBid(uint256 _tokenId, address _owner) public {
    // The sender must be the token owner
    senderMustBeTokenOwner(_tokenId);

    // The owner of the token must have the marketplace approved
    // ownerMustHaveMarketplaceApproved(_owner);

    // Check that a bid exists.
    require(activeBid[_tokenId][_owner].bidder != address(0), "no bid");

    // Get current bid on token

    ActiveBid memory currentBid = activeBid[_tokenId][_owner];

    // Transfer token.
    erc1155.safeTransferFrom(_owner, currentBid.bidder, _tokenId, 1, "");

    Payments.payout(
      currentBid.amount,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      nafter.getServiceFee(_tokenId),
      iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(_tokenId),
      iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
      payable(_owner),
      payable(owner()),
      iERC1155CreatorRoyalty.tokenCreator(_tokenId),
      currentBid.paymentMode,
      feeConfig
    );

    iMarketplaceSettings.markERC1155Token(_tokenId, true);
    if (currentBid.paymentMode == 0) {
      uint256 serviceFee = feeConfig == 2 || feeConfig == 3
        ? currentBid.amount.mul(currentBid.marketplaceFee).div(100)
        : 0;
      bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));
    } else {
      nafterBidBalance[currentBid.bidder] = nafterBidBalance[currentBid.bidder].sub(currentBid.amount);
    }
    uint8 paymentMode = currentBid.paymentMode;
    if (erc1155.balanceOf(_owner, _tokenId) == 0) {
      _resetTokenPrice(_tokenId, _owner);
      _resetBid(_tokenId, _owner);

      //remove from sale after accepting the bid
      nafter.removeFromSale(_tokenId, _owner);
    } else {
      activeBid[_tokenId][_owner].bidder = payable(address(0));
    }
    // Wipe the token price and bid.
    emit AcceptBid(currentBid.bidder, msg.sender, currentBid.amount, _tokenId, paymentMode);
  }

  /**
   * @dev lazy mintng to bid
   * @param _tokenAmount total token amount available
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _signature data signature to return account information
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   * @param _signature data signature to return account information
   * @param _creator address of the creator of the token.
   * @param _newBidAmount new Bid Amount including
   */
  function lazyMintingBid(
    uint256 _tokenAmount,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature,
    address _creator,
    uint256 _newBidAmount
  ) external payable {
    require(_priceType == 1 || _priceType == 2, "no fixed sale");
    if (_priceType == 1) require(_startTime < block.timestamp && _endTime > block.timestamp, "cant place bid");
    require(_newBidAmount >= _price.add(_price.mul(minimumBidIncreasePercentage).div(100)), "high minimum percentage");
    nafter.verify(
      _creator,
      _tokenAmount,
      true,
      _price,
      _priceType, //price type is 0
      _royaltyPercentage,
      _startTime,
      _endTime,
      _tokenId,
      _paymentMode,
      _signature
    );

    nafter.addNewTokenAndSetThePriceWithIdAndMinter(
      _tokenAmount,
      true,
      _price,
      _priceType,
      _royaltyPercentage,
      _tokenId,
      _creator,
      _creator
    );

    // uint8 serviceFee = nafter.getServiceFee(_tokenId);
    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3
        ? _newBidAmount.add(_newBidAmount.mul(nafter.getServiceFee(_tokenId)).div(100))
        : _newBidAmount;
      require(msg.value >= amount, "wrong amount");
    }

    _setBid(_newBidAmount, payable(msg.sender), _tokenId, _creator, _paymentMode);
    activeBidRange[_tokenId][_creator] = ActiveBidRange(_startTime, _endTime);

    nafter.setBid(_price, msg.sender, _tokenId, _creator);

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _newBidAmount);
    }
  }

  /**
   * @dev lazy mintng to buy
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function lazyMintingBuy(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature,
    address _creator
  ) external payable {
    nafter.verify(
      _creator,
      _tokenAmount,
      _isForSale,
      _price,
      0, //price type is 0
      _royaltyPercentage,
      0,
      0,
      _tokenId,
      _paymentMode,
      _signature
    );
    // in case of by, mint token on buyer
    //direct token transfer
    nafter.addNewTokenAndSetThePriceWithIdAndMinter(
      _tokenAmount,
      _isForSale,
      _price,
      0,
      _royaltyPercentage,
      _tokenId,
      _creator,
      _creator
    );
    salePrice[_tokenId][_creator] = SalePrice(payable(_creator), _price, _paymentMode);
    nafter.setPrice(_price, _tokenId, _creator);

    if (_paymentMode == 0) {
      uint256 amount = feeConfig == 2 || feeConfig == 3 ? tokenPriceFeeIncluded(_tokenId, _creator) : _price;
      require(msg.value >= amount, "no correct price");
    }

    erc1155.safeTransferFrom(_creator, msg.sender, _tokenId, 1, "");

    if (_paymentMode == 1) {
      Payments.safeTransferFrom(msg.sender, address(this), _price);
    }
    Payments.payout(
      _price,
      !iMarketplaceSettings.hasTokenSold(_tokenId),
      nafter.getServiceFee(_tokenId),
      iERC1155CreatorRoyalty.getTokenRoyaltyPercentage(_tokenId),
      iMarketplaceSettings.getERC1155ContractPrimarySaleFeePercentage(),
      payable(_creator),
      payable(owner()),
      iERC1155CreatorRoyalty.tokenCreator(_tokenId),
      _paymentMode,
      feeConfig
    );
    //remove from sale after buy
    if (erc1155.balanceOf(_creator, _tokenId) == 0) {
      // Wipe the token price.
      _resetTokenPrice(_tokenId, _creator);
      nafter.removeFromSale(_tokenId, _creator);
    }
  }

  /////////////////////////////////////////////////////////////////////////
  // cancelBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Cancel the bid on the token.
   * @param _tokenId uint256 ID of the token.
   * @param _owner address of the token owner
   */
  function cancelBid(uint256 _tokenId, address _owner) external {
    // Check that sender has a current bid.
    require(_addressHasBidOnToken(msg.sender, _tokenId, _owner), "cant cancel");

    // Refund the bidder.
    // if (_paymentMode == 0) _refundBid(_tokenId, _owner);
    // else _refundNafterBid(_tokenId, _owner);
    _refundBid(_tokenId, _owner);

    emit CancelBid(msg.sender, activeBid[_tokenId][_owner].amount, _tokenId);
  }

  /////////////////////////////////////////////////////////////////////////
  // currentBidDetailsOfToken
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Function to get current bid and bidder of a token.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function currentBidDetailsOfToken(uint256 _tokenId, address _owner)
    public
    view
    returns (
      uint256,
      address,
      uint8
    )
  {
    return (
      activeBid[_tokenId][_owner].amount,
      activeBid[_tokenId][_owner].bidder,
      activeBid[_tokenId][_owner].paymentMode
    );
  }

  /////////////////////////////////////////////////////////////////////////
  // _resetTokenPrice
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to set token price to 0 for a given contract.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _resetTokenPrice(uint256 _tokenId, address _owner) internal {
    salePrice[_tokenId][_owner] = SalePrice(payable(address(0)), 0, 0);
  }

  /////////////////////////////////////////////////////////////////////////
  // _addressHasBidOnToken
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function see if the given address has an existing bid on a token.
   * @param _bidder address that may have a current bid.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _addressHasBidOnToken(
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) internal view returns (bool) {
    return activeBid[_tokenId][_owner].bidder == _bidder;
  }

  /////////////////////////////////////////////////////////////////////////
  // _refundBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to return an existing bid on a token to the
   *      bidder and reset bid.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _refundBid(uint256 _tokenId, address _owner) internal {
    ActiveBid memory currentBid = activeBid[_tokenId][_owner];
    if (currentBid.bidder == address(0) || currentBid.bidder == _owner) {
      return;
    }
    //current bidder should not be owner
    if (currentBid.paymentMode == 0) {
      if (bidBalance[currentBid.bidder] > 0) {
        Payments.refund(currentBid.marketplaceFee, currentBid.bidder, currentBid.amount);
        //subtract bid balance
        uint256 serviceFee = feeConfig == 2 || feeConfig == 3
          ? currentBid.amount.mul(currentBid.marketplaceFee).div(100)
          : currentBid.amount;

        bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));
      }
    } else {
      if (nafterBidBalance[currentBid.bidder] > 0) {
        Payments.safeTransfer(currentBid.bidder, currentBid.amount);
        nafterBidBalance[currentBid.bidder] = nafterBidBalance[currentBid.bidder].sub(currentBid.amount);
      }
    }
    _resetBid(_tokenId, _owner);
  }

  // /////////////////////////////////////////////////////////////////////////
  // // _refundNafterBid
  // /////////////////////////////////////////////////////////////////////////
  // /**
  //  * @dev Internal function to return an existing bid on a token to the
  //  *      bidder and reset bid.
  //  * @param _tokenId uin256 id of the token.
  //  * @param _owner address of the token owner
  //  */
  // function _refundNafterBid(uint256 _tokenId, address _owner) internal {
  //   ActiveBid memory currentBid = activeBid[_tokenId][_owner];
  //   if (currentBid.bidder == address(0)) {
  //     return;
  //   }
  //   //current bidder should not be owner
  //   if (bidBalance[currentBid.bidder] > 0 && currentBid.bidder != _owner) {
  //     Payments.refundNafter(currentBid.marketplaceFee, currentBid.bidder, currentBid.amount);
  //     //subtract bid balance
  //     uint256 serviceFee = feeConfig == 2 || feeConfig == 3
  //       ? currentBid.amount.mul(currentBid.marketplaceFee).div(100)
  //       : currentBid.amount;

  //     bidBalance[currentBid.bidder] = bidBalance[currentBid.bidder].sub(currentBid.amount.add(serviceFee));
  //   }
  //   _resetBid(_tokenId, _owner);
  // }

  /////////////////////////////////////////////////////////////////////////
  // _resetBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to reset bid by setting bidder and bid to 0.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   */
  function _resetBid(uint256 _tokenId, address _owner) internal {
    activeBid[_tokenId][_owner] = ActiveBid(payable(address(0)), 0, 0, 0);
  }

  /////////////////////////////////////////////////////////////////////////
  // _setBid
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to set a bid.
   * @param _amount uint256 value in wei to bid. Does not include marketplace fee.
   * @param _bidder address of the bidder.
   * @param _tokenId uin256 id of the token.
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function _setBid(
    uint256 _amount,
    address payable _bidder,
    uint256 _tokenId,
    address _owner,
    uint8 _paymentMode
  ) internal {
    // Check bidder not 0 address.
    require(_bidder != address(0), "no 0 address");

    // Set bid.
    activeBid[_tokenId][_owner] = ActiveBid(_bidder, nafter.getServiceFee(_tokenId), _amount, _paymentMode);
    //add bid balance
    if (_paymentMode == 0) {
      bidBalance[_bidder] = feeConfig == 2 || feeConfig == 3
        ? bidBalance[_bidder].add(_amount.add(_amount.mul(nafter.getServiceFee(_tokenId)).div(100)))
        : bidBalance[_bidder].add(_amount);
    } else {
      nafterBidBalance[_bidder] = nafterBidBalance[_bidder].add(_amount);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./ISendValueProxy.sol";

/**
 * @dev Contract that attempts to send value to an address.
 */
contract SendValueProxy is ISendValueProxy {
  /**
   * @dev Send some wei to the address.
   * @param _to address to send some value to.
   */
  function sendValue(address payable _to) external payable override {
    // Note that `<address>.transfer` limits gas sent to receiver. It may
    // not support complex contract operations in the future.
    _to.transfer(msg.value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PullPaymentUpgradeable.sol";
import "./MaybeSendValue.sol";

/**
 * @dev Contract to make payments. If a direct transfer fails, it will store the payment in escrow until the address decides to pull the payment.
 */
contract SendValueOrEscrow is MaybeSendValue, PullPaymentUpgradeable {
  /////////////////////////////////////////////////////////////////////////
  // Events
  /////////////////////////////////////////////////////////////////////////
  event SendValue(address indexed _payee, uint256 amount);

  /////////////////////////////////////////////////////////////////////////
  // sendValueOrEscrow
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Send some value to an address.
   * @param _to address to send some value to.
   * @param _value uint256 amount to send.
   */
  function sendValueOrEscrow(address payable _to, uint256 _value) internal {
    // attempt to make the transfer
    bool successfulTransfer = MaybeSendValue.maybeSendValue(_to, _value);
    // if it fails, transfer it into escrow for them to redeem at their will.
    if (!successfulTransfer) {
      _asyncTransfer(_to, _value);
    }
    emit SendValue(_to, _value);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./SendValueOrEscrow.sol";

/**
 * @title Payments contract for Nafter Marketplaces.
 */
contract Payments is SendValueOrEscrow {
  using SafeMath for uint256;
  using SafeMath for uint8;
  using SafeERC20 for IERC20;

  IERC20 public nafterToken;

  /////////////////////////////////////////////////////////////////////////
  // refund
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to refund an address. Typically for canceled bids or offers.
   * Requirements:
   *
   *  - _payee cannot be the zero address
   *
   * @param _marketplacePercentage uint8 percentage of the fee for the marketplace.
   * @param _amount uint256 value to be split.
   * @param _payee address seller of the token.
   */
  function refund(
    uint8 _marketplacePercentage,
    address payable _payee,
    uint256 _amount
  ) internal {
    // require(_payee != address(0), "payee no zero");

    if (_amount > 0) {
      SendValueOrEscrow.sendValueOrEscrow(_payee, _amount.add(calcPercentagePayment(_amount, _marketplacePercentage)));
    }
  }

  /////////////////////////////////////////////////////////////////////////
  // refundNafter
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to refund an address. Typically for canceled bids or offers.
   * Requirements:
   *
   *  - _payee cannot be the zero address
   *
   * @param _amount uint256 value to be split.
   * @param _payee address seller of the token.
   */
  function safeTransfer(address payable _payee, uint256 _amount) internal {
    // require(_payee != address(0), "payee no zero");

    if (_amount > 0) {
      nafterToken.safeTransfer(_payee, _amount);
    }
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _amount
  ) internal {
    nafterToken.safeTransferFrom(_from, _to, _amount);
  }

  /////////////////////////////////////////////////////////////////////////
  // payout
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to pay the seller, creator, and maintainer.
   * Requirements:
   *
   *  - _marketplacePercentage + _royaltyPercentage + _primarySalePercentage <= 100
   *  - no payees can be the zero address
   *
   * @param _amount uint256 value to be split.
   * @param _isPrimarySale bool of whether this is a primary sale.
   * @param _marketplacePercentage uint8 percentage of the fee for the marketplace.
   * @param _royaltyPercentage uint8 percentage of the fee for the royalty.
   * @param _primarySalePercentage uint8 percentage primary sale fee for the marketplace.
   * @param _payee address seller of the token.
   * @param _marketplacePayee address seller of the token.
   * @param _royaltyPayee creater address .
   */
  function payout(
    uint256 _amount,
    bool _isPrimarySale,
    uint8 _marketplacePercentage,
    uint8 _royaltyPercentage,
    uint8 _primarySalePercentage,
    address payable _payee,
    address payable _marketplacePayee,
    address payable _royaltyPayee,
    // address payable _primarySalePayee,
    uint8 _paymentMode,
    uint8 _feeConfig
  ) internal {
    // Note:: Solidity is kind of terrible in that there is a limit to local
    //        variables that can be put into the stack. The real pain is that
    //        one can put structs, arrays, or mappings into memory but not basic
    //        data types. Hence our payments array that stores these values.
    uint256[5] memory payments;

    // uint256 royaltyPayment
    payments[1] = calcRoyaltyPayment(_isPrimarySale, _amount, _royaltyPercentage);

    // uint256 primarySalePayment
    payments[2] = calcPrimarySalePayment(_isPrimarySale, _amount, _primarySalePercentage);

    // uint256 payeePayment
    payments[3] = _amount.sub(payments[1]).sub(payments[2]);

    if (_paymentMode == 0) {
      if (_feeConfig == 1) {
        payments[4] = calcPercentagePayment(_amount, _marketplacePercentage);
      } else if (_feeConfig == 2) {
        payments[0] = calcPercentagePayment(_amount, _marketplacePercentage);
      } else if (_feeConfig == 3) {
        payments[0] = calcPercentagePayment(_amount, _marketplacePercentage);
        payments[4] = calcPercentagePayment(_amount, _marketplacePercentage);
      }
      // marketplacePayment
      if (payments[0] > 0) {
        SendValueOrEscrow.sendValueOrEscrow(_marketplacePayee, payments[0]);
      }

      // royaltyPayment
      if (payments[1] > 0) {
        SendValueOrEscrow.sendValueOrEscrow(_royaltyPayee, payments[1]);
      }
      // primarySalePayment
      if (payments[2] > 0) {
        SendValueOrEscrow.sendValueOrEscrow(_marketplacePayee, payments[2]);
      }
      if (payments[4] > 0) {
        SendValueOrEscrow.sendValueOrEscrow(_marketplacePayee, payments[4]);
        payments[3] = payments[3].sub(payments[4]);
      }
      // payeePayment
      if (payments[3] > 0) {
        SendValueOrEscrow.sendValueOrEscrow(_payee, payments[3]);
      }
    } else {
      // if (payments[0] > 0) {
      //   // SendValueOrEscrow.sendValueOrEscrow(_marketplacePayee, payments[0]);
      //   nafterToken.safeTransfer(_marketplacePayee, payments[0]);
      // }

      // royaltyPayment
      if (payments[1] > 0) {
        // SendValueOrEscrow.sendValueOrEscrow(_royaltyPayee, payments[1]);
        nafterToken.safeTransfer(_royaltyPayee, payments[1]);
      }
      // primarySalePayment
      if (payments[2] > 0) {
        // SendValueOrEscrow.sendValueOrEscrow(_primarySalePayee, payments[2]);
        nafterToken.safeTransfer(_marketplacePayee, payments[2]);
      }
      // payeePayment
      if (payments[3] > 0) {
        // SendValueOrEscrow.sendValueOrEscrow(_payee, payments[3]);
        nafterToken.safeTransfer(_payee, payments[3]);
      }
    }
  }

  /////////////////////////////////////////////////////////////////////////
  // calcRoyaltyPayment
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Private function to calculate Royalty amount.
   *      If primary sale: 0
   *      If no royalty percentage: 0
   *      otherwise: royalty in wei
   * @param _isPrimarySale bool of whether this is a primary sale
   * @param _amount uint256 value to be split
   * @param _percentage uint8 royalty percentage
   * @return uint256 wei value owed for royalty
   */
  function calcRoyaltyPayment(
    bool _isPrimarySale,
    uint256 _amount,
    uint8 _percentage
  ) private pure returns (uint256) {
    if (_isPrimarySale) {
      return 0;
    }
    return calcPercentagePayment(_amount, _percentage);
  }

  /////////////////////////////////////////////////////////////////////////
  // calcPrimarySalePayment
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Private function to calculate PrimarySale amount.
   *      If not primary sale: 0
   *      otherwise: primary sale in wei
   * @param _isPrimarySale bool of whether this is a primary sale
   * @param _amount uint256 value to be split
   * @param _percentage uint8 royalty percentage
   * @return uint256 wei value owed for primary sale
   */
  function calcPrimarySalePayment(
    bool _isPrimarySale,
    uint256 _amount,
    uint8 _percentage
  ) private pure returns (uint256) {
    if (_isPrimarySale) {
      return calcPercentagePayment(_amount, _percentage);
    }
    return 0;
  }

  /////////////////////////////////////////////////////////////////////////
  // calcPercentagePayment
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Internal function to calculate percentage value.
   * @param _amount uint256 wei value
   * @param _percentage uint8  percentage
   * @return uint256 wei value based on percentage.
   */
  function calcPercentagePayment(uint256 _amount, uint8 _percentage) internal pure returns (uint256) {
    return _amount.mul(_percentage).div(100);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./SendValueProxy.sol";

/**
 * @dev Contract with a ISendValueProxy that will catch reverts when attempting to transfer funds.
 */

contract MaybeSendValue {
  // SendValueProxy proxy;

  // constructor() {
  //     proxy = new SendValueProxy();
  // }

  /**
   * @dev Maybe send some wei to the address via a proxy. Returns true on success and false if transfer fails.
   * @param _to address to send some value to.
   * @param _value uint256 amount to send.
   */
  function maybeSendValue(address payable _to, uint256 _value) internal returns (bool) {
    _to.transfer(_value);

    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

interface ISendValueProxy {
  function sendValue(address payable _to) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./IERC1155TokenCreator.sol";

/**
 * @title IERC1155CreatorRoyalty Token level royalty interface.
 */
interface INafterRoyaltyRegistry is IERC1155TokenCreator {
  /**
   * @dev Get the royalty fee percentage for a specific ERC1155 contract.
   * @param _tokenId uint256 token ID.
   * @return uint8 wei royalty fee.
   */
  function getTokenRoyaltyPercentage(uint256 _tokenId) external view returns (uint8);

  /**
   * @dev Utililty function to calculate the royalty fee for a token.
   * @param _tokenId uint256 token ID.
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculateRoyaltyFee(uint256 _tokenId, uint256 _amount) external view returns (uint256);

  /**
     * @dev Sets the royalty percentage set for an Nafter token
     * Requirements:

     * - `_percentage` must be <= 100.
     * - only the owner of this contract or the creator can call this method.
     * @param _tokenId uint256 token ID.
     * @param _percentage uint8 wei royalty fee.
     */
  function setPercentageForTokenRoyalty(uint256 _tokenId, uint8 _percentage) external returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface INafterMarketAuction {
  /**
   * @dev Set the token for sale. The owner of the token must be the sender and have the marketplace approved.
   * @param _tokenId uint256 ID of the token
   * @param _amount uint256 wei value that the item is for sale
   * @param _owner address of the token owner
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setSalePrice(
    uint256 _tokenId,
    uint256 _amount,
    address _owner,
    uint8 _paymentMode
  ) external;

  /**
   * @dev set
   * @param _bidAmount uint256 value in wei to bid.
   * @param _startTime end time of bid
   * @param _endTime end time of bid
   * @param _owner address of the token owner
   * @param _tokenId uint256 ID of the token
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function setInitialBidPriceWithRange(
    uint256 _bidAmount,
    uint256 _startTime,
    uint256 _endTime,
    address _owner,
    uint256 _tokenId,
    uint8 _paymentMode
  ) external;

  /**
   * @dev has active bid
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function hasTokenActiveBid(uint256 _tokenId, address _owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @dev Interface for interacting with the Nafter contract that holds Nafter beta tokens.
 */
interface INafter {
  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function creatorOfToken(uint256 _tokenId) external view returns (address payable);

  /**
   * @dev Gets the Service Fee
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function getServiceFee(uint256 _tokenId) external view returns (uint8);

  /**
   * @dev Gets the price type
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   * @return get the price type
   */
  function getPriceType(uint256 _tokenId, address _owner) external view returns (uint8);

  /**
   * @dev update price only from auction.
   * @param _price price of the token
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setPrice(
    uint256 _price,
    uint256 _tokenId,
    address _owner
  ) external;

  /**
   * @dev update bids only from auction.
   * @param _bid bid Amount
   * @param _bidder bidder address
   * @param _tokenId uint256 id of the token.
   * @param _owner address of the token owner
   */
  function setBid(
    uint256 _bid,
    address _bidder,
    uint256 _tokenId,
    address _owner
  ) external;

  /**
   * @dev remove token from sale
   * @param _tokenId uint256 id of the token.
   * @param _owner owner of the token
   */
  function removeFromSale(uint256 _tokenId, address _owner) external;

  /**
   * @dev get tokenIds length
   */
  function getTokenIdsLength() external view returns (uint256);

  /**
   * @dev get token Id
   * @param _index uint256 index
   */
  function getTokenId(uint256 _index) external view returns (uint256);

  /**
   * @dev Gets the owners
   * @param _tokenId uint256 ID of the token
   */
  function getOwners(uint256 _tokenId) external view returns (address[] memory owners);

  /**
   * @dev Gets the is for sale
   * @param _tokenId uint256 ID of the token
   * @param _owner address of the token owner
   */
  function getIsForSale(uint256 _tokenId, address _owner) external view returns (bool);

  // function getTokenInfo(uint256 _tokenId)
  //       external
  //       view
  //       returns (
  //           address,
  //           uint256,
  //           address[] memory,
  //           uint8,
  //           uint256
  // );
  /**
   * @dev add token and set the price.
   * @param _price price of the item.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _tokenId uint256 ID of the token.
   * @param _creator address of the creator
   * @param _minter address of minter
   */
  function addNewTokenAndSetThePriceWithIdAndMinter(
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _tokenId,
    address _creator,
    address _minter
  ) external;

  /**
   * @dev redeem to add a new token.
   * @param _creator address of the creator of the token.
   * @param _tokenAmount total token amount available
   * @param _isForSale if is for sale
   * @param _price price of the token, 0 is for not set the price.
   * @param _priceType 0 is for fixed, 1 is for Auction Time bound, 2 is for Auction Infinite
   * @param _royaltyPercentage royalty percentage of creator
   * @param _startTime start time of bid, pass 0 of _priceType is not 1
   * @param _endTime end time of bid, pass 0 of _priceType is not 1
   * @param _tokenId uint256 token id
   * @param _paymentMode 0 for ETH/BNB, 1 for NAFT
   */
  function verify(
    address _creator,
    uint256 _tokenAmount,
    bool _isForSale,
    uint256 _price,
    uint8 _priceType,
    uint8 _royaltyPercentage,
    uint256 _startTime,
    uint256 _endTime,
    uint256 _tokenId,
    uint8 _paymentMode,
    bytes calldata _signature
  ) external view;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title IMarketplaceSettings Settings governing a marketplace.
 */
interface IMarketplaceSettings {
  /////////////////////////////////////////////////////////////////////////
  // Marketplace Min and Max Values
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Get the max value to be used with the marketplace.
   * @return uint256 wei value.
   */
  function getMarketplaceMaxValue() external view returns (uint256);

  /**
   * @dev Get the max value to be used with the marketplace.
   * @return uint256 wei value.
   */
  function getMarketplaceMinValue() external view returns (uint256);

  /////////////////////////////////////////////////////////////////////////
  // Marketplace Fee
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Get the marketplace fee percentage.
   * @return uint8 wei fee.
   */
  function getMarketplaceFeePercentage() external view returns (uint8);

  /**
   * @dev Utility function for calculating the marketplace fee for given amount of wei.
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculateMarketplaceFee(uint256 _amount) external view returns (uint256);

  /////////////////////////////////////////////////////////////////////////
  // Primary Sale Fee
  /////////////////////////////////////////////////////////////////////////
  /**
   * @dev Get the primary sale fee percentage for a specific ERC1155 contract.
   * @return uint8 wei primary sale fee.
   */
  function getERC1155ContractPrimarySaleFeePercentage() external view returns (uint8);

  /**
   * @dev Utility function for calculating the primary sale fee for given amount of wei
   * @param _amount uint256 wei amount.
   * @return uint256 wei fee.
   */
  function calculatePrimarySaleFee(uint256 _amount) external view returns (uint256);

  /**
   * @dev Check whether the ERC1155 token has sold at least once.
   * @param _tokenId uint256 token ID.
   * @return bool of whether the token has sold.
   */
  function hasTokenSold(uint256 _tokenId) external view returns (bool);

  /**
     * @dev Mark a token as sold.

     * Requirements:
     *
     * - `_contractAddress` cannot be the zero address.

     * @param _tokenId uint256 token ID.
     * @param _hasSold bool of whether the token should be marked sold or not.
     */
  function markERC1155Token(uint256 _tokenId, bool _hasSold) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title IERC1155 Non-Fungible Token Creator basic interface
 */
interface IERC1155TokenCreator {
  /**
   * @dev Gets the creator of the token
   * @param _tokenId uint256 ID of the token
   * @return address of the creator
   */
  function tokenCreator(uint256 _tokenId) external view returns (address payable);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
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

import "../../access/OwnableUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @title Escrow
 * @dev Base escrow contract, holds funds designated for a payee until they
 * withdraw them.
 *
 * Intended usage: This contract (and derived escrow contracts) should be a
 * standalone contract, that only interacts with the contract that instantiated
 * it. That way, it is guaranteed that all Ether will be handled according to
 * the `Escrow` rules, and there is no need to check for payable functions or
 * transfers in the inheritance tree. The contract that uses the escrow as its
 * payment method should be its owner, and provide public methods redirecting
 * to the escrow's deposit and withdraw.
 */
contract EscrowUpgradeable is Initializable, OwnableUpgradeable {
    function initialize() public virtual initializer {
        __Escrow_init();
    }
    function __Escrow_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __Escrow_init_unchained();
    }

    function __Escrow_init_unchained() internal initializer {
    }
    using AddressUpgradeable for address payable;

    event Deposited(address indexed payee, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    mapping(address => uint256) private _deposits;

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     */
    function deposit(address payee) public payable virtual onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee] += amount;
        emit Deposited(payee, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     */
    function withdraw(address payable payee) public virtual onlyOwner {
        uint256 payment = _deposits[payee];

        _deposits[payee] = 0;

        payee.sendValue(payment);

        emit Withdrawn(payee, payment);
    }
    uint256[49] private __gap;
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

pragma solidity ^0.8.0;

import "../utils/escrow/EscrowUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Simple implementation of a
 * https://consensys.github.io/smart-contract-best-practices/recommendations/#favor-pull-over-push-for-external-calls[pull-payment]
 * strategy, where the paying contract doesn't interact directly with the
 * receiver account, which must withdraw its payments itself.
 *
 * Pull-payments are often considered the best practice when it comes to sending
 * Ether, security-wise. It prevents recipients from blocking execution, and
 * eliminates reentrancy concerns.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 *
 * To use, derive from the `PullPayment` contract, and use {_asyncTransfer}
 * instead of Solidity's `transfer` function. Payees can query their due
 * payments with {payments}, and retrieve them with {withdrawPayments}.
 */
abstract contract PullPaymentUpgradeable is Initializable {
    EscrowUpgradeable private _escrow;

    function __PullPayment_init() internal initializer {
        __PullPayment_init_unchained();
    }

    function __PullPayment_init_unchained() internal initializer {
        _escrow = new EscrowUpgradeable();
        _escrow.initialize();
    }

    /**
     * @dev Withdraw accumulated payments, forwarding all gas to the recipient.
     *
     * Note that _any_ account can call this function, not just the `payee`.
     * This means that contracts unaware of the `PullPayment` protocol can still
     * receive funds this way, by having a separate account call
     * {withdrawPayments}.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee Whose payments will be withdrawn.
     */
    function withdrawPayments(address payable payee) public virtual {
        _escrow.withdraw(payee);
    }

    /**
     * @dev Returns the payments owed to an address.
     * @param dest The creditor's address.
     */
    function payments(address dest) public view returns (uint256) {
        return _escrow.depositsOf(dest);
    }

    /**
     * @dev Called by the payer to store the sent amount as credit to be pulled.
     * Funds sent in this way are stored in an intermediate {Escrow} contract, so
     * there is no danger of them being spent before withdrawal.
     *
     * @param dest The destination address of the funds.
     * @param amount The amount to transfer.
     */
    function _asyncTransfer(address dest, uint256 amount) internal virtual {
        _escrow.deposit{value: amount}(dest);
    }
    uint256[50] private __gap;
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

