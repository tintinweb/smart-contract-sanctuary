// SPDX-License-Identifier: MIT
/*

██████╗ ███████╗██████╗  █████╗ ███████╗███████╗
██╔══██╗██╔════╝██╔══██╗██╔══██╗██╔════╝██╔════╝
██║  ██║█████╗  ██████╔╝███████║███████╗█████╗  
██║  ██║██╔══╝  ██╔══██╗██╔══██║╚════██║██╔══╝  
██████╔╝███████╗██████╔╝██║  ██║███████║███████╗
╚═════╝ ╚══════╝╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝
                                               

* Debase: ExpansionRewarder.sol
* Description:
* Pool that pool the issues rewards on expansions of debase supply
* Coded by: punkUnknown
*/

pragma solidity >=0.6.6;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public y;

    function setStakeToken(address _y) internal {
        y = IERC20(_y);
    }

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual {
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual {
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        y.safeTransfer(msg.sender, amount);
    }
}

contract ExpansionRewarder is Ownable, LPTokenWrapper, ReentrancyGuard {
    using Address for address;

    event LogEmergencyWithdraw(uint256 number);
    event LogSetRewardPercentage(uint256 rewardPercentage_);
    event LogSetBlockDuration(uint256 duration_);
    event LogSetPoolEnabled(bool poolEnabled_);
    event LogStartNewDistribtionCycle(
        uint256 poolShareAdded_,
        uint256 amount_,
        uint256 currentRewardRate_,
        uint256 expansionRewardRate_,
        uint256 stabilityRewardRate_,
        uint256 cycleEnds_
    );

    event LogSetStabilityRewardRatePercentage(
        uint256 stabilityRewardRatePercentage_
    );
    event LogSetRewardRate(uint256 rewardRate_);
    event LogSetEnableUserLpLimit(bool enableUserLpLimit_);
    event LogSetEnablePoolLpLimit(bool enablePoolLpLimit_);
    event LogSetUserLpLimit(uint256 userLpLimit_);
    event LogSetPoolLpLimit(uint256 poolLpLimit_);

    event LogRewardAdded(uint256 reward);
    event LogStaked(address indexed user, uint256 amount);
    event LogWithdrawn(address indexed user, uint256 amount);
    event LogRewardPaid(address indexed user, uint256 reward);
    event LogSetMultiSigPercentage(uint256 multiSigReward_);
    event LogSetMultiSigAddress(address multiSigAddress_);

    IERC20 public debase;
    address public policy;
    uint256 public blockDuration;
    bool public poolEnabled;

    uint256 public periodFinish;
    uint256 public rewardRate;
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;

    uint256 public rewardPerTokenStoredMax;
    uint256 public rewardShare;

    uint256 public rewardPercentage;
    uint256 public rewardDistributed;

    uint256 public expansionRewardRate;
    uint256 public stabilityRewardRate;
    uint256 public stabilityRewardRatePercentage;
    uint256 public cycleEnds;

    uint256 public multiSigRewardPercentage;
    uint256 public multiSigRewardShare;
    address public multiSigRewardAddress;

    //Flag to enable amount of lp that can be staked by a account
    bool public enableUserLpLimit;
    //Amount of lp that can be staked by a account
    uint256 public userLpLimit;

    //Flag to enable total amount of lp that can be staked by all users
    bool public enablePoolLpLimit;
    //Total amount of lp total can be staked
    uint256 public poolLpLimit;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    modifier enabled() {
        require(poolEnabled, "Pool isn't enabled");
        _;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = lastBlockRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier updateRewardMax() {
        rewardPerTokenStoredMax = rewardPerTokenMax();
        _;
    }

    /**
     * @notice Function to set how much reward the stabilizer will request
     */
    function setRewardPercentage(uint256 rewardPercentage_) external onlyOwner {
        rewardPercentage = rewardPercentage_;
        emit LogSetRewardPercentage(rewardPercentage);
    }

    /**
     * @notice Function to set how much of the expansion reward rate should be added to neutral reward rate
     */
    function setStabilityRewardRatePercentage(
        uint256 stabilityRewardRatePercentage_
    ) external onlyOwner {
        stabilityRewardRatePercentage = stabilityRewardRatePercentage_;
        emit LogSetStabilityRewardRatePercentage(stabilityRewardRatePercentage);
    }

    /**
     * @notice Function to set multiSig reward percentage
     */
    function setMultiSigReward(uint256 multiSigRewardPercentage_)
        external
        onlyOwner
    {
        multiSigRewardPercentage = multiSigRewardPercentage_;
        emit LogSetMultiSigPercentage(multiSigRewardPercentage);
    }

    /**
     * @notice Function to set multisig address
     */
    function setMultiSigAddress(address multiSigRewardAddress_)
        external
        onlyOwner
    {
        multiSigRewardAddress = multiSigRewardAddress_;
        emit LogSetMultiSigAddress(multiSigRewardAddress);
    }

    /**
     * @notice Function to set reward drop period
     */
    function setblockDuration(uint256 blockDuration_) external onlyOwner {
        require(blockDuration >= 1);
        blockDuration = blockDuration_;
        emit LogSetBlockDuration(blockDuration);
    }

    /**
     * @notice Function enabled or disable pool staking,withdraw
     */
    function setPoolEnabled(bool poolEnabled_) external onlyOwner {
        poolEnabled = poolEnabled_;
        emit LogSetPoolEnabled(poolEnabled);
    }

    /**
     * @notice Function to enable user lp limit
     */
    function setEnableUserLpLimit(bool enableUserLpLimit_) external onlyOwner {
        enableUserLpLimit = enableUserLpLimit_;
        emit LogSetEnableUserLpLimit(enableUserLpLimit);
    }

    /**
     * @notice Function to set user lp limit
     */
    function setUserLpLimit(uint256 userLpLimit_) external onlyOwner {
        require(
            userLpLimit_ <= poolLpLimit,
            "User lp limit cant be more than pool limit"
        );
        userLpLimit = userLpLimit_;
        emit LogSetUserLpLimit(userLpLimit);
    }

    /**
     * @notice Function to enable pool lp limit
     */
    function setEnablePoolLpLimit(bool enablePoolLpLimit_) external onlyOwner {
        enablePoolLpLimit = enablePoolLpLimit_;
        emit LogSetEnablePoolLpLimit(enablePoolLpLimit);
    }

    /**
     * @notice Function to set pool lp limit
     */
    function setPoolLpLimit(uint256 poolLpLimit_) external onlyOwner {
        require(
            poolLpLimit_ >= userLpLimit,
            "Pool lp limit cant be less than user lp limit"
        );
        poolLpLimit = poolLpLimit_;
        emit LogSetPoolLpLimit(poolLpLimit);
    }

    constructor(
        address debase_,
        address pairToken_,
        address policy_,
        uint256 rewardPercentage_,
        uint256 blockDuration_,
        uint256 stabilityRewardRatePercentage_,
        uint256 multiSigRewardPercentage_,
        address multiSigRewardAddress_,
        bool enableUserLpLimit_,
        uint256 userLpLimit_,
        bool enablePoolLpLimit_,
        uint256 poolLpLimit_
    ) public {
        setStakeToken(pairToken_);
        debase = IERC20(debase_);
        policy = policy_;

        blockDuration = blockDuration_;
        rewardPercentage = rewardPercentage_;

        stabilityRewardRatePercentage = stabilityRewardRatePercentage_;
        multiSigRewardPercentage = multiSigRewardPercentage_;
        multiSigRewardAddress = multiSigRewardAddress_;
        userLpLimit = userLpLimit_;
        enableUserLpLimit = enableUserLpLimit_;
        poolLpLimit = poolLpLimit_;
        enablePoolLpLimit = enablePoolLpLimit_;
    }

    function checkStabilizerAndGetReward(
        int256 supplyDelta_,
        int256 rebaseLag_,
        uint256 exchangeRate_,
        uint256 debasePolicyBalance
    ) external returns (uint256 rewardAmount_) {
        require(
            msg.sender == policy,
            "Only debase policy contract can call this"
        );

        if (multiSigRewardShare != 0) {
            debase.safeTransfer(
                multiSigRewardAddress,
                debase.totalSupply().mul(multiSigRewardShare).div(10**18)
            );
            multiSigRewardShare = 0;
        }

        if (block.number >= cycleEnds) {
            if (supplyDelta_ >= 0) {
                if (rewardShare != 0) {
                    uint256 balanceLost = rewardShare.sub(rewardPerTokenMax());
                    debase.safeTransfer(
                        policy,
                        debase.totalSupply().mul(balanceLost).div(10**18)
                    );
                    rewardShare = 0;
                }

                uint256 rewardAmount =
                    debasePolicyBalance.mul(rewardPercentage).div(10**18);

                uint256 multiSigRewardClaim =
                    rewardAmount.mul(multiSigRewardPercentage).div(10**18);

                multiSigRewardShare = multiSigRewardClaim.mul(10**18).div(
                    debase.totalSupply()
                );

                uint256 totalRewardAmount =
                    multiSigRewardClaim.add(rewardAmount);

                if (debasePolicyBalance >= totalRewardAmount) {
                    startNewDistribtionCycle(supplyDelta_, rewardAmount);
                    return totalRewardAmount;
                }
            }
        } else {
            if (block.number > periodFinish && supplyDelta_ >= 0) {
                startRewards();
            }

            if (supplyDelta_ > 0 && rewardRate != expansionRewardRate) {
                changeRewardRate(expansionRewardRate);
            } else if (supplyDelta_ == 0 && rewardRate != stabilityRewardRate) {
                changeRewardRate(stabilityRewardRate);
            } else if (supplyDelta_ < 0 && block.number < periodFinish) {
                pauseRewards();
            }
        }
        return 0;
    }

    /**
     * @notice Function allows for emergency withdrawal of all reward tokens back into stabilizer fund
     */
    function emergencyWithdraw() external onlyOwner {
        debase.safeTransfer(policy, debase.balanceOf(address(this)));
        emit LogEmergencyWithdraw(block.number);
    }

    function lastBlockRewardApplicable() internal view returns (uint256) {
        return Math.min(block.number, periodFinish);
    }

    function rewardPerTokenMax() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStoredMax;
        }
        return
            rewardPerTokenStoredMax.add(
                lastBlockRewardApplicable().sub(lastUpdateBlock).mul(rewardRate)
            );
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastBlockRewardApplicable()
                    .sub(lastUpdateBlock)
                    .mul(rewardRate)
                    .mul(10**18)
                    .div(totalSupply())
            );
    }

    function earned(address account) public view returns (uint256) {
        return
            balanceOf(account)
                .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
                .div(10**18)
                .add(rewards[account]);
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount)
        public
        override
        nonReentrant
        updateRewardMax()
        updateReward(msg.sender)
        enabled
    {
        require(
            !address(msg.sender).isContract(),
            "Caller must not be a contract"
        );
        require(amount > 0, "Cannot stake 0");

        if (enablePoolLpLimit) {
            uint256 lpBalance = totalSupply();
            require(
                amount.add(lpBalance) <= poolLpLimit,
                "Cant stake pool lp limit reached"
            );
        }
        if (enableUserLpLimit) {
            uint256 userLpBalance = balanceOf(msg.sender);
            require(
                userLpBalance.add(amount) <= userLpLimit,
                "Cant stake more than lp limit"
            );
        }

        super.stake(amount);
        emit LogStaked(msg.sender, amount);
    }

    function withdraw(uint256 amount)
        public
        override
        nonReentrant
        updateRewardMax()
        updateReward(msg.sender)
    {
        require(amount > 0, "Cannot withdraw 0");
        super.withdraw(amount);
        emit LogWithdrawn(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward()
        public
        nonReentrant
        updateRewardMax()
        updateReward(msg.sender)
        enabled
    {
        uint256 reward = earned(msg.sender);
        if (reward > 0) {
            rewards[msg.sender] = 0;

            uint256 rewardToClaim =
                debase.totalSupply().mul(reward).div(10**18);

            debase.safeTransfer(msg.sender, rewardToClaim);

            emit LogRewardPaid(msg.sender, rewardToClaim);
            rewardDistributed = rewardDistributed.add(reward);
        }
    }

    function startRewards() internal {
        lastUpdateBlock = block.number;
        periodFinish = cycleEnds;
    }

    function pauseRewards()
        internal
        updateRewardMax()
        updateReward(address(0))
    {
        periodFinish = block.number;
    }

    function changeRewardRate(uint256 rewardRate_)
        internal
        updateRewardMax()
        updateReward(address(0))
    {
        rewardRate = rewardRate_;
        emit LogSetRewardRate(rewardRate);
    }

    function startNewDistribtionCycle(int256 supplyDelta_, uint256 amount)
        internal
        updateReward(address(0))
    {
        // https://sips.synthetix.io/sips/sip-77
        require(
            amount < uint256(-1) / 10**18,
            "Rewards: rewards too large, would lock"
        );

        rewardShare = amount.mul(10**18).div(debase.totalSupply());

        periodFinish = block.number.add(blockDuration);
        rewardPerTokenStoredMax = 0;
        cycleEnds = periodFinish;
        expansionRewardRate = rewardShare.div(blockDuration);
        stabilityRewardRate = expansionRewardRate
            .mul(stabilityRewardRatePercentage)
            .div(10**18);

        if (supplyDelta_ > 0) {
            rewardRate = expansionRewardRate;
        } else {
            rewardRate = stabilityRewardRate;
        }

        lastUpdateBlock = block.number;

        emit LogStartNewDistribtionCycle(
            rewardShare,
            amount,
            rewardRate,
            expansionRewardRate,
            stabilityRewardRate,
            cycleEnds
        );
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../GSN/Context.sol";
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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

    constructor () internal {
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

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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