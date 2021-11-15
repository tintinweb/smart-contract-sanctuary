// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity >=0.5.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./UniswapV2Library.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library LotteryUtils {
    // Libraries
    // Safe math
    using SafeMath for uint256;

    struct Set {
        uint16[] values;
        mapping(uint16 => bool) isExists;
    }

    // Represents the status of the lottery
    enum Status {
        Open, // The lottery is open for ticket purchases
        Closed, // The lottery is no closed for new round
        RewardCompleted // The lottery reward has been calculated
    }

    struct GamblingInfo {
        address gambler;
        uint16 lotteryNumber;
        uint256 amount;
        uint256 rewardMultiplier;
    }

    // All the needed info around a lottery
    struct LotteryInfo {
        uint256 lotteryId; // ID for lotto
        Status lotteryStatus; // Status for lotto
        mapping(uint16 => GamblingInfo[]) lottoGamblerByNumber; // Mapping of lotteryNumber -> array of GamblingInfo
        mapping(address => GamblingInfo[]) lottoGamblerByAddress; // Mapping of gambler's address -> array of GamblingInfo
        mapping(uint16 => uint256) totalAmountByNumber; // Mapping of lotteryNumber -> total amount
        mapping(uint16 => uint256) totalRewardAmountByNumber; // Mapping of lotteryNumber -> total reward amount
        uint256 totalAmount; // Total bet amount
        Set winningNumbers; // Two digit winning
        uint256 lockedStableAmount; // Stable coin amount that was locked
    }

    uint256 internal constant Q = 1 * (10**8);

    function getLottoStablePairInfo(
        address _factory,
        address _stable,
        address _lotto
    )
        public
        view
        returns (
            uint256 reserveStable,
            uint256 reserveLotto,
            uint256 totalSupply
        )
    {
        IUniswapV2Pair _pair = IUniswapV2Pair(
            UniswapV2Library.pairFor(_factory, _stable, _lotto)
        );
        totalSupply = _pair.totalSupply();
        (uint256 reserves0, uint256 reserves1, ) = _pair.getReserves();
        (reserveStable, reserveLotto) = _stable == _pair.token0()
            ? (reserves0, reserves1)
            : (reserves1, reserves0);
    }

    function getStableOutputWithDirectPrice(
        uint256 _lottoAmount,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 stableOutput) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        stableOutput = reserveStable.mul(_lottoAmount).div(reserveLotto);
    }

    function getLottoOutputWithDirectPrice(
        uint256 _stableAmount,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 lottoOutput) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        lottoOutput = reserveLotto.mul(_stableAmount).div(reserveStable);
    }

    function getRequiredStableForExpectedLotto(
        uint256 _expectedLotto,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 requiredStable) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        require(_expectedLotto < reserveLotto, "Insufficient lotto in lp");
        requiredStable = UniswapV2Library.getAmountIn(
            _expectedLotto,
            reserveStable,
            reserveLotto
        );
    }

    function getPossibleStableOutputForInputLotto(
        uint256 _lottoAmount,
        address _factory,
        address _stable,
        address _lotto
    ) public view returns (uint256 stableOutput) {
        (
            uint256 reserveStable,
            uint256 reserveLotto,

        ) = getLottoStablePairInfo(_factory, _stable, _lotto);
        stableOutput = UniswapV2Library.getAmountOut(
            _lottoAmount,
            reserveLotto,
            reserveStable
        );
    }

    function getRemainingPoolAmount(
        uint256 _currentStakedStableAmount,
        uint256 _currentBetAmount,
        uint256 _currentTotalBetAmount,
        uint256 _totalLotteryNumber
    ) public pure returns (uint256 remainingPoolAmount) {
        uint256 currentPoolAmount = _currentStakedStableAmount.div(
            _totalLotteryNumber
        );
        require(
            currentPoolAmount > 0,
            "Staked stable amount should be greater than zero"
        );
        require(
            _currentBetAmount <= currentPoolAmount,
            "Invalid current bet amount greater than pool amount"
        );
        uint256 averageBetAmount = _currentTotalBetAmount.div(
            _totalLotteryNumber
        );
        if (_currentBetAmount > averageBetAmount) {
            uint256 diffAmount = _currentBetAmount.sub(averageBetAmount);
            remainingPoolAmount = currentPoolAmount.sub(diffAmount);
        } else {
            uint256 diffAmount = averageBetAmount.sub(_currentBetAmount);
            remainingPoolAmount = currentPoolAmount.add(diffAmount);
        }
    }

    function getRewardMultiplier(
        uint256 _currentStakedStableAmount,
        uint256 _currentBetAmount,
        uint256 _currentTotalBetAmount,
        uint256 _totalLotteryNumber,
        uint256 _maxRewardMultiplier
    ) public pure returns (uint256 multiplier) {
        uint256 currentPoolAmount = _currentStakedStableAmount.div(
            _totalLotteryNumber
        );
        uint256 remainingPoolAmount = getRemainingPoolAmount(
            _currentStakedStableAmount,
            _currentBetAmount,
            _currentTotalBetAmount,
            _totalLotteryNumber
        );

        multiplier = remainingPoolAmount.mul(_maxRewardMultiplier).div(
            currentPoolAmount
        );
    }

    function getMaxAllowBetAmount(
        uint256 _currentStakedStableAmount,
        uint256 _currentBetAmount,
        uint256 _currentTotalBetAmount,
        uint256 _totalLotteryNumber,
        uint256 _maxRewardMultiplier,
        uint256 _maxMultiplierSlippageTolerancePercentage
    ) public pure returns (uint256 maxAllowBetAmount) {
        uint256 remainingPoolAmount = getRemainingPoolAmount(
            _currentStakedStableAmount,
            _currentBetAmount,
            _currentTotalBetAmount,
            _totalLotteryNumber
        );
        uint256 currentMultiplierQ = getRewardMultiplier(
            _currentStakedStableAmount,
            _currentBetAmount,
            _currentTotalBetAmount,
            _totalLotteryNumber,
            _maxRewardMultiplier
        ).mul(Q);
        uint256 maxMultiplierSlippageToleranceAmountQ = _maxMultiplierSlippageTolerancePercentage
                .mul(currentMultiplierQ)
                .div(100);
        uint256 targetMultiplierQ = currentMultiplierQ -
            maxMultiplierSlippageToleranceAmountQ;
        maxAllowBetAmount =
            remainingPoolAmount -
            targetMultiplierQ.mul(remainingPoolAmount).div(currentMultiplierQ);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint160(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                 hex'03f6509a2bb88d26dc77ecc6fc204e95089e30cb99667b85e653280b735767c8' // init code hash
            )))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

