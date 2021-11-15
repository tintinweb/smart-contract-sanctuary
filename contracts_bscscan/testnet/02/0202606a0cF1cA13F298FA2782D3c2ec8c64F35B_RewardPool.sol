// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IPancakeFactory {
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
pragma solidity ^0.8.0;

interface IPancakeRouter01 {

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
    )
        external returns (
            uint amountA,
            uint amountB,
            uint liquidity
        )
    ;

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external
        payable returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        )
    ;

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external returns (
            uint amountA,
            uint amountB
        )
    ;

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external returns (
            uint amountToken,
            uint amountETH
        )
    ;

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external returns (
            uint amountA,
            uint amountB
        )
    ;

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external returns (
            uint amountToken,
            uint amountETH
        )
    ;

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external returns (
            uint[] memory amounts
        )
    ;

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external returns (
            uint[] memory amounts
        )
    ;

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
    returns (
            uint[] memory amounts
        )
    ;

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
    returns (
            uint[] memory amounts
        )
    ;

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
    returns (
            uint[] memory amounts
        )
    ;

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable
    returns (
            uint[] memory amounts
        )
    ;

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    )
        external
        pure returns (
            uint amountOut
        )
    ;

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    )
        external
        pure returns (
            uint amountIn
        )
    ;

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    )
        external
        view returns (
            uint[] memory amounts
        )
    ;

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    )
        external
        view returns (
            uint[] memory amounts
        )
    ;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPancakeRouter01.sol";

interface IPancakeRouter02 is IPancakeRouter01 {

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        external returns (
            uint amountETH
        )
    ;

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        external returns (
            uint amountETH
        )
    ;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external
        payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    )
        external;
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IRewardPool {
    function collectingRewards(uint256 amonut, uint256 n) external;
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Utils.sol";
import "./IPancakeFactory.sol";
import "./IPancakeRouter02.sol";
import "./IRewardPool.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract RewardPool is IRewardPool, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    
    address public TOKEN;
    uint256 public TOKEN_DECIMAL;
    address public BUSD;

    uint256[3] public REFERRAL_PERCENTS = [30, 15, 5];
    uint256[3] public BONUS_PERCENTS = [618, 236, 146];
    uint256 constant private PERCENTS_DIVIDER = 1000;

    uint256 counter = 0;

    struct Deposit {
        uint256 amount;
        uint256 readyCheckpoint;
        bool pending;
    }

    struct UserInfo {
        uint256 amount;
        uint256 dividendDebt;
        uint256 bonusProfit;
        address referrer;
        uint256 refBonus;
        uint256 totalRefBonus;
        uint256[3] refLevels;
        uint256 depositCheckpoint;
        uint256 debtCheckpoint;
        Deposit[] deposits;
    }
    mapping(address => UserInfo) private userInfo;

    address[] private addressIndex;

    struct Dividend {
        uint256 delegatedToken;
        uint256 turnoverBUSD;
        uint256 dividendperShare;
        uint256 timestamp;
    }
    mapping(uint256 => Dividend) private dividends;
    mapping(uint256 => uint256) private pendingToken;

    struct PoolInfo {
        uint256 dividendCheckpoint;
        uint256 totalDividends;
    }
    PoolInfo private poolInfo;

    struct BonusPool {
        uint256 enableBonus;
        uint256 nextBonusCalculation;
        uint256 totalBonus;
        address[3] winner;
        uint256[3] amountBonus;
    }
    BonusPool private bonusPool;

    event CollectingRewardEvent(address tokencontract, uint256 amount, uint256 n);
    event DepositEvent(address indexed user, uint256 amount);
    event WithdrawEvent(address indexed user, uint256 amount);
    event ClaimRewardEvent(address indexed user, uint256 amount);
    event DailyRewardEvent(uint256 reward, uint256 amount);
    event BonusWinnerEvent(address user1, uint256 amount1, address user2, uint256 amount2, address user3, uint256 amount3);

    // test busd 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7
    constructor (address token, address busd, uint256 starttime) {

        uint256 start = starttime;
        TOKEN = token;
        BUSD = busd;
        TOKEN_DECIMAL = 10**IERC20Metadata(TOKEN).decimals();

        poolInfo.dividendCheckpoint = 0;
        poolInfo.totalDividends = 0;

        dividends[poolInfo.dividendCheckpoint].delegatedToken = 0;
        dividends[poolInfo.dividendCheckpoint].turnoverBUSD = 0;
        dividends[poolInfo.dividendCheckpoint].timestamp = start;
        dividends[poolInfo.dividendCheckpoint].dividendperShare = 0;

        bonusPool.enableBonus = 4;
        bonusPool.nextBonusCalculation = start;
        bonusPool.totalBonus = 0;
        bonusPool.winner = [address(0), address(0), address(0)];
        bonusPool.amountBonus = [0, 0, 0];
    }
    
        //to receive BNB from pancakeRouter when swapping
    receive() external payable {
    }

    function collectingRewards(uint256 amount, uint256 n) override external {
        require(msg.sender == TOKEN, "Unknown address");
        counter = counter.add(n);
        if (amount > 0) {
            _updatePool(amount);
            emit CollectingRewardEvent(msg.sender, amount, n);
        }
    }

    function _updatePool(uint256 reward) timedTransitions internal {
        uint256 totalDeposits = IERC20Metadata(TOKEN).balanceOf(address(this));
        totalDeposits = totalDeposits.sub(pendingToken[poolInfo.dividendCheckpoint]);

        uint256 addRewardPool = reward;
        uint256 addBonusPool = 0;

        if (0 < bonusPool.enableBonus) {
            addRewardPool = reward.mul(990).div(PERCENTS_DIVIDER);
            addBonusPool = reward.sub(addRewardPool);
        }

        poolInfo.totalDividends = poolInfo.totalDividends.add(addRewardPool);
        dividends[poolInfo.dividendCheckpoint].turnoverBUSD = dividends[poolInfo.dividendCheckpoint].turnoverBUSD.add(addRewardPool);
        dividends[poolInfo.dividendCheckpoint].delegatedToken = totalDeposits;
        bonusPool.totalBonus = bonusPool.totalBonus.add(addBonusPool);
    }

    modifier timedTransitions() {

        Dividend storage dividend = dividends[poolInfo.dividendCheckpoint];

        if (block.timestamp >= dividend.timestamp) {
            _calulateDailyDividend();
            emit DailyRewardEvent(dividend.turnoverBUSD, dividend.delegatedToken);
        }

        if (block.timestamp >= bonusPool.nextBonusCalculation) {
            if (_calulateBonus()) {
                emit BonusWinnerEvent(bonusPool.winner[0], bonusPool.amountBonus[0], 
                    bonusPool.winner[1], bonusPool.amountBonus[1], 
                    bonusPool.winner[2], bonusPool.amountBonus[2]);
            }
        }
        _;
    }

    function _calulateDailyDividend() internal {

        uint256 nextCheckpoint =  poolInfo.dividendCheckpoint.add(1);
        Dividend storage dividendNow = dividends[poolInfo.dividendCheckpoint];

        uint256 totalDeposits = IERC20Metadata(TOKEN).balanceOf(address(this));
        dividendNow.delegatedToken = totalDeposits.sub(pendingToken[poolInfo.dividendCheckpoint]);

        if (dividendNow.delegatedToken != 0) {
            dividendNow.dividendperShare = dividendNow.turnoverBUSD.mul(TOKEN_DECIMAL).div(dividendNow.delegatedToken);
            dividends[nextCheckpoint].turnoverBUSD = 0;
        } else {
            dividends[nextCheckpoint].turnoverBUSD = dividendNow.turnoverBUSD;
        }
        
        dividends[nextCheckpoint].dividendperShare = 0;
        dividends[nextCheckpoint].delegatedToken = dividendNow.delegatedToken;
        dividends[nextCheckpoint].timestamp = dividendNow.timestamp.add(1 days) ;
        poolInfo.dividendCheckpoint = nextCheckpoint;
    }

    function _calulateBonus() internal returns (bool) {
        uint256 timeshift = 1 days;

        if (bonusPool.enableBonus == 0) {
            bonusPool.nextBonusCalculation = bonusPool.nextBonusCalculation.add(timeshift);
            return false;
        }

        uint arrayLength = addressIndex.length;
        if (arrayLength < 3) {
            return false;
        }
        uint256 winner1 = Utils.random(0, arrayLength - 1, bonusPool.totalBonus + 123456789);
        uint256 winner2 = Utils.random(0, arrayLength - 1, bonusPool.totalBonus + 987654321);
        uint256 winner3 = Utils.random(0, arrayLength - 1, bonusPool.totalBonus + 432156789);

        bonusPool.amountBonus[0] = bonusPool.totalBonus.mul(BONUS_PERCENTS[0]).div(PERCENTS_DIVIDER);
        bonusPool.amountBonus[1] = bonusPool.totalBonus.mul(BONUS_PERCENTS[1]).div(PERCENTS_DIVIDER);
        bonusPool.amountBonus[2] = bonusPool.totalBonus.mul(BONUS_PERCENTS[2]).div(PERCENTS_DIVIDER);
        bonusPool.winner[0] = addressIndex[winner1];
        bonusPool.winner[1] = addressIndex[winner2];
        bonusPool.winner[2] = addressIndex[winner3];

        userInfo[bonusPool.winner[0]].bonusProfit = userInfo[bonusPool.winner[0]].bonusProfit.add(bonusPool.amountBonus[0]);
        userInfo[bonusPool.winner[1]].bonusProfit = userInfo[bonusPool.winner[1]].bonusProfit.add(bonusPool.amountBonus[1]);
        userInfo[bonusPool.winner[2]].bonusProfit = userInfo[bonusPool.winner[2]].bonusProfit.add(bonusPool.amountBonus[2]);

        bonusPool.totalBonus = 0;
        bonusPool.nextBonusCalculation = bonusPool.nextBonusCalculation.add(timeshift.div(bonusPool.enableBonus));

        return true;
    }

    function withdraw(uint256 amount) public nonReentrant timedTransitions {
        require(userInfo[msg.sender].deposits.length > 0, "user has no deposit");

		_updateDividendDept(msg.sender);
        _updatePendingDeposit(msg.sender);
       
        uint256 maxamount = _maxAmount(msg.sender);

        require(amount <= maxamount, "withdraw too much");
        
        _removeBalance(msg.sender, amount);

        IERC20Metadata(TOKEN).transferFrom(address(this), address(msg.sender), amount);

        emit WithdrawEvent(msg.sender, amount);
    }

    function _maxAmount(address ofAddress) internal view returns (uint256) {
        UserInfo storage user = userInfo[ofAddress];
        uint256 maxamount = user.amount;

        for (uint256 i = user.depositCheckpoint; i < user.deposits.length;i++) {
            Deposit storage deposit = user.deposits[i];
            if (deposit.pending) {
                maxamount += deposit.amount;
            }
        }
        return maxamount;
    }

    function _removeBalance(address ofAddress, uint256 amount) internal {
        UserInfo storage user = userInfo[ofAddress];
        uint256 toremove = amount;

        if (0 == user.deposits.length) {
            return;
        }

        for (int256 i = int256(user.deposits.length)-1 ; i >= int256(user.depositCheckpoint);i--) {
            Deposit storage deposit = user.deposits[uint256(i)];
            uint256 pendingCheckpoint = deposit.readyCheckpoint.sub(1);
            if ((deposit.pending) && (toremove < deposit.amount)) {

                deposit.amount = deposit.amount.sub(toremove);
                pendingToken[pendingCheckpoint] = pendingToken[pendingCheckpoint].sub(toremove);
                toremove = 0;
                break;
            } else if (deposit.pending) {
                toremove = toremove.sub(deposit.amount);
                uint256 beforeCheckpoint = deposit.readyCheckpoint.sub(1);
                pendingToken[beforeCheckpoint] = pendingToken[beforeCheckpoint].sub(deposit.amount);
                user.deposits.pop();
            }
        }
        user.amount = user.amount.sub(toremove);
    }

    function delegate(
        address referrer,
        uint256 amount
    )
        public
        nonReentrant
        timedTransitions {
        require(msg.sender != address (
                0
                )
            , "user can not deposit");
        require(TOKEN_DECIMAL <= amount, "Minimum amount 1 token");
        require(IERC20Metadata(TOKEN).balanceOf(msg.sender) >= 0, "User has no token");

        IERC20Metadata(TOKEN).transferFrom(msg.sender, address(this), amount);

        _addReferrer(msg.sender, referrer);

        _addToIndex(msg.sender);

		_updateDividendDept(msg.sender);
        _updatePendingDeposit(msg.sender);

        uint256 pendingCheckpoint = poolInfo.dividendCheckpoint.add(1);
        pendingToken[poolInfo.dividendCheckpoint] = pendingToken[poolInfo.dividendCheckpoint].add(amount);

        UserInfo storage user = userInfo[msg.sender];
        if (user.amount == 0 && user.deposits.length == 0) {
            user.debtCheckpoint = pendingCheckpoint;
        }
        user.deposits.push(Deposit(amount, pendingCheckpoint, true));

        emit DepositEvent(msg.sender, amount);
    }

    function claim() public nonReentrant timedTransitions {
        UserInfo storage user = userInfo[msg.sender];
        
        _updateDividendDept(msg.sender);

        _updatePendingDeposit(msg.sender);

        uint256 pending = user.dividendDebt;
        pending -= _calcRefLinkBonus(msg.sender, pending);
        pending += user.refBonus;
        pending += user.bonusProfit;
		require(pending > 0, "user has no reward yet");
        
        if (!safeBUSDTransfer(msg.sender, pending)) {
            return;
        }

        user.dividendDebt = 0;
        user.refBonus = 0;
        user.bonusProfit = 0;

        emit ClaimRewardEvent(msg.sender, pending);
    }
/*************************************************************************************************** */
    function _updateDividendDept(address from) internal {
        UserInfo storage user = userInfo[from];
        
        if(user.amount == 0){
            return;
        }

        for (uint256 i = user.debtCheckpoint; i < poolInfo.dividendCheckpoint;i++) {
            uint256 dividend = dividends[i].dividendperShare.mul(user.amount).div(TOKEN_DECIMAL);
            user.dividendDebt = user.dividendDebt.add(dividend);
            user.debtCheckpoint = user.debtCheckpoint.add(1);
        }
    }

    function _calulateDividendDept(address from) internal view returns (uint256 debt) {
          UserInfo storage user = userInfo[from];
        debt = 0;
        if(user.amount > 0){
        
            for (uint256 i = user.debtCheckpoint; i < poolInfo.dividendCheckpoint;i++) {
                uint256 dividend = dividends[i].dividendperShare.mul(user.amount).div(TOKEN_DECIMAL);
                debt = debt.add(dividend);
            }
        }
    }
    
    function _updatePendingDeposit(address from) internal {
        UserInfo storage user = userInfo[from];

        for (uint256 i = user.depositCheckpoint; i < user.deposits.length;i++) {
            Deposit storage deposit = user.deposits[i];
            if ((deposit.readyCheckpoint <= poolInfo.dividendCheckpoint) && (deposit.pending)) {
                deposit.pending = false;
                user.amount = user.amount.add(deposit.amount);
                user.depositCheckpoint = user.depositCheckpoint.add(1);

                uint256 diff = deposit.readyCheckpoint - poolInfo.dividendCheckpoint;
                if (diff > 0) {
                    uint256 divindend = dividends[deposit.readyCheckpoint].dividendperShare.mul(deposit.amount).div(TOKEN_DECIMAL);
                    user.dividendDebt = user.dividendDebt.add(divindend);
                }
            }
        }
    }

    function _calulatePendingDeposit(address from) internal view returns (uint256 debt) {
        UserInfo storage user = userInfo[from];
        debt = 0;
        for (uint256 i = user.depositCheckpoint; i < user.deposits.length; i++) {
            Deposit storage deposit = user.deposits[i];
            if ((deposit.readyCheckpoint <= poolInfo.dividendCheckpoint) && (deposit.pending)) {
                uint256 diff = deposit.readyCheckpoint - poolInfo.dividendCheckpoint;
                if (diff > 0) {
                    uint256 divindend = dividends[deposit.readyCheckpoint].dividendperShare.mul(deposit.amount).div(TOKEN_DECIMAL);
                    debt = debt.add(divindend);
                }
            }
        }
    }

/**************************************************************************************************** */
    function _getPendingDeposit(
        address from
    )
        internal
        view returns (
            uint256 stillpending,
            uint256 alreadymature
        )
    {
        UserInfo storage user = userInfo[from];
        stillpending = 0;
        alreadymature = 0;
        for (uint256 i = user.depositCheckpoint; i < user.deposits.length;i++) {
            Deposit storage deposit = user.deposits[i];
            if (deposit.pending) {
                if (deposit.readyCheckpoint > poolInfo.dividendCheckpoint) {
                    stillpending = stillpending.add(deposit.amount);
                } else {
                    alreadymature = alreadymature.add(deposit.amount);
                }
            }
        }
    }

    function _addReferrer(address fromaddr, address referrer) internal {

        UserInfo storage user = userInfo[fromaddr];

        if (user.referrer == address(0) && user.deposits.length == 0) {
            if (userInfo[referrer].deposits.length > 0 && referrer != fromaddr) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3;i++) {
                if (upline != address(0)) {
                    userInfo[upline].refLevels[i] = userInfo[upline].refLevels[i].add(1);
                    upline = userInfo[upline].referrer;
                } else break;
            }
        }
    }

    function _addToIndex(address addr) private {
        if (!_isIndexed(addr)) {
            addressIndex.push(addr);
        }
    }

    function _isIndexed(address addr) internal view returns (bool) {
        uint arrayLength = addressIndex.length;
        bool result = false;
        for (uint i = 0; i < arrayLength;i++) {
            if (addressIndex[i] == addr) {
                result = true;
                break;
            }
        }
        return result;
    }

    function _removeFromIndex(address addr) private {
        uint indexToBeDeleted;
        uint arrayLength = addressIndex.length;

        for (uint i=0; i < arrayLength;i++) {
            if (addressIndex[i] == addr) {
                indexToBeDeleted = i;
                break;
            }
        }
        // if index to be deleted is not the last index, swap position.
        if (indexToBeDeleted < arrayLength - 1) {
            addressIndex[indexToBeDeleted] = addressIndex[arrayLength-1];
        }
        addressIndex.pop();
    }

    function _calcRefLinkBonus(address ofAddress, uint256 reward) internal returns (uint256) {
        uint256 allbonus = 0;
        if (userInfo[ofAddress].referrer != address(0)) {

            address upline = userInfo[ofAddress].referrer;
            for (uint256 i = 0; i < 3;i++) {
                if (upline != address(0)) {
                    uint256 amount = reward.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    allbonus = allbonus.add(amount);
                    userInfo[upline].refBonus = userInfo[upline].refBonus.add(amount);
                    userInfo[upline].totalRefBonus = userInfo[upline].totalRefBonus.add(amount);
                    upline = userInfo[upline].referrer;
                } else break;
            }
        }
        return allbonus;
    }

    function _estimateRefLinkBonus(address ofAddress, uint256 reward) internal view returns (uint256) {
        uint256 allbonus = 0;
        if (userInfo[ofAddress].referrer != address(0)) {

            address upline = userInfo[ofAddress].referrer;
            for (uint256 i = 0; i < 3;i++) {
                if (upline != address(0)) {
                    uint256 amount = reward.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    allbonus = allbonus.add(amount);
                    upline = userInfo[upline].referrer;
                } else break;
            }
        }
        return allbonus;
    }

    function totalUserReward (
        address from
    )
        public
        view returns (
            uint256 claimableBUSD,
            uint256 refBonus,
            uint256 winBonus
        )
    {
        require(from != address(0), "address 0 not allowed");

        UserInfo storage user = userInfo[from];
        claimableBUSD = user.dividendDebt;
        claimableBUSD += _calulateDividendDept(from);
        claimableBUSD += _calulatePendingDeposit(from);
        claimableBUSD -= _estimateRefLinkBonus(from, claimableBUSD);
        refBonus = user.refBonus;
        winBonus = user.bonusProfit;
    }

    function totalBUSDReward() public view returns (uint256 totalBUSDRewards) {
        totalBUSDRewards = poolInfo.totalDividends;
    }

    function totalDeposit() public view returns (uint256 total, uint256 pending) {
        total = IERC20Metadata(TOKEN).balanceOf(address(this));
        pending = pendingToken[poolInfo.dividendCheckpoint];
    }

    function totalUserDeposit(
        address useraddress
    )
        public
        view returns (
            uint256 totalamount,
            uint256 totalpending
        )
    {
        if (userInfo[useraddress].deposits.length <= 0)
        	return (0, 0);

        (uint256 stillpending, uint256 alreadymature) = _getPendingDeposit(useraddress);
        totalpending = stillpending;
        totalamount = userInfo[useraddress].amount.add(alreadymature);
    }

    function RewardHistory(
        uint256 index
    )
        public
        view returns (
            uint256 totalRewardOfDay,
            uint256 totalDelegatedTokenOfDay,
            uint256 dividendPerShare,
            uint256 timestamp
        )
    {
        require(poolInfo.dividendCheckpoint >= index, "index out of range");

        Dividend storage dividend = dividends[index];
        totalRewardOfDay = dividend.turnoverBUSD;
        totalDelegatedTokenOfDay = dividend.delegatedToken;
        dividendPerShare = dividend.dividendperShare;
        timestamp = dividend.timestamp;
    }

    function RewardHistoryIndex() public view returns (uint256 index) {
		index = poolInfo.dividendCheckpoint;
    }

    function enableRamdomBonus (uint256 enable) onlyOwner public {
        require(5 > enable, "Bonus value invalid");
        bonusPool.enableBonus = enable;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return userInfo[userAddress].referrer;
    }

    function getCounter() public view returns(uint256) {
        return counter;
    }

    function getUserDownlineCount(
        address userAddress
    )
        public
        view returns (
            uint256 level1,
            uint256 level2,
            uint256 level3
        )
    {
        level1 = userInfo[userAddress].refLevels[0];
        level2 = userInfo[userAddress].refLevels[1];
        level3 = userInfo[userAddress].refLevels[2];
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return userInfo[userAddress].refBonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
        return userInfo[userAddress].totalRefBonus;
    }

    function getUserReferralWithdrawn(
        address userAddress
    )
        public
        view returns (
            uint256 totalReferralWithdrawn
        )
    {
        totalReferralWithdrawn = userInfo[userAddress].totalRefBonus.sub(userInfo[userAddress].refBonus);
    }

    function nextBonusCalculation(
    )
        public
        view returns (
            uint256 nextBonus,
            uint256 win1,
            uint256 win2,
            uint256 win3,
            address addr1,
            address addr2,
            address addr3
        )
    {
        nextBonus = bonusPool.nextBonusCalculation;
        win1 = bonusPool.amountBonus[0];
        win2 = bonusPool.amountBonus[1];
        win3 = bonusPool.amountBonus[2];
        addr1 = bonusPool.winner[0];
        addr2 = bonusPool.winner[1];
        addr3 = bonusPool.winner[2];
    }

    function nextRewardCalculation() public view returns(uint256 nextReward) {
        nextReward = dividends[poolInfo.dividendCheckpoint].timestamp;
    }

    function safeBUSDTransfer(address to, uint256 __amount) internal returns (bool) {
        uint256 remain = IERC20Metadata(BUSD).balanceOf(address(this));
        uint256 amountToTransfer = __amount;
        if (remain < amountToTransfer) {
            amountToTransfer = remain;
        }

        IERC20Metadata(BUSD).approve(address(this), amountToTransfer);

        return IERC20Metadata(BUSD).transferFrom(address(this), to, amountToTransfer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IPancakeRouter02.sol";

library Utils {
    using SafeMath for uint256;

    function random(uint256 from, uint256 to, uint256 salty) public view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp + block.difficulty +
                    ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
                    block.gaslimit +
                    ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
                    block.number +
                    salty
                )
            )
        );
        return seed.mod(to - from) + from;
    }    
    
    function swapTokensForBNB(
        address routerAddress,
        address recipient,
        uint256 tokenAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            recipient,
            block.timestamp
        );
    }

    function swapBNBForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);

        // add the liquidity
        pancakeRouter.addLiquidityETH{value : ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }
    
    function swapTokenForBUSD( address routerAddress, address busd,  address recipient, uint256 tokenAmount) public {
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);
         
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        path[2] = busd;
         
        pancakeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens( tokenAmount,
																		        0,
																		        path,
																		        recipient,
																		        block.timestamp + 360 );
    }
    
    function swapTokenForBUSD2( address routerAddress, address busd,  address recipient, uint256 tokenAmount) public returns ( uint[] memory amounts){
        IPancakeRouter02 pancakeRouter = IPancakeRouter02(routerAddress);
         
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();
        path[2] = busd;
         
        amounts = pancakeRouter.swapExactTokensForTokens( tokenAmount, 0, path, recipient, block.timestamp + 360 );
    }

}

