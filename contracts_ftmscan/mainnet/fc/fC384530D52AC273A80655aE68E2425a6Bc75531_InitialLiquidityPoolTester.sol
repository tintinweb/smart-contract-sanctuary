pragma solidity 0.6.11;

import "InitialLiquidityPool.sol";

contract InitialLiquidityPoolTester is InitialLiquidityPool {

    constructor(
        IERC20 _contributionToken,
        IERC20 _rewardToken,
        IUniswapV2Factory _factory,
        address _treasury,
        uint256 _startTime,
        uint256 _softCap
    ) public InitialLiquidityPool(_contributionToken, _rewardToken, _factory, _treasury, _startTime, _softCap) {}

    // after the deposit period is finished and the soft cap has been reached,
    // call this method to add liquidity and begin reward streaming for contributors
    function addLiquidity() public override {
        require(block.timestamp >= depositEndTime, "Deposits are still open");
        require(totalReceived >= softCap, "Soft cap not reached");
        uint256 amount = contributionToken.balanceOf(address(this));
        contributionToken.transfer(lpToken, amount);
        rewardToken.transfer(lpToken, rewardTokenLpAmount);
        IUniswapV2Pair(lpToken).mint(treasury);

        streamStartTime = block.timestamp;
        streamEndTime = streamStartTime.add(streamDuration);

        currentDepositTotal = totalReceived;
        currentRewardTotal = rewardTokenSaleAmount;
    }

    function setTimes(uint _depositStart, uint _depositEnd) public {
        depositStartTime = _depositStart;
        depositEndTime = _depositEnd;
    }

}

pragma solidity 0.6.11;

import "IERC20.sol";
import "SafeMath.sol";
import "ILQTYTreasury.sol";

interface IUniswapV2Factory {
    function getPair(IERC20 tokenA, IERC20 tokenB) external view returns (address);
}

interface IUniswapV2Pair {
    function mint(address to) external;
}

contract InitialLiquidityPool {
    using SafeMath for uint256;

    // token that this contract accepts from contributors
    IERC20 public contributionToken;
    // new token given as a reward to contributors
    IERC20 public rewardToken;
    // uniswap LP token for `contributionToken` and `rewardToken`
    address public lpToken;
    // address that receives the LP tokens
    address public treasury;

    // amount of `rewardToken` that will be added as liquidity
    uint256 public rewardTokenLpAmount;
    // amount of `rewardToken` that will be distributed to contributors
    uint256 public rewardTokenSaleAmount;

    // the minimum amount of `contributionToken` that must be received,
    // if this amount is not reached all contributions may withdraw
    uint256 public softCap;
    // the maximum amount of `contributionToken` that the contract will accept
    uint256 public hardCap;
    // total amount of `contributionToken` received from all contributors
    uint256 public totalReceived;

    // epoch time when contributors may begin to deposit
    uint256 public depositStartTime;
    // epoch time when the contract no longer accepts deposits
    uint256 public depositEndTime;
    // length of the "grace period" - time that deposits continue
    // after the contributed amount exceeds the soft cap
    uint256 public constant gracePeriod = 3600 * 6;

    // epoch time when `rewardToken` begins streaming to buyers
    uint256 public streamStartTime;
    // epoch time when `rewardToken` streaming has completed
    uint256 public streamEndTime;
    // time over which `rewardToken` is streamed
    uint256 public constant streamDuration = 86400 * 30;

    // dynamic values tracking total balances of `contributionToken`
    // and `rewardToken` based on calls to `earlyExit`
    uint256 public currentDepositTotal;
    uint256 public currentRewardTotal;

    struct UserDeposit {
        uint256 amount;
        uint256 streamed;
    }

    mapping(address => UserDeposit) public userAmounts;

    constructor(
        IERC20 _contributionToken,
        IERC20 _rewardToken,
        IUniswapV2Factory _factory,
        address _treasury,
        uint256 _startTime,
        uint256 _softCap
    ) public {
        contributionToken = _contributionToken;
        rewardToken = _rewardToken;
        treasury = _treasury;
        lpToken = _factory.getPair(_contributionToken, _rewardToken);
        require(lpToken != address(0));

        depositStartTime = _startTime;
        depositEndTime = _startTime.add(86400);

        softCap = _softCap;
        hardCap = _softCap.mul(5);
    }

    // `rewardToken` should be transferred into the contract prior to calling this method
    // this must be called prior to `depositStartTime`
    function notifyRewardAmount() public {
        require(block.timestamp < depositStartTime, "Too late");
        uint amount = rewardToken.balanceOf(address(this));
        rewardTokenLpAmount = amount.mul(2).div(5);
        rewardTokenSaleAmount = amount.sub(rewardTokenLpAmount);
    }

    // contributors call this method to deposit `contributionToken` during the deposit period
    function depositTokens(uint256 _amount) public {
        require(block.timestamp >= depositStartTime, "Not yet started");
        require(block.timestamp < depositEndTime, "Already finished");

        uint256 oldTotal = totalReceived;
        uint256 newTotal = oldTotal.add(_amount);
        require(newTotal <= hardCap, "Hard cap reached");

        contributionToken.transferFrom(msg.sender, address(this), _amount);
        if (oldTotal < softCap && newTotal >= softCap) {
            depositEndTime = block.timestamp.add(gracePeriod);
        }

        userAmounts[msg.sender].amount = userAmounts[msg.sender].amount.add(
            _amount
        );
        totalReceived = newTotal;
    }

    // after the deposit period is finished and the soft cap has been reached,
    // call this method to add liquidity and begin reward streaming for contributors
    function addLiquidity() public virtual {
        require(block.timestamp >= depositEndTime, "Deposits are still open");
        require(totalReceived >= softCap, "Soft cap not reached");
        uint256 amount = contributionToken.balanceOf(address(this));
        contributionToken.transfer(lpToken, amount);
        rewardToken.transfer(lpToken, rewardTokenLpAmount);
        IUniswapV2Pair(lpToken).mint(treasury);

        streamStartTime = ILQTYTreasury(treasury).issuanceStartTime();
        streamEndTime = streamStartTime.add(streamDuration);

        currentDepositTotal = totalReceived;
        currentRewardTotal = rewardTokenSaleAmount;
    }

    // if the deposit period finishes and the soft cap was not reached, contributors
    // may call this method to withdraw their balance of `contributionToken`
    function withdrawTokens() public {
        require(block.timestamp >= depositEndTime, "Deposits are still open");
        require(totalReceived < softCap, "Cap was reached");
        uint256 amount = userAmounts[msg.sender].amount;
        userAmounts[msg.sender].amount = 0;
        contributionToken.transfer(msg.sender, amount);
    }

    // once the streaming period begins, this returns the currently claimable
    // balance of `rewardToken` for a contributor
    function claimable(address _user) public view returns (uint256) {
        if (streamStartTime == 0 || block.timestamp < streamStartTime) {
            return 0;
        }
        uint256 totalClaimable = currentRewardTotal.mul(userAmounts[_user].amount).div(
            currentDepositTotal
        );
        if (block.timestamp >= streamEndTime) {
            return totalClaimable.sub(userAmounts[_user].streamed);
        }
        uint256 duration = block.timestamp.sub(streamStartTime);
        uint256 claimableToDate = totalClaimable.mul(duration).div(streamDuration);
        return claimableToDate.sub(userAmounts[_user].streamed);
    }

    // claim a pending `rewardToken` balance
    function claimReward() external {
        uint256 amount = claimable(msg.sender);
        userAmounts[msg.sender].streamed = userAmounts[msg.sender].streamed.add(
            amount
        );
        rewardToken.transfer(msg.sender, amount);
    }

    // withdraw all available `rewardToken` balance immediately
    // calling this method forfeits 33% of the balance which is not yet available
    // to withdraw using `claimReward`. the extra tokens are then distributed to
    // other contributors who have not yet exitted. If the last contributor exits
    // early, any remaining tokens are are burned.
    function earlyExit() external {
        require(block.timestamp > streamStartTime, "Streaming not active");
        require(block.timestamp < streamEndTime, "Streaming has finished");
        require(userAmounts[msg.sender].amount > 0, "No balance");

        uint256 claimableWithBonus = currentRewardTotal
            .mul(userAmounts[msg.sender].amount)
            .div(currentDepositTotal);
        uint256 claimableBase = rewardTokenLpAmount
            .mul(userAmounts[msg.sender].amount)
            .div(totalReceived);

        uint256 durationFromStart = block.timestamp.sub(streamStartTime);
        uint256 durationToEnd = streamEndTime.sub(block.timestamp);
        uint256 claimable = claimableWithBonus.mul(durationFromStart).div(
            streamDuration
        );
        claimable = claimable.add(
            claimableBase.mul(durationToEnd).div(streamDuration)
        );

        currentDepositTotal = currentDepositTotal.sub(userAmounts[msg.sender].amount);
        currentRewardTotal = currentRewardTotal.sub(claimable);
        claimable = claimable.sub(userAmounts[msg.sender].streamed);
        delete userAmounts[msg.sender];
        rewardToken.transfer(msg.sender, claimable);

        if (currentDepositTotal == 0) {
            uint256 remaining = rewardToken.balanceOf(address(this));
            rewardToken.transfer(address(0xdead), remaining);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ILQTYTreasury {
    function issuanceStartTime() external view returns (uint);
}