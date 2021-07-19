//SourceUnit: Context.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


//SourceUnit: ITRC20.sol

pragma solidity 0.6.0;

interface ITRC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() external view returns (uint8);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

//SourceUnit: OrderBook.sol

pragma solidity 0.6.0;

import "./SafeMath.sol";
import "./ITRC20.sol";
import "./TokenInfo.sol";
import "./Ownable.sol";

contract OrderBook is TokenInfo, Ownable {

  using SafeMath for uint256;

  address _baseCurrencyAddress;
  address _quoteCurrencyAddress;

  uint maxBaseAsset;
  uint maxBaseValue;
  uint minBaseAsset;
  uint minBaseValue;

  uint maxQuoteAsset;
  uint maxQuoteValue;
  uint minQuoteAsset;
  uint minQuoteValue;

  uint minSellPrice;
  uint maxSellPrice;
  uint minBuyPrice;
  uint maxBuyPrice;

  uint48 constant maxAmount = uint48(-1);

  uint _baseCurrencyUnit; // real amount = (amount in contract) * (base unit)
  uint _quoteCurrencyUnit;
  uint _priceDivisor; // real price = (price in contract) / (price divisor)
  uint _quoteDivisor;
  uint _baseDivisor;

  constructor(
    address baseCurrencyAddress,
    address quoteCurrencyAddress,
    uint baseCurrencyUnit,
    uint quoteCurrencyUnit,
    uint priceDivisor
  ) public {
    _baseCurrencyAddress = baseCurrencyAddress;
    _quoteCurrencyAddress = quoteCurrencyAddress;

    _baseCurrencyUnit = baseCurrencyUnit;
    _quoteCurrencyUnit = quoteCurrencyUnit;

    _priceDivisor = priceDivisor;
    (,,uint baseDecimals,) = baseCurrencyInfo();
    (,,uint quoteDecimals,) = baseCurrencyInfo();
    _baseDivisor  = 10**baseDecimals;
    _quoteDivisor = 10**quoteDecimals;

    maxBaseAsset = exactBaseAmount(maxAmount);
    maxBaseValue = exactBaseAmount(maxAmount);
    minBaseAsset = exactBaseAmount(1);
    minBaseValue = exactBaseAmount(1);

    maxQuoteAsset = exactQuoteAmount(maxAmount);
    maxQuoteValue = exactQuoteAmount(maxAmount);
    minQuoteAsset = exactQuoteAmount(1);
    minQuoteValue = exactQuoteAmount(1);

    minSellPrice = 1;
    maxSellPrice = uint(-1).div(exactQuoteAmount(maxAmount)).div(_baseDivisor);
    minBuyPrice = 1;
    maxBuyPrice = uint(-1).div(exactQuoteAmount(maxAmount)).div(_baseDivisor);

  }

  function setLimitSellRanges(
    uint minAsset,
    uint maxAsset,
    uint minValue,
    uint maxValue,
    uint minPrice,
    uint maxPrice
  ) public onlyOwner {
    require(minAsset < maxAsset, "minAsset should be less than maxAsset");
    require(minValue < maxValue, "minValue should be less than maxValue");
    require(minPrice < maxPrice, "minPrice should be less than maxPrice");
    require(minAsset >= exactBaseAmount(1), "minAsset too high");
    require(maxAsset <= exactBaseAmount(maxAmount), "maxAsset too high");
    require(minValue >= exactQuoteAmount(1), "minValue too high");
    require(maxValue <= exactQuoteAmount(maxAmount), "maxValue too high");
    require(minPrice > 0, "minPrice too low");
    require(maxPrice <= uint(-1).div(exactQuoteAmount(maxAmount)).div(_baseDivisor), "maxPrice too high");
    if(minAsset > 0 && minAsset != minBaseAsset) minBaseAsset = minAsset;
    if(maxAsset > 0 && maxAsset != maxBaseAsset) maxBaseAsset = maxAsset;
    if(minValue > 0 && minValue != minQuoteValue) minQuoteValue = minValue;
    if(maxValue > 0 && maxValue != maxQuoteValue) maxQuoteValue = maxValue;
    if(minPrice > 0 && minPrice != minSellPrice) minSellPrice = minPrice;
    if(maxPrice > 0 && maxPrice != maxSellPrice) maxSellPrice = maxPrice;
  }

  function setLimitBuyRanges(
    uint minAsset,
    uint maxAsset,
    uint minValue,
    uint maxValue,
    uint minPrice,
    uint maxPrice
  ) public onlyOwner {
    require(minAsset < maxAsset, "minAsset should be less than maxAsset");
    require(minValue < maxValue, "minValue should be less than maxValue");
    require(minPrice < maxPrice, "minPrice should be less than maxPrice");
    require(minAsset >= exactQuoteAmount(1), "minAsset too high");
    require(maxAsset <= exactQuoteAmount(maxAmount), "maxAsset too high");
    require(minValue >= exactBaseAmount(1), "minValue too high");
    require(maxValue <= exactBaseAmount(maxAmount), "maxValue too high");
    require(minPrice > 0, "minPrice too low");
    require(maxPrice <= uint(-1).div(exactQuoteAmount(maxAmount)).div(_baseDivisor), "maxPrice too high");
    if(minValue > 0 && minValue != minBaseValue) minBaseValue = minValue;
    if(maxValue > 0 && maxValue != maxBaseValue) maxBaseValue = maxValue;
    if(minAsset > 0 && minAsset != minQuoteAsset) minQuoteAsset = minAsset;
    if(maxAsset > 0 && maxAsset != maxQuoteAsset) maxQuoteAsset = maxAsset;
    if(minPrice > 0 && minPrice != minBuyPrice) minBuyPrice = minPrice;
    if(maxPrice > 0 && maxPrice != maxBuyPrice) maxBuyPrice = maxPrice;
  }

  function numberSettings() public view returns (
    uint baseCurrencyUnit,
    uint quoteCurrencyUnit,
    uint priceDivisor,
    uint quoteDivisor,
    uint baseDivisor
  ){
    baseCurrencyUnit = _baseCurrencyUnit;
    quoteCurrencyUnit = _quoteCurrencyUnit;
    priceDivisor = _priceDivisor;
    quoteDivisor = _quoteDivisor;
    baseDivisor = _baseDivisor;
  }

  function rangeSettings() public view returns (
    uint _maxBaseAsset,
    uint _maxBaseValue,
    uint _minBaseAsset,
    uint _minBaseValue,
    uint _maxQuoteAsset,
    uint _maxQuoteValue,
    uint _minQuoteAsset,
    uint _minQuoteValue,
    uint _minSellPrice,
    uint _maxSellPrice,
    uint _minBuyPrice,
    uint _maxBuyPrice
  ){
    _maxBaseAsset = maxBaseAsset;
    _maxBaseValue = maxBaseValue;
    _minBaseAsset = minBaseAsset;
    _minBaseValue = minBaseValue;
    _maxQuoteAsset = maxQuoteAsset;
    _maxQuoteValue = maxQuoteValue;
    _minQuoteAsset = minQuoteAsset;
    _minQuoteValue = minQuoteValue;
    _minSellPrice = minSellPrice;
    _maxSellPrice = maxSellPrice;
    _minBuyPrice = minBuyPrice;
    _maxBuyPrice = maxBuyPrice;
  }

  function _currencyInfo(address addr) private view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) {
    if(addr == address(0)) {
      name = "Tron";
      symbol = "TRX";
      decimals = 6;
      tokenAddress = address(0);
    } else
    return _tokenInfo(ITRC20(addr));
  }

  function baseCurrencyInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _currencyInfo(_baseCurrencyAddress);}
  function quoteCurrencyInfo() public view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) { return _currencyInfo(_quoteCurrencyAddress);}

  function baseCurrencyIsTRC20() internal view returns (bool) { return _baseCurrencyAddress == address(0); }
  function quoteCurrencyIsTRC20() internal view returns (bool) { return _quoteCurrencyAddress == address(0); }

  struct LimitOrder {
    uint48 asset; // то, что
    uint48 value;
    address trader;
  }

  function internalBaseAmount(uint exactAmount) private view returns (uint48) {
    return uint48(exactAmount.div(_baseCurrencyUnit));
  }

  function internalQuoteAmount(uint exactAmount) private view returns (uint48) {
    return uint48(exactAmount.div(_quoteCurrencyUnit));
  }

  function exactBaseAmount(uint48 internalAmount) private view returns (uint) {
    return uint(internalAmount).mul(_baseCurrencyUnit);
  }

  function exactQuoteAmount(uint48 internalAmount) private view returns (uint) {
    return uint(internalAmount).mul(_quoteCurrencyUnit);
  }

  mapping(uint => LimitOrder) sell;
  mapping(uint => LimitOrder) buy;

  uint public lastOrder;

  event LimitSell(uint id, address trader, uint asset, uint value);

  function limitSell(uint asset, uint value) public payable {
    if(baseCurrencyIsTRC20())
      asset = msg.value;
    else
      require(msg.value == 0, "Cannot accept TRX");
    require(asset.mod(_baseCurrencyUnit) == 0, "Asset is not a multiple of base unit");
    require(value.mod(_quoteCurrencyUnit) == 0, "Value is not a multiple of quote unit");
    require(asset >= minBaseAsset, "Asset too low");
    require(asset <= maxBaseAsset, "Asset too high");
    require(value >= minQuoteValue, "Value too low");
    require(value <= maxQuoteValue, "Value too high");

    /* minSellPrice    value   _quoteDivisor      maxSellPrice
      ------------- <= ----- * -------------- <= -------------
      _priceDivisor    asset    _baseDivisor     _priceDivisor */

    require(asset.mul(minSellPrice).mul(_baseDivisor) <= value.mul(_priceDivisor).mul(_quoteDivisor), "Price too low");
    require(asset.mul(maxSellPrice).mul(_baseDivisor) >= value.mul(_priceDivisor).mul(_quoteDivisor), "Price too high");

    if(!baseCurrencyIsTRC20())
      ITRC20(_baseCurrencyAddress).transferFrom(msg.sender, address(this), asset);

    lastOrder++;
    sell[lastOrder] = LimitOrder(internalBaseAmount(asset), internalQuoteAmount(value), msg.sender);
    emit LimitSell(lastOrder, msg.sender, asset, value);
  }

  event LimitBuy(uint id, address trader, uint asset, uint value);

  function limitBuy(uint asset, uint value) public payable {
    if(quoteCurrencyIsTRC20())
      asset = msg.value;
    else
      require(msg.value == 0, "Cannot accept TRX");
    require(asset.mod(_quoteCurrencyUnit) == 0, "Asset is not a multiple of quote unit");
    require(value.mod(_baseCurrencyUnit) == 0, "Value is not a multiple of base unit");
    require(asset >= minQuoteAsset, "Asset too low");
    require(asset <= maxQuoteAsset, "Asset too high");
    require(value >= minBaseValue, "Value too low");
    require(value <= maxBaseValue, "Value too high");

    /* minBuyPrice     asset   _quoteDivisor     maxBuyPrice
       ------------ <= ----- * -------------- <= ------------
      _priceDivisor    value    _baseDivisor    _priceDivisor */

    require(value.mul(minBuyPrice).mul(_baseDivisor) <= asset.mul(_priceDivisor).mul(_quoteDivisor), "Price too low");
    require(value.mul(maxBuyPrice).mul(_baseDivisor) >= asset.mul(_priceDivisor).mul(_quoteDivisor), "Price too high");

    if(!quoteCurrencyIsTRC20())
      ITRC20(_quoteCurrencyAddress).transferFrom(msg.sender, address(this), asset);

    lastOrder++;
    buy[lastOrder] = LimitOrder(internalQuoteAmount(asset), internalBaseAmount(value), msg.sender);
    emit LimitBuy(lastOrder, msg.sender, asset, value);
  }

  function sendBaseCurrency(address recipient, uint amount) private {
    if(baseCurrencyIsTRC20()) {
      payable(recipient).transfer(amount);
    } else {
      ITRC20(_baseCurrencyAddress).transfer(recipient, amount);
    }
  }

  function sendQuoteCurrency(address recipient, uint amount) private {
    if(quoteCurrencyIsTRC20()) {
      payable(recipient).transfer(amount);
    } else {
      ITRC20(_quoteCurrencyAddress).transfer(recipient, amount);
    }
  }

  event Cancel(uint id);

  function cancelBuyOrder(uint id) public {
    LimitOrder storage order = buy[id];
    require(order.trader != address(0), "Order not found");
    require(order.trader == msg.sender, "You cannot cancel someone else's order");
    sendQuoteCurrency(order.trader, exactQuoteAmount(order.asset));
    delete buy[id];
    lastOperation++;
    emit Cancel(id);
  }

  function cancelSellOrder(uint id) public {
    LimitOrder storage order = sell[id];
    require(order.trader != address(0), "Order not found");
    require(order.trader == msg.sender, "You cannot cancel someone else's order");
    sendBaseCurrency(order.trader, exactBaseAmount(order.asset));
    delete sell[id];
    lastOperation++;
    emit Cancel(id);
  }

  uint public lastOperation;

  event Close(uint id);

  event MarketSell(address seller, uint asset, uint value);

  function marketSellSafe(uint asset, uint[] memory ids, uint lastSeenOperation) public payable {
    require(lastSeenOperation == lastOperation, "Market has been changed");
    marketSell(asset, ids);
  }

  function marketSell(uint asset, uint[] memory ids) public payable {
    if(baseCurrencyIsTRC20()) {
      asset = msg.value;
      require(asset >= _baseCurrencyUnit, "Asset too low");
    } else {
      require(msg.value == 0, "Cannot accept TRX");
      require(asset >= _baseCurrencyUnit, "Asset too low");
      ITRC20(_baseCurrencyAddress).transferFrom(msg.sender, address(this), asset);
    }
    uint _asset = asset;
    uint gain = 0;
    for (uint256 i = 0; i < ids.length; i++) {
      LimitOrder storage order = buy[ids[i]];
      uint48 order_value = order.value;
      uint48 order_asset = order.asset;
      address buyer = order.trader;
      if(buyer == address(0) || order_value == 0 || order_asset == 0) continue;
      if(internalBaseAmount(_asset) >= order_value) {
        _asset = _asset.sub(exactBaseAmount(order_value));
        sendBaseCurrency(buyer, exactBaseAmount(order_value));
        gain = gain.add(exactQuoteAmount(order_asset));
        delete buy[ids[i]];
        emit Close(ids[i]);
        if(_asset < _baseCurrencyUnit) break;
      } else {
        // new_order_value = order_value - asset
        // order_value / order_asset == new_order_value / new_order_asset
        // new_order_asset = new_order_value * order_asset / order_value

        uint new_order_value = order_value - internalBaseAmount(_asset);
        uint new_order_asset = new_order_value * order_asset / order_value;

        if(new_order_asset == 0) {
          sendBaseCurrency(buyer, exactBaseAmount(order_value));
          gain = gain.add(exactQuoteAmount(order_asset));
          delete buy[ids[i]];
          emit Close(ids[i]);
        } else {
          sendBaseCurrency(buyer, exactBaseAmount(internalBaseAmount(_asset)));
          gain = gain.add(exactQuoteAmount(order_asset - uint48(new_order_asset)));
          order.asset = uint48(new_order_asset);
          order.value = uint48(new_order_value);
          emit LimitBuy(ids[i], buyer, new_order_asset, new_order_value);
        }
        _asset = 0;
        break;
      }
    }
    if(gain > 0) sendQuoteCurrency(msg.sender, gain);
    if(_asset > 0) sendBaseCurrency(msg.sender, _asset);
    if(gain > 0) emit MarketSell(msg.sender, asset - _asset, gain);
    lastOperation++;
  }

  event MarketBuy(address buyer, uint asset, uint value);

  function marketBuySafe(uint asset, uint[] memory ids, uint lastSeenOperation) public payable {
    require(lastSeenOperation == lastOperation, "Market has been changed");
    marketBuy(asset, ids);
  }

  function marketBuy(uint asset, uint[] memory ids) public payable {
    if(quoteCurrencyIsTRC20()) {
      asset = msg.value;
      require(asset >= _quoteCurrencyUnit, "Asset too low");
    } else {
      require(msg.value == 0, "Cannot accept TRX");
      require(asset >= _quoteCurrencyUnit, "Asset too low");
      ITRC20(_quoteCurrencyAddress).transferFrom(msg.sender, address(this), asset);
    }
    uint _asset = asset;
    uint gain = 0;
    for (uint256 i = 0; i < ids.length; i++) {
      LimitOrder storage order = sell[ids[i]];
      uint48 order_value = order.value;
      uint48 order_asset = order.asset;
      address seller = order.trader;
      if(seller == address(0) || order_value == 0 || order_asset == 0) continue;
      if(internalQuoteAmount(_asset) >= order_value) {
        _asset = _asset.sub(exactQuoteAmount(order_value));
        sendQuoteCurrency(seller, exactQuoteAmount(order_value));
        gain = gain.add(exactBaseAmount(order_asset));
        delete sell[ids[i]];
        emit Close(ids[i]);
        if(_asset < _quoteCurrencyUnit) break;
      } else {
        // new_order_value = order_value - asset
        // order_value / order_asset == new_order_value / new_order_asset
        // new_order_asset = new_order_value * order_asset / order_value

        uint new_order_value = order_value - internalQuoteAmount(_asset);
        uint new_order_asset = new_order_value * order_asset / order_value;

        if(new_order_asset == 0) {
          sendQuoteCurrency(seller, exactQuoteAmount(order_value));
          gain = gain.add(exactBaseAmount(order_asset));
          delete sell[ids[i]];
          emit Close(ids[i]);
        } else {
          sendQuoteCurrency(seller, exactQuoteAmount(internalQuoteAmount(_asset)));
          gain = gain.add(exactBaseAmount(order_asset - uint48(new_order_asset)));
          order.asset = uint48(new_order_asset);
          order.value = uint48(new_order_value);
          emit LimitSell(ids[i], seller, new_order_asset, new_order_value);
        }
        _asset = 0;
        break;
      }
    }
    if(gain > 0) sendBaseCurrency(msg.sender, gain);
    if(_asset > 0) sendQuoteCurrency(msg.sender, _asset);
    if(gain > 0) emit MarketBuy(msg.sender, asset - _asset, gain);
    lastOperation++;
  }

  function checksum() public view returns (bytes32) {
    return keccak256(abi.encodePacked((lastOperation << 128) + lastOrder));
  }

}

//SourceUnit: Ownable.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./Context.sol";
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
contract Ownable is Context {
    address private _owner;
    uint96 private _;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


//SourceUnit: TokenInfo.sol

pragma solidity 0.6.0;

import "./ITRC20.sol";

contract TokenInfo {
  function _tokenInfo(ITRC20 token) internal view returns (string memory name, string memory symbol, uint decimals, address tokenAddress ) {
    name = token.name();
    symbol = token.symbol();
    decimals = token.decimals();
    tokenAddress = address(token);
  }
}