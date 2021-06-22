/**
 *Submitted for verification at Etherscan.io on 2021-06-21
*/

pragma solidity ^0.8.3;

// SPDX-License-Identifier: MIT
interface IERC2981 {
  function royaltyInfo(uint256 _tokenId, uint256 _value)
    external
    view
    returns (address _receiver, uint256 _royaltyAmount);
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);
}

interface IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
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

library Address {
  function isContract(address account) internal view returns (bool) {
    // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
    // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
    // for accounts without code, i.e. `keccak256('')`
    bytes32 codehash;


      bytes32 accountHash
     = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      codehash := extcodehash(account)
    }
    return (codehash != accountHash && codehash != 0x0);
  }
}

library Counters {
  using SafeMath for uint256;

  struct Counter {
    uint256 _value; // default: 0
  }

  function current(Counter storage counter) internal view returns (uint256) {
    return counter._value;
  }

  function increment(Counter storage counter) internal {
    counter._value += 1;
  }

  function decrement(Counter storage counter) internal {
    counter._value = counter._value.sub(1);
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
  using Address for address;

  // maker => token address => tokenId => price
  mapping(address => mapping(address => mapping(uint256 => uint256)))
    private _priceByMakerTokenTokenId;

  uint256 public minPrice;
  uint256 public maxPrice;
  uint256 public exchangeFeeBps;
  address payable public exchangeFeeAddress;
  mapping(address => bool) private _validCurrencies;
  bool public isUnwrappedValid = false;
  address payable private _creator;

  constructor(
    uint256 min,
    uint256 max,
    uint256 fee,
    address payable feeAddress
  ) {
    _creator = payable(_msgSender());
    minPrice = min;
    maxPrice = max;
    exchangeFeeBps = fee;
    exchangeFeeAddress = feeAddress;
  }

  function setUnwrappedValid(bool valid) public onlyAdmin {
    isUnwrappedValid = valid;
  }

  function setCurrencyValid(address erc20, bool valid) public onlyAdmin {
    _validCurrencies[erc20] = valid;
  }

  function setMaxPrice(uint256 price) public onlyAdmin {
    maxPrice = price;
  }

  function setMinPrice(uint256 price) public onlyAdmin {
    minPrice = price;
  }

  function setExchangeFeeBps(uint256 fee) public onlyAdmin {
    exchangeFeeBps = fee;
  }

  function setExchangeAddress(address payable feeAddress) public onlyAdmin {
    exchangeFeeAddress = feeAddress;
  }

  function withdraw(uint256 amount) public onlyAdmin {
    payable(_creator).transfer(amount);
  }

  function withdrawToken(address token, uint256 amount) public onlyAdmin {
    IERC20(token).transfer(_creator, amount);
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

  function _calcPayouts(
    address token,
    uint256 tokenId,
    uint256 price
  ) internal view returns (PayoutResult memory) {
    PayoutResult memory result;
    try IERC2981(token).royaltyInfo(tokenId, price) returns (
      address royaltyAddress,
      uint256 fee
    ) {
      result.royaltyAddress = payable(royaltyAddress);
      result.royaltyFee = fee;
    } catch {
      // noop
    }
    require(result.royaltyFee < price, 'bad IERC2981 royalty amount');

    result.exchangeFee = (price * exchangeFeeBps) / 10000;
    result.makerAmount = price - result.exchangeFee - result.royaltyFee;
    require(result.royaltyFee >= 0, 'bad royalty amount');
    require(result.makerAmount > 0, 'makerAmount must be > 0');
    return result;
  }

  function _validateAndTake(
    address maker,
    address taker,
    address token,
    uint256 tokenId,
    uint256 price
  ) internal returns (PayoutResult memory) {
    require(price >= minPrice, 'price must be >= minPrice');
    require(price <= maxPrice, 'price must be <= maxPrice');

    uint256 offerPrice = getOffer(maker, token, tokenId);
    require(price >= offerPrice, 'price must be >= offerPrice');
    require(offerPrice >= minPrice, 'price must be >= minPrice');
    require(offerPrice <= maxPrice, 'price must be <= maxPrice');
    PayoutResult memory payouts = _calcPayouts(token, tokenId, offerPrice);

    // clear offer re-entrance check
    _clearOffer(maker, token, tokenId);
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
    require(isUnwrappedValid, 'Unwrapped currency not valid');
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
    require(isCurrencyValid(erc20), 'Invalid ERC20 currency');
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