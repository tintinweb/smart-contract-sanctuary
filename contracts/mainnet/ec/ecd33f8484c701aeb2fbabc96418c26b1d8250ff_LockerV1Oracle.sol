/**
 *Submitted for verification at Etherscan.io on 2020-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;
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
interface iCHI is IERC20 {
    function freeFromUpTo(address from, uint256 value) external returns (uint256);
    
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
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
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
    interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface IWETH is IERC20{
    function deposit() external payable;
    function withdraw(uint) external;
}


interface ILock3rV1Mini {
    function isLocker(address) external returns (bool);
    function worked(address locker) external;
    function totalBonded() external view returns (uint);
    function bonds(address locker, address credit) external view returns (uint);
    function votes(address locker) external view returns (uint);
    function isMinLocker(address locker, uint minBond, uint earned, uint age) external returns (bool);
    function addCreditETH(address job) external payable;
    function workedETH(address locker) external;
    function credits(address job, address credit) external view returns (uint);
    function receipt(address credit, address locker, uint amount) external;
    function ETH() external view returns (address);
    function receiptETH(address locker, uint amount) external;
}

interface ILock3rV1Plus is ILock3rV1Mini {
    function unbond(address bonding, uint amount) external;
    function withdraw(address bonding) external;
    function unbondings(address locker, address credit) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function jobs(address job) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function LK3RH() external view returns (ILock3rV1Helper);
}

interface ILock3rV1Helper {
    function getQuoteLimit(uint gasUsed) external view returns (uint);
}

// sliding oracle that uses observations collected to provide moving price averages in the past
//Forked from Lock3rV1Oracle with improvements
contract LockerV1Oracle is Ownable {
    using FixedPoint for *;
    using SafeMath for uint;

    /// @notice CHI Cut fee at 50% initially
    uint public FEE = 5000;
    uint constant public BASE = 10000;

    struct Observation {
        uint timestamp;
        uint price0Cumulative;
        uint price1Cumulative;
    }

    uint public minKeep = 400e18;

    modifier locker() {
        require(LK3R.isMinLocker(msg.sender, minKeep, 0, 0), "::isLocker:!locker");
        _;
    }

    modifier upkeep() {
        uint _gasUsed = gasleft();
        require(LK3R.isMinLocker(msg.sender, minKeep, 0, 0), "::isLocker:!locker");
        _;
        //Gas calcs
        uint256 gasDiff = _gasUsed.sub(gasleft());
        uint256 gasSpent = 21000 + gasDiff + 16 * msg.data.length;
        CHI.freeFromUpTo(address(this), (gasSpent + 14154) / 41947);

        uint _reward = LK3R.LK3RH().getQuoteLimit(gasDiff);
        //Calculate chi budget
        uint chiBudget = getChiBudget(_reward);
        //Get LK3R reward to address to swap
        LK3R.receipt(address(LK3R), address(this), _reward.add(chiBudget));

        //Swap and return eth reward
        _reward = _swap(_reward,chiBudget);
        msg.sender.transfer(_reward);
    }

    address public governance;
    address public pendingGovernance;

    function getChiBudget(uint amount) public view returns (uint) {
        return amount.mul(FEE).div(BASE);
    }

    function setChiBudget(uint newBudget) public onlyOwner {
        FEE = newBudget;
    }

    function setMinKeep(uint _keep) external {
        require(msg.sender == governance, "setGovernance: !gov");
        minKeep = _keep;
    }

    /**
     * @notice Allows governance to change governance (for future upgradability)
     * @param _governance new governance address to set
     */
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "setGovernance: !gov");
        pendingGovernance = _governance;
    }

    /**
     * @notice Allows pendingGovernance to accept their role as governance (protection pattern)
     */
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "acceptGovernance: !pendingGov");
        governance = pendingGovernance;
    }

    ILock3rV1Plus public constant LK3R = ILock3rV1Plus(0xe3f3869dDD41C23Eff3630F58E5bFA584C770D67);
    IWETH public constant WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IUniswapV2Router public constant UNI = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    iCHI public CHI = iCHI(0x0000000000004946c0e9F43F4Dee607b0eF1fA1c);

    address public constant factory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint public constant periodSize = 1800;

    address[] internal _pairs;
    mapping(address => bool) internal _known;

    function pairs() external view returns (address[] memory) {
        return _pairs;
    }

    mapping(address => Observation[]) public observations;

    function observationLength(address pair) external view returns (uint) {
        return observations[pair].length;
    }

    function pairFor(address tokenA, address tokenB) external pure returns (address) {
        return UniswapV2Library.pairFor(factory, tokenA, tokenB);
    }

    function pairForWETH(address tokenA) external pure returns (address) {
        return UniswapV2Library.pairFor(factory, tokenA, address(WETH));
    }

    constructor() public {
        governance = msg.sender;
        //Approve CHI for freeFromUpTo
        require(CHI.approve(address(this), uint256(-1)));
        //Infapprove of lk3r to uniswap router
        require(LK3R.approve(address(UNI), uint256(-1)));

    }

    function updatePair(address pair) external locker returns (bool) {
        return _update(pair);
    }

    function update(address tokenA, address tokenB) external locker returns (bool) {
        address pair = UniswapV2Library.pairFor(factory, tokenA, tokenB);
        return _update(pair);
    }

    function _addPair(address pair) internal {
        require(!_known[pair], "known");
        _known[pair] = true;
        _pairs.push(pair);

        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        observations[pair].push(Observation(block.timestamp, price0Cumulative, price1Cumulative));
    }

    //Add pairs directly
    function addPair(address pair) public upkeep {
        require(msg.sender == governance, "UniswapV2Oracle::add: !gov");
        _addPair(pair);
    }

    //Using upkeep to save on gas
    function batchAddPairs(address[] memory pairsToAdd) public upkeep {
        require(msg.sender == governance, "UniswapV2Oracle::add: !gov");
        for(uint i=0;i<pairsToAdd.length;i++)
            _addPair(pairsToAdd[i]);
    }

    function add(address tokenA, address tokenB) external {
        //Call parent addPair function to avoid duplicated code
        addPair(UniswapV2Library.pairFor(factory, tokenA, tokenB));
    }

    function work() public upkeep {
        bool worked = _updateAll();
        require(worked, "UniswapV2Oracle: !work");
    }

    function workForFree() public locker {
        bool worked = _updateAll();
        require(worked, "UniswapV2Oracle: !work");
    }

    function lastObservation(address pair) public view returns (Observation memory) {
        return observations[pair][observations[pair].length-1];
    }

    function _updateAll() internal returns (bool updated) {
        for (uint i = 0; i < _pairs.length; i++) {
            if (_update(_pairs[i])) {
                updated = true;
            }
        }
    }

    function updateFor(uint i, uint length) external locker returns (bool updated) {
        for (; i < length; i++) {
            if (_update(_pairs[i])) {
                updated = true;
            }
        }
    }

    function workable(address pair) public view returns (bool) {
        return (block.timestamp - lastObservation(pair).timestamp) > periodSize;
    }

    function workable() external view returns (bool) {
        for (uint i = 0; i < _pairs.length; i++) {
            if (workable(_pairs[i])) {
                return true;
            }
        }
        return false;
    }

    function _update(address pair) internal returns (bool) {
        // we only want to commit updates once per period (i.e. windowSize / granularity)
        Observation memory _point = lastObservation(pair);
        uint timeElapsed = block.timestamp - _point.timestamp;
        if (timeElapsed > periodSize) {
            (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
            observations[pair].push(Observation(block.timestamp, price0Cumulative, price1Cumulative));
            return true;
        }
        return false;
    }

    function computeAmountOut(
        uint priceCumulativeStart, uint priceCumulativeEnd,
        uint timeElapsed, uint amountIn
    ) private pure returns (uint amountOut) {
        // overflow is desired.
        FixedPoint.uq112x112 memory priceAverage = FixedPoint.uq112x112(
            uint224((priceCumulativeEnd - priceCumulativeStart) / timeElapsed)
        );
        amountOut = priceAverage.mul(amountIn).decode144();
    }

    function _valid(address pair, uint age) internal view returns (bool) {
        return (block.timestamp - lastObservation(pair).timestamp) <= age;
    }

    function current(address tokenIn, uint amountIn, address tokenOut) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        require(_valid(pair, periodSize.mul(2)), "UniswapV2Oracle::quote: stale prices");
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        Observation memory _observation = lastObservation(pair);
        (uint price0Cumulative, uint price1Cumulative,) = UniswapV2OracleLibrary.currentCumulativePrices(pair);
        if (block.timestamp == _observation.timestamp) {
            _observation = observations[pair][observations[pair].length-2];
        }

        uint timeElapsed = block.timestamp - _observation.timestamp;
        timeElapsed = timeElapsed == 0 ? 1 : timeElapsed;
        if (token0 == tokenIn) {
            return computeAmountOut(_observation.price0Cumulative, price0Cumulative, timeElapsed, amountIn);
        } else {
            return computeAmountOut(_observation.price1Cumulative, price1Cumulative, timeElapsed, amountIn);
        }
    }

    function quote(address tokenIn, uint amountIn, address tokenOut, uint granularity) external view returns (uint amountOut) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        require(_valid(pair, periodSize.mul(granularity)), "UniswapV2Oracle::quote: stale prices");
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);

        uint priceAverageCumulative = 0;
        uint length = observations[pair].length-1;
        uint i = length.sub(granularity);


        uint nextIndex = 0;
        if (token0 == tokenIn) {
            for (; i < length; i++) {
                nextIndex = i+1;
                priceAverageCumulative += computeAmountOut(
                    observations[pair][i].price0Cumulative,
                    observations[pair][nextIndex].price0Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
            }
        } else {
            for (; i < length; i++) {
                nextIndex = i+1;
                priceAverageCumulative += computeAmountOut(
                    observations[pair][i].price1Cumulative,
                    observations[pair][nextIndex].price1Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
            }
        }
        return priceAverageCumulative.div(granularity);
    }

    function prices(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 1);
    }

    function sample(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) public view returns (uint[] memory) {
        address pair = UniswapV2Library.pairFor(factory, tokenIn, tokenOut);
        (address token0,) = UniswapV2Library.sortTokens(tokenIn, tokenOut);
        uint[] memory _prices = new uint[](points);

        uint length = observations[pair].length-1;
        uint i = length.sub(points * window);
        uint nextIndex = 0;
        uint index = 0;

        if (token0 == tokenIn) {
            for (; i < length; i+=window) {
                nextIndex = i + window;
                _prices[index] = computeAmountOut(
                    observations[pair][i].price0Cumulative,
                    observations[pair][nextIndex].price0Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
                index = index + 1;
            }
        } else {
            for (; i < length; i+=window) {
                nextIndex = i + window;
                _prices[index] = computeAmountOut(
                    observations[pair][i].price1Cumulative,
                    observations[pair][nextIndex].price1Cumulative,
                    observations[pair][nextIndex].timestamp - observations[pair][i].timestamp, amountIn);
                index = index + 1;
            }
        }
        return _prices;
    }

    function hourly(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 2);
    }

    function daily(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 48);
    }

    function weekly(address tokenIn, uint amountIn, address tokenOut, uint points) external view returns (uint[] memory) {
        return sample(tokenIn, amountIn, tokenOut, points, 336);
    }

    function realizedVolatility(address tokenIn, uint amountIn, address tokenOut, uint points, uint window) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, points, window));
    }

    function realizedVolatilityHourly(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, 1, 2));
    }

    function realizedVolatilityDaily(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, 1, 48));
    }

    function realizedVolatilityWeekly(address tokenIn, uint amountIn, address tokenOut) external view returns (uint) {
        return stddev(sample(tokenIn, amountIn, tokenOut, 1, 336));
    }

    /**
     * @dev sqrt calculates the square root of a given number x
     * @dev for precision into decimals the number must first
     * @dev be multiplied by the precision factor desired
     * @param x uint256 number for the calculation of square root
     */
    function sqrt(uint256 x) public pure returns (uint256) {
        uint256 c = (x + 1) / 2;
        uint256 b = x;
        while (c < b) {
            b = c;
            c = (x / c + c) / 2;
        }
        return b;
    }

    /**
     * @dev stddev calculates the standard deviation for an array of integers
     * @dev precision is the same as sqrt above meaning for higher precision
     * @dev the decimal place must be moved prior to passing the params
     * @param numbers uint[] array of numbers to be used in calculation
     */
    function stddev(uint[] memory numbers) public pure returns (uint256 sd) {
        uint sum = 0;
        for(uint i = 0; i < numbers.length; i++) {
            sum += numbers[i];
        }
        uint256 mean = sum / numbers.length;        // Integral value; float not supported in Solidity
        sum = 0;
        uint i;
        for(i = 0; i < numbers.length; i++) {
            sum += (numbers[i] - mean) ** 2;
        }
        sd = sqrt(sum / (numbers.length - 1));      //Integral value; float not supported in Solidity
        return sd;
    }


    /**
     * @dev blackScholesEstimate calculates a rough price estimate for an ATM option
     * @dev input parameters should be transformed prior to being passed to the function
     * @dev so as to remove decimal places otherwise results will be far less accurate
     * @param _vol uint256 volatility of the underlying converted to remove decimals
     * @param _underlying uint256 price of the underlying asset
     * @param _time uint256 days to expiration in years multiplied to remove decimals
     */
    function blackScholesEstimate(
        uint256 _vol,
        uint256 _underlying,
        uint256 _time
    ) public pure returns (uint256 estimate) {
        estimate = 40 * _vol * _underlying * sqrt(_time);
        return estimate;
    }

    /**
     * @dev fromReturnsBSestimate first calculates the stddev of an array of price returns
     * @dev then uses that as the volatility param for the blackScholesEstimate
     * @param _numbers uint256[] array of price returns for volatility calculation
     * @param _underlying uint256 price of the underlying asset
     * @param _time uint256 days to expiration in years multiplied to remove decimals
     */
    function retBasedBlackScholesEstimate(
        uint256[] memory _numbers,
        uint256 _underlying,
        uint256 _time
    ) public pure {
        uint _vol = stddev(_numbers);
        blackScholesEstimate(_vol, _underlying, _time);
    }

    receive() external payable {}

    function _swap(uint _amount,uint chiBudget) internal returns (uint) {
        address[] memory path = new address[](2);
        path[0] = address(LK3R);
        path[1] = address(WETH);
        //Swap to ETH
        uint[] memory amounts = UNI.swapExactTokensForTokens(_amount, uint256(0), path, address(this), now.add(1800));
        WETH.withdraw(amounts[1]);

        //Swap the 10% of LK3R to CHI
        address[] memory pathtoChi = new address[](3);

        pathtoChi[0] = address(LK3R);
        pathtoChi[1] = address(WETH);
        pathtoChi[2] = address(CHI);
        //Swap to CHI
        UNI.swapExactTokensForTokens(chiBudget, uint256(0), pathtoChi, address(this), now.add(1800));

        return amounts[1];
    }

    function getTokenBalance(address tokenAddress) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function sendERC20(address tokenAddress,address receiver) internal {
        IERC20(tokenAddress).transfer(receiver, getTokenBalance(tokenAddress));
    }

    function recoverERC20(address token) public onlyOwner {
        sendERC20(token,owner());
    }

    //Use this to depricate this job to move lk3r to another job later
    function destructJob() public onlyOwner {
     //Get the credits for this job first
     uint256 currLK3RCreds = LK3R.credits(address(this),address(LK3R));
     uint256 currETHCreds = LK3R.credits(address(this),LK3R.ETH());
     //Send out LK3R Credits if any
     if(currLK3RCreds > 0) {
        //Invoke receipt to send all the credits of job to owner
        LK3R.receipt(address(LK3R),owner(),currLK3RCreds);
     }
     //Send out ETH credits if any
     if (currETHCreds > 0) {
        LK3R.receiptETH(owner(),currETHCreds);
     }
     //Send out chi balance
     recoverERC20(address(CHI));
     //Finally self destruct the contract after sending the credits
     selfdestruct(payable(owner()));
    }
}