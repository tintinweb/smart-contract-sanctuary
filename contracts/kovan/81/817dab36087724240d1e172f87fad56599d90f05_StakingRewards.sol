// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {IERC20MetadataUpgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {AccessControlEnumerableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import {IStakingRewards} from "../interfaces/IStakingRewards.sol";
import {Reward} from "../interfaces/Reward.sol";
import {ILPStakingRewards} from "../interfaces/ILPStakingRewards.sol";
import {IRhoTokenRewards} from "../interfaces/IRhoTokenRewards.sol";

contract StakingRewards is
    IStakingRewards,
    Reward,
    Initializable,
    AccessControlEnumerableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Events
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardEarned(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 durationInBlocks);
    event RewardsEndUpdated(uint256 rewardsEndBlock);

    // FLURRY Token Staking
    // Locking FLURRY tokens to earn more FLURRY tokens
    // subject to the stakingYield set by the Flurry token owner.
    // rewardsToken is assumed to be a ERC20 compliant token with 18 decimals
    IERC20Upgradeable private _rewardsToken;
    uint256 private _rewardsTokenOne;

    /**
     * @notice We usually require to know who are all the stakeholders.
     */
    address[] private _stakeholders;

    /**
     * @notice  The stakes for each stakeholder.
     * stake holder address -> flurry tokens staked
     */
    uint256 private _totalStakes;

    /**
     * @notice  The stakes for each stakeholder.
     * stake holder address -> flurry tokens staked
     */
    mapping(address => uint256) private _stakes;

    /**
     * @notice The accumulated rewards for each stakeholder.
     * stake holder address -> rewards allocated to staker denominated in flurry token
     */
    mapping(address => uint256) public rewards;

    /**
     * @notice Amount of rewards already paid to stakeholder per token
     */
    mapping(address => uint256) public rewardsPerTokenPaid;

    /**
     * @notice Staking rewards earned per block for the entire staking pool
     */
    uint256 public stakingRate;

    /**
     * @notice Block number that staking reward was last accrued at
     */
    uint256 public lastUpdateBlock;

    /**
     * @notice Staking Rewards entitlement per staking token held
     */
    uint256 public rewardsPerTokenStored;

    /**
     * @notice Duration of the current rewards period in blocks
     */
    uint256 public rewardsDuration;

    /**
     * @notice The last block when rewards distubution end
     */
    uint256 public rewardsEndBlock;

    // TODO: fix this access right tgt with the circular dependency

    /**
     * @notice referennce to LP Staking Rewards contract
     */    
    ILPStakingRewards public lpStakingRewards;

    /**
     * @notice referennce to RhoToken Rewards contract
     */    
    IRhoTokenRewards[] public rhoTokenRewardsList;

    // Role
    bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE");
    bytes32 public constant LP_TOKEN_REWARDS_ROLE = keccak256("LP_TOKEN_REWARDS_ROLE");
    bytes32 public constant RHO_TOKEN_REWARDS_ROLE = keccak256("RHO_TOKEN_REWARDS_ROLE");

    /**
     * @notice initialize function is used in place of constructor for upgradeability
     * Have to call initializers in the parent classes to proper initialize
     */
    function initialize(address _flurryTokenAddr) public initializer {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        _rewardsToken = IERC20Upgradeable(_flurryTokenAddr);
        _rewardsTokenOne = 10**IERC20MetadataUpgradeable(_flurryTokenAddr).decimals();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function totalStakes() external view override returns (uint256) {
        return _totalStakes;
    }

    function stakeOf(address user) external view override returns (uint256) {
        return _stakes[user];
    }

    function rewardOf(address user) external view override returns (uint256) {
        return _earned(user);
    }

    /**
     * @notice Staking rewards are accrued up to this block (put aside in rewardsPerTokenPaid)
     * @return min(The current block # or last rewards accrual block #)
     */
    function lastBlockApplicable() internal view returns (uint256) {
        return _lastBlockApplicable(rewardsEndBlock);
    }

    /**
     * @return The amount of staking rewards distrubuted per block
     */
    function rewardsRate() external view override returns (uint256) {
        return stakingRate;
    }

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement per token staked (in wei)
     */
    function rewardsPerToken() public view override returns (uint256) {
        if (_totalStakes == 0) {
            return rewardsPerTokenStored;
        }
        return
            rewardsPerTokenStored.add(
                (lastBlockApplicable().sub(lastUpdateBlock))
                    .mul(stakingRate)
                    .mul(_rewardsTokenOne)
                    .div(_totalStakes)
            );
    }

    /**
     * @notice Calculate and allocate rewards token for stake holder
     * Staking rewards should be calculated from lastUpdateBlock to lastBlockApplicable
     */
    function updateReward(address addr) internal {
        rewardsPerTokenStored = rewardsPerToken();
        lastUpdateBlock = lastBlockApplicable();
        if (addr != address(0)) {
            rewards[addr] = _earned(addr);
            rewardsPerTokenPaid[addr] = rewardsPerTokenStored;
            emit RewardEarned(addr, rewards[addr]);
        }
    }

    function _earned(address addr) internal view returns (uint256) {
        return super._earned(_stakes[addr], rewardsPerToken().sub(rewardsPerTokenPaid[addr]), _rewardsTokenOne, rewards[addr]);
    }

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @return Reward entitlement for token staked
     */
    function getRewardsForDuration() external view override returns (uint256) {
        return _getRewardsForDuration(stakingRate, rewardsDuration);
    }

    /**
     * @notice A method to set reward amount
     * Can only called by Owner
     */
    function setRewardAmount(uint256 reward) external override onlyRole(DEFAULT_ADMIN_ROLE){
        updateReward(address(0));
        require(rewardsDuration > 0, "Rewards duration is 0");

        if (block.number >= rewardsEndBlock) {
            stakingRate = reward.div(rewardsDuration);
        } else {
            uint256 blocksRemaining = rewardsEndBlock.sub(block.number);
            uint256 leftover = blocksRemaining.mul(stakingRate);
            stakingRate = reward.add(leftover).div(rewardsDuration);
        }

        // Reward amount cannot be more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = _rewardsToken.balanceOf(address(this));
        require(
            stakingRate <= balance.div(rewardsDuration),
            "Insufficient balance for rewards"
        );

        lastUpdateBlock = block.number;
        rewardsEndBlock = block.number.add(rewardsDuration);
        emit RewardAdded(reward);
        emit RewardsEndUpdated(rewardsEndBlock);
    }

    /**
     * @notice A method to set reward duration
     * Can only called by Owner
     */
    function setRewardsDuration(uint256 _rewardsDuration) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        require(
            block.number > rewardsEndBlock,
            "Previous rewards period must be completed before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(_rewardsDuration);
    }

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     */
    function shortenRewardsDuration() external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (rewardsEndBlock > block.number) {
            rewardsEndBlock = block.number;
            emit RewardsEndUpdated(rewardsEndBlock);
        }
    }

    /**
     * @notice A method to add a stake.
     * @param amount amount of flurry tokens to be staked
     */
    function stake(uint256 amount) external override nonReentrant {
        address user = _msgSender();
        require(amount > 0, "Cannot stake 0 tokens");
        require(
            _rewardsToken.balanceOf(user) >= amount,
            "Not Enough balance to stake"
        );
        updateReward(user);
        _stakes[user] = _stakes[user].add(amount);
        _totalStakes = _totalStakes.add(amount);
        _rewardsToken.safeTransferFrom(user, address(this), amount);
        emit Staked(user, amount);
    }

    /**
     * @notice A method to add rewards that are not staked to the staking pool
     * @param amount amount of flurry tokens to be staked
     */
    function stakeRewards(uint256 amount) external override {
        //TODO -asdas
    }

    /**
     * @notice A method to remove a stake.
     * @param amount amount of staked tokens to remove from staking
     */
    function withdraw(uint256 amount) external override {
        _withdrawUser(_msgSender(), amount);
    }

    /**
     * @notice A method to remove a stake.
     * @param user address of stakeholder
     * @param amount amount of staked tokens to remove from staking
     */
    function _withdrawUser(address user, uint256 amount) internal nonReentrant {
        require(isStakeholder(user), "No stakes to withdraw");
        require(_stakes[user] >= amount, "Exceeds staked amount");
        updateReward(user);
        _stakes[user] = _stakes[user].sub(amount);
        _totalStakes = _totalStakes.sub(amount);
        _rewardsToken.safeTransfer(user, amount);
        emit Withdrawn(user, amount);
    }

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit() external override {
        address user = _msgSender();
        if (isStakeholder(user)) {
            _withdrawUser(user, _stakes[user]);
        }
    }

    /**
     * @notice A method to allow a stakeholder to withdraw his FLURRY staking rewards.
     */
    function claimReward(address user) external override nonReentrant {
        updateReward(user);
        if (rewards[user] > 0) {
            rewards[user] = grantFlurryInternal(user, rewards[user]);
        }
    }

    /**
     * @notice used to RhoTokenRewards contract for rewards distribution
     * @param addr account address of RhoToken holder
     * @param amount amount of flurry token reward to claim
     * @return returns outstanding amount if claim is not successful
     */
    function claimRhoTokenReward(address addr, uint256 amount) external override onlyRole(RHO_TOKEN_REWARDS_ROLE) returns (uint256) {
        require(addr != address(0), "claim reward on 0 address");
        return grantFlurryInternal(addr, amount);
    }

   /**
     * @notice used by LPStakingRewards contract for rewards distribution
     * @param addr account address of LP Token staker
     * @param amount amount of flurry token reward to claim
     * @return returns outstanding amount if claim is not successful
     */
    function claimLPTokenReward(address addr, uint256 amount) external override onlyRole(LP_TOKEN_REWARDS_ROLE) returns (uint256) {
        require(addr != address(0), "claim reward on 0 address");
        return grantFlurryInternal(addr, amount);
    }


    /**
     * @notice total balance held under staking rewards contract
     **/
    function totalRewardsPool() external view returns (uint256) {
        return _rewardsToken.balanceOf(address(this));
    }

    /**
     * @notice Transfer FLURRY to the user
     * @dev Note: If there is not enough FLURRY, we do not perform the transfer call
     * @param user The address of the user to transfer FLURRY to
     * @param amount The amount of FLURRY to transfer
     * @return The amount of FLURRY which was NOT transferred to the user
     */
    function grantFlurryInternal(address user, uint256 amount)
        internal
        returns (uint256)
    {
        uint256 flurryRemaining = _rewardsToken.balanceOf(address(this));
        if (amount > 0 && amount <= flurryRemaining) {
            _rewardsToken.safeTransfer(user, amount);
            emit RewardPaid(user, amount);
            return 0;
        }
        emit NotEnoughBalance(user, amount);
        return amount;
    }

    /**
     * @notice A method to check if an address is a stakeholder.
     * @param addr The address to verify.
     * @return bool Whether the address is a stakeholder
     */
    function isStakeholder(address addr) public view returns (bool) {
        return _stakes[addr] > 0;
    }

    function sweepERC20Token(address token, address to) external override onlyRole(SWEEPER_ROLE) {
        require(token != address(_rewardsToken), "!safe");
        _sweepERC20Token(token, to);
    }

    function totalRewardsOf(address user) external view override returns (uint256) {
        uint256 sum = 0;
        for (uint256 i = 0; i < rhoTokenRewardsList.length; i++) {
            sum += rhoTokenRewardsList[i].rewardOf(user);
        }
        return lpStakingRewards.totalRewardOf(user) + this.rewardOf(user) + sum;
    }

    function claimAllRewards(address user) external override {
        lpStakingRewards.claimAllReward(user);
        this.claimReward(user);
        for (uint256 i = 0; i < rhoTokenRewardsList.length; i++) {
            rhoTokenRewardsList[i].claimReward(user);
        }
    }

    function setRhoTokenRewardContract(address _rhoTokenRewardAddr) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        rhoTokenRewardsList.push(IRhoTokenRewards(_rhoTokenRewardAddr));
    }

    function setLPRewardsContract(address _lpRewardsAddr) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        lpStakingRewards = ILPStakingRewards(_lpRewardsAddr);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
library SafeMathUpgradeable {
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping (bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Staking Rewards Interface
 * @notice Interface for Flurry token govenance & staking functions
 *
 */
interface IStakingRewards {

    /**
     * @notice A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() external view returns (uint256);

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param user Stakeholder address
     * @return user staked amount (in wei)
     */
    function stakeOf(address user) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user) external view returns (uint256);

    /**
     * @return The amount of rewards token distrubuted per block
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement per token staked (in wei)
     */
    function rewardsPerToken() external view returns (uint256);

    /**
     * @notice
     * @return Total reward for the specified reward period (in wei)
     */
    function getRewardsForDuration() external view returns (uint256);

    /**
     * @notice A method to take the rewards earned and add to skating pool
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stakeRewards(uint256 amount) external;

    /**
     * @notice A method to add a stake.
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(uint256 amount) external;

    /**
     * @notice A method to remove a stake.
     * @param amount amount of staked tokens to remove from staking
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw his FLURRY taking rewards.
     * @param user The stakeholder to check rewards for.
     */
    function claimReward(address user) external;

    /**
     * @notice used by RhoTokenRewards contract for rewards distribution
     * @param addr account address of RhoToken holder
     * @param amount amount of flurry token reward to claim
     * @return returns outstanding amount if claim is not successful
     */
    function claimRhoTokenReward(address addr, uint256 amount) external returns (uint256);

   /**
     * @notice used by LPStakingRewards contract for rewards distribution
     * @param addr account address of LP Token staker
     * @param amount amount of flurry token reward to claim
     * @return returns outstanding amount if claim is not successful
     */
    function claimLPTokenReward(address addr, uint256 amount) external returns (uint256);

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit() external;

    /**
     * @notice Admin function - A method to set reward amount
     */
    function setRewardAmount(uint256 reward) external;

    /**
     * @notice Admin function A method to set reward duration
     * @param rewardsDuration Reward Duration in number of blocks
     */
    function setRewardsDuration(uint256 rewardsDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     */
    function shortenRewardsDuration() external;

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token,address to) external;

    /**
     * @notice A method to allow a stakeholder to check all his rewards.
     * Includes Staking Rewards + RhoToken Rewards + LP Token Rewards
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardsOf(address user) external view returns (uint256);

    // /**
    //  * @notice A method to allow a stakeholder to claim all his rewards.
    //  */
    function claimAllRewards(address user) external;

    /**
     * admin functions to set addr reference
     */
    function setRhoTokenRewardContract(address _rhoTokenRewardAddr) external;

    /**
     * admin functions to set addr reference
     */
    function setLPRewardsContract(address _lpRewardsAddr) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title Reward Abstract Contract
 * @notice Abstract Contract to be inherited by LPStakingReward, StakingReward and RhoTokenReward.
 * Implements the core logic as internal functions.
 * *** Note: avoid using `super` keyword to avoid confusion because the derived contracts use multiple inheritance ***
 */

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

abstract contract Reward {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // events
    event RewardPaid(address indexed user, uint256 reward);
    event NotEnoughBalance(address indexed user, uint256 withdrawalAmount);

    function _earned(uint256 _tokenBalance, uint256 _netRewardPerToken, uint256 _tokenOne, uint256 accumulatedReward) internal pure returns (uint256) {
        // console.log("calling super earned");
        // console.log("_tokenBalance", _tokenBalance);
        // console.log("_netRewardPerToken", _netRewardPerToken);
        // console.log("");
        return _tokenBalance
            .mul(_netRewardPerToken)
            .div(_tokenOne)
            .add(accumulatedReward);
    }

    /**
     * @notice Transfer FLURRY to the user
     * @dev Note: If there is not enough FLURRY, we do not perform the transfer call
     * @param user The address of the user to transfer FLURRY to
     * @param amount The amount of FLURRY to transfer
     * @return The amount of FLURRY which was NOT transferred to the user
     */
    function _grantFlurryInternal(address flurryTokenAddr, address user, uint256 amount) internal returns (uint256){
        IERC20Upgradeable flurryToken = IERC20Upgradeable(flurryTokenAddr);
        uint256 flurryRemaining = flurryToken.balanceOf(address(this));
        if (amount > 0 && amount <= flurryRemaining) {
            flurryToken.safeTransfer(user, amount);
            emit RewardPaid(user, amount);
            return 0;
        }
        emit NotEnoughBalance(user, amount);
        return amount;
    }

    /**
     * @notice Rewards are accrued up to this block (put aside in rewardsPerTokenPaid)
     * @return min(The current block # or last rewards accrual block #)
     */
    function _lastBlockApplicable(uint256 _rewardsEndBlock) internal view returns (uint256) {
        return MathUpgradeable.min(block.number, _rewardsEndBlock);
    }

    /**
     * @param _rate staking or reward rate
     * @param _duration reward duration in number of blocks
     * @return Total reward for the specified reward period (in wei)
     */
    function _getRewardsForDuration(uint256 _rate, uint256 _duration) internal pure returns (uint256) {
        return _rate.mul(_duration);
    }

    // /**
    //  * @notice A method to add a stake.
    //  * @param amount amount of flurry tokens to be staked (in wei)
    //  * @param lpAddr Address of LP Token contract
    //  */
    // function _stake(address lpAddr, uint256 amount) internal {
    //     address user = _msgSender();
    //     require(amount > 0, "Cannot stake 0 tokens");
    //     require(
    //         _rewardsToken.balanceOf(user) >= amount,
    //         "Not Enough balance to stake"
    //     );
    // }

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function _sweepERC20Token(address token, address to) internal {
        IERC20Upgradeable tokenToSweep = IERC20Upgradeable(token);
        tokenToSweep.transfer(to, tokenToSweep.balanceOf(address(this)));
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title LP Staking Rewards Interface
 * @notice Interface for FLURRY token rewards when staking LP tokens
 */
interface ILPStakingRewards {

    /**
     * @param user user address
     * @return list of addresses of LP user has engaged in
     */
    function getUserEngagedPool(address user) external view returns (address[] memory);

    /**
     * @return staking rate earned per block
     */
    function getStakingRate() external view returns (uint256);

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param addr Stakeholder address
     * @param lpAddr Address of LP Token contract
     * @return user staked amount (in wei)
     */
    function stakeOf(address addr, address lpAddr) external view returns (uint256);

    // TODO: add a function for user to query all rewards for an address (user)

    /**
     * @notice A method to allow a stakeholder to check his rewards for one LP token
     * @param user The stakeholder to check rewards for
     * @param lpAddr Address of LP Token contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address lpAddr) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all LP token
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param amount amount of flurry tokens to be staked (in wei)
     * @param lpAddr Address of LP Token contract
     */
    function stake(address lpAddr, uint256 amount) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for one LP token
     * @param user address of the user (NOT msg.sender, the immediate caller)
     * @param lpAddr Address of LP Token contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address user, address lpAddr) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for all LP token
     * @param user address of the user (NOT msg.sender, the immediate caller)
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward(address user) external;

    /**
     * @notice A method to remove a stake.
     * @param amount amount of staked tokens to remove from staking
     * @param lpAddr Address of LP Token contract
     */
    function withdraw(address lpAddr, uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * @param lpAddr Address of LP Token contract
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit(address lpAddr) external;

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement for rho token
     * @param lpAddr Address of LP Token contract
     */
    function rewardsPerToken(address lpAddr) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param _rewardDuration Reward Duration in number of blocks
     */
    function setRewardDuration(address lpAddr, uint256 _rewardDuration) external;

    /**
     * @notice
     * @return Total reward for the specified reward period (in wei)
     * @param lpAddr Address of LP Token contract
     */
    function getRewardForDuration(address lpAddr) external view returns (uint256);

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token, address to) external;

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title RhoToken Rewards Interface
 * @notice Interface for bonus FLURRY token rewards contract for RhoToken holders
 */
interface IRhoTokenRewards {

    function getRewardRate() external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param addr The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address addr) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all rhoToken
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    // function setRewardSpeed(uint256 flurrySpeed) public

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement for rho token
     */
    function rewardsPerToken() external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward amount
     */
    function setRewardAmount(uint256 reward) external;

    /**
     * @notice Admin function - A method to set reward duration
     * @param _rewardsDuration Reward Duration in number of blocks
     */
    function setRewardsDuration(uint256 _rewardsDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     */
    function shortenRewardsDuration() external;

    /**
     * @notice Calculate and allocate rewards token for address holder
     * Rewards should accrue from _lastUpdateBlock to lastBlockApplicable
     *
     * rewardsPerToken is based on the total supply of the RhoToken, hence
     * this function needs to be called every time total supply changes
     */
    function updateReward(address addr) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards.
     * @param user address of the user (NOT msg.sender, the immediate caller)
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address user) external;

     /**
     * admin functions to withdraw random token transfer to this contract
     */
    function sweepERC20Token(address token,address to) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if(!hasRole(role, account)) {
            revert(string(abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(uint160(account), 20),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(role), 32)
            )));
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

