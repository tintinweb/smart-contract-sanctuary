// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "./INEFTiLicense.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./INEFTiMultiTokens.sol";
import "./INEFTiMPFeeCalcExt.sol";
import "./SafeERC20.sol";
import "./NEFTiMPStorages.sol";

/** a2461f9f */
contract NEFTiMarketplace is NEFTiMPStorages, ReentrancyGuard, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  bytes32 public version = keccak256("1.10.55");

  address internal NEFTi20;
  address internal NEFTiMPFeeCalcExt;
  address internal NEFTiMT;
  address private NEFTiReceivable;
  address private NEFTiLegalInfo;

  event UpdateExternalRelationship(uint8 extType, address extTarget);
  event UpdateReceivableTo(address NEFTiAccount);

  event Sale(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    uint256 price,
    uint256 amount,
    uint8 saleMethod,
    address indexed seller,
    bool[4] states,
    //+-->  bool isPostPaid;
    //+-->  bool isNegotiable;
    //+-->  bool isAuction;
    //+-->  bool isContract;
    uint256[2] saleDate,
    uint8 status
  );

  event Negotiate(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 price,
    address indexed negotiator,
    uint256 negoDate,
    uint8 status
  );
  event NegotiationCanceled(uint256 _sid, address _negotiator);
  event Bid(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    uint256 amount,
    uint256 price,
    address indexed bidder,
    uint256 bidDate,
    uint8 status
  );
  event BidCanceled(uint256 _sid, address _negotiator);
  event CancelSale(
    uint256 indexed saleId,
    uint256 indexed tokenId,
    address indexed seller,
    uint8 status
  );
  event Purchase(
    uint256 indexed purchaseId,
    uint256 indexed saleId,
    uint256 indexed tokenId,
    uint256 price,
    uint256 amount,
    uint8 saleMethod,
    address seller,
    bool[4] states,
    //+-->  bool isPostPaid;
    //+-->  bool isNegotiable;
    //+-->  bool isAuction;
    //+-->  bool isContract;
    uint8 status
  );
  event Suspended(
    uint256 _sid,
    uint256 _tokenId,
    address _seller,
    bool _suspend
  );
  event Delisted(uint256 _sid, uint256 _tokenId, address _seller);

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~~~~~~~ LISTING ~~~~~~~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** 31262f27
   ** @dev Proceed Listing item into Marketplace
   ** @param _from         Owner of the item
   ** @param _id           Token ID of the NEFTiMultiToken
   ** @param _amount       Amount of the item
   ** @param _price        Price of the item
   ** @param _saleMethod   Selling method
   **/
  function _sellToken(
    uint256 _id,
    uint256 _amount,
    uint256 _price,
    SaleMethods _saleMethod
  ) internal {
    uint256 listingFee = (
      SaleMethods(_saleMethod) == SaleMethods.DIRECT
        ? INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
          uint8(FeeTypes.DirectListingFee),
          _price,
          _amount
        )
        : INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
          uint8(FeeTypes.AuctionListingFee),
          _price,
          _amount
        )
    );
    if (listingFee > 0) {
      require(
        IERC20(NEFTi20).balanceOf(msg.sender) >= listingFee,
        "ENEFTiMP.01.INSUFFICIENT_NEFTi"
      ); // Not enough NFT balance for listing
      IERC20(NEFTi20).safeTransferFrom(msg.sender, address(this), listingFee);
    }
    INEFTiMultiTokens(NEFTiMT).safeTransferFrom(
      msg.sender,
      address(this),
      _id,
      _amount,
      ""
    );
  }

  /**
   ** 6f980d6a
   ** @dev Listing NEFTiMultiTokens (MT) into the Marketplace (MP)
   ** @param _sid          Input Sale ID (client-side)
   ** @param _tokenId      Token ID of the NEFTiMultiToken
   ** @param _price        Price of the item
   ** @param _amount       Amount of the item
   ** @param _saleMethod   Selling method
   ** @param _states       States in array
   ** @param _saleDate     Listing date for sale
   **/
  function txSaleItems(
    uint256 _sid,
    uint256 _tokenId,
    uint256 _price,
    uint256 _amount,
    uint8 _saleMethod,
    bool[4] memory _states,
    //+----->  bool _isPostPaid,
    //+----->  bool _isNegotiable,
    //+----->  bool _isAuction,
    //+----->  bool _isContract,
    uint256[2] memory _saleDate
  ) public nonReentrant {
    require(_saleMethod < 0x02, "ENEFTiMP.02.INVALID_SALE_METHOD"); // Unknown Sale Method!
    require(_saleDate[0] >= block.timestamp, "ENEFTiMP.03.TIME_BEHIND_CURRENT"); // Time for sale is behind current time!
    require(
      INEFTiMultiTokens(NEFTiMT).balanceOf(msg.sender, _tokenId) > 0,
      "ENEFTiMP.04.INSUFFICIENT_TOKEN_ID"
    ); // Not enough current token id balance for listing!
    require(_amount > 0, "ENEFTiMP.05.ZERO_AMOUNT"); // Zero amount is not applicable for listing!

    _poolSales[msg.sender][_tokenId] += _amount;
    // if ((_selling[_sid].amount == 0) && (_selling[_sid].amount == 0)) {
    if (_selling[_sid].amount == 0) {
      // _saleItems.push(_sid);
      _itemsOnSaleItems[msg.sender].push(_sid);
    }

    uint256[3] memory values = [uint256(0), uint256(0), uint256(0)];
    _selling[_sid] = SaleItems(
      _tokenId,
      _price,
      _amount,
      msg.sender,
      _states,
      //+--> _states[0] :  _isPostPaid
      //+--> _states[1] :  _isNegotiable
      //+--> _states[2] :  _isAuction
      //+--> _states[3] :  _isContract
      _saleDate,
      values,
      //+--> values[0]  :  _valContract   0
      //+--> values[1]  :  _highBid       0
      //+--> values[2]  :  _bidMultiplier 0
      address(0),
      SaleStatus.OPEN
    );
    _sellToken(_tokenId, _amount, _price, SaleMethods(_saleMethod));

    emit Sale(
      _sid,
      _tokenId,
      _price,
      _amount,
      _saleMethod,
      msg.sender,
      [_states[0], _states[1], _states[2], false],
      _saleDate,
      uint8(SaleStatus.OPEN)
    );
  }

  /**
   ** 96fd6550
   ** @dev Add more amount to Sale item
   ** @param _sid      Input Sale ID (client-side)
   ** @param _tokenId  Token ID of the NEFTiMultiToken
   ** @param _amount   Amount of the item
   **/
  function txAddItemForSale(
    uint256 _sid,
    uint256 _tokenId,
    uint256 _amount
  ) public nonReentrant {
    require(
      (_sid > 0) && (_tokenId > 0) && (_amount > 0),
      "ENEFTiMP.06.INVALID_PARAMS"
    );
    require(
      _selling[_sid].seller == msg.sender,
      "ENEFTiMP.07.FORBIDDEN_EXECUTOR"
    ); // Executor have no rights to the item!
    require(!_selling[_sid].states[2], "ENEFTiMP.08.INVALID_STATE_OF_AUCTION"); // unsupported adding item to Auction

    _selling[_sid].amount += _amount;
    _poolSales[msg.sender][_tokenId] += _amount;

    _sellToken(_tokenId, _amount, _selling[_sid].price, SaleMethods(0x00));

    emit Sale(
      _sid,
      _tokenId,
      _selling[_sid].price,
      _selling[_sid].amount,
      uint8(0),
      msg.sender,
      _selling[_sid].states,
      _selling[_sid].saleDate,
      uint8(SaleStatus.OPEN)
    );
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~~~~~~ UTILITIES ~~~~~~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** ec980dea
   ** @dev Get item information by Sale ID
   ** @param _sid  Sale ID
   ** @return      Item information (SaleItems)
   **/
  function getSaleItemsInfo(uint256 _sid)
    public
    view
    returns (
      uint256[3] memory info,
      //+----->  uint256 tokenId,
      //+----->  uint256 price,
      //+----->  uint256 amount,
      address seller,
      bool[4] memory states,
      //+----->  bool isPostPaid,
      //+----->  bool isNegotiable,
      //+----->  bool isAuction,
      //+----->  bool isContract,
      uint256[2] memory saleDate,
      uint256[3] memory values,
      //+----->  uint256 valContract,
      //+----->  uint256 highBid,
      //+----->  uint256 bidMultiplier,
      address buyer,
      uint8 status
    )
  {
    return (
      [_selling[_sid].tokenId, _selling[_sid].price, _selling[_sid].amount],
      _selling[_sid].seller,
      _selling[_sid].states,
      //+----->  .isPostPaid,
      //+----->  .isNegotiable,
      //+----->  .isAuction,
      //+----->  .isContract,
      _selling[_sid].saleDate,
      _selling[_sid].values,
      //+----->  .valContract,
      //+----->  .highBid,
      //+----->  .bidMultiplier,
      _selling[_sid].buyer,
      uint8(_selling[_sid].status)
    );
  }

  /**
   ** 1626da32
   ** @dev Get sale item amount by seller address and token ID
   ** @param _sid      Sale ID
   ** @param _tokenId  Token ID of the NEFTiMultiToken
   ** @return Balance on Sale amount of current token id
   **/
  function balanceOf(address _seller, uint256 _tokenId)
    public
    view
    returns (uint256)
  {
    return (_poolSales[_seller][_tokenId]);
  }

  /**
   ** 90267f9c
   ** @dev Get sale items by seller address
   ** @param _seller   Address of the seller
   ** @return Array of Sale item IDs (bytes32)
   **/
  function itemsOf(address _seller)
    public
    view
    returns (uint256[] memory items)
  {
    return _itemsOnSaleItems[_seller];
  }

  /**
   ** e894a07a
   ** @dev Cancel Negotiation
   ** @param _sid          Sale ID
   ** @param _negotiator   Negotiator address
   **/
  function cancelNegotiation(uint256 _sid, address _negotiator)
    public
    nonReentrant
  {
    require(
      (_sid > 0) && (_negotiator != address(0)),
      "ENEFTiMP.09.INVALID_PARAMS"
    );
    require((msg.sender).balance > 0, "ENEFTiMP.10.ISSUE_TO_PAY_GAS");

    bool isNegotiator = false;
    bool isSeller = (msg.sender == _selling[_sid].seller);
    address negotiator = address(0);
    NegotiateStatus cancelStatus;
    uint256 cancellationFee = 0;

    if (isSeller || msg.sender == owner()) {
      cancelStatus = NegotiateStatus.REJECTED;
      negotiator = _negotiator;
    } else {
      for (uint256 i = 0; _negotiators[_sid].length > i; i++) {
        if (_negotiators[_sid][i] == msg.sender) {
          isNegotiator = true;
          negotiator = msg.sender;
          break;
        }
      }
      require(isNegotiator, "ENEFTiMP.11.INVALID_EXECUTOR"); // Only seller or negotiator can cancel the negotiation!
      cancelStatus = NegotiateStatus.CANCELED;
    }

    for (uint256 i = 0; _negotiators[_sid].length > i; i++) {
      if ((negotiator != address(0)) && (_negotiators[_sid][i] == negotiator)) {
        if (isNegotiator && (cancelStatus == NegotiateStatus.CANCELED)) {
          cancellationFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
            uint8(FeeTypes.DirectNegotiateCancellationFee),
            _poolNegotiating[_sid][msg.sender].value,
            1
          );

          require(
            IERC20(NEFTi20).balanceOf(msg.sender) >= cancellationFee,
            "ENEFTiMP.12.INSUFFICIENT_NEFTi"
          ); // Not enough current token balance for cancellation!
          IERC20(NEFTi20).safeTransferFrom(
            address(this),
            NEFTiReceivable,
            cancellationFee
          );
        }
        IERC20(NEFTi20).safeTransferFrom(
          address(this),
          _negotiators[_sid][i],
          _poolNegotiating[_sid][negotiator].value.sub(cancellationFee)
        );

        _poolNegotiating[_sid][negotiator].status = cancelStatus;
        _negotiators[_sid][i] = _negotiators[_sid][
          _negotiators[_sid].length - 1
        ];
        // remove last index
        _negotiators[_sid].pop();
        break;
      }
    }

    emit NegotiationCanceled(_sid, negotiator);
  }

  /**
   ** 27106aa4
   ** @dev Cancel Bid's Auction
   ** @param _sid      Sale ID
   ** @param _bidder   Bidder address
   **/
  function cancelAuctionBid(uint256 _sid, address _bidder) public nonReentrant {
    bool isBidder = false;
    bool isAdmin = (msg.sender == owner());
    address bidder = address(0);

    if (isAdmin) {
      bidder = _bidder;
    } else {
      for (uint256 i = 0; _bidders[_sid].length > i; i++) {
        if (_bidders[_sid][i] == msg.sender) {
          isBidder = true;
          bidder = msg.sender;
          break;
        }
      }
      require(isBidder, "ENEFTiMP.13.INVALID_EXECUTOR"); // Only seller or bidder can cancel the negotiation!
    }

    for (uint256 i = 0; _negotiators[_sid].length > i; i++) {
      if (_bidders[_sid][i] == bidder) {
        IERC20(NEFTi20).safeTransferFrom(
          address(this),
          _bidders[_sid][i], // bidder
          _poolBidding[_sid][bidder]
        );
        _poolBidding[_sid][bidder] = 0;

        _bidders[_sid][i] = _bidders[_sid][_bidders[_sid].length - 1];
        // remove last index
        _bidders[_sid].pop();
      }
    }

    emit BidCanceled(_sid, bidder);
  }

  /**
   ** 5447d080
   ** @dev Get listing cancellation fee
   ** @param _sid  Sale ID
   ** @return Value as fee
   **/
  function getListingCancellationFee(uint256 _sid)
    public
    view
    returns (uint256)
  {
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.14.ITEM_NOT_ONSALE"
    ); // Only open sale can be canceled!

    uint8 cancelFor = (
      (!_selling[_sid].states[2] && !_selling[_sid].states[3])
        ? 0x02 // FeeTypes.DirectListingCancellationFee
        : (
          (_selling[_sid].states[2] && !_selling[_sid].states[3])
            ? 0x07 // FeeTypes.AuctionListingCancellationFee
            : 0x0c // FeeTypes.ContractListingCancellationFee
        )
    );
    uint256 cancelFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
      cancelFor,
      _selling[_sid].price,
      _selling[_sid].amount
    );
    return cancelFee;
  }

  /**
   ** e40417c9
   ** @dev Cancel item on sale
   ** @param _sid  Sale ID
   **/
  function cancelSaleItem(uint256 _sid) public nonReentrant {
    require(_sid > 0, "ENEFTiMP.15.INVALID_SALEID"); // Unknown Sale ID
    address seller = _selling[_sid].seller;
    require(
      msg.sender == seller || msg.sender == owner(),
      "ENEFTiMP.16.INVALID_EXECUTOR"
    ); // Only seller can cancel the sale!
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.17.NOT_FOR_SALE"
    ); // Only open sale can be canceled!
    // require(msg.sender.balance > 0, "Cancellation cost gas fee");

    address item_seller = _selling[_sid].seller;
    uint256 item_tokenId = _selling[_sid].tokenId;
    uint256 item_amount = _selling[_sid].amount;

    // when it's an Auction
    if (_selling[_sid].states[2]) {
      if (_bidders[_sid].length > 0) {
        require(msg.sender == owner(), "ENEFTiMP.18.FORBIDDEN_ONLY_ADMIN"); // Only Admin able to cancel auction when bids are placed
        for (uint256 i = 0; i < _bidders[_sid].length; i++) {
          // cancellation index should stay on [0]!
          if (_bidders[_sid][0] != address(0)) {
            cancelAuctionBid(_sid, _bidders[_sid][0]);
          }
        }
      }
    }
    // when it's a Direct Sale
    else if (!_selling[_sid].states[2]) {
      if (_negotiators[_sid].length > 0) {
        for (uint256 i = 0; i < _negotiators[_sid].length; i++) {
          // cancellation index should stay on [0]!
          if (_negotiators[_sid][0] != address(0)) {
            cancelNegotiation(_sid, _negotiators[_sid][0]);
          }
        }
      }
    }

    if (_itemsOnSaleItems[seller].length > 0) {
      for (uint256 i = 0; i < _itemsOnSaleItems[seller].length; i++) {
        if (_itemsOnSaleItems[seller][0] != _sid) {
          _itemsOnSaleItems[seller][i] = _itemsOnSaleItems[seller][
            _itemsOnSaleItems[seller].length - 1
          ];
          // remove last index
          // delete _itemsOnSaleItems[seller][_itemsOnSaleItems[seller].length-1];
          _itemsOnSaleItems[seller].pop();
        }
      }
    }

    _poolSales[seller][_selling[_sid].tokenId] -= _selling[_sid].amount;
    _selling[_sid].buyer = address(0);
    _selling[_sid].status = SaleStatus.CANCELED;

    INEFTiMultiTokens(NEFTiMT).safeTransferFrom(
      address(this),
      item_seller,
      item_tokenId,
      item_amount,
      ""
    );

    emit CancelSale(
      _sid,
      item_tokenId,
      item_seller,
      uint8(SaleStatus.CANCELED)
    );
  }

  /**
   ** b78c56dd
   ** @dev Get list of negotiators
   ** @param _sid  Sale ID
   ** @return List of negotiator addresses
   **/
  function getNegotiators(uint256 _sid) public view returns (address[] memory) {
    return _negotiators[_sid];
  }

  /**
   ** b0ec6c52
   ** @dev Get negotiation info
   ** @param _sid          Sale ID
   ** @param _negotiator   Negotiator address
   ** @return (
   **    saleId    - Sale ID
   **    value     - Negotiation value
   **    amount    - Negotiation amount
   **    negoDate  - Negotiation date
   **    status    - Negotiation status
   ** )
   **/
  function getNegotiationInfo(uint256 _sid, address _negotiator)
    public
    view
    returns (
      uint256 saleId,
      uint256 value,
      uint256 amount,
      uint256 negoDate,
      uint8 status
    )
  {
    require(_negotiator != address(0), "ENEFTiMP.19.INVALID_NEGOTIATOR"); // Unknown Negotiator
    return (
      _poolNegotiating[_sid][_negotiator].saleHash,
      _poolNegotiating[_sid][_negotiator].value,
      _poolNegotiating[_sid][_negotiator].amount,
      _poolNegotiating[_sid][_negotiator].negoDate,
      uint8(_poolNegotiating[_sid][_negotiator].status)
    );
  }

  /**
   ** 5a02723f
   ** @dev Get list of bidders
   ** @param _sid  Sale ID
   ** @return List of bidder addresses
   **/
  function getAuctionBidders(uint256 _sid)
    public
    view
    returns (address[] memory)
  {
    return _bidders[_sid];
  }

  /**
   ** 12f2a515
   ** @dev Get auction bid value
   ** @param _sid      Sale ID
   ** @param _bidder   Bidder address
   ** @return Bid value
   **/
  function getBidValue(uint256 _sid, address _bidder)
    public
    view
    returns (uint256)
  {
    require(_bidder != address(0), "ENEFTiMP.20.INVALID_BIDDER"); // Unknown Bidder
    return _poolBidding[_sid][_bidder];
  }

  /**
   ** db794cbe
   ** @dev Get highest bid amount
   ** @param _sid  Sale ID
   ** @return (
   **    bidder  - Bidder address
   **    bid     - Bid value
   ** )
   **/
  function getHighestBidValue(uint256 _sid)
    public
    view
    returns (address bidder, uint256 bid)
  {
    return (_selling[_sid].buyer, _selling[_sid].values[1]);
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~ PURCHASING - DIRECT ~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** 7de47861
   ** @dev Buying item directly
   ** @param _sid      Sale ID
   ** @param _pid      Input PurchaseItems ID (client-side)
   ** @param _amount   Amount to buy
   **/
  function txDirectBuy(
    uint256 _sid,
    uint256 _pid,
    uint256 _amount
  ) public nonReentrant {
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.21.NOT_FOR_SALE"
    ); // Item is not for sale!
    require(
      _selling[_sid].saleDate[0] <= block.timestamp,
      "ENEFTiMP.22.ITEM_WAIT_FOR_CONFIRMATION"
    ); // Item is not yet for sale!
    require(
      _selling[_sid].amount >= _amount,
      "ENEFTiMP.23.PURCHASE_AMOUNT_OVERFLOW"
    ); // Not enough tokens for sale!
    require(address(msg.sender).balance > 0, "ENEFTiMP.24.ISSUE_TO_PAY_GAS"); // Not enough BNB to spend for Gas fee!

    uint256 subTotal = _selling[_sid].price * _amount;
    uint256 txFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
      uint8(FeeTypes.DirectTransactionFee),
      subTotal,
      0x01
    );
    require(
      IERC20(NEFTi20).balanceOf(msg.sender) >= subTotal,
      "ENEFTiMP.25.INSUFFICIENT_NEFTi"
    ); // Not enough NFT balance for purchase!

    // transfer NFT20 purchase value to seller
    IERC20(NEFTi20).safeTransferFrom(
      msg.sender,
      _selling[_sid].seller,
      subTotal.sub(txFee)
    );
    // transfer NFT20 fee to owner
    IERC20(NEFTi20).safeTransferFrom(msg.sender, NEFTiReceivable, txFee);
    // then transfer NFT1155 token in return
    INEFTiMultiTokens(NEFTiMT).safeTransferFrom(
      address(this),
      msg.sender,
      _selling[_sid].tokenId,
      _amount,
      ""
    );

    _poolSales[_selling[_sid].seller][_selling[_sid].tokenId] = _selling[_sid]
      .amount
      .sub(_amount);
    _selling[_sid].amount = _selling[_sid].amount.sub(_amount);
    if (_selling[_sid].amount == 0) {
      _selling[_sid].status = SaleStatus.FULFILLED;
    }

    emit Purchase(
      _pid,
      _sid,
      _selling[_sid].tokenId,
      _selling[_sid].price,
      _amount,
      1,
      _selling[_sid].seller,
      [false, false, false, false],
      uint8(PurchaseStatus.FULFILLED)
    );
  }

  /**
   ** 38e8818e
   ** @dev Buyer negotiate an offer
   ** @param _sid      Sale ID
   ** @param _amount   Amount to buy
   ** @param _price    Price per token
   **/
  function txDirectOffering(
    uint256 _sid,
    uint256 _amount,
    uint256 _price
  ) public nonReentrant {
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.26.NOT_FOR_SALE"
    ); // Item is not for sale!
    require(
      _selling[_sid].saleDate[0] <= block.timestamp,
      "ENEFTiMP.27.ITEM_WAIT_FOR_CONFIRMATION"
    ); // Item is not yet for sale!
    require(
      _selling[_sid].amount >= _amount,
      "ENEFTiMP.28.OFFERING_AMOUNT_OVERFLOW"
    ); // Not enough tokens for sale!
    require(address(msg.sender).balance > 0, "ENEFTiMP.29.ISSUE_TO_PAY_GAS"); // Not enough BNB to spend for Gas fee!
    require(_selling[_sid].states[1], "ENEFTiMP.30.NEGOTIATION_DISABLED"); // This item is not for negotiation!

    uint256 subTotal = (_price * _amount);
    uint256 txFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
      uint8(FeeTypes.DirectNegotiateFee),
      _price,
      _amount
    );
    require(
      (subTotal + txFee) <= IERC20(NEFTi20).balanceOf(msg.sender),
      "ENEFTiMP.31.INSUFFICIENT_NEFTi"
    ); // Not enough NFT token to place the offer!

    // transfer NFT20 negotiation price to pool
    IERC20(NEFTi20).safeTransferFrom(msg.sender, address(this), subTotal);
    // transfer NFT20 fee to owner
    IERC20(NEFTi20).safeTransferFrom(msg.sender, NEFTiReceivable, txFee);

    if (_poolNegotiating[_sid][msg.sender].value == 0) {
      _negotiators[_sid].push(msg.sender);
    }

    uint256 prevPrice = (
      _poolNegotiating[_sid][msg.sender].amount == 0
        ? 0
        : _poolNegotiating[_sid][msg.sender].value.div(
          _poolNegotiating[_sid][msg.sender].amount
        )
    );
    uint256 totalAmount = _poolNegotiating[_sid][msg.sender].amount.add(
      _amount
    );

    _poolNegotiating[_sid][msg.sender] = Negotiating(
      _sid,
      msg.sender,
      (prevPrice.add(_price) * totalAmount),
      totalAmount,
      block.timestamp,
      NegotiateStatus.OPEN
    );

    emit Negotiate(
      _sid,
      _selling[_sid].tokenId,
      _amount,
      _price,
      msg.sender,
      block.timestamp,
      uint8(NegotiateStatus.OPEN)
    );
  }

  /**
   ** 9bf7b83a
   ** @dev Seller accept an offer
   ** @param _sid          Sale ID
   ** @param _pid          Input PurchaseItems ID (client-side)
   ** @param _negotiator   Selected negotiator address
   **/
  function txAcceptDirectOffering(
    uint256 _sid,
    uint256 _pid,
    address _negotiator
  ) public nonReentrant {
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.32.SALE_HAS_PASSED"
    ); // Item is not for sale anymore!
    require(
      (_selling[_sid].amount > 0) &&
        (_poolSales[msg.sender][_selling[_sid].tokenId] > 0) &&
        (_selling[_sid].amount >= _poolNegotiating[_sid][_negotiator].amount),
      "ENEFTiMP.33.SALE_AMOUNT_UNDERFLOW"
    ); // Not enough tokens at pool for sale!
    require(
      _poolNegotiating[_sid][_negotiator].status == NegotiateStatus.OPEN,
      "ENEFTiMP.34.OFFER_HAS_PASSED"
    ); // This negotiation is not available anymore!
    require(
      _poolNegotiating[_sid][_negotiator].amount > 0,
      "ENEFTiMP.35.UNDEFINED_OFFERING_AMOUNT"
    ); // Current negotiation amount was not set!

    uint256 subTotal = _poolNegotiating[_sid][_negotiator].value;
    uint256 txFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
      uint8(FeeTypes.DirectTransactionFee),
      subTotal,
      1
    );

    // transfer NFT20 purchased value to seller - fee
    IERC20(NEFTi20).safeTransfer(_selling[_sid].seller, subTotal.sub(txFee));
    // transfer NFT20 fee to owner
    IERC20(NEFTi20).safeTransfer(NEFTiReceivable, txFee);
    // transfer NFT1155 asset to buyer
    INEFTiMultiTokens(NEFTiMT).safeTransferFrom(
      address(this),
      _negotiator,
      _selling[_sid].tokenId,
      _poolNegotiating[_sid][_negotiator].amount,
      ""
    );

    uint256 updateAmount = _selling[_sid].amount.sub(1);
    _poolSales[msg.sender][_selling[_sid].tokenId] = updateAmount;
    _selling[_sid].amount = updateAmount;

    if (_selling[_sid].amount == 0) {
      _selling[_sid].status = SaleStatus.FULFILLED;
    }

    _poolNegotiating[_sid][_negotiator].status = NegotiateStatus.FULFILLED;

    emit Purchase(
      _pid,
      _sid,
      _selling[_sid].tokenId,
      _poolNegotiating[_sid][_negotiator].value.div(
        _poolNegotiating[_sid][_negotiator].amount
      ), /** price  */
      _poolNegotiating[_sid][_negotiator].amount, /** amount */
      1,
      _selling[_sid].seller,
      [false, false, false, false],
      uint8(PurchaseStatus.FULFILLED)
    );
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~ PURCHASING - AUCTION ~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** 5f212d35
   ** @dev Buyer bid an offer
   ** @param _sid      Sale ID
   ** @param _price    Price to bid
   **/
  function txBid(uint256 _sid, uint256 _price) public nonReentrant {
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.36.NOT_FOR_AUCTION"
    ); // Item is not for auction!
    require(
      _selling[_sid].saleDate[0] <= block.timestamp,
      "ENEFTiMP.37.ITEM_WAIT_FOR_CONFIRMATION"
    ); // Item is not yet for sale!

    uint256 txFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
      uint8(FeeTypes.AuctionBiddingFee),
      _price,
      1
    );
    require(
      (_price + txFee) <= IERC20(NEFTi20).balanceOf(msg.sender),
      "ENEFTiMP.38.INSUFFICIENT_NEFTi"
    ); // Not enough NFT token to bid in auction!
    require(address(msg.sender).balance > 0, "ENEFTiMP.39.ISSUE_TO_PAY_GAS"); // Not enough BNB to spend for Gas fee!

    // when Auction
    if (_selling[_sid].states[2]) {
      require(
        _price >= _selling[_sid].values[2],
        "ENEFTiMP.40.BID_UNDERFLOW_THE_MULTIPLIER"
      ); // Bid value less than required multiplier!

      uint256 _totalBids = _poolBidding[_sid][msg.sender].add(_price);
      require(
        (_selling[_sid].values[1] + _selling[_sid].values[1]) < _totalBids,
        "ENEFTiMP.41.BID_UNDERFLOW_THE_HIGHEST"
      ); // Price is too lower than highest bid!

      // send NFT20 to auction pool
      IERC20(NEFTi20).safeTransferFrom(msg.sender, address(this), _price);
      // send fee NFT20 to owner
      IERC20(NEFTi20).safeTransferFrom(msg.sender, NEFTiReceivable, txFee);

      if (_poolBidding[_sid][msg.sender] == 0) {
        _bidders[_sid].push(msg.sender);
      }

      // if exist and higher than the highest bid, update to auction bidding pool
      _poolBidding[_sid][msg.sender] = _totalBids;

      // update highest bidder price and address
      _selling[_sid].values[1] = _totalBids;
      _selling[_sid].buyer = msg.sender;

      _poolBidding[_sid][msg.sender] = _totalBids;

      emit Bid(
        _sid,
        _selling[_sid].tokenId,
        _selling[_sid].amount,
        _totalBids,
        msg.sender,
        block.timestamp,
        uint8(NegotiateStatus.OPEN)
      );
    }
    // This item is not for auction!
    else {
      revert("ENEFTiMP.42.ITEM_NOT_FOR_AUCTION");
    }
  }

  /**
   ** da064fc0
   ** @dev Buyer accept an offer of highest bid
   ** @param _sid  Sale ID
   ** @param _pid  Input PurchaseItems ID (client-side)
   **/
  function txAcceptAuctionBid(uint256 _sid, uint256 _pid) public nonReentrant {
    require(
      _selling[_sid].status == SaleStatus.OPEN,
      "ENEFTiMP.43.AUCTION_HAS_PASSED"
    ); // Item is not for auction anymore!
    require(
      (_selling[_sid].amount > 0) &&
        (_poolSales[msg.sender][_selling[_sid].tokenId] > 0),
      "ENEFTiMP.44.BID_AMOUNT_OVERFLOW"
    ); // Not enough tokens at pool for sale!

    require(_selling[_sid].buyer != address(0), "ENEFTiMP.45.INVALID_BIDDER"); // Current bidder address was not set!
    require(
      _poolBidding[_sid][_selling[_sid].buyer] > 0,
      "ENEFTiMP.46.INVALID_BID_VALUE"
    ); // Current bid value was not available!
    require(_selling[_sid].values[1] > 0, "ENEFTiMP.47.UNDEFINED_HIGHEST_BID"); // Highest bid value was not set!

    uint256 txFee = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
      uint8(FeeTypes.AuctionTransactionFee),
      _selling[_sid].values[1],
      0x01
    );

    uint256 subTotal = _selling[_sid].values[1];

    // transfer NFT20 purchased value to seller - fee
    IERC20(NEFTi20).safeTransferFrom(
      address(this),
      _selling[_sid].seller,
      subTotal.sub(txFee)
    );
    // transfer NFT20 fee to owner
    IERC20(NEFTi20).safeTransferFrom(address(this), NEFTiReceivable, txFee);
    // transfer NFT1155 asset to buyer
    INEFTiMultiTokens(NEFTiMT).safeTransferFrom(
      address(this),
      _selling[_sid].buyer,
      _selling[_sid].tokenId,
      _selling[_sid].amount,
      ""
    );

    uint256 updateAmount = _selling[_sid].amount.sub(1);
    _poolSales[msg.sender][_selling[_sid].tokenId] = updateAmount;
    _selling[_sid].amount = updateAmount;
    if (_selling[_sid].amount == 0) {
      _selling[_sid].status = SaleStatus.FULFILLED;
    }
    _poolBidding[_sid][_selling[_sid].buyer] = 0;

    emit Purchase(
      _pid,
      _sid,
      _selling[_sid].tokenId,
      /* price  */
      _poolBidding[_sid][_selling[_sid].buyer].div(_selling[_sid].amount),
      /* amount */
      _selling[_sid].amount,
      1,
      _selling[_sid].seller,
      [false, false, true, false],
      uint8(PurchaseStatus.FULFILLED)
    );
  }

  /*════════════oooooOooooo═════════════╗
    ║█~~~~~~~~~~ MISCELLANEOUS ~~~~~~~~~~█║
    ╚════════════════════════════════════*/

  /**
   ** f3c2e296
   ** @dev Caller is refers to a smart contract
   ** @return The acceptance magic value
   **/
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return
      bytes4(
        keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")
      );
  }

  /**
   ** 1cb8a750
   ** @dev Default Payment info
   ** @return (
   **    tokenContract - ERC20 contract address
   **    decimals      - ERC20 decimals
   **    priceUSD      - Equivalent value in USD
   ** )
   **/
  function defaultPayment()
    public
    view
    returns (
      address tokenContract,
      uint8 decimals,
      uint256 priceUSD
    )
  {
    (tokenContract, decimals, priceUSD) = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt)
      .defaultPayment();
  }

  /**
   ** c1f7235a
   ** @dev Get Calculated Fees
   ** @param _price    Item price
   ** @param _amount   Amount of item
   ** @return List of calculated fees
   ** +--->   uint256 DirectListingFee,
   ** +--->   uint256 DirectListingCancellationFee,
   ** +--->   uint256 DirectNegotiateFee,
   ** +--->   uint256 DirectNegotiateCancellationFee,
   ** +--->   uint256 DirectTransactionFee,
   ** +--->   uint256 AuctionListingFee,
   ** +--->   uint256 AuctionListingCancellationFee,
   ** +--->   uint256 AuctionBiddingFee,
   ** +--->   uint256 AuctionBiddingCancellationFee,
   ** +--->   uint256 AuctionTransactionFee
   **/
  function feesOf(uint256 _price, uint256 _amount)
    public
    view
    returns (uint256[11] memory fees)
  {
    // uint256[11] memory fees;
    fees[0] = 0;
    for (uint8 i = 1; i < 11; i++) {
      fees[i] = INEFTiMPFeeCalcExt(NEFTiMPFeeCalcExt).calcFeeOf(
        i,
        _price,
        _amount
      );
    }
    // return fees;
  }

  /**
   ** 2612ddc0
   ** @dev Update External Relationship
   ** @param _extType   External type
   ** @param _extTarget External address
   **/
  function updateExtRelationship(uint8 _extType, address _extTarget)
    public
    onlyOwner
  {
    if (ExternalRelationship(_extType) == ExternalRelationship.NEFTi20) {
      NEFTi20 = _extTarget;
    } else if (
      ExternalRelationship(_extType) == ExternalRelationship.NEFTiMultiTokens
    ) {
      NEFTiMT = _extTarget;
    } else if (
      ExternalRelationship(_extType) == ExternalRelationship.NEFTiMPFeeCalcExt
    ) {
      NEFTiMPFeeCalcExt = _extTarget;
    } else {
      revert("ENEFTiMP.48.INVALID_EXTERNAL_RELATIONSHIP");
    } // Invalid external relationship type
    emit UpdateExternalRelationship(_extType, _extTarget);
  }

  /**
   ** 4b28fc21
   ** @dev Update Receivable account
   ** @param _NEFTiAccount Account address
   **/
  function updateReceivable(address _NEFTiAccount) public onlyOwner {
    require(_NEFTiAccount != address(0), "ENEFTiMP.49.INVALID_NEFTi_ACCOUNT");
    NEFTiReceivable = _NEFTiAccount;
    emit UpdateReceivableTo(_NEFTiAccount);
  }

  /**
   ** 220a8b22
   ** @dev Send Asset
   ** @param _to       Receiver address
   ** @param _tokenId  Asset ID
   ** @param _amount   Asset amount
   **/
  function sendAssets(
    address _to,
    uint256 _tokenId,
    uint256 _amount
  ) public nonReentrant onlyOwner {
    require(_amount > 0, "ENEFTiMP.50.INVALID_AMOUNT"); // Amount must be greater than 0
    require(_tokenId > 0, "ENEFTiMP.51.INVALID_TOKEN_ID"); // Token ID must be greater than 0
    INEFTiMultiTokens cNEFTiMT = INEFTiMultiTokens(NEFTiMT);
    require(
      cNEFTiMT.balanceOf(address(this), _tokenId) >= _amount,
      "ENEFTiMP.52.INSUFFICIENT_FOR_TOKEN_ID"
    ); // Insufficient tokens
    cNEFTiMT.safeTransferFrom(address(this), _to, _tokenId, _amount, "");
  }

  /**
   ** 88436dbd
   ** @dev Send Currency
   ** @param _tokenContract    Receiver address
   ** @param _to               Asset ID
   ** @param _amount           Asset amount
   **/
  function sendCurrencies(
    address _tokenContract,
    address _to,
    uint256 _amount
  ) public nonReentrant onlyOwner {
    require(_amount > 0, "ENEFTiMP.53.INVALID_AMOUNT"); // Amount must be greater than 0
    if (_tokenContract != address(0)) {
      IERC20 _ERC20 = IERC20(_tokenContract);
      require(
        _ERC20.balanceOf(address(this)) >= _amount,
        "ENEFTiMP.54.INSUFFICIENT_ERC20"
      ); // Insufficient tokens
      _ERC20.safeTransfer(_to, _amount);
    } else {
      (bool sent, ) = address(this).call{value: _amount}("");
      require(sent, "ENEFTiMP.55.INSUFFICIENT_BALANCE"); // Insufficient Balance
    }
  }

  /**
   ** b6485833
   ** @dev Suspending Sale item
   ** @param _sid          Sale ID
   ** @param _isSuspended  True/False
   **/
  function suspend(uint256 _sid, bool _isSuspended) public onlyOwner {
    require(_sid > 0, "ENEFTiMP.56.INVALID_SALE_ITEM_ID"); // Sale item ID must be greater than 0
    _selling[_sid].status = (
      _isSuspended ? SaleStatus.SUSPENDED : SaleStatus.OPEN
    );
    emit Suspended(
      _sid,
      _selling[_sid].tokenId,
      _selling[_sid].seller,
      _isSuspended
    );
  }

  /**
   ** f7cced22
   ** @dev Delisting Sale item
   ** @param _sid          Sale ID
   **/
  function delist(uint256 _sid) public onlyOwner {
    require(_sid > 0, "ENEFTiMP.57.INVALID_SALE_ITEM_ID"); // Sale item ID must be greater than 0
    INEFTiMultiTokens(NEFTiMT).safeTransferFrom(
      address(this),
      _selling[_sid].seller,
      _selling[_sid].tokenId,
      _selling[_sid].amount,
      ""
    );
    _selling[_sid].status = SaleStatus.DELISTED;
    emit Delisted(_sid, _selling[_sid].tokenId, _selling[_sid].seller);
  }

  /**
   ** 1955f1b8
   ** @dev Show legal info
   ** @return (
   **    string title,
   **    string license,
   **    string version,
   **    string url
   ** )
   **/
  function legalInfo()
    public
    view
    returns (
      string memory _title,
      string memory _license,
      string memory _version,
      string memory _url
    )
  {
    (_title, _license, _version, _url) = INEFTiLicense(NEFTiLegalInfo)
      .legalInfo();
  }

  /**
   ** 31084f3e
   ** @dev Update legal info
   ** @param _newLegalInfo Updated info
   **/
  function updateLicense(address _newLegalInfo) public onlyOwner {
    NEFTiLegalInfo = _newLegalInfo;
  }

  /**
   ** @dev NEFTi Marketplace contract constructor
   ** @params _NEFTi20 - address of ERC20 contract for NFT20
   ** @params _NEFTiMT - address of ERC1155 contract for NFT1155
   ** @params _NEFTiMPFeeCalcExt - address of NEFTi MP Fee Calc Extension contract
   ** @params _NEFTiReceivable - address of NEFTi Receivable contract
   **/
  constructor(
    address _NEFTi20,
    address _NEFTiMT,
    address _NEFTiMPFeeCalcExt,
    address _NEFTiAccount,
    address _NEFTiLegalInfo
  ) {
    NEFTi20 = _NEFTi20;
    NEFTiMT = _NEFTiMT;
    NEFTiMPFeeCalcExt = _NEFTiMPFeeCalcExt;
    NEFTiReceivable = _NEFTiAccount;
    NEFTiLegalInfo = _NEFTiLegalInfo;
  }

  /*════════════════════════════oooooOooooo════════════════════════════╗
    ║█  (!) WARNING  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~█║
    ╚════════════════════════════════════════════════════════════════════╝
    ║  There are no handler in fallback function,                        ║
    ║  If there are any incoming value directly to Smart Contract, will  ║
    ║  considered as generous donation. And Thank you!                   ║
    ╚═══════════════════════════════════════════════════════════════════*/
  receive() external payable /* nonReentrant */
  {

  }

  fallback() external payable /* nonReentrant */
  {

  }
}

/**
 **    █▄░█ █▀▀ █▀▀ ▀█▀ █ █▀█ █▀▀ █▀▄ █ ▄▀█
 **    █░▀█ ██▄ █▀░ ░█░ █ █▀▀ ██▄ █▄▀ █ █▀█
 **    ____________________________________
 **    https://neftipedia.com
 **    [email protected]
 **/