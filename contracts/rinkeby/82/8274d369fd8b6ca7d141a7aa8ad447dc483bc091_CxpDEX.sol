/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;


// 
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

// 
/**
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

// 
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
    constructor() {
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

// 
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

//
contract CxpDEX is Pausable {

    using SafeMath for uint256;
    IERC20 public tokenA;
    IERC20 public tokenB;

    uint256 public totalLiquidity;
    mapping(address => uint256) public liquidity;
    // TODO: slippage should be calculated from back-end
    uint256 public currentRate;

    //Section Events
    event PoolCreated(uint256 totalLiquidity, address investor, uint256 token_amountA, uint256 token_amountB);

    event PurchasedTokens(address purchaser, uint256 coins, uint256 tokensBought);
    event TokensSold(address vendor, uint256 eth_bought, uint256 token_amount);

    event LiquidityChanged(uint256 oldLiq, uint256 newLiq);
    event LiquidityWithdraw(address investor, uint256 coins, uint256 token_amount, uint256 newliquidity);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    function init(uint amountA, uint amountB) public returns (uint256) {
        require(tokenA.allowance(_msgSender(), address(this)) >= amountA, "1");
        require(tokenB.allowance(_msgSender(), address(this)) >= amountB, "2");
        require(totalLiquidity == 0, "DEX:init - already has liquidity");

        totalLiquidity = amountA;
        liquidity[msg.sender] = totalLiquidity;
        require(tokenA.transferFrom(msg.sender, address(this), amountA));
        require(tokenB.transferFrom(msg.sender, address(this), amountB));

        emit PoolCreated(totalLiquidity, _msgSender(), amountA, amountB);
        currentRate = amountB / amountA;
        return totalLiquidity;
    }

    function slippage(address tokenIn, uint amountIn) public view returns (int) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        if (tokenIn == address(tokenA)) {
            uint256 tokensBought = swapPrice(tokenIn, address(tokenB), amountIn);
            return int(currentRate.sub(tokensBought.div(amountIn)).mul(10000).div(currentRate));
        } else {
            uint256 tokensBought = swapPrice(tokenIn, address(tokenA), amountIn);
            return int(amountIn.sub(tokensBought.mul(currentRate)).mul(10000).div(amountIn));
        }
    }

    function swapPrice(address tokenIn, address tokenOut, uint amountIn) public view returns (uint) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');

        uint256 reserveIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));

        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(996);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        return numerator / denominator;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function price(uint amountIn, uint reserveIn, uint reserveOut) private pure returns (uint256) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 amountInWithFee = amountIn.mul(996);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        return numerator / denominator;
    }

    function planePrice(address tokenIn, address tokenOut, uint amountIn) public view returns (uint256) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');

        uint256 reserveIn = IERC20(tokenIn).balanceOf(address(this));
        uint256 reserveOut = IERC20(tokenOut).balanceOf(address(this));

        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint256 inputAmountWithFee0 = amountIn;
        uint256 numerator = inputAmountWithFee0.mul(reserveOut);
        uint256 denominator = reserveIn.add(inputAmountWithFee0);
        return numerator / denominator;
    }

    function calcFee(address tokenIn, uint amountIn) public view returns (uint256) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        if (tokenIn == address(tokenA)) {
            return amountIn.mul(4).div(1000);
        } else {
            return planePrice(tokenIn, address(tokenA), amountIn) - swapPrice(tokenIn, address(tokenA), amountIn);
        }
    }

    function sellTokenB(uint256 tokena_amount) whenNotPaused external returns (uint256) {
        require(tokenA.allowance(_msgSender(), address(this)) >= tokena_amount, "!aptk");

        require(totalLiquidity > 0, "1");

        uint256 tokena_reserve = tokenA.balanceOf(address(this));
        uint256 tokenb_reserve = tokenB.balanceOf(address(this));
        uint256 tokens_bought = price(tokena_amount, tokena_reserve, tokenb_reserve);

        require(tokenA.transferFrom(_msgSender(), address(this), tokena_amount));

        require(tokenB.transfer(_msgSender(), tokens_bought), "5");

        emit PurchasedTokens(_msgSender(), tokena_amount, tokens_bought);
        currentRate = tokens_bought / tokena_amount;
        return tokens_bought;
    }

    function sellTokenA(uint256 tokenb_amount) whenNotPaused external returns (uint256) {
        require(tokenB.allowance(_msgSender(), address(this)) >= tokenb_amount, "!aptk");

        require(totalLiquidity > 0, "1");
        uint256 tokenb_reserve = tokenB.balanceOf(address(this));

        uint256 tokena_bought = price(tokenb_amount, tokenb_reserve, tokenA.balanceOf(address(this)));

        require(tokenA.transfer(_msgSender(), tokena_bought), "4");

        require(tokenB.transferFrom(_msgSender(), address(this), tokenb_amount), "5");

        emit TokensSold(_msgSender(), tokena_bought, tokenb_amount);
        currentRate = tokenb_amount / tokena_bought;
        return tokena_bought;
    }

    function deposit(uint256 amountA) whenNotPaused external returns (uint256) {
        uint reserveA = tokenA.balanceOf(address(this));
        uint reserveB = tokenB.balanceOf(address(this));
        uint256 amountB = (amountA.mul(reserveB) / reserveA).add(1);

        require(_msgSender() != address(0) && tokenB.allowance(_msgSender(), address(this)) >= amountB, "1");

        require(tokenA.allowance(_msgSender(), address(this)) >= amountA, "2");

        uint256 liquidity_minted = amountA.mul(totalLiquidity) / reserveA;
        liquidity[msg.sender] = liquidity[msg.sender].add(liquidity_minted);

        uint256 oldLiq = totalLiquidity;
        totalLiquidity = totalLiquidity.add(liquidity_minted);

        require(tokenA.transferFrom(_msgSender(), address(this), amountA));
        require(tokenB.transferFrom(msg.sender, address(this), amountB));

        emit LiquidityChanged(oldLiq, totalLiquidity);
        return liquidity_minted;
    }

    function withdraw(uint256 amount) whenNotPaused public returns (uint256, uint256) {
        require(totalLiquidity > 0, "1");

        uint reserveB = tokenB.balanceOf(address(this));
        uint256 amountA = amount.mul(tokenA.balanceOf(address(this))).div(totalLiquidity);
        uint256 amountB = amount.mul(reserveB) / totalLiquidity;
        liquidity[msg.sender] = liquidity[msg.sender].sub(amountA);

        uint256 oldLiq = totalLiquidity;

        totalLiquidity = totalLiquidity.sub(amount);

        require(tokenA.transfer(_msgSender(), amountA), "6");

        require(tokenB.transfer(_msgSender(), amountB), "7");

        emit LiquidityWithdraw(_msgSender(), amountA, amountB, totalLiquidity);
        emit LiquidityChanged(oldLiq, totalLiquidity);
        return (amountA, amountB);
    }

    function getCalcRewardAmount(address account, uint256 amount) public view returns (uint256, uint256)    {
        if (liquidity[account] <= 0) return (0, 0);

        uint reserveB = tokenB.balanceOf(address(this));
        uint256 amountA = amount.mul(tokenA.balanceOf(address(this))).div(totalLiquidity);
        uint256 amountB = amount.mul(reserveB) / totalLiquidity;

        return (amountA, amountB);
    }
}