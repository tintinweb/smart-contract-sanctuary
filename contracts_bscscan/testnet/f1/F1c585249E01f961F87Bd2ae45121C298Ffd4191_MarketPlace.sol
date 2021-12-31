// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "./libs/zeppelin/token/BEP20/IBEP20.sol";
import "./interfaces/IGameNFT.sol";
import "./interfaces/ICitizen.sol";
import "./interfaces/IMarketPlace.sol";
import "./interfaces/IFOTAGame.sol";
import "./interfaces/IFOTAPricer.sol";
import "./interfaces/IEatherTransporter.sol";
import "./libs/fota/Auth.sol";

contract MarketPlace is Auth, PausableUpgradeable {
  struct Order {
    address maker;
    uint startingPrice;
    uint endingPrice;
    uint auctionDuration;
    uint rentingDuration;
    uint activatedAt;
    bool rented;
  }
  IBEP20 public fotaToken;
  IBEP20 public busdToken;
  IBEP20 public usdtToken;
  mapping (IMarketPlace.OrderKind => mapping (uint => Order)) public tradingOrders;
  mapping (IMarketPlace.OrderKind => mapping (uint => Order)) public rentingOrders;
  mapping (IMarketPlace.OrderKind => IGameNFT) public nftTokens;
  mapping (address => bool) public lockedUser;
  mapping (uint16 => bool) public lockedHeroClassId;
  mapping (uint16 => bool) public lockedItemClassId;
  mapping (uint => bool) public lockedHeroNFTId;
  mapping (uint => bool) public lockedItemNFTId;
  mapping (IMarketPlace.OrderKind => mapping(uint16 => uint)) public remainingSale;
  address public fundAdmin;
  address public treasuryAddress;
  ICitizen public citizen;
  IMarketPlace.PaymentType public paymentType;
  IFOTAGame public pveContract;
  IFOTAGame public pvpContract;
  IFOTAPricer public fotaPricer;
  IEatherTransporter public eatherTransporter;
  uint public referralShare; // decimal 3
  uint public creativeShare; // decimal 3
  uint public treasuryShare; // decimal 3
  mapping(uint16 => uint) public heroPrices;
  mapping(uint16 => uint) public heroMinPrices;
  mapping(uint16 => uint) public itemPrices;
  mapping(uint16 => uint) public itemMinPrices;
  uint public minLevel;
  uint public minGene;

  event RemainingSaleUpdated(
    IMarketPlace.OrderKind kind,
    uint16 classId,
    uint remainingSale
  );
  event OrderCreated(
    IMarketPlace.OrderType indexed orderType,
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId,
    address maker,
    uint startingPrice,
    uint endingPrice,
    uint auctionDuration,
    uint rentingDuration
  );
  event OrderCanceled(
    IMarketPlace.OrderType indexed orderType,
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event OrderCanceledByAdmin(
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId
  );
  event OrderTaken(
    IMarketPlace.OrderKind orderKind,
    IMarketPlace.OrderType indexed orderType,
    uint indexed tokenId,
    address indexed taker,
    IMarketPlace.PaymentType paymentType,
    uint amount,
    IMarketPlace.PaymentCurrency paymentCurrency,
    uint timestamp
  );
  event FoundingOrderTaken(
    IMarketPlace.OrderKind kind,
    uint indexed tokenId,
    address indexed taker,
    IMarketPlace.PaymentType paymentType,
    uint amount,
    IMarketPlace.PaymentCurrency paymentCurrency,
    uint timestamp
  );
  event OrderCompleted(
    IMarketPlace.OrderKind indexed orderKind,
    uint indexed tokenId,
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
    IMarketPlace.PaymentType newMethod
  );
  event UserLocked(
    address user,
    bool locked,
    uint timestamp
  );
  event HeroClassIdLocked(
    uint16 classId,
    bool locked,
    uint timestamp
  );
  event HeroNFTLocked(
    uint id,
    bool locked,
    uint timestamp
  );
  event ItemClassIdLocked(
    uint16 classId,
    bool locked,
    uint timestamp
  );
  event ItemNFTLocked(
    uint id,
    bool locked,
    uint timestamp
  );
  event HeroPriceUpdated(uint16 class, uint price);
  event HeroMinPriceUpdated(uint16 class, uint price);
  event ItemPriceUpdated(uint16 class, uint price);
  event ItemMinPriceUpdated(uint16 class, uint price);
  event ReferralSent(
    address indexed inviter,
    address indexed invitee,
    uint referralSharingAmount,
    IMarketPlace.PaymentCurrency paymentCurrency
  );

  function initialize(
    address _mainAdmin,
    address _citizen,
    IGameNFT _heroNFTToken,
    IGameNFT _itemNFTToken,
    IGameNFT _landNFTToken,
    address _treasuryAddress,
    address _fotaPricer,
    address _eatherTransporter
  ) public initializer {
    Auth.initialize(_mainAdmin);
    fundAdmin = _mainAdmin;
    citizen = ICitizen(_citizen);
    nftTokens[IMarketPlace.OrderKind.hero] = _heroNFTToken;
    nftTokens[IMarketPlace.OrderKind.item] = _itemNFTToken;
    nftTokens[IMarketPlace.OrderKind.land] = _landNFTToken;
    fotaPricer = IFOTAPricer(_fotaPricer);
    eatherTransporter = IEatherTransporter(_eatherTransporter);
    fotaToken = IBEP20(0x0A4E1BdFA75292A98C15870AeF24bd94BFFe0Bd4);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    treasuryAddress = _treasuryAddress;
  }

  function makeOrder(
    IMarketPlace.OrderType _type,
    IMarketPlace.OrderKind _kind,
    uint _tokenId,
    uint _startPrice,
    uint _endingPrice,
    uint _auctionDuration,
    uint _rentingDuration
  ) public whenNotPaused {
    _validateUser();
    if (_kind == IMarketPlace.OrderKind.hero) {
      _validateHero(_type, _kind, _tokenId, _startPrice, _endingPrice);
    } else if (_kind == IMarketPlace.OrderKind.item) {
      _validateItem(_type, _kind, _tokenId, _startPrice, _endingPrice);
    }
    if (_startPrice != _endingPrice) {
      require(_auctionDuration >= 1 minutes && _auctionDuration <= 365 days, "duration is invalid");
    }
    if (_type == IMarketPlace.OrderType.renting) {
      require(_rentingDuration >= 7 minutes && _rentingDuration <= 365 days, "renting duration is invalid");
    }
    require(nftTokens[_kind].ownerOf(_tokenId) == msg.sender, "not owner");
    _transferNFTToken(_kind, msg.sender, address(this), _tokenId);
    Order memory order = Order(
      msg.sender,
      _startPrice,
      _endingPrice,
      _auctionDuration,
      _rentingDuration,
      block.timestamp,
      false
    );
    _type == IMarketPlace.OrderType.trading ? tradingOrders[_kind][_tokenId] = order : rentingOrders[_kind][_tokenId] = order;
    emit OrderCreated(_type, _kind, _tokenId, msg.sender, _startPrice, _endingPrice, _auctionDuration, _rentingDuration);
  }

  function cancelOrder(IMarketPlace.OrderKind _kind, uint _tokenId) external whenNotPaused {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    if (_isActive(tradingOrder)) {
      _cancelTradingOrder(_kind, _tokenId, tradingOrder);
    } else {
      _checkCancelRentingOrder(_kind, _tokenId);
    }
  }

  function takeOrder(IMarketPlace.OrderKind _kind, uint _tokenId, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    _validateTaker(_paymentCurrency);
    uint16 _classId = nftTokens[_kind].getClassId(_tokenId);
    if (_kind == IMarketPlace.OrderKind.hero) {
      require(!lockedHeroNFTId[_tokenId], "hero locked");
      require(!lockedHeroClassId[_classId], "hero not valid");
    } else if (_kind == IMarketPlace.OrderKind.item) {
      require(!lockedItemNFTId[_tokenId], "item locked");
      require(!lockedItemClassId[_classId], "item not valid");
    }
    Order storage order = tradingOrders[_kind][_tokenId];
    IMarketPlace.OrderType orderType = IMarketPlace.OrderType.trading;
    if (!_isActive(order)) {
      order = rentingOrders[_kind][_tokenId];
      orderType = IMarketPlace.OrderType.renting;
    }
    require(_isActive(order), "not active");
    require(order.maker != msg.sender, "can not buy yourself");
    uint currentPrice = _getCurrentPrice(_kind, _paymentCurrency, order, _tokenId);
    _takeFund(currentPrice, _paymentCurrency);
    address maker = order.maker;
    if (orderType == IMarketPlace.OrderType.trading) {
      _removeTradingOrder(_kind, _tokenId);
    } else {
      _markRentingOrderAsRented(_kind, _tokenId);
    }
    if (currentPrice > 0) {
      _releaseFund(_kind, maker, currentPrice, _tokenId, _paymentCurrency);
    }
    if (orderType == IMarketPlace.OrderType.trading) {
      if (_isFotaPayment(_paymentCurrency)) {
        nftTokens[_kind].updateOwnPrice(_tokenId, _convertFotaToUsd(currentPrice));
      } else {
        nftTokens[_kind].updateOwnPrice(_tokenId, currentPrice);
      }
      nftTokens[_kind].updateFailedUpgradingAmount(_tokenId, 0);
      _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    }
    emit OrderTaken(_kind, orderType, _tokenId, msg.sender, paymentType, currentPrice, _paymentCurrency, block.timestamp);
  }

  function takeFounding(IMarketPlace.OrderKind _kind, uint16 _classId, IMarketPlace.PaymentCurrency _paymentCurrency) external whenNotPaused {
    require(remainingSale[_kind][_classId] > 0, "sold out");
    remainingSale[_kind][_classId]--;
    _validateTaker(_paymentCurrency);
    uint currentPrice;
    uint tokenId;
    if (_kind == IMarketPlace.OrderKind.hero) {
      currentPrice = heroPrices[_classId];
      tokenId = nftTokens[_kind].mintHero(msg.sender, _classId, currentPrice, 0);
    } else {
      currentPrice = itemPrices[_classId];
      tokenId = nftTokens[_kind].mintItem(msg.sender, 1, _classId, currentPrice, 0);
    }
    if (_isFotaPayment(_paymentCurrency)) {
      currentPrice = currentPrice * 1000 / fotaPricer.fotaPrice();
    }
    require(currentPrice > 0, "please set price first");
    _takeFund(currentPrice, _paymentCurrency);
    _releaseFund(_kind, fundAdmin, currentPrice, tokenId, _paymentCurrency);
    emit FoundingOrderTaken(_kind, tokenId, msg.sender, paymentType, currentPrice, _paymentCurrency, block.timestamp);
  }

  function getNFTBack(IMarketPlace.OrderKind _kind, uint _tokenId) external whenNotPaused {
    Order storage order = rentingOrders[_kind][_tokenId];
    require(order.maker == msg.sender, "not owner");
    require(order.rented, "order not rented");
    require(block.timestamp >= order.activatedAt + order.rentingDuration, "please wait more time");
    _removeRentingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCompleted(_kind, _tokenId, block.timestamp);
  }

  function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
    return interfaceId == type(IERC721Upgradeable).interfaceId;
  }

  // PRIVATE FUNCTIONS

  function _convertFotaToUsd(uint _amount) private view returns (uint) {
    return _amount * fotaPricer.fotaPrice() / 1000;
  }

  function _validateTaker(IMarketPlace.PaymentCurrency _paymentCurrency) private view {
    _validatePaymentMethod(_paymentCurrency);
    _validateUser();
    require(citizen.isCitizen(msg.sender), "register required");
  }

  function _releaseFund(IMarketPlace.OrderKind _kind, address _maker, uint _currentPrice, uint _tokenId, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    uint sharingAmount = _currentPrice * (referralShare + creativeShare + treasuryShare) / 100000;
    _transferFund(_maker, _currentPrice - sharingAmount, _paymentCurrency);
    _shareOrderValue(_kind, _tokenId, sharingAmount, _paymentCurrency);
  }

  function _isFotaPayment(IMarketPlace.PaymentCurrency _paymentCurrency) private view returns (bool) {
    return paymentType == IMarketPlace.PaymentType.fota || (paymentType == IMarketPlace.PaymentType.all && _paymentCurrency == IMarketPlace.PaymentCurrency.fota);
  }

  function _cancelTradingOrder(IMarketPlace.OrderKind _kind, uint _tokenId, Order storage _tradingOrder) private {
    require(_tradingOrder.maker == msg.sender, "not owner");
    _removeTradingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCanceled(IMarketPlace.OrderType.trading, _kind, _tokenId);
  }

  function _checkCancelRentingOrder(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    Order storage rentingOrder = rentingOrders[_kind][_tokenId];
    require(_isActive(rentingOrder), "no active order found");
    require(rentingOrder.maker == msg.sender, "not owner");
    _removeRentingOrder(_kind, _tokenId);
    _transferNFTToken(_kind, address(this), msg.sender, _tokenId);
    emit OrderCanceled(IMarketPlace.OrderType.renting, _kind, _tokenId);
  }

  function _isActive(Order storage _order) private view returns (bool) {
    return _order.activatedAt > 0;
  }

  function _removeTradingOrder(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    delete tradingOrders[_kind][_tokenId];
  }

  function _markRentingOrderAsRented(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    rentingOrders[_kind][_tokenId].rented = true;
    rentingOrders[_kind][_tokenId].activatedAt = block.timestamp;
	}
  function _removeRentingOrder(IMarketPlace.OrderKind _kind, uint _tokenId) private {
    delete rentingOrders[_kind][_tokenId];
  }

  function _getCurrentPrice(IMarketPlace.OrderKind _kind, IMarketPlace.PaymentCurrency _paymentCurrency, Order storage _order, uint _tokenId) private view returns (uint) {
    uint currentPrice;

    if (_order.maker == address(this)) {
      currentPrice = _getPriceFromTokenId(_kind, _tokenId);
    } else {
      uint secondPassed;
      if (block.timestamp > _order.activatedAt) {
        secondPassed = block.timestamp - _order.activatedAt;
      }
      if (secondPassed >= _order.auctionDuration) {
        currentPrice = _order.endingPrice;
      } else {
        int changedPrice = int(_order.endingPrice) - int(_order.startingPrice);
        int currentPriceChange = changedPrice * int(secondPassed) / int(_order.auctionDuration);
        int currentPriceInt = int(_order.startingPrice) + currentPriceChange;
        currentPrice = uint(currentPriceInt);
      }
    }

    return _paymentCurrency == IMarketPlace.PaymentCurrency.fota ? currentPrice * 1000 / fotaPricer.fotaPrice() : currentPrice;
  }

  function _getPriceFromTokenId(IMarketPlace.OrderKind _kind, uint _tokenId) private view returns (uint) {
    require(_kind == IMarketPlace.OrderKind.hero || _kind == IMarketPlace.OrderKind.item, "invalid kind");
    if (_kind == IMarketPlace.OrderKind.hero) {
      (,,, uint16 class,,,) = nftTokens[_kind].getHero(_tokenId);
      return heroPrices[class];
    } else {
      (, uint16 class,,,) = nftTokens[_kind].getItem(_tokenId);
      return itemPrices[class];
    }
  }

  function _takeFund(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (paymentType == IMarketPlace.PaymentType.fota) {
      _takeFundFOTA(_amount);
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      _takeFundUSD(_amount, _paymentCurrency);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      _takeFundFOTA(_amount);
    } else {
      _takeFundUSD(_amount, _paymentCurrency);
    }
  }

  function _takeFundUSD(uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    require(_paymentCurrency != IMarketPlace.PaymentCurrency.fota, "payment currency invalid");
    IBEP20 usdToken = _paymentCurrency == IMarketPlace.PaymentCurrency.busd ? busdToken : usdtToken;
    require(usdToken.allowance(msg.sender, address(this)) >= _amount, "please approve busdt first");
    require(usdToken.balanceOf(msg.sender) >= _amount, "insufficient balance");
    require(usdToken.transferFrom(msg.sender, address(this), _amount), "transfer busd failed");
  }

  function _takeFundFOTA(uint _amount) private {
    require(fotaToken.allowance(msg.sender, address(this)) >= _amount, "please approve fota first");
    require(fotaToken.balanceOf(msg.sender) >= _amount, "please fund your account");
    require(fotaToken.transferFrom(msg.sender, address(this), _amount), "transfer fota failed");
  }

  function _transferFund(address _receiver, uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (_receiver == address(this)) {
      _receiver = fundAdmin;
    }
    if (paymentType == IMarketPlace.PaymentType.usd) {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    } else if (paymentType == IMarketPlace.PaymentType.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else if (_paymentCurrency == IMarketPlace.PaymentCurrency.fota) {
      _transferFundFOTA(_receiver, _amount);
    } else {
      _transferFundUSD(_receiver, _amount, _paymentCurrency);
    }
  }

  function _transferFundUSD(address _receiver, uint _amount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    if (_paymentCurrency == IMarketPlace.PaymentCurrency.usdt) {
      require(usdtToken.transfer(_receiver, _amount), "transfer usdt failed");
    } else {
      require(busdToken.transfer(_receiver, _amount), "transfer busd failed");
    }
  }

  function _transferFundFOTA(address _receiver, uint _amount) private {
    require(fotaToken.transfer(_receiver, _amount), "transfer token failed");
  }

  function _transferNFTToken(IMarketPlace.OrderKind _kind, address _from, address _to, uint _tokenId) private {
    nftTokens[_kind].transferFrom(_from, _to, _tokenId);
  }

  function _shareOrderValue(IMarketPlace.OrderKind _kind, uint _tokenId, uint _totalShareAmount, IMarketPlace.PaymentCurrency _paymentCurrency) private {
    uint totalSharePercent = referralShare + creativeShare + treasuryShare;
    uint referralSharingAmount = referralShare * _totalShareAmount / totalSharePercent;
    uint treasurySharingAmount = treasuryShare * _totalShareAmount / totalSharePercent;
    uint creativeSharingAmount = creativeShare * _totalShareAmount / totalSharePercent;
    address inviter = citizen.getInviter(msg.sender);
    if (inviter == address(0)) {
      inviter = treasuryAddress;
    } else {
      bool validInviter = _validateInviter(inviter);
      if (!validInviter) {
        inviter = treasuryAddress;
      }
    }
    emit ReferralSent(inviter, msg.sender, referralSharingAmount, _paymentCurrency);
    _transferFund(inviter, referralSharingAmount, _paymentCurrency);

    address creator = nftTokens[_kind].getCreator(_tokenId);
    if (creator == address(0)) {
      creator = fundAdmin;
    }
    _transferFund(creator, creativeSharingAmount, _paymentCurrency);

    _transferFund(treasuryAddress, treasurySharingAmount, _paymentCurrency);
  }

  function _validateInviter(address _inviter) private view returns (bool) {
    return pveContract.validateInviter(_inviter) && pvpContract.validateInviter(_inviter);
  }

  function _validatePaymentMethod(IMarketPlace.PaymentCurrency _paymentCurrency) private view {
    if (paymentType == IMarketPlace.PaymentType.fota) {
      require(_paymentCurrency == IMarketPlace.PaymentCurrency.fota, "wrong payment method");
    } else if (paymentType == IMarketPlace.PaymentType.usd) {
      require(_paymentCurrency != IMarketPlace.PaymentCurrency.fota, "wrong payment method");
    }
  }

  function _validateUser() private view {
    require(!lockedUser[msg.sender], "user locked");
  }

  function _validateHero(IMarketPlace.OrderType _type, IMarketPlace.OrderKind _kind, uint _tokenId, uint _startPrice, uint _endingPrice) private view {
    (,,,uint16 _id,, uint8 level,) = nftTokens[_kind].getHero(_tokenId);
    require(level >= minLevel, "level invalid");
    require(!lockedHeroClassId[_id], "hero invalid");
    require(!lockedHeroNFTId[_tokenId], "hero locked");

    if (_type == IMarketPlace.OrderType.trading) {
      require(_startPrice >= heroMinPrices[_id] && _endingPrice >= heroMinPrices[_id], "price is too low");
    }
  }

  function _validateItem(IMarketPlace.OrderType _type, IMarketPlace.OrderKind _kind, uint _tokenId, uint _startPrice, uint _endingPrice) private view {
    (uint gene, uint16 _class,,,) = nftTokens[_kind].getItem(_tokenId);
    if (eatherTransporter.openEather()) {
      require(gene == 0 || gene >= minGene, "item invalid");
    } else {
      require(gene >= minGene, "item invalid");
    }
    require(!lockedItemClassId[_class], "item invalid");
    require(!lockedItemNFTId[_tokenId], "item locked");

    if (_type == IMarketPlace.OrderType.trading) {
      require(_startPrice >= itemMinPrices[_class] && _endingPrice >= itemMinPrices[_class], "price is too low");
    }
  }

  // ADMIN FUNCTIONS

  function setMinLevel(uint8 _minLevel) external onlyMainAdmin {
    require(_minLevel <= 25);
    minLevel = _minLevel;
    emit MinLevelChanged(_minLevel, block.timestamp);
  }

  function setMinGene(uint8 _minGene) external onlyMainAdmin {
    minGene = _minGene;
    emit MinGeneChanged(_minGene, block.timestamp);
  }

  function updatePaymentType(IMarketPlace.PaymentType _type) external onlyMainAdmin {
    paymentType = _type;
    emit PaymentTypeChanged(_type);
  }

  function adminCancelOrder(IMarketPlace.OrderKind _kind, uint _tokenId) external onlyMainAdmin {
    Order storage tradingOrder = tradingOrders[_kind][_tokenId];
    address maker;
    if (_isActive(tradingOrder)) {
      maker = tradingOrder.maker;
      _removeTradingOrder(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), maker, _tokenId);
    } else {
      Order storage rentingOrder = rentingOrders[_kind][_tokenId];
      require(_isActive(rentingOrder));
      maker = rentingOrder.maker;
      _removeRentingOrder(_kind, _tokenId);
      _transferNFTToken(_kind, address(this), maker, _tokenId);
    }
    emit OrderCanceledByAdmin(_kind, _tokenId);
  }

  function updateLockUserStatus(address _user, bool _locked) external onlyMainAdmin {
    lockedUser[_user] = _locked;
    emit UserLocked(_user, _locked, block.timestamp);
  }

  function updateLockHeroStatus(uint16 _id, bool _locked) external onlyMainAdmin {
    lockedHeroClassId[_id] = _locked;
    emit HeroClassIdLocked(_id, _locked, block.timestamp);
  }

  function updateLockHeroNFTIdStatus(uint _id, bool _locked) external onlyMainAdmin {
    lockedHeroNFTId[_id] = _locked;
    emit HeroNFTLocked(_id, _locked, block.timestamp);
  }

  function updateLockItemStatus(uint16 _id, bool _locked) external onlyMainAdmin {
    lockedItemClassId[_id] = _locked;
    emit ItemClassIdLocked(_id, _locked, block.timestamp);
  }

  function updateLockItemNFTIdStatus(uint _id, bool _locked) external onlyMainAdmin {
    lockedItemNFTId[_id] = _locked;
    emit ItemNFTLocked(_id, _locked, block.timestamp);
  }

  function setShares(uint _referralShare, uint _creatorShare, uint _treasuryShare) external onlyMainAdmin {
    require(_referralShare > 0 && _referralShare <= 10000);
    referralShare = _referralShare;
    require(_creatorShare > 0 && _creatorShare <= 10000);
    creativeShare = _creatorShare;
    require(_treasuryShare > 0 && _treasuryShare <= 10000);
    treasuryShare = _treasuryShare;
  }

  function updateFundAdmin(address _address) external onlyMainAdmin {
    require(_address != address(0));
    fundAdmin = _address;
  }

  function updateHeroPrice(uint16 _class, uint _price) external onlyMainAdmin {
    heroPrices[_class] = _price;
    emit HeroPriceUpdated(_class, _price);
  }

  function updateHeroMinPrice(uint16 _class, uint _price) external onlyMainAdmin {
    heroMinPrices[_class] = _price;
    emit HeroMinPriceUpdated(_class, _price);
  }

  function updateItemPrice(uint16 _class, uint _price) external onlyMainAdmin {
    itemPrices[_class] = _price;
    emit ItemPriceUpdated(_class, _price);
  }

  function updateItemMinPrice(uint16 _class, uint _price) external onlyMainAdmin {
    itemMinPrices[_class] = _price;
    emit ItemMinPriceUpdated(_class, _price);
  }

  function setGameContracts(address _pve, address _pvp) external onlyMainAdmin {
    pveContract = IFOTAGame(_pve);
    pvpContract = IFOTAGame(_pvp);
  }

  function setEatherTransporter(address _eatherTransporter) external onlyMainAdmin {
    eatherTransporter = IEatherTransporter(_eatherTransporter);
  }

  function setFOTAPricer(address _fotaPricer) external onlyMainAdmin {
    fotaPricer = IFOTAPricer(_fotaPricer);
  }

  function updatePauseStatus(bool _paused) external onlyMainAdmin {
    if(_paused) {
      _pause();
    } else {
      _unpause();
    }
  }

  function setRemainingSale(IMarketPlace.OrderKind _kind, uint16 _classId, uint _remainingSale) external onlyMainAdmin {
    if (_kind == IMarketPlace.OrderKind.hero) {
      uint16 totalId = nftTokens[_kind].countId();
      require(_classId <= totalId, "classId invalid");
    }
    remainingSale[_kind][_classId] = _remainingSale;
    emit RemainingSaleUpdated(_kind, _classId, _remainingSale);
  }


  // TODO for testing purpose
  function setToken(address _fotaToken, address _busdToken, address _usdtToken) external onlyMainAdmin {
    fotaToken = IBEP20(_fotaToken);
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
  }

//  function setUsdToken(address _busdToken, address _usdtToken) external onlyMainAdmin {
//    busdToken = IBEP20(_busdToken);
//    usdtToken = IBEP20(_usdtToken);
//  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface ICitizen {
  function isCitizen(address _address) external view returns (bool);
  function register(address _address, string memory _userName, address _inviter) external returns (uint);
  function getInviter(address _address) external returns (address);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IEatherTransporter {
  function openEather() external view returns (bool);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFOTAGame {
  function validateInviter(address _inviter) external view returns (bool);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface IFOTAPricer {
  function fotaPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IGameNFT is IERC721Upgradeable {
  function mintHero(address _owner, uint16 _classId, uint _price, uint _index) external returns (uint);
  function getHero(uint _tokenId) external view returns (string memory, string memory, string memory, uint16, uint, uint8, uint32);
  function getHeroPrices(uint _tokenId) external view returns (uint, uint);
  function getHeroStrength(uint _tokenId) external view returns (uint, uint, uint, uint, uint);
  function mintItem(address _owner, uint8 _gene, uint16 _class, uint _price, uint _index) external returns (uint);
  function getItem(uint _tokenId) external view returns (uint8, uint16, uint, uint, uint);
  function getClassId(uint _tokenId) external view returns (uint16);
  function burn(uint _tokenId) external;
  function getCreator(uint _tokenId) external view returns (address);
  function countId() external view returns (uint16);
  function updateOwnPrice(uint _tokenId, uint _ownPrice) external;
  function updateFailedUpgradingAmount(uint _tokenId, uint _amount) external;
  function skillUp(uint _tokenId, uint8 _index) external;
  function experienceCheckpoint(uint8 _level) external view returns (uint32);
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

import "./IGameNFT.sol";

interface IMarketPlace {
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
  function fotaToken() external view returns (address);
  function busdToken() external view returns (address);
  function usdtToken() external view returns (address);
  function citizen() external view returns (address);
  function takeOrder(OrderKind _kind, uint _tokenId, PaymentCurrency _paymentCurrency) external;
  function paymentType() external view returns (PaymentType);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

abstract contract Auth is Initializable {

  address public mainAdmin;
  address public contractAdmin;

  event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);
  event ContractAdminUpdated(address indexed _newOwner);

  function initialize(address _mainAdmin) virtual public initializer {
    mainAdmin = _mainAdmin;
    contractAdmin = _mainAdmin;
  }

  modifier onlyMainAdmin() {
    require(_isMainAdmin(), "onlyMainAdmin");
    _;
  }

  modifier onlyContractAdmin() {
    require(_isContractAdmin() || _isMainAdmin(), "onlyContractAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function updateContractAdmin(address _newAdmin) onlyMainAdmin external {
    require(_newAdmin != address(0x0));
    contractAdmin = _newAdmin;
    emit ContractAdminUpdated(_newAdmin);
  }

  function _isMainAdmin() public view returns (bool) {
    return msg.sender == mainAdmin;
  }

  function _isContractAdmin() public view returns (bool) {
    return msg.sender == contractAdmin;
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