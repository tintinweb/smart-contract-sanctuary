// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./libs/fota/MarketAuth.sol";
import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./interfaces/IGameNFT.sol";
import "./interfaces/ICitizen.sol";

contract MarketPlace is MarketAuth, PausableUpgradeable {
  enum OrderType {
    trading,
    renting
  }
  enum OrderKind {
    hero,
    item,
    land
  }
  enum PaymentType {
    fota,
    usd,
    all
	}
  enum PaymentCurrency {
    fota,
    busd,
    usdt
	}
  struct Order {
    address maker;
    uint startingPrice;
    uint endingPrice;
    uint duration;
    uint activatedAt;
    bool rented;
  }
  IBEP20 public fotaToken;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  mapping (OrderKind => mapping (uint => Order)) public tradingOrders;
  mapping (OrderKind => mapping (uint => Order)) public rentingOrders;
  mapping (OrderKind => IGameNFT) public nftTokens;
  mapping (OrderKind => mapping(uint => bool)) public locked;
  uint constant shareDivider = 100000;
  uint constant decimal3 = 1000;
  address public fundAdmin;
  address public treasuryAddress;
  ICitizen public citizen;
  PaymentType public paymentType;
  uint public referralShare; // decimal 3
  uint public creativeShare; // decimal 3
  uint public treasuryShare; // decimal 3
  uint public fotaPrice; // decimal 3
  mapping(uint16 => uint) public heroPrices;
  mapping(uint16 => uint) public itemPrices;
  uint public minLevel;
  uint public minGene;
  bool public openFormulaItem;

  event OrderCreated(
    OrderType indexed orderType,
    OrderKind indexed orderKind,
    uint indexed tokenId,
    address maker,
    uint startingPrice,
    uint endingPrice,
    uint duration
  );
  event OrderCanceled(
    OrderType indexed orderType,
    OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event OrderCanceledByAdmin(
    OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event OrderCanceledByAdminTest(
    OrderKind indexed orderKind,
    uint indexed tokenId,
    address maker
   );
  event OrderTaken(
    OrderKind orderKind,
    OrderType indexed orderType,
    uint indexed tokenId,
    address indexed taker,
    PaymentType paymentType,
    uint amount,
    PaymentCurrency paymentCurrency,
    uint timestamp
  );
  event OrderCompleted(
    OrderKind indexed orderKind,
    uint indexed tokenId,
    uint timestamp
  );
  event TokenPriceSynced(
    uint newPrice,
    uint timestamp
  );
  event MinLevelChanged(
    uint8 minLevel,
    uint timestamp
  );
  event MinGeneChanged(
    uint8 minGene,
    uint timestamp
  );
  event PaymentTypeChanged(
    PaymentType newMethod
  );
  event NFTLocked(
    OrderKind kind,
    uint tokenId,
    bool locked,
    uint timestamp
  );
  event OpenFormulaItemUpdated(bool opened);
  event HeroPriceUpdated(uint16 class, uint price);
  event ItemPriceUpdated(uint16 class, uint price);

  function initialize(
    address _mainAdmin,
    address _contractAdmin,
    address _fundAdmin,
    address _citizen,
    IGameNFT _heroNFTToken,
    IGameNFT _itemNFTToken,
    IGameNFT _landNFTToken,
    address _fotaToken,
    address _treasuryAddress,
    uint _fotaPrice
  ) public initializer {
    MarketAuth.initialize(_mainAdmin, _contractAdmin);
    fundAdmin = _fundAdmin;
    referralShare = 2000;
    creativeShare = 3000;
    treasuryShare = 5000;
    citizen = ICitizen(_citizen);
    nftTokens[OrderKind.hero] = _heroNFTToken;
    nftTokens[OrderKind.item] = _itemNFTToken;
    nftTokens[OrderKind.land] = _landNFTToken; // TODO is baseNFT?
    fotaToken = IBEP20(_fotaToken);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    // TODO remove test
    if (block.chainid == 97) {
      busdToken = IBEP20(0xD8aD05ff852ae4EB264089c377501494EA1D03C9);
      usdtToken = IBEP20(0xa1D3c78f0f98f6ba7b08ec15df48E22880a0024c);
    }
    treasuryAddress = _treasuryAddress;
    fotaPrice = _fotaPrice;
    minLevel = 10;
    _initItemPrices();
    _initHeroPrices();
  }

  fallback () external {}

  function makeOrder(
    OrderType _type,
    OrderKind _kind,
    uint _tokenId,
    uint _startPrice,
    uint _endingPrice,
    uint _duration
  ) public whenNotPaused {
    if (_kind == OrderKind.hero) {
      (,,,, uint8 level,,) = nftTokens[_kind].getHero(_tokenId);
      (, uint minPrice) = nftTokens[_kind].getHeroPrices(_tokenId);
      require(level >= minLevel, "MarketPlace: level invalid");
      require(_startPrice >= minPrice && _endingPrice >= minPrice, "MarketPlace: price is too low");
    } else if (_kind == OrderKind.item) {
      (uint gene,,,, uint minPrice,,) = nftTokens[_kind].getItem(_tokenId);
      if (openFormulaItem) {
        require(gene == 0 || gene >= minGene, "MarketPlace: item invalid");
      } else {
        require(gene >= minGene, "MarketPlace: item invalid");
      }
      require(_startPrice >= minPrice && _endingPrice >= minPrice, "MarketPlace: price is too low");
    }
    require(_duration >= (_type == OrderType.trading ? 1 days : 7 days), "MarketPlace: duration is invalid");
    require(_duration <= 365 days, "MarketPlace: duration is invalid");
    require(nftTokens[_kind].ownerOf(_tokenId) == msg.sender, "MarketPlace: not owner");
    _transferNFTToken(_kind, msg.sender, address(this), _tokenId);
    Order memory order = Order(
      msg.sender,
      _startPrice,
      _endingPrice,
      _duration,
      block.timestamp,
      false
    );
    _type == OrderType.trading ? tradingOrders[_kind][_tokenId] = order : rentingOrders[_kind][_tokenId] = order;
    emit OrderCreated(_type, _kind, _tokenId, msg.sender, _startPrice, _endingPrice, _duration);
  }

  function cancelOrder(OrderKind _kind, uint _tokenId) external whenNotPaused {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    if (_isActive(tradingOrder)) {
      _cancelTradingOrder(_kind, _tokenId, tradingOrder);
    } else {
      _checkCancelRentingOrder(_kind, _tokenId);
    }
  }

  function takeOrder(OrderKind _kind, uint _tokenId, PaymentCurrency _paymentCurrency) external whenNotPaused {
    _validatePaymentMethod(_paymentCurrency);
    require(!locked[_kind][_tokenId], "MarketPlace: locked");
    require(citizen.isCitizen(msg.sender), "MarketPlace: you have to register first");
    Order storage order = tradingOrders[_kind][_tokenId];
    OrderType orderType = OrderType.trading;
    if (!_isActive(order)) {
      order = rentingOrders[_kind][_tokenId];
      orderType = OrderType.renting;
    }
    require(_isActive(order), "MarketPlace: order is not active");
    uint currentPrice = _getCurrentPrice(_kind, _paymentCurrency, order, _tokenId);
    _takeFund(currentPrice, _paymentCurrency);
    address maker = order.maker;
    if (orderType == OrderType.trading) {
      _removeTradingOrder(_kind, _tokenId);
    } else {
      _markRentingOrderAsRented(_kind, _tokenId);
    }
    if (currentPrice > 0) {
      uint sharingAmount = currentPrice * (referralShare + creativeShare + treasuryShare) / shareDivider;
      _transferFund(maker, currentPrice - sharingAmount, _paymentCurrency);
      _shareOrderValue(_kind, _tokenId, maker, sharingAmount, _paymentCurrency);
    }
    if (orderType == OrderType.trading) {
      _updateOwnPrice(_kind, _tokenId, currentPrice);
      _resetFailedUpgradingAmount(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    }
    emit OrderTaken(_kind, orderType, _tokenId, msg.sender, paymentType, currentPrice, _paymentCurrency, block.timestamp);
  }

  function getNFTBack(OrderKind _kind, uint _tokenId) external whenNotPaused {
    Order storage order = rentingOrders[_kind][_tokenId];
    require(order.maker == msg.sender, "MarketPlace: not owner of order");
    require(order.rented, "MarketPlace: order is not rented");
    require(block.timestamp >= order.activatedAt + order.duration, "MarketPlace: please wait more time");
    _removeRentingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCompleted(_kind, _tokenId, block.timestamp);
  }

  function getCurrentPrice(OrderKind _kind, PaymentCurrency _paymentCurrency, uint _tokenId) external view returns(uint) {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    if (_isActive(tradingOrder)) {
      return _getCurrentPrice(_kind, _paymentCurrency, tradingOrder, _tokenId);
    }
    Order storage rentingOrder = rentingOrders[_kind][_tokenId];
    if (_isActive(rentingOrder)) {
      return _getCurrentPrice(_kind, _paymentCurrency, rentingOrder, _tokenId);
    }
    return 0;
  }

  function getOrder(OrderType _type, OrderKind _kind, uint _tokenId) external view returns(address, uint, uint, uint, uint, bool) {
    Order storage order = _type == OrderType.trading ? tradingOrders[_kind][_tokenId] : rentingOrders[_kind][_tokenId];
    return (
      order.maker,
      order.startingPrice,
      order.endingPrice,
      order.duration,
      order.activatedAt,
      order.rented
    );
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == type(IERC721Upgradeable).interfaceId;
  }

  function getItemToken() public view returns (IGameNFT) {
    return nftTokens[OrderKind.item];
  }

  function transferFormulaItem(address _to, uint _tokenId) external {
    require(openFormulaItem, "MarketPlace: you can't do this now");
    require(nftTokens[OrderKind.item].ownerOf(_tokenId) == msg.sender, "MarketPlace: not owner");
    _resetFailedUpgradingAmount(OrderKind.item, _tokenId);
    _transferNFTToken(OrderKind.item, msg.sender, _to, _tokenId);
  }

  // PRIVATE FUNCTIONS

  function _cancelTradingOrder(OrderKind _kind, uint _tokenId, Order storage _tradingOrder) private {
    require(_tradingOrder.maker == msg.sender, "MarketPlace: not owner");
    _removeTradingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCanceled(OrderType.trading, _kind, _tokenId);
  }

  function _checkCancelRentingOrder(OrderKind _kind, uint _tokenId) private {
    Order storage rentingOrder = rentingOrders[_kind][_tokenId];
    require(_isActive(rentingOrder), "MarketPlace: no active order found");
    require(rentingOrder.maker == msg.sender, "MarketPlace: not owner");
    _removeRentingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCanceled(OrderType.renting, _kind, _tokenId);
  }

  function _isActive(Order storage _order) private view returns (bool) {
    return _order.activatedAt > 0;
  }

  function _removeTradingOrder(OrderKind _kind, uint _tokenId) private {
    delete tradingOrders[_kind][_tokenId];
  }

  function _markRentingOrderAsRented(OrderKind _kind, uint _tokenId) private {
    rentingOrders[_kind][_tokenId].rented = true;
	}
  function _removeRentingOrder(OrderKind _kind, uint _tokenId) private {
    delete rentingOrders[_kind][_tokenId];
  }

  function _getCurrentPrice(OrderKind _kind, PaymentCurrency _paymentCurrency, Order storage _order, uint _tokenId) private view returns (uint) {
    uint currentPrice;

    if (_order.maker == address(this)) {
      currentPrice = _getPriceFromTokenId(_kind, _tokenId);
    } else {
      uint secondPassed;
      if (block.timestamp > _order.activatedAt) {
        secondPassed = block.timestamp - _order.activatedAt;
      }
      if (secondPassed >= _order.duration) {
        currentPrice = _order.endingPrice;
      } else {
        int changedPrice = int(_order.endingPrice) - int(_order.startingPrice);
        int currentPriceChange = changedPrice * int(secondPassed) / int(_order.duration);
        int currentPriceInt = int(_order.startingPrice) + currentPriceChange;
        currentPrice = uint(currentPriceInt);
      }
    }

    return _paymentCurrency == PaymentCurrency.fota ? currentPrice * decimal3 / fotaPrice : currentPrice;
  }

  function _getPriceFromTokenId(OrderKind _kind, uint _tokenId) private view returns (uint) {
    require(_kind == OrderKind.hero || _kind == OrderKind.item, "MarketPlace: invalid kind");
    if (_kind == OrderKind.hero) {
      (,, uint16 class,,,,) = nftTokens[_kind].getHero(_tokenId);
      return heroPrices[class];
    } else {
      (, uint16 class,,,,,) = nftTokens[_kind].getItem(_tokenId);
      return itemPrices[class];
    }
  }

  function _takeFund(uint _amount, PaymentCurrency _paymentCurrency) private {
    if (paymentType == PaymentType.fota) {
      _takeFundFOTA(_amount);
    } else if (paymentType == PaymentType.usd) {
      _takeFundUSD(_amount, _paymentCurrency);
    } else if (_paymentCurrency == PaymentCurrency.fota) {
      _takeFundFOTA(_amount);
    } else {
      _takeFundUSD(_amount, _paymentCurrency);
    }
  }

  function _takeFundUSD(uint _amount, PaymentCurrency _paymentCurrency) private {
    require(_paymentCurrency != PaymentCurrency.fota, "MarketPlace: payment currency invalid");
    IBEP20 usdToken = _paymentCurrency == PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "MarketPlace: please approve busdt first");
    require(usdToken.balanceOf(msg.sender) >= _amount, "MarketPlace: please fund your account");
    require(usdToken.transferFrom(msg.sender, address(this), _amount), "MarketPlace: transfer busd failed");
  }

  function _takeFundFOTA(uint _amount) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "MarketPlace: please approve fota first");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "MarketPlace: please fund your account");
    require(fotaToken.transferFrom(msg.sender, address(this), _amount), "MarketPlace: transfer fota failed");
  }

  function _transferFund(address _receiver, uint _amount, PaymentCurrency _paymentCurrency) private {
    if (_receiver == address(this)) {
      _receiver = fundAdmin;
    }
    if (paymentType == PaymentType.usd) {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    } else if (paymentType == PaymentType.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else if (_paymentCurrency == PaymentCurrency.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    }
  }

  function _transferFundUSD(address _receiver, uint _amount, PaymentCurrency _paymentCurrency) private {
    if (_paymentCurrency == PaymentCurrency.usdt) {
      require(usdtToken.transfer(_receiver, _amount), "MarketPlace: transfer usdt failed");
    } else {
      require(busdToken.transfer(_receiver, _amount), "MarketPlace: transfer busd failed");
    }
  }

  function _transferFundFOTA(address _receiver, uint _amount) private {
    require(fotaToken.transfer(_receiver, _amount), "MarketPlace: transfer token failed");
  }

  function _updateOwnPrice(OrderKind _kind, uint _tokenId, uint currentPrice) private {
    nftTokens[_kind].updateOwnPrice(_tokenId, currentPrice);
  }

  function _resetFailedUpgradingAmount(OrderKind _kind, uint _tokenId) private {
    nftTokens[_kind].resetFailedUpgradingAmount(_tokenId);
  }

  function _transferNFTToken(OrderKind _kind, address _from, address _to, uint _tokenId) private {
    nftTokens[_kind].transferFrom(_from, _to, _tokenId);
  }

  function _shareOrderValue(OrderKind _kind, uint _tokenId, address _maker, uint _totalShare, PaymentCurrency _paymentCurrency) private {
    uint totalShare = (referralShare + creativeShare + treasuryShare);
    uint referralSharingAmount = referralShare * _totalShare / totalShare;
    uint creativeSharingAmount = creativeShare * _totalShare / totalShare;
    uint treasurySharingAmount = treasuryShare * _totalShare / totalShare;

    address inviter = citizen.getInviter(_maker);
    if (inviter == address(0)) {
      inviter = fundAdmin;
    }
    _transferFund(inviter, referralSharingAmount, _paymentCurrency);

    address creator = nftTokens[_kind].creators(_tokenId);
    if (creator == address(0)) {
      creator = fundAdmin;
    }
    _transferFund(creator, creativeSharingAmount, _paymentCurrency);

    _transferFund(treasuryAddress, treasurySharingAmount, _paymentCurrency);
  }

  function _marketMakeOrder(
    OrderType _type,
    OrderKind _kind,
    uint _tokenId
  ) private whenNotPaused {
    uint price = _getPriceFromTokenId(_kind, _tokenId);
    uint duration = 365 days;
    Order memory order = Order(
      address(this),
        price,
        price,
        duration,
      block.timestamp,
      false
    );
    _type == OrderType.trading ? tradingOrders[_kind][_tokenId] = order : rentingOrders[_kind][_tokenId] = order;
    emit OrderCreated(_type, _kind, _tokenId, address(this), price, price, duration);
  }

  function _validatePaymentMethod(PaymentCurrency _paymentCurrency) private view {
    if (paymentType == PaymentType.fota) {
      require(_paymentCurrency == PaymentCurrency.fota, "MarketPlace: wrong payment method");
    } else if (paymentType == PaymentType.usd) {
      require(_paymentCurrency != PaymentCurrency.fota, "MarketPlace: wrong payment method");
    }
  }

  function _extractGeneFromClass(uint16 _class) private pure returns(uint8) {
    return uint8(_class / 100);
  }

  function _initItemPrices() private {
    uint16[70] memory classes = [101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 201, 202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 301, 302, 303, 304, 305, 306, 308, 307, 309, 310, 311, 312, 313, 401, 402, 403, 404, 405, 406, 407, 408, 409, 410, 411, 412, 413, 414, 415, 416, 417];
    for(uint i = 0; i < classes.length; i++) {
      itemPrices[classes[i]] = 100e18;
    }
  }

  function _initHeroPrices() private {
    uint8[18] memory classes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17];
    for(uint i = 0; i < classes.length; i++) {
      heroPrices[uint16(classes[i])] = 100e18;
    }
  }

  // ADMIN FUNCTIONS

  function setMinLevel(uint8 _minLevel) external onlyMainAdmin {
    require(_minLevel <= 20, "MarketPlace: invalid level");
    minLevel = _minLevel;
    emit MinLevelChanged(_minLevel, block.timestamp);
  }

  function setMinGene(uint8 _minGene) external onlyMainAdmin {
    minGene = _minGene;
    emit MinGeneChanged(_minGene, block.timestamp);
  }

  function syncFOTAPrice(uint _fotaPrice) external onlyContractAdmin {
    fotaPrice = _fotaPrice;
    emit TokenPriceSynced(fotaPrice, block.timestamp);
  }

  function updatePaymentType(PaymentType _type) external onlyMainAdmin {
    paymentType = _type;
    emit PaymentTypeChanged(_type);
  }

  function listHeroes(
    OrderType _type,
    uint _quantity,
    uint8 _gene,
    uint16 _class
  ) external onlyMainAdmin {
    require(heroPrices[_class] > 0, "MarketPlace: please setup the hero price first");
    for(uint i = 0; i < _quantity; i++) {
      uint _tokenId = nftTokens[OrderKind.hero].mintHero(address(this), _gene, _class, heroPrices[_class], i);
      _marketMakeOrder(_type, OrderKind.hero, _tokenId);
    }
  }

  function listItems(
    OrderType _type,
    uint _quantity,
    uint16 _class
  ) external onlyMainAdmin {
    for(uint i = 0; i < _quantity; i++) {
      require(_class >= 100, "MarketPlace: invalid item class");
      require(itemPrices[_class] > 0, "MarketPlace: please setup the item price first");
      uint8 gene = _extractGeneFromClass(_class);
      uint _tokenId = nftTokens[OrderKind.item].mintItem(address(this), gene, _class, itemPrices[_class], i);
      _marketMakeOrder(_type, OrderKind.item, _tokenId);
    }
  }

  function adminCancelOrder(OrderKind _kind, uint _tokenId) external onlyMainAdmin {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    address maker;
    if (_isActive(tradingOrder)) {
      maker = tradingOrder.maker;
      _removeTradingOrder(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), maker, _tokenId);
      emit OrderCanceledByAdmin(_kind, _tokenId);
    } else {
      Order storage rentingOrder = rentingOrders[_kind][_tokenId];
      require(_isActive(rentingOrder), "MarketPlace: no active order found");
      maker = rentingOrder.maker;
      _removeRentingOrder(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), maker, _tokenId);
      emit OrderCanceledByAdmin(_kind, _tokenId);
    }
  }

  function updateLockStatus(OrderKind _kind, uint _tokenId, bool _locked) external onlyMainAdmin {
    locked[_kind][_tokenId] = _locked;
    emit NFTLocked(_kind, _tokenId, _locked, block.timestamp);
  }

  function burn(OrderKind _kind, uint _tokenId) external onlyMainAdmin {
    require(nftTokens[_kind].ownerOf(_tokenId) == address(this), "MarketPlace: 401");
    nftTokens[_kind].burn(_tokenId);
  }

  function setReferralShare(uint _referralShare) external onlyMainAdmin {
    require(_referralShare > 0 && _referralShare <= 10000, "Invalid amount");
    referralShare = _referralShare;
  }

  function setCreatorShare(uint _creatorShare) external onlyMainAdmin {
	  require(_creatorShare > 0 && _creatorShare <= 10000, "Invalid amount");
    creativeShare = _creatorShare;
  }

  function setTreasuryShare(uint _treasuryShare) external onlyMainAdmin {
    require(_treasuryShare > 0 && _treasuryShare <= 10000, "Invalid amount");
    treasuryShare = _treasuryShare;
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0), "MarketPlace: invalid address");
    fundAdmin = _address;
  }

  function updateOpenFormulaItem(bool _opened) external onlyMainAdmin {
    openFormulaItem = _opened;
    emit OpenFormulaItemUpdated(_opened);
  }

  function updateHeroPrice(uint16 _class, uint _price) external onlyMainAdmin {
    require(_price > 0, "MarketPlace: price invalid");
    heroPrices[_class] = _price;
    emit HeroPriceUpdated(_class, _price);
  }

  function updateItemPrice(uint16 _class, uint _price) external onlyMainAdmin {
    require(_price > 0, "MarketPlace: price invalid");
    itemPrices[_class] = _price;
    emit ItemPriceUpdated(_class, _price);
  }

  // TODO for testing purpose
  function setUsdToken(address _busdToken, address _usdtToken) external onlyMainAdmin {
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface ICitizen {
  function isCitizen(address _address) external view returns (bool);
  function register(address _address, string memory _userName, address _inviter) external returns (uint);
  function getInviter(address _address) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IGameNFT is IERC721Upgradeable {
  function mintHero(address _owner, uint8 _gene, uint16 _class, uint _price, uint _index) external returns (uint);
  function getHero(uint _tokenId) external view returns (uint8, string memory, uint16, uint, uint8, uint32, address);
  function getHeroPrices(uint _tokenId) external view returns (uint, uint);
  function getHeroStrength(uint _tokenId) external view returns (uint, uint, uint, uint, uint);
  function mintItem(address _owner, uint8 _gene, uint16 _class, uint _price, uint _index) external returns (uint);
  function getItem(uint _tokenId) external view returns (uint8, uint16, uint, uint, uint, uint, address);
  function burn(uint _tokenId) external;
  function creators(uint _tokenId) external view returns (address);
  function updateOwnPrice(uint _tokenId, uint _ownPrice) external;
  function updateMinPrice(uint _tokenId, uint _ownPrice) external;
  function updateFailedUpgradingAmount(uint _tokenId, uint _amount) external;
  function resetFailedUpgradingAmount(uint _tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address internal mainAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./Auth.sol";

contract MarketAuth is Auth {
  address contractAdmin;
  function initialize(address _mainAdmin, address _contractAdmin) public {
    Auth.initialize(_mainAdmin);
    contractAdmin = _contractAdmin;
  }

  modifier onlyContractAdmin() {
    require(msg.sender == contractAdmin || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function updateContractAdmin(address _contractAdmin) onlyMainAdmin external {
    require(_contractAdmin != address(0), "Invalid address");
    contractAdmin = _contractAdmin;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

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