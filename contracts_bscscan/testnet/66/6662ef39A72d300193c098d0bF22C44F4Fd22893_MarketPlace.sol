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
  enum PaymentMethod {
    fota,
    usd
	}
  enum USDCurrency {
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
  address public treasuryAddress;
  PaymentMethod public paymentMethod;
  uint public referralShare; // decimal 3
  uint public creativeShare; // decimal 3
  uint public treasuryShare; // decimal 3
  uint public fotaPrice;
  mapping (OrderKind => mapping (uint => Order)) public tradingOrders;
  mapping (OrderKind => mapping (uint => Order)) public rentingOrders;
  mapping (OrderKind => IGameNFT) public nftTokens;
  mapping (uint => bool) public locked;
  uint constant shareDivider = 100000;
  uint constant decimal3 = 1000;
  ICitizen citizen;

  event OrderCreated(
    OrderType indexed orderType,
    OrderKind indexed orderKind,
    uint indexed nftId,
    address maker,
    uint startingPrice,
    uint endingPrice,
    uint duration
  );
  event OrderCanceled(
    OrderType indexed orderType,
    OrderKind indexed orderKind,
    uint indexed nftId
  );
  event OrderCanceledByAdmin(
    OrderKind indexed orderKind,
    uint indexed nftId
  );
  event OrderTaken(
    OrderType indexed orderType,
    uint indexed nftId,
    address indexed taker,
    PaymentMethod paymentMethod,
    uint amount
  );
  event TokenPriceSynced(
    uint newPrice,
    uint timestamp
  );
  event PaymentMethodChanged(
    PaymentMethod newMethod
  );
  event NFTLocked(
    uint nftId,
    bool locked,
    uint timestamp
  );

  function initialize(
    address _mainAdmin,
    address _contractAdmin,
    address _citizen,
    address _heroNFTToken,
    address _itemNFTToken,
    address _landNFTToken,
    address _fotaToken,
    address _treasuryAddress,
    uint _fotaPrice
  ) public initializer {
    MarketAuth.initialize(_mainAdmin, _contractAdmin);
    referralShare = 2000;
    creativeShare = 3000;
    treasuryShare = 5000;
    citizen = ICitizen(_citizen);
    nftTokens[OrderKind.hero] = IGameNFT(_heroNFTToken);
    nftTokens[OrderKind.item] = IGameNFT(_itemNFTToken);
    nftTokens[OrderKind.land] = IGameNFT(_landNFTToken);
    fotaToken = IBEP20(_fotaToken);
    busdToken = IBEP20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    usdtToken = IBEP20(0x55d398326f99059fF775485246999027B3197955);
    treasuryAddress = _treasuryAddress;
    fotaPrice = _fotaPrice;
  }

  fallback () external {}

  function makeOrder(
    OrderType _type,
    OrderKind _kind,
    uint _nftId,
    uint _startPrice,
    uint _endingPrice,
    uint _duration
  ) public whenNotPaused {
    require(_duration >= (_type == OrderType.trading ? 1 days : 7 days), "MarketPlace: duration is invalid");
    require(_duration <= 365 days, "MarketPlace: duration is invalid");
    require(nftTokens[_kind].ownerOf(_nftId) == msg.sender, "MarketPlace: not owner");
    _transferNFTToken(_kind, msg.sender, address(this), _nftId);
    Order memory order = Order(
      msg.sender,
      _startPrice,
      _endingPrice,
      _duration,
      block.timestamp,
      false
    );
    _type == OrderType.trading ? tradingOrders[_kind][_nftId] = order : rentingOrders[_kind][_nftId] = order;
    emit OrderCreated(_type, _kind, _nftId, msg.sender, _startPrice, _endingPrice, _duration);
  }

  function cancelOrder(OrderKind _kind, uint _nftId) external whenNotPaused {
    Order storage tradingOrder = tradingOrders[_kind][_nftId];
    if (_isActive(tradingOrder)) {
      _cancelTradingOrder(_kind, _nftId, tradingOrder);
    } else {
      _checkCancelRentingOrder(_kind, _nftId);
    }
  }

  function takeOrder(OrderKind _kind, uint _nftId, USDCurrency _usdCurrency) external payable whenNotPaused {
    require(!locked[_nftId], "MarketPlace: locked");
    require(citizen.isCitizen(msg.sender), "MarketPlace: you have to register first");
    Order storage order = tradingOrders[_kind][_nftId];
    OrderType orderType = OrderType.trading;
    if (!_isActive(order)) {
      order = rentingOrders[_kind][_nftId];
    }
    require(_isActive(order), "MarketPlace: order is not active");
    orderType = OrderType.renting;
    uint currentPrice = _getCurrentPrice(order);
    _takeFund(currentPrice, _usdCurrency);
    address maker = order.maker;
    if (orderType == OrderType.trading) {
      _removeTradingOrder(_kind, _nftId);
    } else {
      _markRentingOrderAsRented(_kind, _nftId);
    }
    if (currentPrice > 0) {
      uint sharingAmount = currentPrice * (referralShare + creativeShare + treasuryShare) / shareDivider;
      _transferFund(maker, currentPrice - sharingAmount, _usdCurrency);
      _shareOrderValue(_kind, _nftId, maker, sharingAmount, _usdCurrency);
    }
    if (orderType == OrderType.trading) {
      _transferNFTToken(_kind, address(this), msg.sender, _nftId);
    }
    emit OrderTaken(orderType, _nftId, msg.sender, paymentMethod, currentPrice);
  }

  function getCurrentPrice(OrderKind _kind, uint _nftId) external view returns(uint) {
    Order storage tradingOrder = tradingOrders[_kind][_nftId];
    if (_isActive(tradingOrder)) {
      return _getCurrentPrice(tradingOrder);
    }
    Order storage rentingOrder = rentingOrders[_kind][_nftId];
    if (_isActive(rentingOrder)) {
      return _getCurrentPrice(rentingOrder);
    }
    return 0;
  }

  function getOrder(OrderType _type, OrderKind _kind, uint _nftId) external view returns(address, uint, uint, uint, uint, bool) {
    Order storage order = _type == OrderType.trading ? tradingOrders[_kind][_nftId] : rentingOrders[_kind][_nftId];
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

  // PRIVATE FUNCTIONS

  function _cancelTradingOrder(OrderKind _kind, uint _nftId, Order storage _tradingOrder) private {
    require(_tradingOrder.maker == msg.sender, "MarketPlace: not owner");
    _removeTradingOrder(_kind, _nftId);
    _transferNFTToken(_kind, address(this), msg.sender, _nftId);
    emit OrderCanceled(OrderType.trading, _kind, _nftId);
  }

  function _checkCancelRentingOrder(OrderKind _kind, uint _nftId) private {
    Order storage rentingOrder = rentingOrders[_kind][_nftId];
    if (_isActive(rentingOrder)) {
      require(rentingOrder.maker == msg.sender, "MarketPlace: not owner");
      _removeRentingOrder(_kind, _nftId);
      _transferNFTToken(_kind, address(this), msg.sender, _nftId);
      emit OrderCanceled(OrderType.renting, _kind, _nftId);
    }
  }

  function _isActive(Order storage _order) private view returns (bool) {
    return _order.activatedAt > 0;
  }

  function _removeTradingOrder(OrderKind _kind, uint _nftId) private {
    delete tradingOrders[_kind][_nftId];
  }

  function _markRentingOrderAsRented(OrderKind _kind, uint _nftId) private {
    rentingOrders[_kind][_nftId].rented = true;
	}
  function _removeRentingOrder(OrderKind _kind, uint _nftId) private {
    delete rentingOrders[_kind][_nftId];
  }

  function _getCurrentPrice(Order storage _order) private view returns(uint) {
    uint secondPassed;
    uint currentPrice;
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
    return paymentMethod == PaymentMethod.usd ? currentPrice : currentPrice * decimal3 / fotaPrice;
  }

  function _takeFund(uint _amount, USDCurrency _usdCurrency) private {
    if (paymentMethod == PaymentMethod.usd) {
      if (_usdCurrency == USDCurrency.usdt) {
        usdtToken.transferFrom(msg.sender, address(this), _amount);
      } else {
        busdToken.transferFrom(msg.sender, address(this), _amount);
      }
    } else {
      fotaToken.transferFrom(msg.sender, address(this), _amount);
    }
  }

  function _transferFund(address _receiver, uint _amount, USDCurrency _usdCurrency) private {
    if (paymentMethod == PaymentMethod.usd) {
      if (_usdCurrency == USDCurrency.usdt) {
        require(usdtToken.transfer(_receiver, _amount), "MarketPlace: transfer usdt failed");
      } else {
        require(busdToken.transfer(_receiver, _amount), "MarketPlace: transfer busd failed");
      }
    } else {
      require(fotaToken.transfer(_receiver, _amount), "MarketPlace: transfer token failed");
    }
  }

  function _transferNFTToken(OrderKind _kind, address _from, address _to, uint _nftId) private {
    nftTokens[_kind].transferFrom(_from, _to, _nftId);
  }

  function _shareOrderValue(OrderKind _kind, uint _nftId, address _maker, uint _totalShare, USDCurrency _usdCurrency) private {
    uint totalShare = (referralShare + creativeShare + treasuryShare);
    uint referralSharingAmount = referralShare * _totalShare / totalShare;
    uint creativeSharingAmount = creativeShare * _totalShare / totalShare;
    uint treasurySharingAmount = treasuryShare * _totalShare / totalShare;

    address inviter = citizen.getInviter(_maker);
    if (inviter != address(0)) {
      _transferFund(inviter, referralSharingAmount, _usdCurrency);
    }

    address creator = nftTokens[_kind].creators(_nftId);
    if (creator != address(0)) {
      _transferFund(creator, creativeSharingAmount, _usdCurrency);
    }

    _transferFund(treasuryAddress, treasurySharingAmount, _usdCurrency);
  }

  // ADMIN FUNCTIONS

  function claimSharing() external onlyMainAdmin {
    usdtToken.transfer(mainAdmin, usdtToken.balanceOf(address(this)));
    busdToken.transfer(mainAdmin, busdToken.balanceOf(address(this)));
    fotaToken.transfer(mainAdmin, fotaToken.balanceOf(address(this)));
  }

  function syncFOTPrice(uint _fotaPrice) external onlyContractAdmin {
    fotaPrice = _fotaPrice;
    emit TokenPriceSynced(fotaPrice, block.timestamp);
  }

  function updatePaymentMethod(PaymentMethod _method) external onlyMainAdmin {
    paymentMethod = _method;
    emit PaymentMethodChanged(_method);
  }

  function removeTradingOrder(OrderKind _kind, uint[] memory _nftIds) external onlyMainAdmin {
    for (uint i = 0; i < _nftIds.length; i++) {
      delete tradingOrders[_kind][_nftIds[i]];
    }
  }

  function removeRentingOrder(OrderKind _kind, uint[] memory _nftIds) external onlyMainAdmin {
    for (uint i = 0; i < _nftIds.length; i++) {
      delete rentingOrders[_kind][_nftIds[i]];
    }
  }

  function listHeroes(
    OrderType _type,
    uint _quantity,
    IGameNFT.Gene _gene,
    uint _class,
    string calldata _name,
    uint _price
  ) external onlyMainAdmin {
    for(uint i = 0; i < _quantity; i++) {
//      uint _nftId = nftTokens[OrderKind.hero].mintHero(address(this), _gene, _class, _name);
      uint _nftId = nftTokens[OrderKind.hero].mintHero(msg.sender, _gene, _class, _name);
      makeOrder(_type, OrderKind.hero, _nftId, _price, _price, 365 days);
    }
  }

  function listItems(
    OrderType _type,
    uint _quantity,
    uint _class,
    string calldata _name,
    uint _price
  ) external onlyMainAdmin {
    for(uint i = 0; i < _quantity; i++) {
      uint _nftId = nftTokens[OrderKind.item].mintItem(address(this), _class, _name);
      makeOrder(_type, OrderKind.item, _nftId, _price, _price, 365 days);
    }
  }

  function adminCancelOrder(OrderKind _kind, uint _nftId) external onlyMainAdmin {
    Order storage tradingOrder = tradingOrders[_kind][_nftId];
    if (_isActive(tradingOrder)) {
      _removeTradingOrder(_kind, _nftId);
      _transferNFTToken(_kind, address(this), tradingOrder.maker, _nftId);
      emit OrderCanceledByAdmin(_kind, _nftId);
    } else {
      Order storage rentingOrder = rentingOrders[_kind][_nftId];
      if (_isActive(rentingOrder)) {
        _removeRentingOrder(_kind, _nftId);
        _transferNFTToken(_kind, address(this), tradingOrder.maker, _nftId);
        emit OrderCanceledByAdmin(_kind, _nftId);
      }
    }
  }

  function updateLockStatus(uint _nftId, bool _locked) external onlyMainAdmin {
    locked[_nftId] = _locked;
    emit NFTLocked(_nftId, _locked, block.timestamp);
  }

  function burn(OrderKind _kind, uint _nftId) external onlyMainAdmin {
    require(nftTokens[_kind].ownerOf(_nftId) == address(this), "MarketPlace: 401");
    nftTokens[_kind].burn(_nftId);
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

  // TODO for testing purpose
  function setUsdToken(address _busdToken, address _usdtToken) external onlyMainAdmin {
    busdToken = IBEP20(_busdToken);
    usdtToken = IBEP20(_usdtToken);
  }
}

// SPDX-License-Identifier: GPL

pragma solidity 0.8.0;

interface ICitizen {
  function isCitizen(address _address) external returns (bool);
  function register(address _address, string memory _userName, address _inviter) external returns (uint);
  function getInviter(address _address) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import '@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol';

interface IGameNFT is IERC721Upgradeable {
  enum Gene {
    Human,
    Beast,
    Animal
  }
  function mintHero(address _owner, Gene _gene, uint _class, string calldata _name) external returns (uint);
  function getHero(uint _nftId) external view returns (Gene, uint, string memory, uint, uint8, uint);
  function getHeroStrength(uint _nftId) external view returns (uint, uint, uint, uint, uint);
  function mintItem(address _owner, uint _class, string calldata _name) external returns (uint);
  function getItem(uint _nftId) external view returns (uint, string memory, uint);
  function burn(uint _nftId) external;
  function creators(uint _nftId) external view returns (address);
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
    require(isMainAdmin(), "onlyMainAdmin");
    _;
  }

  function transferOwnership(address _newOwner) onlyMainAdmin external {
    require(_newOwner != address(0x0));
    mainAdmin = _newOwner;
    emit OwnershipTransferred(msg.sender, _newOwner);
  }

  function isMainAdmin() public view returns (bool) {
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
    require(msg.sender == contractAdmin || isMainAdmin(), "onlyContractAdmin");
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
abstract contract IBEP20 {
    function transfer(address to, uint256 value) external virtual returns (bool);

    function approve(address spender, uint256 value) external virtual returns (bool);

    function transferFrom(address from, address to, uint256 value) external virtual returns (bool);

    function balanceOf(address who) external virtual view returns (uint256);

    function allowance(address owner, address spender) external virtual view returns (uint256);

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

