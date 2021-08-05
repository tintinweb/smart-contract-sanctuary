/**
 *Submitted for verification at Etherscan.io on 2021-01-05
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

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

interface IBPool is IERC20 {
    function version() external view returns(uint);
    function swapExactAmountIn(address, uint, address, uint, uint) external returns (uint, uint);

    function swapExactAmountOut(address, uint, address, uint, uint) external returns (uint, uint);

    function calcInGivenOut(uint, uint, uint, uint, uint, uint) external pure returns (uint);

    function calcOutGivenIn(uint, uint, uint, uint, uint, uint) external pure returns (uint);

    function getDenormalizedWeight(address) external view returns (uint);

    function swapFee() external view returns (uint);

    function setSwapFee(uint _swapFee) external;

    function bind(address token, uint balance, uint denorm) external;

    function rebind(address token, uint balance, uint denorm) external;

    function finalize(
        uint _swapFee,
        uint _initPoolSupply,
        address[] calldata _bindTokens,
        uint[] calldata _bindDenorms
    ) external;

    function setPublicSwap(bool _publicSwap) external;
    function setController(address _controller) external;
    function setExchangeProxy(address _exchangeProxy) external;
    function getFinalTokens() external view returns (address[] memory tokens);


    function getTotalDenormalizedWeight() external view returns (uint);

    function getBalance(address token) external view returns (uint);


    function joinPool(uint poolAmountOut, uint[] calldata maxAmountsIn) external;
    function joinPoolFor(address account, uint rewardAmountOut, uint[] calldata maxAmountsIn) external;
    function joinswapPoolAmountOut(address tokenIn, uint poolAmountOut, uint maxAmountIn) external returns (uint tokenAmountIn);

    function exitPool(uint poolAmountIn, uint[] calldata minAmountsOut) external;
    function exitswapPoolAmountIn(address tokenOut, uint poolAmountIn, uint minAmountOut) external returns (uint tokenAmountOut);
    function exitswapExternAmountOut(address tokenOut, uint tokenAmountOut, uint maxPoolAmountIn) external returns (uint poolAmountIn);
    function joinswapExternAmountIn(
        address tokenIn,
        uint tokenAmountIn,
        uint minPoolAmountOut
    ) external returns (uint poolAmountOut);
    function finalizeRewardFundInfo(address _rewardFund, uint _unstakingFrozenTime) external;
    function addRewardPool(IERC20 _rewardToken, uint256 _startBlock, uint256 _endRewardBlock, uint256 _rewardPerBlock,
        uint256 _lockRewardPercent, uint256 _startVestingBlock, uint256 _endVestingBlock) external;
    function isBound(address t) external view returns (bool);
    function getSpotPrice(address tokenIn, address tokenOut) external view returns (uint spotPrice);
}

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = uint256(1) << RESOLUTION;
    uint256 private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z;
        require(y == 0 || (z = uint256(self._x) * y) / y == uint256(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, "FixedPoint: ZERO_RECIPROCAL");
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
// range: [0, 2**112 - 1]
// resolution: 1 / 2**112
library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

interface IDecimals {
    function decimals() external view returns (uint8);
}

// fixed window oracle that recomputes the average price for the entire epochPeriod once every epochPeriod
// note that the price average is only guaranteed to be over at least 1 epochPeriod, but may be over a longer epochPeriod
// @dev This version 2 supports querying twap with shorted period (ie 2hrs for BSDB reference price)
contract OracleMultiPairV2 is Ownable {
    using FixedPoint for *;
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant BPOOL_BONE = 10**18;
    uint256 public constant ORACLE_RESERVE_MINIMUM = 10000 ether; // $10,000

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // epoch
    uint256 public startTime;
    uint256 public lastEpochTime;
    uint256 public epoch; // for display only
    uint256 public epochPeriod;

    // 2-hours update
    uint256 public lastUpdateHour;
    uint256 public updatePeriod;

    mapping(uint256 => uint112) public epochPrice;

    // BPool
    address public mainToken;
    address[] public sideTokens;
    uint256[] public sideTokenDecimals;
    IBPool[] public pools;

    // Pool price for update in cumulative epochPeriod
    uint32 public blockTimestampCumulativeLast;
    uint public priceCumulative;

    // oracle
    uint32 public blockTimestampLast;
    uint256 public priceCumulativeLast;
    FixedPoint.uq112x112 public priceAverage;

    event Updated(uint256 priceCumulativeLast);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address[] memory _pools,
        address _mainToken,
        address[] memory _sideTokens,
        uint256 _epoch,
        uint256 _epochPeriod,
        uint256 _lastEpochTime,
        uint256 _updatePeriod,
        uint256 _lastUpdateHour
    ) public {
        require(_pools.length == _sideTokens.length, "ERR_LENGTH_MISMATCH");

        mainToken = _mainToken;

        for (uint256 i = 0; i < _pools.length; i++) {
            IBPool pool = IBPool(_pools[i]);
            require(pool.isBound(_mainToken) && pool.isBound(_sideTokens[i]), "!bound");
            require(pool.getBalance(_mainToken) != 0 && pool.getBalance(_sideTokens[i]) != 0, "OracleMultiPair: NO_RESERVES"); // ensure that there's liquidity in the pool

            pools.push(pool);
            sideTokens.push(_sideTokens[i]);
            sideTokenDecimals.push(IDecimals(_sideTokens[i]).decimals());
        }

        epoch = _epoch;
        epochPeriod = _epochPeriod;
        lastEpochTime = _lastEpochTime;
        lastUpdateHour = _lastUpdateHour;
        updatePeriod = _updatePeriod;

        operator = msg.sender;
    }

    /* ========== GOVERNANCE ========== */

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setEpoch(uint256 _epoch) external onlyOperator {
        epoch = _epoch;
    }

    function setEpochPeriod(uint256 _epochPeriod) external onlyOperator {
        require(_epochPeriod >= 1 hours && _epochPeriod <= 48 hours, '_epochPeriod out of range');
        epochPeriod = _epochPeriod;
    }

    function setLastUpdateHour(uint256 _lastUpdateHour) external onlyOperator {
        require(_lastUpdateHour % 3600 == 0, '_lastUpdateHour is not valid');
        lastUpdateHour = _lastUpdateHour;
    }

    function setUpdatePeriod(uint256 _updatePeriod) external onlyOperator {
        require(_updatePeriod >= 1 hours && _updatePeriod <= epochPeriod, '_updatePeriod out of range');
        updatePeriod = _updatePeriod;
    }

    function addPool(address _pool, address _sideToken) public onlyOperator {
        IBPool pool = IBPool(_pool);
        require(pool.isBound(mainToken) && pool.isBound(_sideToken), "!bound");
        require(pool.getBalance(mainToken) != 0 && pool.getBalance(_sideToken) != 0, "OracleMultiPair: NO_RESERVES");
        // ensure that there's liquidity in the pool

        pools.push(pool);
        sideTokens.push(_sideToken);
        sideTokenDecimals.push(IDecimals(_sideToken).decimals());
    }

    function removePool(address _pool, address _sideToken) public onlyOperator {
        uint last = pools.length - 1;

        for (uint256 i = 0; i < pools.length; i++) {
            if (address(pools[i]) == _pool && sideTokens[i] == _sideToken) {
                pools[i] = pools[last];
                sideTokens[i] = sideTokens[last];
                sideTokenDecimals[i] = sideTokenDecimals[last];

                pools.pop();
                sideTokens.pop();
                sideTokenDecimals.pop();

                break;
            }
        }
    }

    /* =================== Modifier =================== */

    modifier checkEpoch {
        uint256 _nextEpochPoint = nextEpochPoint();
        require(now >= _nextEpochPoint, "OracleMultiPair: not opened yet");

        _;

        for (;;) {
            lastEpochTime = _nextEpochPoint;
            ++epoch;
            _nextEpochPoint = nextEpochPoint();
            if (now < _nextEpochPoint) break;
        }
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "OracleMultiPair: caller is not the operator");
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function nextEpochPoint() public view returns (uint256) {
        return lastEpochTime.add(epochPeriod);
    }

    function nextUpdateHour() public view returns (uint256) {
        return lastUpdateHour.add(updatePeriod);
    }

    /* ========== MUTABLE FUNCTIONS ========== */
    // update reserves and, on the first call per block, price accumulators
    function updateCumulative() public {
        uint256 _nextUpdateHour = lastUpdateHour.add(updatePeriod);
        if (now >= _nextUpdateHour) {
            uint totalMainPriceWeight;
            uint totalMainPoolBal;

            for (uint256 i = 0; i < pools.length; i++) {
                uint _decimalFactor = 10 ** (uint256(18).sub(sideTokenDecimals[i]));
                uint tokenMainPrice = pools[i].getSpotPrice(sideTokens[i], mainToken).mul(_decimalFactor);
                require(tokenMainPrice != 0, "!price");

                uint reserveBal = pools[i].getBalance(sideTokens[i]).mul(_decimalFactor);
                require(reserveBal >= ORACLE_RESERVE_MINIMUM, "!min reserve");

                uint tokenBal = pools[i].getBalance(mainToken);
                totalMainPriceWeight = totalMainPriceWeight.add(tokenMainPrice.mul(tokenBal).div(BPOOL_BONE));
                totalMainPoolBal = totalMainPoolBal.add(tokenBal);
            }

            require(totalMainPriceWeight <= uint112(- 1) && totalMainPoolBal <= uint112(- 1), 'BPool: OVERFLOW');
            uint32 blockTimestamp = uint32(block.timestamp % 2 ** 32);
            uint32 timeElapsed = blockTimestamp - blockTimestampCumulativeLast; // overflow is desired

            if (timeElapsed > 0 && totalMainPoolBal != 0) {
                // * never overflows, and + overflow is desired
                priceCumulative += uint(UQ112x112.encode(uint112(totalMainPriceWeight)).uqdiv(uint112(totalMainPoolBal))) * timeElapsed;

                blockTimestampCumulativeLast = blockTimestamp;
            }

            lastUpdateHour = _nextUpdateHour;
        }
    }

    /** @dev Updates 1-day EMA price.  */
    function update() external checkEpoch {
        updateCumulative();

        uint32 timeElapsed = blockTimestampCumulativeLast - blockTimestampLast; // overflow is desired

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        priceAverage = FixedPoint.uq112x112(uint224((priceCumulative - priceCumulativeLast) / timeElapsed));

        priceCumulativeLast = priceCumulative;
        blockTimestampLast = blockTimestampCumulativeLast;

        epochPrice[epoch] = priceAverage.decode();
        emit Updated(priceCumulative);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address token, uint256 amountIn) external view returns (uint144 amountOut) {
        require(token == mainToken, "OracleMultiPair: INVALID_TOKEN");
        require(now.sub(blockTimestampLast) <= epochPeriod, "OracleMultiPair: Price out-of-date");
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    function twap(uint256 _amountIn) external view returns (uint144) {
        uint32 timeElapsed = blockTimestampCumulativeLast - blockTimestampLast;
        return (timeElapsed == 0) ? priceAverage.mul(_amountIn).decode144() : FixedPoint.uq112x112(uint224((priceCumulative - priceCumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
    }

    function governanceRecoverUnsupported(IERC20 _token, uint256 _amount, address _to) external onlyOperator {
        _token.transfer(_to, _amount);
    }
}