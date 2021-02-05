/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// File: openzeppelin-solidity-2.3.0/contracts/utils/Address.sol

pragma solidity ^0.5.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

// File: openzeppelin-solidity-2.3.0/contracts/token/ERC20/IERC20.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
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
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


// File: openzeppelin-solidity-2.3.0/contracts/math/Math.sol

pragma solidity ^0.5.0;

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


// File: openzeppelin-solidity-2.3.0/contracts/math/SafeMath.sol

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File: openzeppelin-solidity-2.3.0/contracts/utils/ReentrancyGuard.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;

    constructor () internal {
        // The counter starts at one to prevent changing it from zero to a non-zero
        // value, which is a more expensive operation.
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// File: contracts/interfaces/ILinkswapERC20.sol

pragma solidity 0.5.16;

interface ILinkswapERC20 {
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// File: contracts/interfaces/IStakingRewards.sol

pragma solidity 0.5.16;

interface IStakingRewards {
    // Mutative
    function stake(uint256 amount) external;

    function unstakeAndClaimRewards(uint256 unstakeAmount) external;

    function unstake(uint256 amount) external;

    function claimRewards() external;

    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken(uint256 rewardTokenIndex) external view returns (uint256);

    function earned(address account, uint256 rewardTokenIndex) external view returns (uint256);

    function getRewardForDuration(uint256 rewardTokenIndex) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/RewardsRecipient.sol

pragma solidity 0.5.16;

contract RewardsRecipient {
    address public rewardsDistributor;

    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "!rewardsDistributor");
        _;
    }

    function notifyRewardAmount(uint256 rewardTokenIndex, uint256 amount) external;
}


// File: contracts/StakingRewards.sol

pragma solidity 0.5.16;


contract StakingRewards is IStakingRewards, RewardsRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */

    event RewardAdded(address indexed rewardToken, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, address indexed rewardToken, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    address public owner;
    IERC20 public stakingToken;
    uint256 public lastUpdateTime;
    uint256 public periodFinish;
    uint256 public rewardsDuration;

    IERC20[2] public rewardTokens;
    uint256[2] public rewardRate;
    uint256[2] public rewardPerTokenStored;
    mapping(address => uint256)[2] public userRewardPerTokenPaid;
    mapping(address => uint256)[2] public unclaimedRewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _stakingToken,
        address _rewardsDistributor,
        address _yflToken,
        address _extraRewardToken, // optional
        uint256 _rewardsDuration,
        address _owner
    ) public {
        require(
            _rewardsDistributor != address(0) &&
                _yflToken != address(0) &&
                _stakingToken != address(0),
            "address(0)"
        );
        require(_rewardsDuration > 0, "rewardsDuration=0");
        rewardsDistributor = _rewardsDistributor;
        rewardTokens[0] = IERC20(_yflToken);
        rewardTokens[1] = IERC20(_extraRewardToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDuration = _rewardsDuration;
        owner = _owner;
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        rewardPerTokenStored[0] = rewardPerToken(0);
        if (address(rewardTokens[1]) != address(0)) rewardPerTokenStored[1] = rewardPerToken(1);
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            unclaimedRewards[0][account] = earned(account, 0);
            unclaimedRewards[1][account] = earned(account, 1);
            userRewardPerTokenPaid[0][account] = rewardPerTokenStored[0];
            userRewardPerTokenPaid[1][account] = rewardPerTokenStored[1];
        }
        _;
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function getRewardForDuration(uint256 rewardTokenIndex) external view returns (uint256) {
        return rewardRate[rewardTokenIndex].mul(rewardsDuration);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken(uint256 rewardTokenIndex) public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored[rewardTokenIndex];
        }
        return
            rewardPerTokenStored[rewardTokenIndex].add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate[rewardTokenIndex])
                    .mul(1e18)
                    .div(_totalSupply)
            );
    }

    function earned(address account, uint256 rewardTokenIndex) public view returns (uint256) {
        return
            _balances[account]
                .mul(
                rewardPerToken(rewardTokenIndex).sub(
                    userRewardPerTokenPaid[rewardTokenIndex][account]
                )
            )
                .div(1e18)
                .add(unclaimedRewards[rewardTokenIndex][account]);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function stakeWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        ILinkswapERC20(address(stakingToken)).permit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        _stake(amount);
    }

    function unstakeAndClaimRewards(uint256 unstakeAmount)
        external
        nonReentrant
        updateReward(msg.sender)
    {
        _unstake(unstakeAmount);
        _claimReward(0);
        _claimReward(1);
    }

    // Unstake without claiming rewards. For emergency use if claiming rewards is failing.
    function unstake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        _unstake(amount);
    }

    // Sends to the caller any unclaimed rewards earned by the caller.
    function claimRewards() external nonReentrant updateReward(msg.sender) {
        _claimReward(0);
        _claimReward(1);
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    function _stake(uint256 amount) private {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function _unstake(uint256 amount) private {
        require(amount > 0, "Cannot unstake 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    function _claimReward(uint256 rewardTokenIndex) private {
        uint256 rewardAmount = unclaimedRewards[rewardTokenIndex][msg.sender];
        if (rewardAmount > 0) {
            uint256 rewardsBal = rewardTokens[rewardTokenIndex].balanceOf(address(this));
            if (rewardsBal == 0) return;
            // avoid paying more than total rewards balance
            rewardAmount = rewardsBal < rewardAmount ? rewardsBal : rewardAmount;
            unclaimedRewards[rewardTokenIndex][msg.sender] = unclaimedRewards[rewardTokenIndex][msg
                .sender]
                .sub(rewardAmount);
            rewardTokens[rewardTokenIndex].safeTransfer(msg.sender, rewardAmount);
            emit RewardPaid(msg.sender, address(rewardTokens[rewardTokenIndex]), rewardAmount);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function notifyRewardAmount(uint256 amount, uint256 extraAmount)
        external
        onlyRewardsDistributor
        updateReward(address(0))
    {
        require(amount > 0 || extraAmount > 0, "zero amount");
        if (extraAmount > 0) {
            require(address(rewardTokens[1]) != address(0), "extraRewardToken=0x0");
        }
        if (block.timestamp >= periodFinish) {
            rewardRate[0] = amount.div(rewardsDuration);
            if (extraAmount > 0) rewardRate[1] = extraAmount.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate[0]);
            rewardRate[0] = amount.add(leftover).div(rewardsDuration);
            if (extraAmount > 0) {
                leftover = remaining.mul(rewardRate[1]);
                rewardRate[1] = extraAmount.add(leftover).div(rewardsDuration);
            }
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = rewardTokens[0].balanceOf(address(this));
        require(rewardRate[0] <= balance.div(rewardsDuration), "Provided reward too high");
        if (extraAmount > 0) {
            balance = rewardTokens[1].balanceOf(address(this));
            require(
                rewardRate[1] <= balance.div(rewardsDuration),
                "Provided extra reward too high"
            );
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(address(rewardTokens[0]), amount);
        if (extraAmount > 0) emit RewardAdded(address(rewardTokens[1]), extraAmount);
    }

    function emergencyWithdraw(address _token) external {
        require(msg.sender == owner, "!owner");
        require(_token != address(stakingToken), "cannot withdraw staking token");
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }
}