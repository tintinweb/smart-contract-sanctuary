/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT

interface IERC20 {
  function balanceOf(address account) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);

  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (address _receiver, uint256 _royaltyAmount);

  function royaltyInfo(
    uint256 _tokenId,
    uint256 _value,
    bytes calldata _data
  )
    external
    view
    returns (
      address _receiver,
      uint256 _royaltyAmount,
      bytes memory _royaltyPaymentData
    );
}

library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');

    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    return sub(a, b, 'SafeMath: subtraction overflow');
  }

  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    uint256 c = a - b;

    return c;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');

    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return div(a, b, 'SafeMath: division by zero');
  }

  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    uint256 c = a / b;

    return c;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    return mod(a, b, 'SafeMath: modulo by zero');
  }

  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b != 0, errorMessage);
    return a % b;
  }
}

library Roles {
  struct Role {
    mapping(address => bool) bearer;
  }

  function add(Role storage role, address account) internal {
    require(!has(role, account), 'Roles: account already has role');
    role.bearer[account] = true;
  }

  function remove(Role storage role, address account) internal {
    require(has(role, account), 'Roles: account does not have role');
    role.bearer[account] = false;
  }

  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0), 'Roles: account is the zero address');
    return role.bearer[account];
  }
}

abstract contract Context {
  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this;
    return msg.data;
  }
}

abstract contract AdminRole is Context {
  using Roles for Roles.Role;

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;

  constructor() {
    _addAdmin(_msgSender());
  }

  modifier onlyAdmin() {
    require(
      isAdmin(_msgSender()),
      'AdminRole: caller does not have the Admin role'
    );
    _;
  }

  function isAdmin(address account) public view returns (bool) {
    return _admins.has(account);
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

  function renounceAdmin() public {
    _removeAdmin(_msgSender());
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    emit AdminRemoved(account);
  }
}

contract HarbourAuction is AdminRole {
  using SafeMath for uint256;

  address payable private _creator;
  // maker => token address => tokenId => price
  mapping(address => mapping(address => mapping(uint256 => uint256)))
    private _priceByMakerTokenTokenId;

  uint256 public minPrice;
  uint256 public maxPrice;
  uint256 public exchangeFeeBps;
  address payable public exchangeFeeAddress;
  bool public isUnwrappedValid = false;
  mapping(address => bool) private _validCurrencies;

  constructor(
    uint256 min,
    uint256 max,
    uint256 fee,
    address payable feeAddress,
    bool unwrappedValid
  ) {
    _creator = payable(_msgSender());
    minPrice = min;
    maxPrice = max;
    exchangeFeeBps = fee;
    exchangeFeeAddress = feeAddress;
    isUnwrappedValid = unwrappedValid;
  }

  event CurrencyUpdate(address erc20, bool valid);
  event LimitUpdate(uint256 min, uint256 max);
  event FeeUpdate(address payable feeAddress, uint256 fee);

  function setCurrencyValid(address erc20, bool valid) public onlyAdmin {
    if (erc20 == address(0)) {
      isUnwrappedValid = valid;
    } else {
      _validCurrencies[erc20] = valid;
    }
    emit CurrencyUpdate(erc20, valid);
  }

  function setPriceLimits(uint256 min, uint256 max) public onlyAdmin {
    minPrice = min;
    maxPrice = max;
    emit LimitUpdate(min, max);
  }

  function setExchangeFee(address payable feeAddress, uint256 fee)
    public
    onlyAdmin
  {
    exchangeFeeAddress = feeAddress;
    exchangeFeeBps = fee;
    emit FeeUpdate(feeAddress, fee);
  }

  function withdraw(address erc20, uint256 amount) public onlyAdmin {
    if (erc20 == address(0)) {
      _creator.transfer(amount);
    } else {
      IERC20(erc20).transfer(_creator, amount);
    }
  }

  event OrderOffer(
    address indexed maker,
    address indexed token,
    uint256 indexed tokenId,
    uint256 price
  );
  event OrderCancel(
    address indexed maker,
    address indexed token,
    uint256 indexed tokenId
  );
  event OrderTaken(
    address indexed maker,
    address indexed token,
    uint256 indexed tokenId,
    uint256 price,
    address taker
  );

  function _setOffer(
    address maker,
    address token,
    uint256 tokenId,
    uint256 price
  ) internal {
    _priceByMakerTokenTokenId[maker][token][tokenId] = price;
  }

  function _clearOffer(
    address maker,
    address token,
    uint256 tokenId
  ) internal {
    _priceByMakerTokenTokenId[maker][token][tokenId] = 0;
  }

  function isCurrencyValid(address erc20) public view returns (bool) {
    return _validCurrencies[erc20];
  }

  function getOffer(
    address maker,
    address token,
    uint256 tokenId
  ) public view returns (uint256) {
    return _priceByMakerTokenTokenId[maker][token][tokenId];
  }

  function cancelOffer(address token, uint256 tokenId) public {
    address maker = _msgSender();
    uint256 oldPrice = getOffer(maker, token, tokenId);
    require(oldPrice > 0, 'cant cancel an order that doesnt exist');
    _clearOffer(maker, token, tokenId);
    emit OrderCancel(maker, token, tokenId);
  }

  function makeOffer(
    address token,
    uint256 tokenId,
    uint256 price
  ) public {
    require(price >= minPrice, 'price must be >= minPrice');
    require(price <= maxPrice, 'price must be <= maxPrice');

    address maker = _msgSender();
    _setOffer(maker, token, tokenId, price);
    emit OrderOffer(maker, token, tokenId, price);
  }

  struct PayoutResult {
    address payable royaltyAddress;
    uint256 royaltyFee;
    uint256 exchangeFee;
    uint256 makerAmount;
  }

  function _getPayouts(
    address token,
    uint256 tokenId,
    uint256 price
  ) internal view returns (PayoutResult memory) {
    PayoutResult memory payouts;
    try IERC721(token).royaltyInfo(tokenId, price) returns (
      address royaltyAddress,
      uint256 fee
    ) {
      payouts.royaltyAddress = payable(royaltyAddress);
      payouts.royaltyFee = fee;
    } catch {
      try IERC721(token).royaltyInfo(tokenId, price, '') returns (
        address royaltyAddress2,
        uint256 fee2,
        bytes memory
      ) {
        payouts.royaltyAddress = payable(royaltyAddress2);
        payouts.royaltyFee = fee2;
      } catch {
        payouts.royaltyFee = 0;
      }
    }
    require(price > payouts.royaltyFee, 'bad IERC2981 royalty amount');

    payouts.exchangeFee = (price * exchangeFeeBps) / 10000;
    payouts.makerAmount = price - payouts.exchangeFee - payouts.royaltyFee;
    require(payouts.makerAmount > 0, 'maker amount must be > 0');
    return payouts;
  }

  function previewPayout(
    address token,
    uint256 tokenId,
    uint256 price
  )
    public
    view
    returns (
      uint256 exchangeFee,
      uint256 royaltyFee,
      uint256 makerAmount
    )
  {
    PayoutResult memory payouts = _getPayouts(token, tokenId, price);
    return (payouts.exchangeFee, payouts.royaltyFee, payouts.makerAmount);
  }

  function checkOffer(
    address maker,
    address token,
    uint256 tokenId
  ) public view returns (uint256 price) {
    price = getOffer(maker, token, tokenId);
    require(price != 0, 'offer not found');
    require(price >= minPrice, 'price must be >= minPrice');
    require(price <= maxPrice, 'price must be <= maxPrice');
    address owner = IERC721(token).ownerOf(tokenId);
    require(owner == maker, 'owner must be maker');
    bool isApprovedForAll = IERC721(token).isApprovedForAll(
      maker,
      address(this)
    );
    bool isApproved = IERC721(token).getApproved(tokenId) == address(this);
    require(isApprovedForAll || isApproved, 'auction not approved');
    return price;
  }

  function preflightTake(
    address maker,
    address taker,
    address token,
    uint256 tokenId,
    uint256 price,
    address erc20
  ) public view {
    require(maker != taker, 'maker cant be taker');
    uint256 offerPrice = checkOffer(maker, token, tokenId);
    require(offerPrice >= price, 'price must be >= offer price');
    _getPayouts(token, tokenId, price);
    if (erc20 != address(0)) {
      uint256 balance = IERC20(erc20).balanceOf(taker);
      require(balance >= price, 'taker doesnt have enough erc20');
      uint256 allowance = IERC20(erc20).allowance(taker, address(this));
      require(allowance >= price, 'auction not approved for erc20 transfer');
    }
  }

  function _validateAndTake(
    address maker,
    address taker,
    address token,
    uint256 tokenId,
    uint256 price
  ) internal returns (PayoutResult memory) {
    require(maker != taker, 'maker cant be taker');

    uint256 offerPrice = getOffer(maker, token, tokenId);
    require(offerPrice != 0, 'offer not found');
    require(price >= offerPrice, 'price must be >= offer price');
    require(offerPrice >= minPrice, 'offer price must be >= minPrice');
    require(offerPrice <= maxPrice, 'offer price must be <= maxPrice');

    // clear offer re-entrance check
    _clearOffer(maker, token, tokenId);

    address owner = IERC721(token).ownerOf(tokenId);
    require(owner == maker, 'owner must be maker');
    PayoutResult memory payouts = _getPayouts(token, tokenId, price);
    IERC721(token).safeTransferFrom(maker, taker, tokenId);
    emit OrderTaken(maker, token, tokenId, offerPrice, taker);
    return payouts;
  }

  function _sendTokens(
    address erc20,
    address from,
    address to,
    uint256 amount
  ) internal {
    require(
      IERC20(erc20).transferFrom(from, to, amount),
      'ERC20 Transfer failed'
    );
  }

  function takeOfferUnwrapped(
    address payable maker,
    address token,
    uint256 tokenId
  ) public payable {
    require(isUnwrappedValid, 'unwrapped currency not valid');
    uint256 price = msg.value;
    address taker = _msgSender();
    PayoutResult memory payouts = _validateAndTake(
      maker,
      taker,
      token,
      tokenId,
      price
    );
    if (payouts.exchangeFee > 0) {
      exchangeFeeAddress.transfer(payouts.exchangeFee);
    }
    if (payouts.royaltyFee > 0) {
      payouts.royaltyAddress.transfer(payouts.royaltyFee);
    }
    maker.transfer(payouts.makerAmount);
  }

  function takeOffer(
    address maker,
    address token,
    uint256 tokenId,
    uint256 price,
    address erc20
  ) public {
    require(isCurrencyValid(erc20), 'invalid ERC20 currency');
    address taker = _msgSender();
    PayoutResult memory payouts = _validateAndTake(
      maker,
      taker,
      token,
      tokenId,
      price
    );
    if (payouts.exchangeFee > 0) {
      _sendTokens(erc20, taker, exchangeFeeAddress, payouts.exchangeFee);
    }
    if (payouts.royaltyFee > 0) {
      _sendTokens(erc20, taker, payouts.royaltyAddress, payouts.royaltyFee);
    }
    _sendTokens(erc20, taker, maker, payouts.makerAmount);
  }
}