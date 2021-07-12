/**
 *Submitted for verification at BscScan.com on 2021-07-12
*/

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT
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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() external view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "Operator: caller is not the operator.");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) external onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "Operator: Zero address given for new operator.");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
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

interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// library with helper methods for oracles that are concerned with computing average prices
library PancakeswapOracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IPancakePair(pair).price0CumulativeLast();
        price1Cumulative = IPancakePair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

interface IEpoch {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);
}

// Note: Fixed window oracle that recomputes the average price for the entire period once every period.
// The price average is only guaranteed to be over at least 1 period, but may be over a longer period.
contract Oracle is IEpoch, Operator {
    using FixedPoint for *;
    using SafeMath for uint256;

    address public CHIP;
//    address public ETH_BNB_LP;
    address public ETH_BUSD_LP;
    IERC20 public ETH;
//    IERC20 public BNB;
    IERC20 public BUSD;

    bool public initialized = false;

    IPancakePair public pair; // CHIP/ETH LP
    address public token0;
    address public token1;

    uint32 public blockTimestampLast;
    uint256 public price0CumulativeLast;
    uint256 public price1CumulativeLast;
    FixedPoint.uq112x112 public price0Average;
    FixedPoint.uq112x112 public price1Average;

    IPancakePair public pair_1; // CHIP/BUSD LP
    address public token0_1;
    address public token1_1;

    uint32 public blockTimestampLast_1;
    uint256 public price0CumulativeLast_1;
    uint256 public price1CumulativeLast_1;
    FixedPoint.uq112x112 public price0Average_1;
    FixedPoint.uq112x112 public price1Average_1;

    address public treasury;
    mapping(uint256 => uint256) public epochDollarPrice;
    uint256 public priceAppreciation;

    event Initialized(address indexed executor, uint256 at);
    event Updated(uint256 price0CumulativeLast, uint256 price1CumulativeLast);

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "OracleMultiPair: not opened yet");
        _;
    }

    modifier notInitialized {
        require(!initialized, "Treasury: already initialized");
        _;
    }

    function epoch() public view override returns (uint256) {
        return IEpoch(treasury).epoch();
    }

    function nextEpochPoint() public view override returns (uint256) {
        return IEpoch(treasury).nextEpochPoint();
    }

    function nextEpochLength() external view override returns (uint256) {
        return IEpoch(treasury).nextEpochLength();
    }

    function setAddress(
        address _CHIP,
        address _ETH_BUSD_LP,
        IERC20 _ETH,
        IERC20 _BUSD
    ) external onlyOperator {
        CHIP = _CHIP;
        ETH_BUSD_LP = _ETH_BUSD_LP;
        ETH = _ETH;
        BUSD = _BUSD;
    }

    // _pair is CHIP/ETH LP, _pair_1 is CHIP/BUSD LP
    function initialize(IPancakePair _pair, IPancakePair _pair_1) external onlyOperator notInitialized {
        pair = _pair;
        token0 = pair.token0();
        token1 = pair.token1();
        price0CumulativeLast = pair.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0).
        price1CumulativeLast = pair.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1).
        uint112 reserve0;
        uint112 reserve1;
        (reserve0, reserve1, blockTimestampLast) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // Ensure that there's liquidity in the pair.
        pair_1 = _pair_1;
        token0_1 = pair_1.token0();
        token1_1 = pair_1.token1();
        price0CumulativeLast_1 = pair_1.price0CumulativeLast(); // Fetch the current accumulated price value (1 / 0).
        price1CumulativeLast_1 = pair_1.price1CumulativeLast(); // Fetch the current accumulated price value (0 / 1).
        (reserve0, reserve1, blockTimestampLast_1) = pair_1.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "Oracle: NO_RESERVES"); // Ensure that there's liquidity in the pair.
        initialized = true;
        emit Initialized(msg.sender, block.number);
    }

    function setTreasury(address _treasury) external onlyOperator {
        treasury = _treasury;
    }

    function setPriceAppreciation(uint256 _priceAppreciation) external onlyOperator {
        require(_priceAppreciation <= 2e17, "_priceAppreciation is insane"); // <= 20%
        priceAppreciation = _priceAppreciation;
    }

    // Updates 1-day EMA price from pancakeswap.
    function update() external checkEpoch {
        // CHIP/ETH LP
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = PancakeswapOracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired.
        if (timeElapsed == 0) {
            // Prevent divided by zero.
            return;
        }
        // Overflow is desired, casting never truncates.
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed.
        price0Average = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed));
        price1Average = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed));
        price0CumulativeLast = price0Cumulative;
        price1CumulativeLast = price1Cumulative;
        blockTimestampLast = blockTimestamp;
        epochDollarPrice[epoch()] = consult(CHIP, 1e18);
        // CHIP/BUSD LP
        (uint256 price0Cumulative_1, uint256 price1Cumulative_1, uint32 blockTimestamp_1) = PancakeswapOracleLibrary.currentCumulativePrices(address(pair_1));
        uint32 timeElapsed_1 = blockTimestamp_1 - blockTimestampLast_1; // overflow is desired
        if (timeElapsed_1 == 0) {
            // Prevent divided by zero.
            return;
        }
        // Overflow is desired, casting never truncates.
        // Cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed.
        price0Average_1 = FixedPoint.uq112x112(uint224((price0Cumulative_1 - price0CumulativeLast_1) / timeElapsed_1));
        price1Average_1 = FixedPoint.uq112x112(uint224((price1Cumulative_1 - price1CumulativeLast_1) / timeElapsed_1));
        price0CumulativeLast_1 = price0Cumulative_1;
        price1CumulativeLast_1 = price1Cumulative_1;
        blockTimestampLast_1 = blockTimestamp_1;
        emit Updated(price0Cumulative, price1Cumulative);
    }

    // This will always return 0 before update has been called successfully for the first time.
    // This function returns average of ETH-based and BUSD-based price of CHIP.
    function consult(address _token, uint256 _amountIn) public view returns (uint144 _amountOut) {
        if (priceAppreciation > 0) {
            uint256 _added = _amountIn.mul(priceAppreciation).div(1e18);
            _amountIn = _amountIn.add(_added);
        }
        if (_token == token0) {
            _amountOut = price0Average.mul(_amountIn).decode144();
        } else {
            require(_token == token1, "Oracle: INVALID_TOKEN");
            _amountOut = price1Average.mul(_amountIn).decode144();
        }

        uint144 _amountOut2;
        if (_token == token0_1) {
            _amountOut2 = price0Average_1.mul(_amountIn).decode144();
        } else {
            require(_token == token1_1, "Oracle: INVALID_TOKEN");
            _amountOut2 = price1Average_1.mul(_amountIn).decode144();
        }

        uint256 tmp = uint256(_amountOut);

        uint256 ETHBalance = ETH.balanceOf(ETH_BUSD_LP);
        uint256 BUSDBalance = BUSD.balanceOf(ETH_BUSD_LP);
        uint256 tmp_1 = uint256(_amountOut2);
        tmp_1 = tmp_1.mul(ETHBalance).div(BUSDBalance);

        tmp = tmp.add(tmp_1).div(2);

        _amountOut = uint144(tmp);
    }

    // Twap of CHIP/ETH LP.
    function twap_1(address _token, uint256 _amountIn) internal view returns (uint144 _amountOut) {
        if (priceAppreciation > 0) {
            uint256 _added = _amountIn.mul(priceAppreciation).div(1e18);
            _amountIn = _amountIn.add(_added);
        }
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = PancakeswapOracleLibrary.currentCumulativePrices(address(pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // Overflow is desired.
        require(timeElapsed > 0, "Oracle : Elapsed time Error");
        if (_token == token0) {
            require(price0Cumulative >= price0CumulativeLast, "Oracle : Price Calculation Error");
            _amountOut = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
        } else if (_token == token1) {
            require(price1Cumulative >= price1CumulativeLast, "Oracle : Price Calculation Error");
            _amountOut = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
        }
    }

    // Twap of CHIP/BUSD LP.
    function twap_2(address _token, uint256 _amountIn) internal view returns (uint144 _amountOut) {
        if (priceAppreciation > 0) {
            uint256 _added = _amountIn.mul(priceAppreciation).div(1e18);
            _amountIn = _amountIn.add(_added);
        }
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = PancakeswapOracleLibrary.currentCumulativePrices(address(pair_1));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast_1; // Overflow is desired.
        require(timeElapsed > 0, "Oracle : Elapsed time Error");
        if (_token == token0_1) {
            require(price0Cumulative >= price0CumulativeLast_1, "Oracle : Price Calculation Error");
            _amountOut = FixedPoint.uq112x112(uint224((price0Cumulative - price0CumulativeLast_1) / timeElapsed)).mul(_amountIn).decode144();
        } else if (_token == token1_1) {
            require(price1Cumulative >= price1CumulativeLast_1, "Oracle : Price Calculation Error");
            _amountOut = FixedPoint.uq112x112(uint224((price1Cumulative - price1CumulativeLast_1) / timeElapsed)).mul(_amountIn).decode144();
        }
    }

    function twap(address _token, uint256 _amountIn) external view returns (uint256 _amountOut) {
        // CHIP/ETH LP, ETH-based price of CHIP.
        uint256 v1 = twap_1(_token, _amountIn);

        // CHIP/BUSD LP, BUSD-based price of CHIP.
        uint256 v2 = twap_2(_token, _amountIn);
        uint256 ETHBalance = ETH.balanceOf(ETH_BUSD_LP);
        uint256 BUSDBalance = BUSD.balanceOf(ETH_BUSD_LP);
        uint256 ETHPricePerBUSD = 1e18;
        ETHPricePerBUSD = ETHPricePerBUSD.mul(ETHBalance).div(BUSDBalance);
        v2 = v2.mul(ETHPricePerBUSD).div(1e18);
        _amountOut = v1.add(v2).div(2);
    }
}