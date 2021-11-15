//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import {ILPStakingRewards} from "../interfaces/ILPStakingRewards.sol";
import {BaseRewards} from "./BaseRewards.sol";
import {IFlurryStakingRewards} from "../interfaces/IFlurryStakingRewards.sol";

/**
 * @title Rewards for LP Token Stakers
 * @notice This reward scheme enables users to stake (lock) LP tokens
 * from Automated Market Makers (AMM), e.g. Uniswap, Pancakeswap,
 * into this contract to earn FLURRY tokens.
 */
contract LPStakingRewards is ILPStakingRewards, BaseRewards {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // events
    event Staked(address indexed user, address indexed lpToken, uint256 blockNumber, uint256 amount);
    event Withdrawn(address indexed user, address indexed lpToken, uint256 blockNumber, uint256 amount);
    event LPRewardsRateChanged(uint256 blockNumber, uint256 rewardsRate);
    event LPRewardsEndUpdated(address indexed lpToken, uint256 blockNumber, uint256 rewardsEndBlock);
    event LPAdded(address indexed lpToken);

    // role of Flurry Staking Rewards contract
    bytes32 public constant FLURRY_STAKING_REWARDS_ROLE = keccak256("FLURRY_STAKING_REWARDS_ROLE");

    // LP staking reward scheme params
    uint256 public override rewardsRate;
    uint256 public totalAllocPoint; // total allocation points = sum of allocation points in all pools
    address[] private poolList;

    // LP params
    struct PoolInfo {
        IERC20Upgradeable lpToken; // Address of LP token contract.
        uint256 totalStakes; // Total stakes for this pool
        uint256 allocPoint; // How many allocation points assigned to this pool
        uint256 lastUpdateBlock; // Last block number for staking rewards accrual
        uint256 rewardPerToken; // accumulated reward per staked token
        uint256 rewardsEndBlock; // the last block when reward distubution ends
        uint256 stakeTokenOne; // multiplier for one unit of staked Token
    }
    mapping(address => PoolInfo) public poolInfo;
    mapping(address => bool) public override isSupported;

    // user info
    struct UserInfo {
        uint256 amount; // number of LP tokens staked by user
        uint256 rewardPerTokenPaid; // amount of reward already paid to user per token
        uint256 reward; // accumulated reward for each user
    }
    mapping(address => mapping(address => UserInfo)) public userInfo;
    mapping(address => address[]) public userPoolRecord; // order not guaranteed

    IFlurryStakingRewards public override flurryStakingRewards;

    function initialize(address flurryStakingRewardsAddr) public initializer {
        BaseRewards.__initialize();
        flurryStakingRewards = IFlurryStakingRewards(flurryStakingRewardsAddr);
    }

    function getUserEngagedPool(address user) external view override returns (address[] memory) {
        return userPoolRecord[user];
    }

    function getPoolList() external view override returns (address[] memory) {
        return poolList;
    }

    function setRewardsRate(uint256 newRewardsRate) external override onlyRole(DEFAULT_ADMIN_ROLE) whenNotPaused {
        updateRewardForAll();
        rewardsRate = newRewardsRate;
        emit LPRewardsRateChanged(block.number, rewardsRate);
    }

    function stake(address lpToken, uint256 amount)
        external
        override
        whenNotPaused
        nonReentrant
        isSupportedLP(lpToken)
    {
        address user = _msgSender();
        // check and update
        require(amount > 0, "Staking amount must be positive");
        require(poolInfo[lpToken].lpToken.balanceOf(user) >= amount, "Not Enough balance to stake");
        updateReward(user, lpToken);
        // state change
        userInfo[lpToken][user].amount += amount;
        poolInfo[lpToken].totalStakes += amount;
        // interaction
        poolInfo[lpToken].lpToken.safeTransferFrom(user, address(this), amount);
        emit Staked(_msgSender(), lpToken, block.number, amount);

        for (uint256 i = 0; i < userPoolRecord[user].length; i++) {
            if (userPoolRecord[user][i] == lpToken) return;
        }
        userPoolRecord[user].push(lpToken);
    }

    function updateRewardInternal(address lpToken) internal {
        PoolInfo storage pool = poolInfo[lpToken];
        pool.rewardPerToken = rewardsPerToken(lpToken);
        pool.lastUpdateBlock = block.number;
    }

    function updateReward(address user, address lpToken) internal {
        updateRewardInternal(lpToken);
        if (user != address(0)) {
            userInfo[lpToken][user].reward = _earned(user, lpToken);
            userInfo[lpToken][user].rewardPerTokenPaid = poolInfo[lpToken].rewardPerToken;
        }
    }

    /**
     * @notice Staking rewards are accrued up to this block (put aside in _rewardsPerTokenPaid)
     * @return min(current block #, last reward accrual block #)
     */
    function lastBlockApplicable(address lpToken) internal view returns (uint256) {
        return _lastBlockApplicable(poolInfo[lpToken].rewardsEndBlock);
    }

    function rewardOf(address user, address lpToken) external view override returns (uint256) {
        return _earned(user, lpToken);
    }

    function totalRewardOf(address user) external view override returns (uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < poolList.length; i++) {
            totalReward += _earned(user, poolList[i]);
        }
        return totalReward;
    }

    function stakeOf(address user, address lpToken) external view override isSupportedLP(lpToken) returns (uint256) {
        return userInfo[lpToken][user].amount;
    }

    function rewardsPerToken(address lpToken) public view override isSupportedLP(lpToken) returns (uint256) {
        if (poolInfo[lpToken].totalStakes == 0) return poolInfo[lpToken].rewardPerToken;
        return
            rewardPerTokenInternal(
                poolInfo[lpToken].rewardPerToken,
                lastBlockApplicable(lpToken) - poolInfo[lpToken].lastUpdateBlock,
                rewardRatePerTokenInternal(
                    rewardsRate,
                    poolInfo[lpToken].stakeTokenOne,
                    poolInfo[lpToken].allocPoint,
                    poolInfo[lpToken].totalStakes,
                    totalAllocPoint
                )
            );
    }

    function rewardRatePerTokenStaked(address lpToken) external view override isSupportedLP(lpToken) returns (uint256) {
        if (totalAllocPoint == 0) return type(uint256).max;
        PoolInfo storage pool = poolInfo[lpToken];
        if (pool.totalStakes == 0) return type(uint256).max;
        return
            rewardRatePerTokenInternal(
                rewardsRate,
                poolInfo[lpToken].stakeTokenOne,
                pool.allocPoint,
                pool.totalStakes,
                totalAllocPoint
            );
    }

    function _earned(address user, address lpToken) internal view returns (uint256) {
        UserInfo storage _user = userInfo[lpToken][user];
        return
            super._earned(
                _user.amount,
                rewardsPerToken(lpToken) - _user.rewardPerTokenPaid,
                poolInfo[lpToken].stakeTokenOne,
                _user.reward
            );
    }

    /**
     * @dev removes an LP from an array of addresses by linear search (O(n))
     */
    function removeTokenFromRecord(address user, address lpToken) internal {
        for (uint256 i = 0; i < userPoolRecord[user].length; i++) {
            if (userPoolRecord[user][i] == lpToken) {
                // swap the ith item and the last item
                userPoolRecord[user][i] = userPoolRecord[user][userPoolRecord[user].length - 1];
                // pop the last item
                userPoolRecord[user].pop();
                break;
            }
        }
    }

    function withdraw(address lpToken, uint256 amount) external override whenNotPaused nonReentrant {
        // if user exits LP, remove LP from record
        if (amount == userInfo[lpToken][_msgSender()].amount) removeTokenFromRecord(_msgSender(), lpToken);
        _withdrawUser(_msgSender(), lpToken, amount);
    }

    function exit(address lpToken) external override whenNotPaused nonReentrant {
        // remove LP from record
        removeTokenFromRecord(_msgSender(), lpToken);
        _withdrawUser(_msgSender(), lpToken, userInfo[lpToken][_msgSender()].amount);
    }

    function exitAll() external whenNotPaused nonReentrant {
        address user = _msgSender();
        for (uint256 i = 0; i < userPoolRecord[user].length; i++) {
            address poolAddr = userPoolRecord[user][i];
            uint256 amount = userInfo[poolAddr][user].amount;
            if (amount > 0) _withdrawUser(user, poolAddr, amount);
        }
        while (userPoolRecord[user].length > 0) userPoolRecord[user].pop();
    }

    /**
     * @dev this function does NOT handle record removal
     */
    function _withdrawUser(
        address user,
        address lpToken,
        uint256 amount
    ) internal isSupportedLP(lpToken) {
        // check and update
        require(userInfo[lpToken][user].amount != 0, "No stakes to withdraw");
        require(userInfo[lpToken][user].amount >= amount, "Exceeds staked amount");
        updateReward(user, lpToken);
        // state change
        userInfo[lpToken][user].amount -= amount;
        poolInfo[lpToken].totalStakes -= amount;
        // interaction
        poolInfo[lpToken].lpToken.safeTransfer(user, amount);
        emit Withdrawn(user, lpToken, block.number, amount);
    }

    function claimRewardInternal(address user, address lpToken) internal isSupportedLP(lpToken) {
        updateReward(user, lpToken);
        if (userInfo[lpToken][user].reward > 0) {
            userInfo[lpToken][user].reward = flurryStakingRewards.grantFlurry(user, userInfo[lpToken][user].reward);
        }
    }

    function claimReward(address onBehalfOf, address lpToken)
        external
        override
        onlyRole(FLURRY_STAKING_REWARDS_ROLE)
        whenNotPaused
        nonReentrant
        claimerNotZeroAddr(onBehalfOf)
    {
        claimRewardInternal(onBehalfOf, lpToken);
    }

    function claimReward(address lpToken) external override whenNotPaused nonReentrant {
        claimRewardInternal(_msgSender(), lpToken);
    }

    function claimAllRewardInternal(address user) internal {
        for (uint256 i = 0; i < poolList.length; i++) {
            claimRewardInternal(user, poolList[i]);
        }
    }

    function claimAllReward(address onBehalfOf)
        external
        override
        onlyRole(FLURRY_STAKING_REWARDS_ROLE)
        whenNotPaused
        nonReentrant
        claimerNotZeroAddr(onBehalfOf)
    {
        claimAllRewardInternal(onBehalfOf);
    }

    function claimAllReward() external override whenNotPaused nonReentrant {
        claimAllRewardInternal(_msgSender());
    }

    function addLP(address lpToken, uint256 allocPoint)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        notSupportedLP(lpToken)
    {
        updateRewardForAll();
        totalAllocPoint += allocPoint;
        poolList.push(lpToken);
        poolInfo[lpToken] = PoolInfo({
            lpToken: IERC20Upgradeable(lpToken),
            allocPoint: allocPoint,
            totalStakes: 0,
            lastUpdateBlock: block.number,
            rewardPerToken: 0,
            rewardsEndBlock: 0,
            stakeTokenOne: getTokenOne(lpToken)
        });
        isSupported[lpToken] = true;
        emit LPAdded(lpToken);
    }

    function setLP(address lpToken, uint256 allocPoint)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        isSupportedLP(lpToken)
    {
        updateRewardForAll();
        totalAllocPoint = totalAllocPoint - poolInfo[lpToken].allocPoint + allocPoint;
        poolInfo[lpToken].allocPoint = allocPoint;
    }

    function startRewards(address lpToken, uint256 rewardDuration)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        isSupportedLP(lpToken)
        isValidDuration(rewardDuration)
    {
        PoolInfo storage pool = poolInfo[lpToken];
        require(block.number > pool.rewardsEndBlock, "Previous rewards period must complete before starting a new one");
        updateRewardInternal(lpToken);
        pool.lastUpdateBlock = block.number;
        pool.rewardsEndBlock = block.number + rewardDuration;
        emit LPRewardsEndUpdated(lpToken, block.number, pool.rewardsEndBlock);
    }

    function endRewards(address lpToken)
        external
        override
        onlyRole(DEFAULT_ADMIN_ROLE)
        whenNotPaused
        isSupportedLP(lpToken)
    {
        PoolInfo storage pool = poolInfo[lpToken];
        if (pool.rewardsEndBlock > block.number) {
            pool.rewardsEndBlock = block.number;
            emit LPRewardsEndUpdated(lpToken, block.number, pool.rewardsEndBlock);
        }
    }

    function updateRewardForAll() internal {
        for (uint256 i = 0; i < poolList.length; i++) {
            updateRewardInternal(poolList[i]);
        }
    }

    function sweepERC20Token(address token, address to) external override onlyRole(SWEEPER_ROLE) {
        require(!isSupported[token], "!safe");
        _sweepERC20Token(token, to);
    }

    modifier isSupportedLP(address lpToken) {
        require(isSupported[lpToken], "LP Token not supported");
        _;
    }

    modifier notSupportedLP(address lpToken) {
        require(!isSupported[lpToken], "LP token already registered");
        _;
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IFlurryStakingRewards} from "../interfaces/IFlurryStakingRewards.sol";

/**
 * @title LP Staking Rewards Interface
 * @notice Interface for FLURRY token rewards when staking LP tokens
 */
interface ILPStakingRewards {
    /**
     * @notice checks whether the staking of a LP token is supported by the reward scheme
     * @param lpToken address of LP Token contract
     * @return true if the reward scheme supports `lpToken`, false otherwise
     */
    function isSupported(address lpToken) external returns (bool);

    /**
     * @param user user address
     * @return list of addresses of LP user has engaged in
     */
    function getUserEngagedPool(address user) external view returns (address[] memory);

    /**
     * @return list of addresses of LP registered in this contract
     */
    function getPoolList() external view returns (address[] memory);

    /**
     * @return amount of FLURRY distrubuted for all LP per block,
     * to be shared by the staking pools according to allocation points
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Admin function - set rewards rate earned for all LP per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice Retrieve the stake balance for a stakeholder.
     * @param addr Stakeholder address
     * @param lpToken Address of LP Token contract
     * @return user staked amount (in wei)
     */
    function stakeOf(address addr, address lpToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for one LP token
     * @param user The stakeholder to check rewards for
     * @param lpToken Address of LP Token contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address lpToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all LP token
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param lpToken Address of LP Token contract
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(address lpToken, uint256 amount) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for one LP on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     * @param lpToken Address of LP Token contract
     */
    function claimReward(address onBehalfOf, address lpToken) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for one LP token
     * @param lpToken Address of LP Token contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address lpToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for all LP on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     */
    function claimAllReward(address onBehalfOf) external;

    /**
     * @notice A method to allow a LP token holder to claim his rewards for all LP token
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward() external;

    /**
     * @notice A method to unstake.
     * @param lpToken Address of LP Token contract
     * @param amount amount to unstake (in wei)
     */
    function withdraw(address lpToken, uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * @param lpToken Address of LP Token contract
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit(address lpToken) external;

    /**
     * @notice Total accumulated reward per token
     * @param lpToken Address of LP Token contract
     * @return Reward entitlement per LP token staked (in wei)
     */
    function rewardsPerToken(address lpToken) external view returns (uint256);

    /**
     * @notice current reward rate per LP token staked
     * @param lpToken Address of LP Token contract
     * @return rewards rate in FLURRY per block per LP staked scaled by 18 decimals
     */
    function rewardRatePerTokenStaked(address lpToken) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param lpToken Address of LP Token contract
     * @param rewardDuration Reward Duration in number of blocks
     */
    function startRewards(address lpToken, uint256 rewardDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier if there is one running
     * @param lpToken Address of LP Token contract
     */
    function endRewards(address lpToken) external;

    /**
     * @notice Admin function - register a LP to this contract
     * @param lpToken address of the LP to be registered
     * @param allocPoint allocation points (weight) assigned to the given LP
     */
    function addLP(address lpToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - change the allocation points of a LP registered in this contract
     * @param lpToken address of the LP subject to change
     * @param allocPoint allocation points (weight) assigned to the given LP
     */
    function setLP(address lpToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @return reference to RhoToken Rewards contract
     */
    function flurryStakingRewards() external returns (IFlurryStakingRewards);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/**
 * @title BaseRewards Abstract Contract
 * @notice Abstract Contract to be inherited by LPStakingReward, StakingReward and RhoTokenReward.
 * Implements the core logic as internal functions.
 * *** Note: avoid using `super` keyword to avoid confusion because the derived contracts use multiple inheritance ***
 */

import {MathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import {
    IERC20MetadataUpgradeable
} from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import {
    AccessControlEnumerableUpgradeable
} from "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

abstract contract BaseRewards is AccessControlEnumerableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // events
    event RewardPaid(address indexed user, uint256 reward);
    event NotEnoughBalance(address indexed user, uint256 withdrawalAmount);

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant SWEEPER_ROLE = keccak256("SWEEPER_ROLE");

    function __initialize() internal {
        AccessControlEnumerableUpgradeable.__AccessControlEnumerable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function getTokenOne(address token) internal view returns (uint256) {
        return 10**IERC20MetadataUpgradeable(token).decimals();
    }

    /**
     * @notice Calculate accrued but unclaimed reward for a user
     * @param _tokenBalance balance of the rhoToken, OR staking ammount of LP/FLURRY
     * @param _netRewardPerToken accumulated reward minus the reward already paid to user, on a per token basis
     * @param _tokenOne decimal of the token
     * @param accumulatedReward accumulated reward of the user
     * @return claimable reward of the user
     */
    function _earned(
        uint256 _tokenBalance,
        uint256 _netRewardPerToken,
        uint256 _tokenOne,
        uint256 accumulatedReward
    ) internal pure returns (uint256) {
        return ((_tokenBalance * _netRewardPerToken) / _tokenOne) + accumulatedReward;
    }

    /**
     * @notice Rewards are accrued up to this block (put aside in rewardsPerTokenPaid)
     * @return min(The current block # or last rewards accrual block #)
     */
    function _lastBlockApplicable(uint256 _rewardsEndBlock) internal view returns (uint256) {
        return MathUpgradeable.min(block.number, _rewardsEndBlock);
    }

    function rewardRatePerTokenInternal(
        uint256 rewardRate,
        uint256 tokenOne,
        uint256 allocPoint,
        uint256 totalToken,
        uint256 totalAllocPoint
    ) internal pure returns (uint256) {
        return (rewardRate * tokenOne * allocPoint) / (totalToken * totalAllocPoint);
    }

    function rewardPerTokenInternal(
        uint256 accruedRewardsPerToken,
        uint256 blockDelta,
        uint256 rewardRatePerToken
    ) internal pure returns (uint256) {
        return accruedRewardsPerToken + blockDelta * rewardRatePerToken;
    }

    /**
     * admin functions to withdraw random token transfer to this contract
     */
    function _sweepERC20Token(address token, address to) internal {
        IERC20Upgradeable tokenToSweep = IERC20Upgradeable(token);
        tokenToSweep.safeTransfer(to, tokenToSweep.balanceOf(address(this)));
    }

    /** Pausable */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    modifier claimerNotZeroAddr(address addr) {
        require(addr != address(0), "Claimer cannot be zero address");
        _;
    }

    modifier isValidDuration(uint256 rewardDuration) {
        require(rewardDuration > 0, "Reward duration cannot be zero");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {ILPStakingRewards} from "../interfaces/ILPStakingRewards.sol";
import {IRhoTokenRewards} from "../interfaces/IRhoTokenRewards.sol";

/**
 * @title Flurry Staking Rewards Interface
 * @notice Interface for Flurry token staking functions
 *
 */
interface IFlurryStakingRewards {
    /**
     * @return amount of FLURRY rewards available for the three reward schemes
     * (Flurry Staking, LP Token Staking and rhoToken Holding)
     */
    function totalRewardsPool() external view returns (uint256);

    /**
     * @return aggregated FLURRY stakes from all stakers (in wei)
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
     * @notice A method to allow a stakeholder to check all his rewards.
     * Includes Staking Rewards + RhoToken Rewards + LP Token Rewards
     * @param user The stakeholder to check rewards for.
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardsOf(address user) external view returns (uint256);

    /**
     * @return amount of FLURRY distrubuted to all FLURRY stakers per block
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Total accumulated reward per token
     * @return Reward entitlement per FLURRY token staked (in wei)
     */
    function rewardsPerToken() external view returns (uint256);

    /**
     * @notice current reward rate per FLURRY token staked
     * @return rewards rate in FLURRY per block per FLURRY staked scaled by 18 decimals
     */
    function rewardRatePerTokenStaked() external view returns (uint256);

    /**
     * @notice A method to add a stake.
     * @param amount amount of flurry tokens to be staked (in wei)
     */
    function stake(uint256 amount) external;

    /**
     * @notice A method to unstake.
     * @param amount amount to unstake (in wei)
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice A method to allow a stakeholder to withdraw his FLURRY staking rewards.
     */
    function claimReward() external;

    /**
     * @notice A method to allow a stakeholder to claim all his rewards.
     */
    function claimAllRewards() external;

    /**
     * @notice NOT for external use
     * @dev only callable by LPStakingRewards or RhoTokenRewards for FLURRY distribution
     * @param addr address of LP Token staker / rhoToken holder
     * @param amount amount of FLURRY token rewards to grant (in wei)
     * @return outstanding amount if claim is not successful, 0 if successful
     */
    function grantFlurry(address addr, uint256 amount) external returns (uint256);

    /**
     * @notice A method to allow a stakeholder to withdraw full stake.
     * Rewards are not automatically claimed. Use claimReward()
     */
    function exit() external;

    /**
     * @notice Admin function - set rewards rate earned for FLURRY staking per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice Admin function - A method to start rewards distribution
     * @param rewardsDuration rewards duration in number of blocks
     */
    function startRewards(uint256 rewardsDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     */
    function endRewards() external;

    /**
     * @return true if reward is locked, false otherwise
     */
    function isLocked() external view returns (bool);

    /**
     * @notice Admin function - lock all rewards for all users for a given duration
     * This function should be called BEFORE startRewards()
     * @param lockDuration lock duration in number of blocks
     */
    function setTimeLock(uint256 lockDuration) external;

    /**
     * @notice Admin function - unlock all rewards immediately, if there is a time lock
     */
    function earlyUnlock() external;

    /**
     * @notice Admin function - withdraw other ERC20 tokens sent to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @notice Admin function - set RhoTokenReward contract reference
     */
    function setRhoTokenRewardContract(address rhoTokenRewardAddr) external;

    /**
     * @notice Admin function - set LP Rewards contract reference
     */
    function setLPRewardsContract(address lpRewardsAddr) external;

    /**
     * @return reference to LP Staking Rewards contract
     */
    function lpStakingRewards() external returns (ILPStakingRewards);

    /**
     * @return reference to RhoToken Rewards contract
     */
    function rhoTokenRewards() external returns (IRhoTokenRewards);
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import {IFlurryStakingRewards} from "../interfaces/IFlurryStakingRewards.sol";

/**
 * @title RhoToken Rewards Interface
 * @notice Interface for bonus FLURRY token rewards contract for RhoToken holders
 */
interface IRhoTokenRewards {
    /**
     * @notice checks whether the rewards for a rhoToken is supported by the reward scheme
     * @param rhoToken address of rhoToken contract
     * @return true if the reward scheme supports `rhoToken`, false otherwise
     */
    function isSupported(address rhoToken) external returns (bool);

    /**
     * @return list of addresses of rhoTokens registered in this contract
     */
    function getRhoTokenList() external view returns (address[] memory);

    /**
     * @return amount of FLURRY distributed for all rhoTokens per block
     */
    function rewardsRate() external view returns (uint256);

    /**
     * @notice Admin function - set reward rate earned for all rhoTokens per block
     * @param newRewardsRate amount of FLURRY (in wei) per block
     */
    function setRewardsRate(uint256 newRewardsRate) external;

    /**
     * @notice A method to allow a stakeholder to check his rewards.
     * @param user The stakeholder to check rewards for.
     * @param rhoToken Address of rhoToken contract
     * @return Accumulated rewards of addr holder (in wei)
     */
    function rewardOf(address user, address rhoToken) external view returns (uint256);

    /**
     * @notice A method to allow a stakeholder to check his rewards for all rhoToken
     * @param user The stakeholder to check rewards for
     * @return Accumulated rewards of addr holder (in wei)
     */
    function totalRewardOf(address user) external view returns (uint256);

    // function setRewardSpeed(uint256 flurrySpeed) public

    /**
     * @notice Total accumulated reward per token
     * @param rhoToken Address of rhoToken contract
     * @return Reward entitlement for rho token
     */
    function rewardsPerToken(address rhoToken) external view returns (uint256);

    /**
     * @notice current reward rate per token staked
     * @param rhoToken Address of rhoToken contract
     * @return reward rate denominated in FLURRY per block
     */
    function rewardRatePerRhoToken(address rhoToken) external view returns (uint256);

    /**
     * @notice Admin function - A method to set reward duration
     * @param rhoToken Address of rhoToken contract
     * @param rewardDuration Reward duration in number of blocks
     */
    function startRewards(address rhoToken, uint256 rewardDuration) external;

    /**
     * @notice Admin function - End Rewards distribution earlier, if there is one running
     * @param rhoToken Address of rhoToken contract
     */
    function endRewards(address rhoToken) external;

    /**
     * @notice Calculate and allocate rewards token for address holder
     * Rewards should accrue from _lastUpdateBlock to lastBlockApplicable
     * rewardsPerToken is based on the total supply of the RhoToken, hence
     * this function needs to be called every time total supply changes
     * @dev intended to be called externally by RhoToken contract modifier, and internally
     * @param user the user to update reward for
     * @param rhoToken the rhoToken to update reward for
     */
    function updateReward(address user, address rhoToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for one rhoToken on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     * @param rhoToken Address of rhoToken contract
     */
    function claimReward(address onBehalfOf, address rhoToken) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for one rhoToken
     * @param rhoToken Address of rhoToken contract
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimReward(address rhoToken) external;

    /**
     * @notice NOT for external use
     * @dev allows Flurry Staking Rewards contract to claim rewards for all rhoTokens on behalf of a user
     * @param onBehalfOf address of the user to claim rewards for
     */
    function claimAllReward(address onBehalfOf) external;

    /**
     * @notice A method to allow a rhoToken holder to claim his rewards for all rhoTokens
     * Note: If stakingRewards contract do not have enough tokens to pay,
     * this will fail silently and user rewards remains as a credit in this contract
     */
    function claimAllReward() external;

    /**
     * @notice Admin function - register a rhoToken to this contract
     * @param rhoToken address of the rhoToken to be registered
     * @param allocPoint allocation points (weight) assigned to the given rhoToken
     */
    function addRhoToken(address rhoToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - change the allocation points of a rhoToken registered in this contract
     * @param rhoToken address of the rhoToken subject to change
     * @param allocPoint allocation points (weight) assigned to the given rhoToken
     */
    function setRhoToken(address rhoToken, uint256 allocPoint) external;

    /**
     * @notice Admin function - withdraw random token transfer to this contract
     * @param token ERC20 token address to be sweeped
     * @param to address for sending sweeped tokens to
     */
    function sweepERC20Token(address token, address to) external;

    /**
     * @return reference to RhoToken Rewards contract
     */
    function flurryStakingRewards() external returns (IFlurryStakingRewards);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
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

