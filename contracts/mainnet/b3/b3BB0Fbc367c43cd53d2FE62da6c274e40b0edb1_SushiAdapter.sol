// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../libraries/UniswapV2Library.sol";
import "../../BaseAdapter.sol";
import "./IMasterChef.sol";


interface ISushiBar is IERC20 {
    function enter(uint256 amount) external;
}

contract SushiAdapter is BaseAdapter {
    using SafeMath for uint256;
    IMasterChef constant SUSHI_MASTER_CHEF = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd);
    address immutable MASTER_VAMPIRE;
    address constant DEV_FUND = 0xa896e4bd97a733F049b23d2AcEB091BcE01f298d;
    IERC20 constant SUSHI = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    ISushiBar constant SUSHI_BAR = ISushiBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);
    IUniswapV2Pair constant SUSHI_WETH_PAIR = IUniswapV2Pair(0x795065dCc9f64b5614C407a6EFDC400DA6221FB0);
    uint256 constant BLOCKS_PER_YEAR = 2336000;
    uint256 constant DEV_SHARE = 20; // 2%
    // token 0 - SUSHI
    // token 1 - WETH

    constructor(address _weth, address _factory, address _masterVampire)
        BaseAdapter(_weth, _factory)
    {
        MASTER_VAMPIRE = _masterVampire;
    }

    // Victim info
    function rewardToken(uint256) public pure override returns (IERC20) {
        return SUSHI;
    }

    function poolCount() external view override returns (uint256) {
        return SUSHI_MASTER_CHEF.poolLength();
    }

    function sellableRewardAmount(uint256) external pure override returns (uint256) {
        return uint256(-1);
    }

    // Victim actions, requires impersonation via delegatecall
    function sellRewardForWeth(address, uint256, uint256 rewardAmount, address to) external override returns(uint256) {
        uint256 devAmt = rewardAmount.mul(DEV_SHARE).div(1000);
        SUSHI.approve(address(SUSHI_BAR), devAmt);
        SUSHI_BAR.enter(devAmt);
        SUSHI_BAR.transfer(DEV_FUND, SUSHI_BAR.balanceOf(address(this)));
        rewardAmount = rewardAmount.sub(devAmt);

        SUSHI.transfer(address(SUSHI_WETH_PAIR), rewardAmount);
        (uint sushiReserve, uint wethReserve,) = SUSHI_WETH_PAIR.getReserves();
        uint amountOutput = UniswapV2Library.getAmountOut(rewardAmount, sushiReserve, wethReserve);
        SUSHI_WETH_PAIR.swap(uint(0), amountOutput, to, new bytes(0));
        return amountOutput;
    }

    // Pool info
    function lockableToken(uint256 victimPID) external view override returns (IERC20) {
        (IERC20 lpToken,,,) = SUSHI_MASTER_CHEF.poolInfo(victimPID);
        return lpToken;
    }

    function lockedAmount(address user, uint256 victimPID) external view override returns (uint256) {
        (uint256 amount,) = SUSHI_MASTER_CHEF.userInfo(victimPID, user);
        return amount;
    }

    function pendingReward(address, uint256, uint256 victimPID) external view override returns (uint256) {
        return SUSHI_MASTER_CHEF.pendingSushi(victimPID, MASTER_VAMPIRE);
    }

    // Pool actions, requires impersonation via delegatecall
    function deposit(address _adapter, uint256 victimPID, uint256 amount) external override returns (uint256) {
        IVampireAdapter adapter = IVampireAdapter(_adapter);
        adapter.lockableToken(victimPID).approve(address(SUSHI_MASTER_CHEF), uint256(-1));
        SUSHI_MASTER_CHEF.deposit(victimPID, amount);
        return 0;
    }

    function withdraw(address, uint256 victimPID, uint256 amount) external override returns (uint256) {
        SUSHI_MASTER_CHEF.withdraw(victimPID, amount);
        return 0;
    }

    function claimReward(address, uint256, uint256 victimPID) external override {
        SUSHI_MASTER_CHEF.deposit(victimPID, 0);
    }

    function emergencyWithdraw(address, uint256 victimPID) external override {
        SUSHI_MASTER_CHEF.emergencyWithdraw(victimPID);
    }

    // Service methods
    function poolAddress(uint256) external pure override returns (address) {
        return address(SUSHI_MASTER_CHEF);
    }

    function rewardToWethPool() external pure override returns (address) {
        return address(SUSHI_WETH_PAIR);
    }

    function lockedValue(address user, uint256 victimPID) external override view returns (uint256) {
        SushiAdapter adapter = SushiAdapter(this);
        return adapter.lpTokenValue(adapter.lockedAmount(user, victimPID),IUniswapV2Pair(address(adapter.lockableToken(victimPID))));
    }

    function totalLockedValue(uint256 victimPID) external override view returns (uint256) {
        SushiAdapter adapter = SushiAdapter(this);
        IUniswapV2Pair lockedToken = IUniswapV2Pair(address(adapter.lockableToken(victimPID)));
        return adapter.lpTokenValue(lockedToken.balanceOf(adapter.poolAddress(victimPID)), lockedToken);
    }

    function normalizedAPY(uint256 victimPID) external override view returns (uint256) {
        SushiAdapter adapter = SushiAdapter(this);
        (,uint256 allocationPoints,,) = SUSHI_MASTER_CHEF.poolInfo(victimPID);
        uint256 sushiPerBlock = SUSHI_MASTER_CHEF.sushiPerBlock();
        uint256 totalAllocPoint = SUSHI_MASTER_CHEF.totalAllocPoint();
        uint256 multiplier = SUSHI_MASTER_CHEF.getMultiplier(block.number - 1, block.number);
        uint256 rewardPerBlock = multiplier.mul(sushiPerBlock).mul(allocationPoints).div(totalAllocPoint);
        (uint256 sushiReserve, uint256 wethReserve,) = SUSHI_WETH_PAIR.getReserves();
        uint256 valuePerYear = rewardPerBlock.mul(wethReserve).mul(BLOCKS_PER_YEAR).div(sushiReserve);
        return valuePerYear.mul(1 ether).div(adapter.totalLockedValue(victimPID));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

pragma solidity ^0.7.0;

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
pragma solidity ^0.7.6;

import "../interfaces/IUniswapV2Pair.sol";
import "./SafeMath.sol";

library UniswapV2Library {
    using SafeMathUniswap for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303' // init code hash
            ))));
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./libraries/UniswapV2Library.sol";
import "./IVampireAdapter.sol";

abstract contract BaseAdapter is IVampireAdapter {
    using SafeMath for uint256;

    IERC20 immutable weth;
    IUniswapV2Factory immutable factory;

    constructor(address _weth, address _factory) {
        weth = IERC20(_weth);
        factory = IUniswapV2Factory(_factory);
    }

    /**
     * @notice Calculates the WETH value of an LP token
     */
    function lpTokenValue(uint256 amount, IUniswapV2Pair lpToken) public virtual override view returns(uint256) {
        (uint256 token0Reserve, uint256 token1Reserve,) = lpToken.getReserves();
        address token0 = lpToken.token0();
        address token1 = lpToken.token1();
        if (token0 == address(weth)) {
            return amount.mul(token0Reserve).mul(2).div(lpToken.totalSupply());
        }

        if (token1 == address(weth)) {
            return amount.mul(token1Reserve).mul(2).div(lpToken.totalSupply());
        }

        if (IUniswapV2Factory(lpToken.factory()).getPair(token0, address(weth)) != address(0)) {
            (uint256 wethReserve0, uint256 token0ToWethReserve0) = UniswapV2Library.getReserves(lpToken.factory(), address(weth), token0);
            uint256 tmp0 = amount.mul(token0Reserve).mul(wethReserve0).mul(2);
            return tmp0.div(token0ToWethReserve0).div(lpToken.totalSupply());
        }

        require(
            IUniswapV2Factory(lpToken.factory()).getPair(token1, address(weth)) != address(0),
            "Neither token0-weth nor token1-weth pair exists");
        (uint256 wethReserve1, uint256 token1ToWethReserve1) = UniswapV2Library.getReserves(lpToken.factory(), address(weth), token1);
        uint256 tmp1 = amount.mul(token1Reserve).mul(wethReserve1).mul(2);
        return tmp1.div(token1ToWethReserve1).div(lpToken.totalSupply());
    }

    /**
     * @notice Calculates the WETH value for an amount of pool reward token
     */
    function rewardValue(uint256 poolId, uint256 amount) external virtual override view returns(uint256) {
        address token = address(rewardToken(poolId));

        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(token), address(weth)));
        if (address(pair) != address(0)) {
                (uint tokenReserve0, uint wethReserve0,) = pair.getReserves();
                return UniswapV2Library.getAmountOut(amount, tokenReserve0, wethReserve0);
        }

        pair = IUniswapV2Pair(factory.getPair(address(weth), address(token)));
        require(
            address(pair) != address(0),
            "Neither token-weth nor weth-token pair exists");
        (uint wethReserve1, uint tokenReserve1,) = pair.getReserves();
        return UniswapV2Library.getAmountOut(amount, tokenReserve1, wethReserve1);
    }

    function rewardToken(uint256) public virtual override view returns (IERC20) {
        return IERC20(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMasterChef{
    function poolInfo(uint256) external view returns (IERC20,uint256,uint256,uint256);
    function userInfo(uint256, address) external view returns (uint256,uint256);
    function poolLength() external view returns (uint256);
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function emergencyWithdraw(uint256 _pid) external;
    function getMultiplier(uint256 _from, uint256 _to) external view returns (uint256);
    function sushiPerBlock() external view returns (uint256);
    function totalAllocPoint() external view returns (uint256);
    function pendingSushi(uint256 _pid, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";

interface IVampireAdapter {
    // Victim info
    function rewardToken(uint256 poolId) external view returns (IERC20);
    function rewardValue(uint256 poolId, uint256 amount) external view returns(uint256);
    function poolCount() external view returns (uint256);
    function sellableRewardAmount(uint256 poolId) external view returns (uint256);

    // Victim actions, requires impersonation via delegatecall
    function sellRewardForWeth(address adapter, uint256 poolId, uint256 rewardAmount, address to) external returns(uint256);

    // Pool info
    function lockableToken(uint256 poolId) external view returns (IERC20);
    function lockedAmount(address user, uint256 poolId) external view returns (uint256);
    function pendingReward(address adapter, uint256 poolId, uint256 victimPoolId) external view returns (uint256);

    // Pool actions, requires impersonation via delegatecall
    function deposit(address adapter, uint256 poolId, uint256 amount) external returns (uint256);
    function withdraw(address adapter, uint256 poolId, uint256 amount) external returns (uint256);
    function claimReward(address adapter, uint256 poolId, uint256 victimPoolId) external;

    function emergencyWithdraw(address adapter, uint256 poolId) external;

    // Service methods
    function poolAddress(uint256 poolId) external view returns (address);
    function rewardToWethPool() external view returns (address);

    // Governance info methods
    function lpTokenValue(uint256 amount, IUniswapV2Pair lpToken) external view returns(uint256);
    function lockedValue(address user, uint256 poolId) external view returns (uint256);
    function totalLockedValue(uint256 poolId) external view returns (uint256);
    function normalizedAPY(uint256 poolId) external view returns (uint256);
}

