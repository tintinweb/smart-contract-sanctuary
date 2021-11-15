//SPDX-License-Identifier: Unlicense
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interface/IETF.sol";
import "./interface/IPriceCalculator.sol";

contract ETFMarket is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;
    using Counters for Counters.Counter;

    struct Order {
        uint256 id;
        address holder;
        uint256 amount;
        uint256 filled;
        uint256 price;
        bool locked;
        uint256 lastUpdated;
    }

    struct Price {
        uint256 price;
        uint256 timestamp;
    }

    enum PriceStatus { LOW, NORMAL, HIGH }

    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);

    mapping(uint256 => Order) public buyOrderMap;
    mapping(uint256 => Order) public sellOrderMap;
    EnumerableSet.UintSet buyOrders;
    EnumerableSet.UintSet sellOrders;

    Counters.Counter private _orderIds;

    IERC20 public currency;
    IERC20 public etf;

    uint256 public totalSupply;
    uint256 public totalCurrencySupply;

    address public feeRecipient;
    uint256 public sellFee = 25; // 0.25%
    uint256 public buyFee = 15; // 0.15%
    uint256 public constant MAX_FEE = 10000;

    uint256 public priceMargin = 500; // 5%
    IPriceCalculator public priceCalc;

    // Price Queue
    mapping(uint256 => Price) priceQueue;
    uint256 first = 1;
    uint256 last = 0;
    uint256 public avgMinCount = 5;
    uint256 public maxQueueSize = 100;

    modifier whenETFNotPaused {
        require(IETF(address(etf)).paused() == false, "ETF maintenance");
        _;
    }

    modifier checkPrice(uint256 _price) {
        require(_checkPrice(_price) == PriceStatus.NORMAL, "expired price");
        _;
    }

    modifier checkOwner(uint256 _orderId, bool _flag) {
        _flag
            ? require(
                sellOrders.contains(_orderId) &&
                    sellOrderMap[_orderId].holder == msg.sender,
                "!available order"
            )
            : require(
                buyOrders.contains(_orderId) &&
                    buyOrderMap[_orderId].holder == msg.sender,
                "!available order"
            );
        _;
    }

    modifier checkSellOrder(uint256 _orderId) {
        require(sellOrders.contains(_orderId), "doesn't exist in sell orders");
        Order storage order = sellOrderMap[_orderId];
        require(order.holder != msg.sender, "invalid order");
        require(_checkPrice(order.price) == PriceStatus.NORMAL, "expired price");
        require(order.locked == false, "in process");
        order.locked = true;
        _;
        _enqueuePrice(order.price);
        if (order.filled == order.amount) {
            delete sellOrderMap[_orderId];
            sellOrders.remove(_orderId);
        } else {
            order.lastUpdated = block.timestamp;
        }
        order.locked = false;
    }

    modifier checkBuyOrder(uint256 _orderId) {
        require(buyOrders.contains(_orderId), "doesn't exist in buy orders");
        Order storage order = buyOrderMap[_orderId];
        require(order.holder != msg.sender, "invalid order");
        require(_checkPrice(order.price) == PriceStatus.NORMAL, "expired price");
        require(order.locked == false, "in process");
        order.locked = true;
        _;
        if (order.filled == order.amount) {
            delete buyOrderMap[_orderId];
            buyOrders.remove(_orderId);
        } else {
            order.lastUpdated = block.timestamp;
        }
        order.locked = false;
    }

    constructor(
        address _etf,
        address _currency,
        address _priceCalc,
        address _feeRecipient
    ) public {
        currency = IERC20(_currency);
        etf = IERC20(_etf);
        priceCalc = IPriceCalculator(_priceCalc);
        feeRecipient = _feeRecipient;
    }

    function orderSell(
        uint256 _amount,
        uint256 _wantPrice
    ) external whenNotPaused whenETFNotPaused {
        require(_amount > 0, "!amount");
        // Transfer etf from seller to market
        etf.safeTransferFrom(msg.sender, address(this), _amount);

        _orderIds.increment();
        uint256 orderId = _orderIds.current();
        sellOrderMap[orderId].id = orderId;
        sellOrderMap[orderId].holder = msg.sender;
        sellOrderMap[orderId].price = _wantPrice;
        sellOrderMap[orderId].amount = _amount;
        sellOrderMap[orderId].lastUpdated = block.timestamp;

        sellOrders.add(orderId);
        totalSupply += _amount;
    }

    function orderBuy(
        uint256 _amount,
        uint256 _wantPrice
    ) external whenNotPaused whenETFNotPaused {
        require(_amount > 0, "!amount");
        // Transfer fund from buyer to market
        uint256 paid = _wantPrice.mul(_amount).div(1e18);
        currency.safeTransferFrom(
            msg.sender,
            address(this),
            paid
        );

        _orderIds.increment();
        uint256 orderId = _orderIds.current();
        buyOrderMap[orderId].id = orderId;
        buyOrderMap[orderId].holder = msg.sender;
        buyOrderMap[orderId].price = _wantPrice;
        buyOrderMap[orderId].amount = _amount;
        buyOrderMap[orderId].lastUpdated = block.timestamp;

        buyOrders.add(orderId);
        totalCurrencySupply += paid;
    }

    function buy(uint256 _orderId, uint256 _amount) 
    external whenNotPaused whenETFNotPaused checkSellOrder(_orderId) {
        Order storage order = sellOrderMap[_orderId];
        if (_amount > order.amount.sub(order.filled)) _amount = order.amount.sub(order.filled);
        uint256 beforeBalance = currency.balanceOf(address(this));
        currency.safeTransferFrom(
            msg.sender,
            address(this),
            order.price.mul(_amount).div(1e18)
        );
        uint256 paid = currency.balanceOf(address(this)).sub(beforeBalance);

        // Transfer payment to sell order holder
        uint256 sellFeeAmount = paid.mul(sellFee).div(MAX_FEE);
        if (sellFeeAmount > 0) {
            paid -= sellFeeAmount;
            currency.safeTransfer(feeRecipient, sellFeeAmount);
        }
        currency.safeTransfer(order.holder, paid);

        // Transfer etf from market to buyer
        uint256 buyFeeAmount = _amount.mul(buyFee).div(MAX_FEE);
        if (buyFeeAmount > 0) {
            etf.safeTransfer(feeRecipient, buyFeeAmount);
            etf.safeTransfer(msg.sender, _amount.sub(buyFeeAmount));
        } else {
            etf.safeTransfer(msg.sender, _amount);
        }

        totalSupply = totalSupply.sub(_amount, "exceeded totaly supply");
        order.filled += _amount;
    }

    function sell(uint256 _orderId, uint256 _amount) 
    external whenNotPaused whenETFNotPaused checkBuyOrder(_orderId) {
        Order storage order = buyOrderMap[_orderId];
        if (_amount > order.amount.sub(order.filled)) _amount = order.amount.sub(order.filled);
        etf.safeTransferFrom(msg.sender, address(this), _amount);

        // Transfer payment to seller
        uint256 paid = _amount.mul(order.price).div(1e18);
        uint256 sellFeeAmount = paid.mul(sellFee).div(MAX_FEE);
        if (sellFeeAmount > 0) {
            paid -= sellFeeAmount;
            currency.safeTransfer(feeRecipient, sellFeeAmount);
        }
        currency.safeTransfer(msg.sender, paid);

        // Transfer etf from market to buy order holder
        uint256 buyFeeAmount = _amount.mul(buyFee).div(MAX_FEE);
        if (buyFeeAmount > 0) {
            etf.safeTransfer(feeRecipient, buyFeeAmount);
            etf.safeTransfer(order.holder, _amount.sub(buyFeeAmount));
        } else {
            etf.safeTransfer(order.holder, _amount);
        }

        totalCurrencySupply = totalCurrencySupply.sub(paid, "exceeded total currency supply");
        order.filled += _amount;
    }

    function updateSellOrder(uint256 _orderId, uint _price) external checkOwner(_orderId, true) {
        Order storage order = sellOrderMap[_orderId];
        require(order.locked == false, "in process");
        order.locked = true;
        order.price = _price;
        order.locked = false;
    }

    // function updateBuyOrder(uint256 _orderId, uint _price) external checkOwner(_orderId, false) {
    //     Order storage order = buyOrderMap[_orderId];
    //     require(order.locked == false, "in process");
    //     order.locked = true;
    //     order.price = _price;
    //     order.locked = false;
    // }

    function removeSellOrder(uint256 _orderId)
        external
        checkOwner(_orderId, true)
    {
        Order storage order = sellOrderMap[_orderId];
        etf.safeTransfer(msg.sender, order.amount);

        totalSupply = totalSupply.sub(order.amount, "exceeded totaly supply");
        delete sellOrderMap[_orderId];
        sellOrders.remove(_orderId);
    }

    function removeBuyOrder(uint256 _orderId)
        external
        checkOwner(_orderId, false)
    {
        Order storage order = buyOrderMap[_orderId];
        uint256 amount = order.price.mul(order.amount).div(1e18);
        totalCurrencySupply = totalCurrencySupply.sub(amount, "exceeded total currency supply");
        if (amount > currency.balanceOf(address(this)))
            amount = currency.balanceOf(address(this));
        currency.safeTransfer(msg.sender, amount);

        delete buyOrderMap[_orderId];
        buyOrders.remove(_orderId);
    }

    function sellOrderCount() external view returns (uint) {
        return sellOrders.length();
    }

    function getSellOrders() external view returns(Order[] memory) {
        Order[] memory orders = new Order[](sellOrders.length());
        for (uint i = 0; i < sellOrders.length(); i++) {
            orders[i] = sellOrderMap[sellOrders.at(i)];
        }
        return orders;
    }

    function buyOrderCount() external view returns (uint) {
        return buyOrders.length();
    }

    function getBuyOrders() external view returns(Order[] memory) {
        Order[] memory orders = new Order[](buyOrders.length());
        for (uint i = 0; i < buyOrders.length(); i++) {
            orders[i] = buyOrderMap[buyOrders.at(i)];
        }
        return orders;
    }

    function oraclePrice() public view returns (uint) {
        if (address(currency) == wbnb) {
            return IETF(address(etf)).oraclePrice();
        } else {
            uint bnbPrice = IETF(address(etf)).oraclePrice();
            (uint currencyBNBPrice,) = priceCalc.priceOf(address(currency));
            return bnbPrice.mul(1e18).div(currencyBNBPrice);
        }
    }

    function marketPrice(uint _count, uint _period) external view returns (uint avgPrice, uint sumCount, uint lastTime) {
        require(_count > 0 || _period > 0, "!parameter");

        uint basePrice = oraclePrice();
        if (last < first) return (basePrice, 0, 0);

        uint priceSum = 0;
        if (_count == 0 && _period > 0) {
            for (uint i = last; i >= first; i--) {
                Price storage price = priceQueue[i];
                if (price.timestamp < block.timestamp.sub(_period)) break;
                if (i == last) lastTime = price.timestamp;
                priceSum += _absolutedPrice(price.price, basePrice);
                sumCount++;
            }
        } else if (_count > 0 && _period == 0) {
            for (uint i = last; i >= first && sumCount <= _count; i--) {
                Price storage price = priceQueue[i];
                if (i == last) lastTime = price.timestamp;
                priceSum += _absolutedPrice(price.price, basePrice);
                sumCount++;
            }
        } else {
            for (uint i = last; i >= first && sumCount <= _count; i--) {
                Price storage price = priceQueue[i];
                if (price.timestamp < block.timestamp.sub(_period)) break;
                if (i == last) lastTime = price.timestamp;
                priceSum += _absolutedPrice(price.price, basePrice);
                sumCount++;
            }
        }

        if (sumCount == 0) return (basePrice, sumCount, 0);

        return (priceSum.div(sumCount), sumCount, lastTime);
    }

    function _absolutedPrice(uint _price, uint _basePrice) internal view returns (uint) {
        if (_price > _basePrice.mul(MAX_FEE+priceMargin).div(MAX_FEE)) {
            return _basePrice.mul(MAX_FEE+priceMargin).div(MAX_FEE);
        } else if (_price < _basePrice.mul(MAX_FEE-priceMargin).div(MAX_FEE)) {
            return _basePrice.mul(MAX_FEE-priceMargin).div(MAX_FEE);
        }
        return _price;
    }

    function _checkPrice(uint _price) internal view returns (PriceStatus) {
        if (_price < oraclePrice().mul(MAX_FEE-priceMargin).div(MAX_FEE)) {
            return PriceStatus.LOW;
        } else if (_price > oraclePrice().mul(MAX_FEE+priceMargin).div(MAX_FEE)) {
            return PriceStatus.HIGH;
        }
        return PriceStatus.NORMAL;
    }

    function _enqueuePrice(uint256 _price) internal {
        if (last > first && last.sub(first) >= maxQueueSize) {
            _dequeuePrice();
        }
        last += 1;
        priceQueue[last] = Price({price: _price, timestamp: block.timestamp});
    }

    function _dequeuePrice() internal {
        if (last < first) return;  // non-empty queue

        delete priceQueue[first];
        first += 1;
    }

    function setSellFee(uint256 _fee) external onlyOwner {
        require(_fee < MAX_FEE, "!fee");
        sellFee = _fee;
    }

    function setBuyFee(uint256 _fee) external onlyOwner {
        require(_fee < MAX_FEE, "!fee");
        buyFee = _fee;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setPriceMargin(uint256 _margin) external onlyOwner {
        require(_margin < MAX_FEE, "!margin");
        priceMargin = _margin;
    }

    function setPriceCalculator(address _priceCalc) external onlyOwner {
        priceCalc = IPriceCalculator(_priceCalc);
    }

    function setMaxQueueSize(uint256 _size) external onlyOwner {
        require(_size > 0, "!size");
        maxQueueSize = _size;
    }

    function setAvgMinCount(uint256 _count) external onlyOwner {
        require(_count > 0, "!count");
        avgMinCount = _count;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
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
abstract contract Ownable is Context {
    address private _owner;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor () internal {
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        mapping (bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

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
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IETF {
    function getAssetList() external view returns (address[] memory);
    function oraclePrice() external view returns (uint);
    function basePrice() external view returns (uint);
    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IPriceCalculator {
    function priceOf(address) external view returns(uint, uint);
    function valueOfToken(address, uint) external view returns (uint, uint);
    function valueOfLP(address, uint) external view returns (uint, uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
pragma solidity >0.6.0;

import "./ETFMarket.sol";

contract MarketFactory is Ownable {
    struct Market {
        string name;
        address market;
        uint deployed;
        bool isActive;
    }

    Market[] public markets;

    address public immutable etf;
    address public feeRecipient;
    address public priceCalc;

    constructor (
        address _etf,
        address _priceCalculator,
        address _feeRecipient
    ) public {
        etf = _etf;
        feeRecipient = _feeRecipient;
        priceCalc = _priceCalculator;
    }

    function setFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
    }

    function setPriceCalculator(address _priceCalc) external onlyOwner {
        priceCalc = _priceCalc;
    }

    function setActive(uint _id, bool _flag) external onlyOwner {
        markets[_id].isActive = _flag;
    }

    function deploy(string memory _name, address _currency) external returns (address) {
        require(msg.sender == owner(), "!owner");
        
        ETFMarket market = new ETFMarket(etf, _currency, priceCalc, feeRecipient);
        market.transferOwnership(msg.sender);
        markets.push(Market({name:_name, market:address(market), deployed:block.timestamp,isActive:true}));

        return address(market);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >0.6.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";

import "./interface/IUniswapRouter.sol";
import "./interface/IPriceCalculator.sol";

contract StarboundETF is ERC20, Ownable, Pausable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct AssetInfo {
        uint weight;
        uint decimals;
        uint txFee;
    }

    struct Pending {
        address asset;
        uint total;
        uint amount;
    }

    uint public constant DEFAULT_WEIGHT = 1e9;
    uint public constant MAX_FEE = 10000;
    uint public unwrapFee = 5; // 0.05%
    IUniswapRouter public uniswapRouter = IUniswapRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E);
    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address public keeper;
    address public feeRecipient;
    IPriceCalculator public priceCalc;

    // Base price in BNB, it might be updated a little by current market activities
    uint public immutable basePrice;

    mapping(address => AssetInfo) public assetInfo;
    EnumerableSet.AddressSet assets;

    mapping(address => Pending[]) pendings;
    mapping(address => uint) public totalPendings;
    mapping(address => uint) public totalFunds;
    mapping(address => bool) private whiteList;

    event Mint(address indexed to, uint amount);

    modifier onlyKeeper {
        require(msg.sender == owner() || msg.sender == keeper, "!permission");
        _;
    }

    modifier whiteListed {
        require(whiteList[msg.sender] == true, "!permission");
        _;
    }

    constructor (
        address _primaryAsset,
        uint _basePrice,
        address _priceCalc
    ) public ERC20 ("Starbound ETF", "sETF")
    {
        assets.add(_primaryAsset);
        assetInfo[_primaryAsset] = AssetInfo(DEFAULT_WEIGHT, ERC20(_primaryAsset).decimals(), 0);
        basePrice = _basePrice;
        priceCalc = IPriceCalculator(_priceCalc);
        keeper = msg.sender;
        feeRecipient = msg.sender;
        whiteList[msg.sender] = true;
    }

    ////////////////////////
    // Writable functions //
    ////////////////////////
    function initDeposit(uint _primaryAmount) external whenPaused onlyKeeper {
        Pending[] storage pending = pendings[msg.sender];
        
        require(pending.length > 0, "already initialized");

        pending.push(Pending(assets.at(0), _primaryAmount, 0));
        
        for (uint i = 1; i < assets.length(); i++) {
            uint amountToDeposit = _amountOfAsset(assets.at(0), assets.at(i), _primaryAmount);
            pending.push(Pending(assets.at(i), amountToDeposit, 0));
        }
    }

    function wrap() external whenPaused onlyKeeper {
        uint curPrice = oraclePrice();
        Pending[] storage pending = pendings[msg.sender];
        uint totalValue = 0;
        for (uint i = 0; i < pending.length; i++) {
            require(pending[i].amount >= pending[i].total, "Still not enough funds");

            totalValue += valueOfAsset(pending[i].asset, wbnb, pending[i].amount);
            totalPendings[pending[i].asset] -= pending[i].amount;
            totalFunds[pending[i].asset] += pending[i].amount;
            delete pending[i];
        }

        if (totalValue > 0) {
            _mintETF(msg.sender, totalValue, curPrice);
        }
        
        // Clean pendings after deposited
        delete pendings[msg.sender];
    }

    function cancel() external {
        Pending[] storage pending = pendings[msg.sender];
        for (uint i = 0; i < pending.length; i++) {
            totalPendings[pending[i].asset] -= pending[i].amount;
            IERC20(pending[i].asset).safeTransfer(msg.sender, pending[i].amount);
            delete pending[i];
        }
        delete pendings[msg.sender];
    }

    function deposit(address _asset, uint _amount) external {
        Pending[] storage pending = pendings[msg.sender];
        for (uint i = 0; i < pending.length; i++) {
            if (pending[i].asset != _asset) continue;

            require(pending[i].total > pending[i].amount, "already filled");

            uint before = IERC20(_asset).balanceOf(address(this));
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
            _amount = IERC20(_asset).balanceOf(address(this)) - before;

            uint returnBack = 0;
            if (pending[i].total - pending[i].amount < _amount) {
                returnBack = _amount.sub(pending[i].total - pending[i].amount);
                _amount = pending[i].total - pending[i].amount;
            }

            if (returnBack > 0) IERC20(_asset).safeTransfer(msg.sender, returnBack);

            pending[i].amount += _amount;
            totalPendings[_asset] += _amount;
        }
    }

    function unwrap(uint _amount) external whenNotPaused whiteListed {
        require(balanceOf(msg.sender) > 0, "no funds");

        if (_amount > balanceOf(msg.sender)) _amount = balanceOf(msg.sender);

        for (uint i = 0; i < assets.length(); i++) {
            address asset = assets.at(i);
            uint amountToRelease = totalFunds[asset].mul(_amount).div(totalSupply());
            uint curBal = IERC20(asset).balanceOf(address(this));
            if (amountToRelease > curBal) amountToRelease = curBal;
            
            uint feeAmount = amountToRelease.mul(unwrapFee).div(MAX_FEE);
            if (feeAmount > 0 && whiteList[msg.sender] == false) {
                IERC20(asset).safeTransfer(feeRecipient, feeAmount);
                IERC20(asset).safeTransfer(msg.sender, amountToRelease.sub(feeAmount));
            } else {
                IERC20(asset).safeTransfer(msg.sender, amountToRelease);
            }

            totalFunds[asset] -= amountToRelease;
        }

        _burn(msg.sender, _amount);
    }

    function _mintETF(address _to, uint _bnbAmount, uint _price) internal {
        uint amount = _bnbAmount.mul(1e18).div(_price);
        _mint(_to, amount);

        emit Mint(_to, amount);
    }

    function _transfer(address _from, address _to, uint _amount) internal override whenNotPaused {
        super._transfer(_from, _to, _amount);
    }

    ////////////////////////
    // View functions //////
    ////////////////////////
    function valueOfAsset(address _from, address _to, uint _amount) public view returns (uint) {
        (uint bnbPriceOfFrom,) = priceCalc.priceOf(_from);
        (uint bnbPriceOfTo,) = priceCalc.priceOf(_to);
        return _amount.mul(bnbPriceOfFrom).div(bnbPriceOfTo);
    }

    function marketPrice() public view returns (uint) {
        return basePrice;
    }

    function oraclePrice() public view returns (uint) {
        uint totalValue = 0;
        for (uint i = 0; i < assets.length(); i++) {
            address asset = assets.at(i);
            totalValue += valueOfAsset(asset, wbnb, totalFunds[asset]);
        }
        return totalSupply() == 0 ? basePrice : totalValue.mul(1e18).div(totalSupply());
    }

    function pendingOf(address _user) external view returns (Pending[] memory pendingData) {
        Pending[] storage pending = pendings[_user];
        pendingData = new Pending[](pending.length);
        for (uint i = 0; i < pending.length; i++) {
            pendingData[i] = pending[i];
        }
    }

    function fundOf(address _user, address _asset) external view returns (uint) {
        if (totalSupply() == 0) return 0;
        return totalFunds[_asset].mul(balanceOf(_user)).div(totalSupply());
    }

    function calculateFundsLayout(address _asset, uint _amount, bool _flag) external view returns (uint newPrice, uint newWeight) {
        if (!assets.contains(_asset)) return (basePrice, 0);
        if (totalSupply() == 0) return (basePrice, assetInfo[_asset].weight);

        uint totalValue = 0;
        for (uint i = 0; i < assets.length(); i++) {
            uint fund = totalFunds[assets.at(i)];
            if (_asset == assets.at(i)) {
                if (_flag == true) {
                    newWeight = assetInfo[_asset].weight.add(assetInfo[_asset].weight.mul(_amount).div(fund));
                    fund += _amount;
                } else {
                    newWeight = fund < _amount ? 0 : assetInfo[_asset].weight.sub(assetInfo[_asset].weight.mul(_amount).div(fund));
                    fund = fund > _amount ? fund.sub(_amount) : 0;
                }
            }
            totalValue += valueOfAsset(assets.at(i), wbnb, fund);
        }
        newPrice = totalValue.mul(1e18).div(totalSupply());
    }

    function getAssetList() external view returns (address[] memory) {
        address[] memory assetList = new address[](assets.length());
        for (uint i = 0; i < assets.length(); i++) {
            assetList[i] = assets.at(i);
        }

        return assetList;
    }

    ////////////////////////
    // Internal functions //
    ////////////////////////
    function _amountOfAsset(address _from, address _to, uint _amount) internal view returns (uint) {
        return valueOfAsset(_from, _to, _amount).mul(assetInfo[_to].weight).div(assetInfo[_from].weight);
    }

    //////////////////////
    // Admin operations //
    //////////////////////
    function updateFundsLayout(address _asset, uint _amount, bool _flag) external whenPaused onlyKeeper {
        require(assets.contains(_asset), "invalid asset");
        uint decimals = ERC20(_asset).decimals();
        if (decimals > 9) require(_amount > 10**(decimals-9), "too small amount");

        uint before = IERC20(_asset).balanceOf(address(this));

        if (_flag == true) {
            // Deposit
            IERC20(_asset).safeTransferFrom(msg.sender, address(this), _amount);
            _amount = IERC20(_asset).balanceOf(address(this)) - before;

            assetInfo[_asset].weight += assetInfo[_asset].weight.mul(_amount).div(totalFunds[_asset]);
            totalFunds[_asset] += _amount;
        } else {
            // Withdraw
            require(totalFunds[_asset] > 0 && before > 0, "no fund");

            if (totalFunds[_asset] < _amount) _amount = totalFunds[_asset];
            if (before < _amount) _amount = before;
            IERC20(_asset).safeTransfer(msg.sender, _amount);

            assetInfo[_asset].weight -= assetInfo[_asset].weight.mul(_amount).div(totalFunds[_asset]);
            totalFunds[_asset] -= _amount;
        }
    }

    // It should be called before funding from users at the first
    function addAsset(address _token, uint _weight) external onlyOwner {
        require(assets.contains(_token) == false, "already existing asset");
        assets.add(_token);
        assetInfo[_token] = AssetInfo(_weight, 18, 0);
    }

    function setAssetWeight(address _asset, uint _weight) external onlyOwner {
        require(totalSupply() == 0, "already supplied");
        assetInfo[_asset].weight = _weight;
    }

    function setAssetDecimals(address _asset, uint _decimals) external onlyOwner {
        assetInfo[_asset].decimals = _decimals;
    }

    function setAssetTxFee(address _asset, uint _fee) external onlyOwner {
        assetInfo[_asset].txFee = _fee;
    }

    function setUniswapRouter(address _router) external onlyOwner {
        uniswapRouter = IUniswapRouter(_router);
    }

    function setPriceCalculator(address _priceCalc) external onlyOwner {
        priceCalc = IPriceCalculator(_priceCalc);
    }

    function setKeeper(address _keeper) external onlyOwner {
        keeper = _keeper;
        whiteList[_keeper] = true;
    }

    function setFeeRecipient(address _recipient) external onlyOwner {
        feeRecipient = _recipient;
    }

    function setUnwrapFee(uint _fee) external onlyOwner {
        require(_fee < MAX_FEE, "!fee");
        unwrapFee = _fee;
    }

    function setWhiteList(address _user, bool _flag) external onlyOwner {
        whiteList[_user] = _flag;
    }

    function pause() external onlyKeeper {
        _pause();
    }

    function unpause() external onlyKeeper {
        _unpause();
    }

    function emergencyWithdraw(address _token, uint256 _amount) external onlyOwner {
        uint256 _bal = IERC20(_token).balanceOf(address(this));
        if (_amount > _bal) _amount = _bal;

        IERC20(_token).safeTransfer(msg.sender, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

interface IUniswapRouter {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function swapExactTokensForTokens(
        uint amountIn, 
        uint amountOutMin, 
        address[] calldata path, 
        address to, 
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    function getAmountsOut(
      uint amountIn,
      address[] memory path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
      uint amountOut,
      address[] memory path
    ) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interface/IPriceCalculator.sol";
import "./interface/IUniswapRouter.sol";
import "./interface/IUniswapPair.sol";
import "./interface/IAggregatorV3.sol";

contract PriceCalculator is IPriceCalculator, Ownable {
    using EnumerableSet for EnumerableSet.AddressSet;
    using SafeMath for uint256;

    struct PriceInfo {
        uint256 bnbPrice;
        uint256 usdPrice;
        uint256 lastUpdated;
    }

    address constant public eth = address(0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619);
    address constant public wbnb = address(0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c);
    address constant public usdt = address(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

    mapping(address => address) public tokenFeeds;

    address public unirouter = address(0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff);

    bool public isManualMode = false;
    mapping(address => PriceInfo) public prices;

    modifier checkManualMode {
        require(isManualMode == true, "Should be manual mode");
        _;
    }

    /**
     * @dev Updates router that will be used for swaps.
     * @param _unirouter new unirouter address.
     */
    function setUnirouter(address _unirouter) external onlyOwner {
        unirouter = _unirouter;
    }

    function setTokenFeed(address asset, address feed) public onlyOwner {
        tokenFeeds[asset] = feed;
    }

    function priceOf(address _token) public override view returns (uint bnbPrice, uint usdPrice) {
        if (tokenFeeds[wbnb] != address(0) && tokenFeeds[_token] != address(0)) {
            (, int256 _usdPrice, , ,) = IAggregatorV3(tokenFeeds[_token]).latestRoundData();
            (, int256 _bnbPrice, , ,) = IAggregatorV3(tokenFeeds[wbnb]).latestRoundData();
            usdPrice = uint256(_usdPrice).mul(1e10);
            bnbPrice = usdPrice.mul(1e8).div(uint256(_bnbPrice));
        } else {
            uint _decimal = ERC20(_token).decimals() - 2;
            uint _padding = 10 ** 14; // USDT decimals is 6
            if (_token == wbnb) {
                bnbPrice = 1 ether;
                address[] memory route = new address[](2);
                route[0] = _token; route[1] = usdt;
                usdPrice = IUniswapRouter(unirouter).getAmountsOut(uint256(10 ** _decimal), route)[1] * _padding;
            } else if (_token == usdt) {
                usdPrice = 1 ether;
                address[] memory route = new address[](2);
                route[0] = _token; route[1] = wbnb;
                bnbPrice = IUniswapRouter(unirouter).getAmountsOut(uint256(10 ** _decimal), route)[1] * 1e2;
            } else {
                address[] memory route0 = new address[](2);
                route0[0] = _token; route0[1] = wbnb;
                address[] memory route1 = new address[](3);
                route1[0] = _token; route1[1] = eth; route1[2] = usdt;
                bnbPrice = IUniswapRouter(unirouter).getAmountsOut(uint256(10 ** _decimal), route0)[1] * 1e2;
                usdPrice = IUniswapRouter(unirouter).getAmountsOut(uint256(10 ** _decimal), route1)[2] * _padding;
            }
        }
    }

    function valueOfToken(address _token, uint _amount) public view override returns (uint bnbAmount, uint usdAmount) {
        if (isManualMode == true && !(tokenFeeds[wbnb] != address(0) && tokenFeeds[_token] != address(0))) {
            bnbAmount = _amount * prices[_token].bnbPrice / 1e18;
            usdAmount = _amount * prices[_token].usdPrice / 1e18;
        } else {
            (bnbAmount, usdAmount) = _valueOfToken(_token, _amount);
        }
    }

    function valueOfLP(address _token, uint _amount) public view override returns (uint bnbAmount, uint usdAmount) {
        if (isManualMode == false) {
            (bnbAmount, usdAmount) = _valueOfLP(_token, _amount);
        } else {
            bnbAmount = _amount * prices[_token].bnbPrice / 1e18;
            usdAmount = _amount * prices[_token].usdPrice / 1e18;
        }
    }

    function _valueOfToken(address _token, uint _amount) internal view returns (uint bnbAmount, uint usdAmount) {
        (uint256 _bnbPrice,uint256 _usdPrice) = priceOf(_token);
        bnbAmount = _amount * _bnbPrice / 1e18;
        usdAmount = _amount * _usdPrice / 1e18;
    }

    function _valueOfLP(address _token, uint _amount) internal view returns (uint bnbAmount, uint usdAmount) {
        IUniswapPair _lp = IUniswapPair(_token);
        address _token0 = _lp.token0();
        uint diffDecimals = 18 - ERC20(_token0).decimals();
        (uint256 _reserve0,,) = _lp.getReserves();
        (uint256 _bnbPrice,uint256 _usdPrice) = priceOf(_token0);
        bnbAmount = 2 * _amount * _bnbPrice * _reserve0 / _lp.totalSupply() / 1e18 * 10**diffDecimals;
        usdAmount = 2 * _amount * _usdPrice * _reserve0 / _lp.totalSupply() / 1e18 * 10**diffDecimals;
    }

    function setTokenPrice(address _token, uint256 _bnbPrice, uint256 _usdPrice) external checkManualMode {
        prices[_token].bnbPrice = _bnbPrice;
        prices[_token].usdPrice = _usdPrice;
        prices[_token].lastUpdated = block.timestamp;
    }

    function updateTokenPrice(address _token, bool _isLP) external checkManualMode {
        uint256 _bnbPrice = 0;
        uint256 _usdPrice = 0;
        if (_isLP == true) {
            (_bnbPrice, _usdPrice) = _valueOfLP(_token, uint256(1 ether));
        } else {
            (_bnbPrice, _usdPrice) = _valueOfToken(_token, uint256(1 ether));
        }

        prices[_token].bnbPrice = _bnbPrice;
        prices[_token].usdPrice = _usdPrice;
        prices[_token].lastUpdated = block.timestamp;
    }

    function setManualMode(bool _mode) external {
        isManualMode = _mode;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IUniswapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IAggregatorV3 {

  function decimals() external view returns (uint8);
  function description() external view returns (string memory);
  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

