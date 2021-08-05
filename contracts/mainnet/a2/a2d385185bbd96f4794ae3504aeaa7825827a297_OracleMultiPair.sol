/**
 *Submitted for verification at Etherscan.io on 2021-01-28
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE

pragma solidity 0.7.6;

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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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

interface IOracle {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function updateCumulative() external;

    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

    function consultDollarPrice(address _sideToken, uint256 _amountIn) external view returns (uint256 _dollarPrice);

    function twap(uint256 _amountIn) external view returns (uint144 _amountOut);

    function twapDollarPrice(address _sideToken, uint256 _amountIn) external view returns (uint256 _amountOut);
}

interface IValueLiquidFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint32 tokenWeight0, uint32 swapFee, uint256);

    function feeTo() external view returns (address);

    function formula() external view returns (address);

    function protocolFee() external view returns (uint256);

    function feeToSetter() external view returns (address);

    function getPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function isPair(address) external view returns (bool);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        uint32 tokenWeightA,
        uint32 swapFee
    ) external returns (address pair);

    function getWeightsAndSwapFee(address pair)
        external
        view
        returns (
            uint32 tokenWeight0,
            uint32 tokenWeight1,
            uint32 swapFee
        );

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setProtocolFee(uint256) external;
}

interface IValueLiquidPair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

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

    event PaidProtocolFee(uint112 collectedFee0, uint112 collectedFee1);
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

    function getCollectedFees() external view returns (uint112 _collectedFee0, uint112 _collectedFee1);

    function getTokenWeights() external view returns (uint32 tokenWeight0, uint32 tokenWeight1);

    function getSwapFee() external view returns (uint32);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

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

    function initialize(
        address,
        address,
        uint32,
        uint32
    ) external;
}

interface IEpochController {
    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function nextEpochLength() external view returns (uint256);

    function nextEpochAllocatedReward(address _pool) external view returns (uint256);
}

interface IAggregatorInterface {
    function latestAnswer() external view returns (int256);
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

// fixed window oracle that recomputes the average price for the entire epochPeriod once every epochPeriod
// note that the price average is only guaranteed to be over at least 1 epochPeriod, but may be over a longer epochPeriod
contract OracleMultiPair is Ownable, IOracle {
    using FixedPoint for *;
    using SafeMath for uint256;
    using UQ112x112 for uint224;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;
    address public factory;

    uint256 public oracleReserveMinimum; // $10k

    // epoch
    address public epochController;
    uint256 public maxEpochPeriod;

    // 1-hour update
    uint256 public lastUpdateHour;
    uint256 public updatePeriod;

    mapping(uint256 => uint256) public epochDollarPrice;

    // chain-link price feed
    mapping(address => address) public chainLinkOracle;

    // ValueLiquidPair
    address public mainToken;
    bool[] public isToken0s;
    uint256[] public decimalFactors;
    uint32[] public mainTokenWeights;
    IValueLiquidPair[] public pairs;

    // Pair price for update in cumulative epochPeriod
    uint256 public priceCumulative;
    uint256[] public priceMainCumulativeLast;

    // oracle
    uint256 public priceCumulativeLast;
    FixedPoint.uq112x112 public priceAverage;

    uint32 public blockTimestampCumulativeLast;
    uint32 public blockTimestampLast;

    event Updated(uint256 priceCumulativeLast);

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address[] memory _pairs,
        address _mainToken,
        address _epochController,
        uint256 _maxEpochPeriod,
        uint256 _updatePeriod,
        uint256 _lastUpdateHour,
        address _pairFactory,
        address _defaultOracle,
        uint256 _oracleReserveMinimum
    ) {
        for (uint256 i = 0; i < _pairs.length; i++) {
            IValueLiquidPair pair = IValueLiquidPair(_pairs[i]);
            {
                (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
                require(reserve0 != 0 && reserve1 != 0, "OracleMultiPair: NO_RESERVES"); // ensure that there's liquidity in the pair
            }

            pairs.push(pair);
            bool isToken0 = pair.token0() == _mainToken;
            isToken0s.push(isToken0);
            priceMainCumulativeLast.push(0);
            {
                uint256 decimal = IERC20(isToken0 ? pair.token1() : pair.token0()).decimals();
                decimalFactors.push(10**(uint256(18).sub(decimal)));
            }
            (uint32 _tokenWeight0, uint32 _tokenWeight1, ) = IValueLiquidFactory(_pairFactory).getWeightsAndSwapFee(_pairs[i]);
            mainTokenWeights.push(isToken0 ? _tokenWeight0 : _tokenWeight1);
        }

        epochController = _epochController;
        maxEpochPeriod = _maxEpochPeriod;
        lastUpdateHour = _lastUpdateHour;
        updatePeriod = _updatePeriod;
        factory = _pairFactory;
        mainToken = _mainToken;
        chainLinkOracle[address(0)] = _defaultOracle;
        oracleReserveMinimum = _oracleReserveMinimum;

        operator = msg.sender;
    }

    /* ========== GOVERNANCE ========== */

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setEpochController(address _epochController) external onlyOperator {
        epochController = _epochController;
    }

    function setChainLinkOracle(address _token, address _priceFeed) external onlyOperator {
        chainLinkOracle[_token] = _priceFeed;
    }

    function setOracleReserveMinimum(uint256 _oracleReserveMinimum) external onlyOperator {
        oracleReserveMinimum = _oracleReserveMinimum;
    }

    function setMaxEpochPeriod(uint256 _maxEpochPeriod) external onlyOperator {
        require(_maxEpochPeriod <= 48 hours, "_maxEpochPeriod is not valid");
        maxEpochPeriod = _maxEpochPeriod;
    }

    function setLastUpdateHour(uint256 _lastUpdateHour) external onlyOperator {
        require(_lastUpdateHour % 3600 == 0, "_lastUpdateHour is not valid");
        lastUpdateHour = _lastUpdateHour;
    }

    function addPair(address _pair) public onlyOperator {
        IValueLiquidPair pair = IValueLiquidPair(_pair);
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        require(reserve0 != 0 && reserve1 != 0, "OracleMultiPair: NO_RESERVES");
        // ensure that there's liquidity in the pair

        pairs.push(pair);
        bool isToken0 = pair.token0() == mainToken;
        isToken0s.push(isToken0);
        priceMainCumulativeLast.push(isToken0 ? pair.price0CumulativeLast() : pair.price1CumulativeLast());
        {
            uint256 decimal = IERC20(isToken0 ? pair.token1() : pair.token0()).decimals();
            decimalFactors.push(10**(uint256(18).sub(decimal)));
        }
        (uint32 _tokenWeight0, uint32 _tokenWeight1, ) = IValueLiquidFactory(factory).getWeightsAndSwapFee(_pair);
        mainTokenWeights.push(isToken0 ? _tokenWeight0 : _tokenWeight1);
    }

    function removePair(address _pair) public onlyOperator {
        uint256 last = pairs.length - 1;

        for (uint256 i = 0; i < pairs.length; i++) {
            if (address(pairs[i]) == _pair) {
                pairs[i] = pairs[last];
                isToken0s[i] = isToken0s[last];
                priceMainCumulativeLast[i] = priceMainCumulativeLast[last];
                decimalFactors[i] = decimalFactors[last];
                mainTokenWeights[i] = mainTokenWeights[last];

                pairs.pop();
                isToken0s.pop();
                mainTokenWeights.pop();
                priceMainCumulativeLast.pop();
                decimalFactors.pop();

                break;
            }
        }
    }

    /* =================== Modifier =================== */

    modifier checkEpoch {
        require(block.timestamp >= nextEpochPoint(), "OracleMultiPair: not opened yet");
        _;
    }

    modifier onlyOperator() {
        require(operator == msg.sender, "OracleMultiPair: caller is not the operator");
        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function epoch() public view override returns (uint256) {
        return IEpochController(epochController).epoch();
    }

    function nextEpochPoint() public view override returns (uint256) {
        return IEpochController(epochController).nextEpochPoint();
    }

    function nextEpochLength() external view returns (uint256) {
        return IEpochController(epochController).nextEpochLength();
    }

    function nextUpdateHour() public view returns (uint256) {
        return lastUpdateHour.add(updatePeriod);
    }

    /* ========== MUTABLE FUNCTIONS ========== */
    // update reserves and, on the first call per block, price accumulators
    function updateCumulative() public override {
        uint256 _updatePeriod = updatePeriod;
        uint256 _nextUpdateHour = lastUpdateHour.add(_updatePeriod);
        if (block.timestamp >= _nextUpdateHour) {
            uint256 totalMainPriceWeight;
            uint256 totalSidePairBal;

            uint32 blockTimestamp = uint32(block.timestamp % 2**32);
            if (blockTimestamp != blockTimestampCumulativeLast) {
                for (uint256 i = 0; i < pairs.length; i++) {
                    (uint256 priceMainCumulative, , uint256 reserveSideToken) =
                        currentTokenCumulativePriceAndReserves(pairs[i], isToken0s[i], mainTokenWeights[i], blockTimestamp);

                    uint256 _decimalFactor = decimalFactors[i];
                    uint256 reserveBal = reserveSideToken.mul(_decimalFactor);
                    require(reserveBal >= oracleReserveMinimum, "!min reserve");

                    totalMainPriceWeight = totalMainPriceWeight.add(
                        (priceMainCumulative - priceMainCumulativeLast[i]).mul(reserveSideToken.mul(_decimalFactor))
                    );
                    totalSidePairBal = totalSidePairBal.add(reserveSideToken);
                    priceMainCumulativeLast[i] = priceMainCumulative;
                }

                require(totalSidePairBal <= uint112(-1), "OracleMultiPair: OVERFLOW");
                if (totalSidePairBal != 0) {
                    priceCumulative += totalMainPriceWeight.div(totalSidePairBal);
                    blockTimestampCumulativeLast = blockTimestamp;
                }
            }

            for (;;) {
                if (block.timestamp < _nextUpdateHour.add(_updatePeriod)) {
                    lastUpdateHour = _nextUpdateHour;
                    break;
                } else {
                    _nextUpdateHour = _nextUpdateHour.add(_updatePeriod);
                }
            }
        }
    }

    /** @dev Updates 1-day EMA price.  */
    function update() external override checkEpoch {
        updateCumulative();

        uint32 _blockTimestampCumulativeLast = blockTimestampCumulativeLast; // gas saving
        uint32 timeElapsed = _blockTimestampCumulativeLast - blockTimestampLast; // overflow is desired

        if (timeElapsed == 0) {
            // prevent divided by zero
            return;
        }

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        uint256 _priceCumulative = priceCumulative; //gas saving
        priceAverage = FixedPoint.uq112x112(uint224((_priceCumulative - priceCumulativeLast) / timeElapsed));

        priceCumulativeLast = _priceCumulative;
        blockTimestampLast = _blockTimestampCumulativeLast;

        epochDollarPrice[epoch()] = consultDollarPrice(address(0), 1e18);
        emit Updated(_priceCumulative);
    }

    // note this will always return 0 before update has been called successfully for the first time.
    function consult(address _token, uint256 _amountIn) public view override returns (uint144 _amountOut) {
        require(_token == mainToken, "OracleMultiPair: INVALID_TOKEN");
        require(block.timestamp.sub(blockTimestampLast) <= maxEpochPeriod, "OracleMultiPair: Price out-of-date");
        _amountOut = priceAverage.mul(_amountIn).decode144();
    }

    function consultDollarPrice(address _sideToken, uint256 _amountIn) public view override returns (uint256) {
        address _priceFeed = chainLinkOracle[_sideToken];
        if (_priceFeed == address(0)) {
            _priceFeed = chainLinkOracle[address(0)];
        }
        require(_priceFeed != address(0), "OracleMultiPair: No price feed");
        int256 _price = IAggregatorInterface(_priceFeed).latestAnswer();
        uint144 _amountOut = consult(mainToken, _amountIn);
        return uint256(_amountOut).mul(uint256(_price)).div(1e8);
    }

    function twap(uint256 _amountIn) public view override returns (uint144 _amountOut) {
        uint32 timeElapsed = blockTimestampCumulativeLast - blockTimestampLast;
        _amountOut = (timeElapsed == 0)
            ? priceAverage.mul(_amountIn).decode144()
            : FixedPoint.uq112x112(uint224((priceCumulative - priceCumulativeLast) / timeElapsed)).mul(_amountIn).decode144();
    }

    function twapDollarPrice(address _sideToken, uint256 _amountIn) external view override returns (uint256) {
        address _priceFeed = chainLinkOracle[_sideToken];
        if (_priceFeed == address(0)) {
            _priceFeed = chainLinkOracle[address(0)];
        }
        require(_priceFeed != address(0), "OracleMultiPair: No price feed");
        int256 _price = IAggregatorInterface(_priceFeed).latestAnswer();
        uint144 _amountOut = twap(_amountIn);
        return uint256(_amountOut).mul(uint256(_price)).div(1e8);
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        _token.transfer(_to, _amount);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync
    function currentTokenCumulativePriceAndReserves(
        IValueLiquidPair pair,
        bool isToken0,
        uint32 mainTokenWeight,
        uint32 blockTimestamp
    )
        internal
        view
        returns (
            uint256 _priceCumulative,
            uint256 reserveMain,
            uint256 reserveSideToken
        )
    {
        uint32 _blockTimestampLast;
        if (isToken0) {
            (reserveMain, reserveSideToken, _blockTimestampLast) = pair.getReserves();
            _priceCumulative = pair.price0CumulativeLast();
        } else {
            (reserveSideToken, reserveMain, _blockTimestampLast) = pair.getReserves();
            _priceCumulative = pair.price1CumulativeLast();
        }

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        if (_blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - _blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            uint112 mReserveMain = uint112(reserveMain) * (100 - mainTokenWeight);
            uint112 mReserveSide = uint112(reserveSideToken) * mainTokenWeight;
            _priceCumulative += uint256(FixedPoint.fraction(mReserveSide, mReserveMain)._x) * timeElapsed;
        }
    }
}