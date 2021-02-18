// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./interfaces/IBuyback.sol";
import "./interfaces/IBuybackInitializer.sol";
import "./interfaces/ITransferLimiter.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/GSN/Context.sol";

contract Buyback is Context, IBuyback, IBuybackInitializer, ITransferLimiter {
    event BuybackInitialized(uint256 _totalAmount, uint256 _singleAmount, uint256 _minTokensToHold);
    event SingleBuybackExecuted(address _sender, uint256 _senderRewardAmount, uint256 _buybackAmount);

    using SafeMath for uint256;

    bool private isInitialized;
    address private token;
    address private uniswapRouter;
    address private initializer;
    address private treasury;
    address private weth;
    uint256 private totalBuyback;
    uint256 private singleBuyback;
    uint256 private alreadyBoughtBack;
    uint256 private lastBuybackTimestamp;
    uint256 private nextBuybackTimestamp;
    uint256 private lastBuybackBlockNumber;
    uint256 private lastBuybackAmount;
    uint256 private minTokensToHold;

    constructor(
        address _initializer,
        address _treasury,
        address _weth
    ) public {
        initializer = _initializer;
        treasury = _treasury;
        weth = _weth;
    }

    modifier onlyInitializer() {
        require(msg.sender == initializer, "Only initializer allowed.");
        _;
    }

    modifier initialized() {
        require(isInitialized, "Not initialized.");
        _;
    }

    modifier notInitialized() {
        require(!isInitialized, "Already initialized.");
        _;
    }

    modifier scheduled() {
        require(block.timestamp >= nextBuybackTimestamp, "Not scheduled yet.");
        _;
    }

    modifier available() {
        require(totalBuyback > alreadyBoughtBack, "No more funds available.");
        _;
    }

    modifier enoughTokens() {
        require(IERC20(token).balanceOf(msg.sender) >= minTokensToHold, "Insufficient token balance.");
        _;
    }

    function initializerAddress() external view override returns (address) {
        return initializer;
    }

    function tokenAddress() external view override returns (address) {
        return token;
    }

    function uniswapRouterAddress() external view override returns (address) {
        return uniswapRouter;
    }

    function treasuryAddress() external view override returns (address) {
        return treasury;
    }

    function wethAddress() external view override returns (address) {
        return weth;
    }

    function totalAmount() external view override returns (uint256) {
        return totalBuyback;
    }

    function singleAmount() external view override returns (uint256) {
        return singleBuyback;
    }

    function boughtBackAmount() external view override returns (uint256) {
        return alreadyBoughtBack;
    }

    function lastBuyback() external view override returns (uint256) {
        return lastBuybackTimestamp;
    }

    function nextBuyback() external view override returns (uint256) {
        return nextBuybackTimestamp;
    }

    function getTransferLimitPerETH() external view override returns (uint256) {
        if (block.number != lastBuybackBlockNumber || lastBuybackAmount == 0 || singleBuyback == 0) {
            return 0;
        }
        return lastBuybackAmount.mul(10**18).div(singleBuyback);
    }

    function init(
        address _token,
        address _uniswapRouter,
        uint256 _minTokensToHold
    ) external payable override notInitialized onlyInitializer {
        token = _token;
        uniswapRouter = _uniswapRouter;
        totalBuyback = msg.value;
        singleBuyback = totalBuyback.div(10);
        minTokensToHold = _minTokensToHold;
        updateBuybackTimestamps(true);

        isInitialized = true;
        emit BuybackInitialized(totalBuyback, singleBuyback, minTokensToHold);
    }

    function minTokensForBuybackCall() external view override returns (uint256) {
        return minTokensToHold;
    }

    function buyback() external override scheduled initialized available enoughTokens {
        uint256 fundsLeft = totalBuyback.sub(alreadyBoughtBack);
        uint256 actualBuyback = Math.min(fundsLeft, singleBuyback);

        // send 1% to the sender as a reward for triggering the function
        uint256 senderShare = actualBuyback.div(100);
        _msgSender().transfer(senderShare);

        // buy tokens with other 99% and send them to the treasury address
        uint256 buyShare = actualBuyback.sub(senderShare);
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = token;
        uint256[] memory amounts =
            IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{ value: buyShare }(
                0,
                path,
                treasury,
                block.timestamp
            );

        alreadyBoughtBack = alreadyBoughtBack.add(actualBuyback);
        lastBuybackBlockNumber = block.number;
        lastBuybackAmount = amounts[amounts.length - 1];
        updateBuybackTimestamps(false);

        emit SingleBuybackExecuted(msg.sender, senderShare, buyShare);
    }

    function updateBuybackTimestamps(bool _isInit) private {
        lastBuybackTimestamp = _isInit ? 0 : block.timestamp;
        nextBuybackTimestamp = (_isInit ? block.timestamp : nextBuybackTimestamp) + 1 days;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IBuyback {
    event BuybackInitialized(uint256 _totalAmount, uint256 _singleAmount, uint256 _minTokensToHold);

    event SingleBuybackExecuted(address _sender, uint256 _senderRewardAmount, uint256 _buybackAmount);

    function initializerAddress() external view returns (address);

    function tokenAddress() external view returns (address);

    function uniswapRouterAddress() external view returns (address);

    function treasuryAddress() external view returns (address);

    function wethAddress() external view returns (address);

    function totalAmount() external view returns (uint256);

    function singleAmount() external view returns (uint256);

    function boughtBackAmount() external view returns (uint256);

    function lastBuyback() external view returns (uint256);

    function nextBuyback() external view returns (uint256);

    function minTokensForBuybackCall() external view returns (uint256);

    function buyback() external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IBuybackInitializer {
    function init(address _token, address _uniswapRouter, uint256 _minTokensToHold) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface ITransferLimiter {
    function getTransferLimitPerETH() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IUniswapV2Router02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);
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
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
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