/**
 *Submitted for verification at Etherscan.io on 2021-03-29
*/

pragma solidity ^0.5.0;

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
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IPOWToken {
    function updateIncomeRate() external;
    function incomeToken() external view returns(uint256);
    function incomeRate() external view returns(uint256);
    function startMiningTime() external view returns (uint256);
    function mint(address to, uint value) external;
    function remainingAmount() external view returns(uint256);
    function rewardToken() external view returns(uint256);
    function stakingRewardRate() external view returns(uint256);
    function lpStakingRewardRate() external view returns(uint256);
    function rewardPeriodFinish() external view returns(uint256);
    function claimIncome(address to, uint256 amount) external;
    function claimReward(address to, uint256 amount) external;
}

interface IUniswapV2Pair {
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
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;

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
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
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
}

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}

interface IMiningParam {
    function incomeAssetPrice() external view returns (uint256);
    function incomePerSecInWei() external view returns(uint256);
}

contract BTCParamV2 is IMiningParam{
    using SafeMath for uint256;

    bool internal initialized;
    address public owner;
    address public paramSetter;

    uint256 public btcBlockRewardInWei;
    uint256 public btcNetDiff;
    uint256 public btcTxFeeRewardPerTPerSecInWei;

    address public uniPairAddress;
    bool public usePrice0;
    uint32 public lastPriceUpdateTime;
    uint256 public lastCumulativePrice;
    uint256 public lastAveragePrice;

    address[] public paramListeners;

    function initialize(address newOwner, address _paramSetter, uint256 _btcNetDiff, uint256 _btcBlockRewardInWei, address _uniPairAddress, bool _usePrice0) public {
        require(!initialized, "already initialized");
        require(newOwner != address(0), "new owner is the zero address");
        initialized = true;
        owner = newOwner;
        paramSetter= _paramSetter;
        btcBlockRewardInWei = _btcBlockRewardInWei;
        btcNetDiff = _btcNetDiff;

        uniPairAddress = _uniPairAddress;
        usePrice0 = _usePrice0;
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 currentBlockTimestamp) =
        UniswapV2OracleLibrary.currentCumulativePrices(_uniPairAddress);

        lastPriceUpdateTime = currentBlockTimestamp;
        lastCumulativePrice = _usePrice0?price0Cumulative:price1Cumulative;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function setParamSetter(address _paramSetter) external onlyOwner {
        require(_paramSetter != address(0), "param setter is the zero address");
        emit ParamSetterChanged(paramSetter, _paramSetter);
        paramSetter = _paramSetter;
    }

    function setBtcNetDiff(uint256 _btcNetDiff) external onlyParamSetter {
        require(_btcNetDiff > 10000000000000, "_btcNetDiff limit at 10000000000000");
        btcNetDiff = _btcNetDiff;
        notifyListeners();
    }

    function setBtcBlockReward(uint256 _btcBlockRewardInWei) external onlyParamSetter {
        require(_btcBlockRewardInWei < btcBlockRewardInWei, "invalid _btcBlockRewardInWei");
        btcBlockRewardInWei = _btcBlockRewardInWei;
        notifyListeners();
    }

    function updateAssetPrice() external onlyParamSetter {
        _updatePrice();
        notifyListeners();
    }

    function _updatePrice() internal {
        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 currentBlockTimestamp) =
        UniswapV2OracleLibrary.currentCumulativePrices(uniPairAddress);
        uint256 currentPrice = usePrice0?price0Cumulative:price1Cumulative;

        uint256 timeElapsed = currentBlockTimestamp - lastPriceUpdateTime; // overflow is desired
        if (timeElapsed > 0) {
            lastAveragePrice = currentPrice.sub(lastCumulativePrice).div(timeElapsed);
            lastPriceUpdateTime = currentBlockTimestamp;
            lastCumulativePrice = currentPrice;
        }
    }

    function setBtcTxFeeRewardRate(uint256 _btcTxFeeRewardPerTPerSecInWei) external onlyParamSetter {
        _setBtcTxFeeRewardRate(_btcTxFeeRewardPerTPerSecInWei);
        notifyListeners();
    }

    function setBtcTxFeeRewardRateAndUpdateBtcPrice(uint256 _btcTxFeeRewardPerTPerSecInWei) external onlyParamSetter{
        _setBtcTxFeeRewardRate(_btcTxFeeRewardPerTPerSecInWei);
        _updatePrice();
        notifyListeners();
    }

    function _setBtcTxFeeRewardRate(uint256 _btcTxFeeRewardPerTPerSecInWei) internal {
        require(_btcTxFeeRewardPerTPerSecInWei < 100000000, "_btcTxFeeRewardPerTPerSecInWei limit at 100000000");
        btcTxFeeRewardPerTPerSecInWei = _btcTxFeeRewardPerTPerSecInWei;
    }

    function addListener(address _listener) external onlyParamSetter {
        for (uint i=0; i<paramListeners.length; i++){
            address listener = paramListeners[i];
            require(listener != _listener, 'listener already added.');
        }
        paramListeners.push(_listener);
    }

    function removeListener(address _listener) external onlyParamSetter returns(bool ){
        for (uint i=0; i<paramListeners.length; i++){
            address listener = paramListeners[i];
            if (listener == _listener) {
                delete paramListeners[i];
                return true;
            }
        }
        return false;
    }

    function notifyListeners() internal {
        for (uint i=0; i<paramListeners.length; i++){
            address listener = paramListeners[i];
            if (listener != address(0)) {
                IPOWToken(listener).updateIncomeRate();
            }
        }
    }

    function incomePerSecInWei() external view returns(uint256){
        uint256 oneTHash = 10 ** 12;
        uint256 baseDiff = 2 ** 32;
        uint256 blockRewardRate = oneTHash.mul(btcBlockRewardInWei).div(baseDiff).div(btcNetDiff);
        return blockRewardRate.add(btcTxFeeRewardPerTPerSecInWei);
    }

    function incomeAssetPrice() external view returns (uint256) {
        return lastAveragePrice.mul(100).div(2**112);
    }

    /* ========== MODIFIERS ========== */
    modifier onlyOwner() {
        require(msg.sender == owner, "!owner");
        _;
    }

    modifier onlyParamSetter() {
        require(msg.sender == paramSetter, "!paramSetter");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ParamSetterChanged(address indexed previousSetter, address indexed newSetter);
}