// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {SafeMath} from './libraries/SafeMath.sol';
import {DistributionTypes} from './libraries/DistributionTypes.sol';
import {IDistributionManager} from './interfaces/IDistributionManager.sol';
import {IERC20} from './interfaces/IERC20.sol';

/**
 * @title DistributionManager
 * @notice Accounting contract to manage multiple staking distributions
 * @author Moonwell
 **/
contract DistributionManager is IDistributionManager {
    using SafeMath for uint256;

    struct AssetData {
        uint128 emissionPerSecond;
        uint128 lastUpdateTimestamp;
        uint256 index;
        mapping(address => uint256) users;
    }

    uint256 public DISTRIBUTION_END;

    address public EMISSION_MANAGER;

    uint8 public constant PRECISION = 18;

    mapping(address => AssetData) public assets;

    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);

    function __DistributionManager_init_unchained(address emissionManager, uint256 distributionDuration) internal {
        require(emissionManager != address(0), 'ZERO_ADDRESS');
        DISTRIBUTION_END = block.timestamp.add(distributionDuration);
        EMISSION_MANAGER = emissionManager;
    }

    /**
     * @dev Configures the distribution of rewards for an asset. This method is useful because it automatically
     *      computes the amount of the asset that is staked.
     **/
    function configureAsset(uint128 emissionsPerSecond, IERC20 underlyingAsset) external override {
      require(msg.sender == EMISSION_MANAGER, 'ONLY_EMISSION_MANAGER');

      // Grab the balance of the underlying asset.
      uint256 totalStaked = underlyingAsset.balanceOf(address(this));

      // Pass data through to the configure assets function.
      _configureAssetInternal(emissionsPerSecond, totalStaked, address(underlyingAsset));
    }

    /**
     * @dev Configures the distribution of rewards for a list of assets
     * @param assetsConfigInput The list of configurations to apply
     **/
    function configureAssets(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput) external override {
        require(msg.sender == EMISSION_MANAGER, 'ONLY_EMISSION_MANAGER');

        for (uint256 i = 0; i < assetsConfigInput.length; ++i) {
          _configureAssetInternal(
            assetsConfigInput[i].emissionPerSecond, 
            assetsConfigInput[i].totalStaked, 
            assetsConfigInput[i].underlyingAsset
          );
        }
    }

    function _configureAssetInternal(uint128 emissionsPerSecond, uint256 totalStaked, address underlyingAsset) internal {
      AssetData storage assetConfig = assets[underlyingAsset];

      _updateAssetStateInternal(
          underlyingAsset,
          assetConfig,
          totalStaked
      );

      assetConfig.emissionPerSecond = emissionsPerSecond;

      emit AssetConfigUpdated(
          underlyingAsset,
          emissionsPerSecond
      );
    }

    /**
     * @dev Updates the state of one distribution, mainly rewards index and timestamp
     * @param underlyingAsset The address used as key in the distribution, for example stkMFAM or the mTokens addresses on Moonwell
     * @param assetConfig Storage pointer to the distribution's config
     * @param totalStaked Current total of staked assets for this distribution
     * @return The new distribution index
     **/
    function _updateAssetStateInternal(
        address underlyingAsset,
        AssetData storage assetConfig,
        uint256 totalStaked
    ) internal returns (uint256) {
        uint256 oldIndex = assetConfig.index;
        uint128 lastUpdateTimestamp = assetConfig.lastUpdateTimestamp;

        if (block.timestamp == lastUpdateTimestamp) {
            return oldIndex;
        }

        uint256 newIndex = _getAssetIndex(
            oldIndex,
            assetConfig.emissionPerSecond,
            lastUpdateTimestamp,
            totalStaked
        );

        if (newIndex != oldIndex) {
            assetConfig.index = newIndex;
            emit AssetIndexUpdated(underlyingAsset, newIndex);
        }

        assetConfig.lastUpdateTimestamp = uint128(block.timestamp);

        return newIndex;
    }

  /**
   * @dev Updates the state of an user in a distribution
   * @param user The user's address
   * @param asset The address of the reference asset of the distribution
   * @param stakedByUser Amount of tokens staked by the user in the distribution at the moment
   * @param totalStaked Total tokens staked in the distribution
   * @return The accrued rewards for the user until the moment
   **/
  function _updateUserAssetInternal(
    address user,
    address asset,
    uint256 stakedByUser,
    uint256 totalStaked
  ) internal returns (uint256) {
    AssetData storage assetData = assets[asset];
    uint256 userIndex = assetData.users[user];
    uint256 accruedRewards = 0;

    uint256 newIndex = _updateAssetStateInternal(asset, assetData, totalStaked);

    if (userIndex != newIndex) {
      if (stakedByUser != 0) {
        accruedRewards = _getRewards(stakedByUser, newIndex, userIndex);
      }

      assetData.users[user] = newIndex;
      emit UserIndexUpdated(user, asset, newIndex);
    }

    return accruedRewards;
  }

  /**
   * @dev Used by "frontend" stake contracts to update the data of an user when claiming rewards from there
   * @param user The address of the user
   * @param stakes List of structs of the user data related with his stake
   * @return The accrued rewards for the user until the moment
   **/
  function _claimRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
    internal
    returns (uint256)
  {
    uint256 accruedRewards = 0;

    for (uint256 i = 0; i < stakes.length; ++i) {
      accruedRewards = accruedRewards.add(
        _updateUserAssetInternal(
          user,
          stakes[i].underlyingAsset,
          stakes[i].stakedByUser,
          stakes[i].totalStaked
        )
      );
    }

    return accruedRewards;
  }

  /**
   * @dev Return the accrued rewards for an user over a list of distribution
   * @param user The address of the user
   * @param stakes List of structs of the user data related with his stake
   * @return The accrued rewards for the user until the moment
   **/
  function _getUnclaimedRewards(address user, DistributionTypes.UserStakeInput[] memory stakes)
    internal
    view
    returns (uint256)
  {
    uint256 accruedRewards = 0;

    for (uint256 i = 0; i < stakes.length; ++i) {
      AssetData storage assetConfig = assets[stakes[i].underlyingAsset];
      uint256 assetIndex = _getAssetIndex(
        assetConfig.index,
        assetConfig.emissionPerSecond,
        assetConfig.lastUpdateTimestamp,
        stakes[i].totalStaked
      );

      accruedRewards = accruedRewards.add(
        _getRewards(stakes[i].stakedByUser, assetIndex, assetConfig.users[user])
      );
    }
    return accruedRewards;
  }

  /**
   * @dev Internal function for the calculation of user's rewards on a distribution
   * @param principalUserBalance Amount staked by the user on a distribution
   * @param reserveIndex Current index of the distribution
   * @param userIndex Index stored for the user, representation his staking moment
   * @return The rewards
   **/
  function _getRewards(
    uint256 principalUserBalance,
    uint256 reserveIndex,
    uint256 userIndex
  ) internal pure returns (uint256) {
    return principalUserBalance.mul(reserveIndex.sub(userIndex)).div(1e18);
  }

  /**
   * @dev Calculates the next value of an specific distribution index, with validations
   * @param currentIndex Current index of the distribution
   * @param emissionPerSecond Representing the total rewards distributed per second per asset unit, on the distribution
   * @param lastUpdateTimestamp Last moment this distribution was updated
   * @param totalBalance of tokens considered for the distribution
   * @return The new index.
   **/
  function _getAssetIndex(
    uint256 currentIndex,
    uint256 emissionPerSecond,
    uint128 lastUpdateTimestamp,
    uint256 totalBalance
  ) internal view returns (uint256) {
    if (
      emissionPerSecond == 0 ||
      totalBalance == 0 ||
      lastUpdateTimestamp == block.timestamp ||
      lastUpdateTimestamp >= DISTRIBUTION_END
    ) {
      return currentIndex;
    }

    uint256 currentTimestamp = block.timestamp > DISTRIBUTION_END
      ? DISTRIBUTION_END
      : block.timestamp;
    uint256 timeDelta = currentTimestamp.sub(lastUpdateTimestamp);
    return
      emissionPerSecond.mul(timeDelta).mul(1e18).div(totalBalance).add(
        currentIndex
      );
  }

  /**
   * @dev Returns the data of an user on a distribution
   * @param user Address of the user
   * @param asset The address of the reference asset of the distribution
   * @return The new index
   **/
  function getUserAssetData(address user, address asset) public view returns (uint256) {
    return assets[asset].users[user];
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers over Solidity's arithmetic operations with added overflow
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
        require(c >= a, 'SafeMath: addition overflow');

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
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        require(c / a == b, 'SafeMath: multiplication overflow');

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
        return div(a, b, 'SafeMath: division by zero');
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
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
        return mod(a, b, 'SafeMath: modulo by zero');
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
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

library DistributionTypes {
    struct AssetConfigInput {
        uint128 emissionPerSecond;
        uint256 totalStaked;
        address underlyingAsset;
    }

    struct UserStakeInput {
        address underlyingAsset;
        uint256 stakedByUser;
        uint256 totalStaked;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "./IERC20.sol";
import {DistributionTypes} from "../libraries/DistributionTypes.sol";

interface IDistributionManager {
  function configureAsset(uint128 emissionPerSecond, IERC20 underlyingAsset) external;
  function configureAssets(DistributionTypes.AssetConfigInput[] calldata assetsConfigInput) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "./interfaces/IERC20.sol";
import {IStakedToken} from "./interfaces/IStakedToken.sol";
import {ITransferHook} from "./interfaces/ITransferHook.sol";
import {IEcosystemReserve} from "./interfaces/IEcosystemReserve.sol";
import {ERC20WithSnapshot} from "./libraries/ERC20WithSnapshot.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {DistributionTypes} from "./libraries/DistributionTypes.sol";
import {Initializable} from "./utils/Initializable.sol";
import {DistributionManager} from "./DistributionManager.sol";
import {ReentrancyGuardUpgradeable} from "./OpenZeppelin/ReentrancyGuardUpgradeable.sol";

/**
 * @title StakedToken
 * @notice Contract to stake MFAM token, tokenize the position and get rewards, inheriting from a distribution manager contract
 * @author Moonwell
 **/
contract StakedToken is IStakedToken, ERC20WithSnapshot, Initializable, DistributionManager, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    IERC20 public STAKED_TOKEN;
    IERC20 public REWARD_TOKEN;
    uint256 public COOLDOWN_SECONDS;

    /// @notice Seconds available to redeem once the cooldown period is fullfilled
    uint256 public UNSTAKE_WINDOW;

    /// @notice Address to pull from the rewards, needs to have approved this contract
    address public REWARDS_VAULT;

    mapping(address => uint256) public stakerRewardsToClaim;
    mapping(address => uint256) public stakersCooldowns;

    event Staked(address indexed from, address indexed onBehalfOf, uint256 amount);
    event Redeem(address indexed from, address indexed to, uint256 amount);

    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed from, address indexed to, uint256 amount);

    event Cooldown(address indexed user);

    function __StakedToken_init(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        address rewardsVault,
        address emissionManager,
        uint128 distributionDuration,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address governance
    ) internal initializer {
        __ReentrancyGuard_init();
        __ERC20_init_unchained(name, symbol, decimals);
        __DistributionManager_init_unchained(emissionManager, distributionDuration);
        __StakedToken_init_unchained(
            stakedToken,
            rewardToken,
            cooldownSeconds,
            unstakeWindow,
            rewardsVault,
            governance
        );
    }

    function __StakedToken_init_unchained(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        address rewardsVault,
        address governance
    ) internal {
        STAKED_TOKEN = stakedToken;
        REWARD_TOKEN = rewardToken;
        COOLDOWN_SECONDS = cooldownSeconds;
        UNSTAKE_WINDOW = unstakeWindow;
        REWARDS_VAULT = rewardsVault;
        _setGovernance(ITransferHook(governance));
    }

    function stake(address onBehalfOf, uint256 amount) external override nonReentrant {
        require(amount != 0, 'INVALID_ZERO_AMOUNT');
        require(onBehalfOf != address(0), 'STAKE_ZERO_ADDRESS');
        uint256 balanceOfUser = balanceOf(onBehalfOf);

        uint256 accruedRewards = _updateUserAssetInternal(
            onBehalfOf,
            address(this),
            balanceOfUser,
            totalSupply()
        );
        if (accruedRewards != 0) {
            emit RewardsAccrued(onBehalfOf, accruedRewards);
            stakerRewardsToClaim[onBehalfOf] = stakerRewardsToClaim[onBehalfOf].add(accruedRewards);
        }

        stakersCooldowns[onBehalfOf] = getNextCooldownTimestamp(0, amount, onBehalfOf, balanceOfUser);

        _mint(onBehalfOf, amount);
        IERC20(STAKED_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, onBehalfOf, amount);
    }

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param to Address to redeem to
     * @param amount Amount to redeem
     **/
    function redeem(address to, uint256 amount) external override nonReentrant {
        require(amount != 0, 'INVALID_ZERO_AMOUNT');
        require(to != address(0), 'REDEEM_ZERO_ADDRESS');
        //solium-disable-next-line
        uint256 cooldownStartTimestamp = stakersCooldowns[msg.sender];
        require(
            block.timestamp > cooldownStartTimestamp.add(COOLDOWN_SECONDS),
            'INSUFFICIENT_COOLDOWN'
        );
        require(
            block.timestamp.sub(cooldownStartTimestamp.add(COOLDOWN_SECONDS)) <= UNSTAKE_WINDOW,
            'UNSTAKE_WINDOW_FINISHED'
        );
        uint256 balanceOfMessageSender = balanceOf(msg.sender);

        uint256 amountToRedeem = (amount > balanceOfMessageSender) ? balanceOfMessageSender : amount;

        _updateCurrentUnclaimedRewards(msg.sender, balanceOfMessageSender, true);

        _burn(msg.sender, amountToRedeem);

        if (balanceOfMessageSender.sub(amountToRedeem) == 0) {
            stakersCooldowns[msg.sender] = 0;
        }

        IERC20(STAKED_TOKEN).safeTransfer(to, amountToRedeem);

        emit Redeem(msg.sender, to, amountToRedeem);
    }

    /**
     * @dev Activates the cooldown period to unstake
     * - It can't be called if the user is not staking
     **/
    function cooldown() external override {
        require(balanceOf(msg.sender) != 0, "INVALID_BALANCE_ON_COOLDOWN");
        //solium-disable-next-line
        stakersCooldowns[msg.sender] = block.timestamp;

        emit Cooldown(msg.sender);
    }

    /**
     * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
     * @param to Address to stake for
     * @param amount Amount to stake
     **/
    function claimRewards(address to, uint256 amount) external override nonReentrant {
        uint256 newTotalRewards = _updateCurrentUnclaimedRewards(
            msg.sender,
            balanceOf(msg.sender),
            false
        );
        uint256 amountToClaim = (amount == type(uint256).max) ? newTotalRewards : amount;

        stakerRewardsToClaim[msg.sender] = newTotalRewards.sub(amountToClaim, "INVALID_AMOUNT");

        IERC20(REWARD_TOKEN).safeTransferFrom(REWARDS_VAULT, to, amountToClaim);

        emit RewardsClaimed(msg.sender, to, amountToClaim);
    }

    /**
     * @dev Internal ERC20 _transfer of the tokenized staked tokens
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param amount Amount to transfer
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balanceOfFrom = balanceOf(from);
        // Sender
        _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);

        // Recipient
        if (from != to) {
            uint256 balanceOfTo = balanceOf(to);
            _updateCurrentUnclaimedRewards(to, balanceOfTo, true);

            uint256 previousSenderCooldown = stakersCooldowns[from];
            stakersCooldowns[to] = getNextCooldownTimestamp(previousSenderCooldown, amount, to, balanceOfTo);
            // if cooldown was set and whole balance of sender was transferred - clear cooldown
            if (balanceOfFrom == amount && previousSenderCooldown != 0) {
                stakersCooldowns[from] = 0;
            }
        }

        super._transfer(from, to, amount);
    }

    /**
     * @dev Updates the user state related with his accrued rewards
     * @param user Address of the user
     * @param userBalance The current balance of the user
     * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
     * @return The unclaimed rewards that were added to the total accrued
     **/
    function _updateCurrentUnclaimedRewards(
        address user,
        uint256 userBalance,
        bool updateStorage
    ) internal returns (uint256) {
        uint256 accruedRewards = _updateUserAssetInternal(
            user,
            address(this),
            userBalance,
            totalSupply()
        );
        uint256 unclaimedRewards = stakerRewardsToClaim[user].add(accruedRewards);

        if (accruedRewards != 0) {
            if (updateStorage) {
                stakerRewardsToClaim[user] = unclaimedRewards;
            }
            emit RewardsAccrued(user, accruedRewards);
        }

        return unclaimedRewards;
    }

    /**
     * @dev Calculates the how is gonna be a new cooldown timestamp depending on the sender/receiver situation
     *  - If the timestamp of the sender is "better" or the timestamp of the recipient is 0, we take the one of the recipient
     *  - Weighted average of from/to cooldown timestamps if:
     *    # The sender doesn't have the cooldown activated (timestamp 0).
     *    # The sender timestamp is expired
     *    # The sender has a "worse" timestamp
     *  - If the receiver's cooldown timestamp expired (too old), the next is 0
     * @param fromCooldownTimestamp Cooldown timestamp of the sender
     * @param amountToReceive Amount
     * @param toAddress Address of the recipient
     * @param toBalance Current balance of the receiver
     * @return The new cooldown timestamp
     **/
    function getNextCooldownTimestamp(
        uint256 fromCooldownTimestamp,
        uint256 amountToReceive,
        address toAddress,
        uint256 toBalance
    ) public returns (uint256) {
        uint256 toCooldownTimestamp = stakersCooldowns[toAddress];
        if (toCooldownTimestamp == 0) {
            return 0;
        }

        uint256 minimalValidCooldownTimestamp = block.timestamp.sub(COOLDOWN_SECONDS).sub(
            UNSTAKE_WINDOW
        );

        if (minimalValidCooldownTimestamp > toCooldownTimestamp) {
            toCooldownTimestamp = 0;
        } else {
            uint256 fromCooldownTimestampFinal = (minimalValidCooldownTimestamp > fromCooldownTimestamp)
                ? block.timestamp
                : fromCooldownTimestamp;

            if (fromCooldownTimestampFinal < toCooldownTimestamp) {
                return toCooldownTimestamp;
            } else {
                toCooldownTimestamp = (
                    amountToReceive.mul(fromCooldownTimestampFinal).add(toBalance.mul(toCooldownTimestamp))
                )
                    .div(amountToReceive.add(toBalance));
            }
        }
        stakersCooldowns[toAddress] = toCooldownTimestamp;

        return toCooldownTimestamp;
    }

    /**
     * @dev Return the total rewards pending to claim by an staker
     * @param staker The staker address
     * @return The rewards
     */
    function getTotalRewardsBalance(address staker) external view returns (uint256) {
        DistributionTypes.UserStakeInput[] memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
        userStakeInputs[0] = DistributionTypes.UserStakeInput({
            underlyingAsset: address(this),
            stakedByUser: balanceOf(staker),
            totalStaked: totalSupply()
        });
        return stakerRewardsToClaim[staker].add(_getUnclaimedRewards(staker, userStakeInputs));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IStakedToken {
    function stake(address to, uint256 amount) external;

    function redeem(address to, uint256 amount) external;

    function cooldown() external;

    function claimRewards(address to, uint256 amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface ITransferHook {
    function onTransfer(address from, address to, uint256 amount) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "../interfaces/IERC20.sol";

interface IEcosystemReserve {
    function approve(IERC20 token, address recipient, uint256 amount) external;

    function transfer(IERC20 token, address recipient, uint256 amount) external;

    function setFundsAdmin(address admin) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "@openzeppelin/upgrades-core/contracts/Initializable.sol";
import {ERC20} from "../libraries/ERC20.sol";
import {ITransferHook} from "../interfaces/ITransferHook.sol";

/**
 * @title ERC20WithSnapshot
 * @notice ERC20 including snapshots of balances on transfer-related actions
 * @author Moonwell
 **/
contract ERC20WithSnapshot is ERC20 {

    /// @dev snapshot of a value on a specific block, used for balances
    struct Snapshot {
        uint128 blockNumber;
        uint128 value;
    }

    mapping (address => mapping (uint256 => Snapshot)) public _snapshots;
    mapping (address => uint256) public _countsSnapshots;
    /// @dev reference to the Moonwell governance contract to call (if initialized) on _beforeTokenTransfer
    /// !!! IMPORTANT The Moonwell governance is considered a trustable contract, being its responsibility
    /// to control all potential reentrancies by calling back the this contract
    ITransferHook public _governance;

    event SnapshotDone(address owner, uint128 oldValue, uint128 newValue);

    function _setGovernance(ITransferHook governance) internal virtual {
        _governance = governance;
    }

    /**
    * @dev Writes a snapshot for an owner of tokens
    * @param owner The owner of the tokens
    * @param oldValue The value before the operation that is gonna be executed after the snapshot
    * @param newValue The value after the operation
    */
    function _writeSnapshot(address owner, uint128 oldValue, uint128 newValue) internal virtual {
        uint128 currentBlock = uint128(block.number);

        uint256 ownerCountOfSnapshots = _countsSnapshots[owner];
        mapping (uint256 => Snapshot) storage snapshotsOwner = _snapshots[owner];

        // Doing multiple operations in the same block
        if (ownerCountOfSnapshots != 0 && snapshotsOwner[ownerCountOfSnapshots.sub(1)].blockNumber == currentBlock) {
            snapshotsOwner[ownerCountOfSnapshots.sub(1)].value = newValue;
        } else {
            snapshotsOwner[ownerCountOfSnapshots] = Snapshot(currentBlock, newValue);
            _countsSnapshots[owner] = ownerCountOfSnapshots.add(1);
        }

        emit SnapshotDone(owner, oldValue, newValue);
    }

    /**
    * @dev Writes a snapshot before any operation involving transfer of value: _transfer, _mint and _burn
    * - On _transfer, it writes snapshots for both "from" and "to"
    * - On _mint, only for _to
    * - On _burn, only for _from
    * @param from the from address
    * @param to the to address
    * @param amount the amount to transfer
    */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        if (from == to) {
            return;
        }

        if (from != address(0)) {
            uint256 fromBalance = balanceOf(from);
            _writeSnapshot(from, uint128(fromBalance), uint128(fromBalance.sub(amount)));
        }
        if (to != address(0)) {
            uint256 toBalance = balanceOf(to);
            _writeSnapshot(to, uint128(toBalance), uint128(toBalance.add(amount)));
        }

        // caching the Moonwell governance address to avoid multiple state loads
        ITransferHook governance = _governance;
        if (governance != ITransferHook(0)) {
            governance.onTransfer(from, to, amount);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "../libraries/SafeMath.sol";
import {Address} from "../libraries/Address.sol";

/**
 * @title SafeERC20
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Wrappers around ERC20 operations that throw on failure (when the token
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

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (proxy/utils/Initializable.sol)

pragma solidity 0.6.12;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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

pragma solidity 0.6.12;
import "../utils/Initializable.sol";

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
     * by making the `nonReentrant` function external, and making it call a
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.24 <0.7.0;


/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {

  /**
   * @dev Indicates that the contract has been initialized.
   */
  bool private initialized;

  /**
   * @dev Indicates that the contract is in the process of being initialized.
   */
  bool private initializing;

  /**
   * @dev Modifier to use in the initializer function of a contract.
   */
  modifier initializer() {
    require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");

    bool isTopLevelCall = !initializing;
    if (isTopLevelCall) {
      initializing = true;
      initialized = true;
    }

    _;

    if (isTopLevelCall) {
      initializing = false;
    }
  }

  /// @dev Returns true if and only if the function is running in the constructor
  function isConstructor() private view returns (bool) {
    // extcodesize checks the size of the code stored in an address, and
    // address returns the current address. Since the code is still not
    // deployed when running a constructor, any checks on its code size will
    // yield zero, making it an effective way to detect if a contract is
    // under construction or not.
    address self = address(this);
    uint256 cs;
    assembly { cs := extcodesize(self) }
    return cs == 0;
  }

  // Reserved storage space to allow for layout changes in the future.
  uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Context} from "./Context.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IERC20Detailed} from "../interfaces/IERC20Detailed.sol";
import {SafeMath} from "./SafeMath.sol";

/**
 * @title ERC20
 * @notice Basic ERC20 implementation
 * @author Moonwell
 **/
contract ERC20 is Context, IERC20, IERC20Detailed {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    function __ERC20_init_unchained(string memory name, string memory symbol, uint8 decimals) internal {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
    * @return the name of the token
    **/
    function name() public override view returns (string memory) {
        return _name;
    }

    /**
    * @return the symbol of the token
    **/
    function symbol() public override view returns (string memory) {
        return _symbol;
    }

    /**
    * @return the decimals of the token
    **/
    function decimals() public override view returns (uint8) {
        return _decimals;
    }

    /**
    * @return the total supply of the token
    **/
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
    * @return the balance of the token
    **/
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
    * @dev executes a transfer of tokens from msg.sender to recipient
    * @param recipient the recipient of the tokens
    * @param amount the amount of tokens being transferred
    * @return true if the transfer succeeds, false otherwise
    **/
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
    * @dev returns the allowance of spender on the tokens owned by owner
    * @param owner the owner of the tokens
    * @param spender the user allowed to spend the owner"s tokens
    * @return the amount of owner"s tokens spender is allowed to spend
    **/
    function allowance(address owner, address spender)
    public
    virtual
    override
    view
    returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
    * @dev allows spender to spend the tokens owned by msg.sender
    * @param spender the user allowed to spend msg.sender tokens
    * @return true
    **/
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
    * @dev executes a transfer of token from sender to recipient, if msg.sender is allowed to do so
    * @param sender the owner of the tokens
    * @param recipient the recipient of the tokens
    * @param amount the amount of tokens being transferred
    * @return true if the transfer succeeds, false otherwise
    **/
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(amount, 'ERC20: transfer amount exceeds allowance')
        );
        return true;
    }

    /**
    * @dev increases the allowance of spender to spend msg.sender tokens
    * @param spender the user allowed to spend on behalf of msg.sender
    * @param addedValue the amount being added to the allowance
    * @return true
    **/
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
    * @dev decreases the allowance of spender to spend msg.sender tokens
    * @param spender the user allowed to spend on behalf of msg.sender
    * @param subtractedValue the amount being subtracted to the allowance
    * @return true
    **/
    function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
            subtractedValue,
            'ERC20: decreased allowance below zero'
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), 'ERC20: transfer from the zero address');
        require(recipient != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, 'ERC20: transfer amount exceeds balance');
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: mint to the zero address');

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, 'ERC20: burn amount exceeds balance');
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _setName(string memory newName) internal {
        _name = newName;
    }

    function _setSymbol(string memory newSymbol) internal {
        _symbol = newSymbol;
    }

    function _setDecimals(uint8 newDecimals) internal {
        _decimals = newDecimals;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal virtual view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal virtual view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IERC20} from "./IERC20.sol";

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Collection of functions related to the address type
 * From https://github.com/OpenZeppelin/openzeppelin-contracts
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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(address(this).balance >= amount, 'Address: insufficient balance');

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./interfaces/IERC20.sol";
import {StakedToken} from "./StakedToken.sol";

/**
 * @title StakedWell
 * @notice StakedToken with WELL token as staked token
 * @author Moonwell
 **/
contract StakedWell is StakedToken {
    string internal constant NAME = "Staked WELL";
    string internal constant SYMBOL = "stkWELL";
    uint8 internal constant DECIMALS = 18;

    /**
     * @dev Called by the proxy contract
     **/
    function initialize(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        address rewardsVault,
        address emissionManager,
        uint128 distributionDuration,
        address governance
  ) external {
        __StakedToken_init(
            stakedToken,
            rewardToken,
            cooldownSeconds,
            unstakeWindow,
            rewardsVault,
            emissionManager,
            distributionDuration,
            NAME,
            SYMBOL,
            DECIMALS,
            governance
        );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {IERC20} from "./interfaces/IERC20.sol";
import {IStakedToken} from "./interfaces/IStakedToken.sol";
import {ITransferHook} from "./interfaces/ITransferHook.sol";
import {IEcosystemReserve} from "./interfaces/IEcosystemReserve.sol";
import {ERC20WithSnapshot} from "./libraries/ERC20WithSnapshot.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {DistributionTypes} from "./libraries/DistributionTypes.sol";
import {Initializable} from "./utils/Initializable.sol";
import {DistributionManager} from "./DistributionManager.sol";

/**
 * @title StakedToken
 * 
 * This contract embeds logic for UpgradeableReentrancyGuard in the contract rather than inheriting. This is
 * to work around storage layout incompatibilities because the Moonriver contracts were deployed without a reentrancy
 * guard.
 *
 * @notice Contract to stake MFAM token, tokenize the position and get rewards, inheriting from a distribution manager contract
 * @author Moonwell
 **/
contract StakedMfam is IStakedToken, ERC20WithSnapshot, Initializable, DistributionManager {
    /**
     * StakedToken
     * 
     * Code below this line is copied verbatim from StakedToken.sol
     */

    using SafeERC20 for IERC20;

    IERC20 public STAKED_TOKEN;
    IERC20 public REWARD_TOKEN;
    uint256 public COOLDOWN_SECONDS;

    /// @notice Seconds available to redeem once the cooldown period is fullfilled
    uint256 public UNSTAKE_WINDOW;

    /// @notice Address to pull from the rewards, needs to have approved this contract
    address public REWARDS_VAULT;

    mapping(address => uint256) public stakerRewardsToClaim;
    mapping(address => uint256) public stakersCooldowns;

    event Staked(address indexed from, address indexed onBehalfOf, uint256 amount);
    event Redeem(address indexed from, address indexed to, uint256 amount);

    event RewardsAccrued(address user, uint256 amount);
    event RewardsClaimed(address indexed from, address indexed to, uint256 amount);

    event Cooldown(address indexed user);


    function __StakedMfam_init(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        address rewardsVault,
        address emissionManager,
        uint128 distributionDuration,
        string memory name,
        string memory symbol,
        uint8 decimals,
        address governance
    ) internal initializer {
        __ERC20_init_unchained(name, symbol, decimals);
        __DistributionManager_init_unchained(emissionManager, distributionDuration);
        __StakedMfam_init_unchained(
            stakedToken,
            rewardToken,
            cooldownSeconds,
            unstakeWindow,
            rewardsVault,
            governance
        );
    }

    function __StakedMfam_init_unchained(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        address rewardsVault,
        address governance
    ) internal {
        STAKED_TOKEN = stakedToken;
        REWARD_TOKEN = rewardToken;
        COOLDOWN_SECONDS = cooldownSeconds;
        UNSTAKE_WINDOW = unstakeWindow;
        REWARDS_VAULT = rewardsVault;
        _setGovernance(ITransferHook(governance));
    }

    function stake(address onBehalfOf, uint256 amount) external override nonReentrant {
        require(amount != 0, 'INVALID_ZERO_AMOUNT');
        require(onBehalfOf != address(0), 'STAKE_ZERO_ADDRESS');
        uint256 balanceOfUser = balanceOf(onBehalfOf);

        uint256 accruedRewards = _updateUserAssetInternal(
            onBehalfOf,
            address(this),
            balanceOfUser,
            totalSupply()
        );
        if (accruedRewards != 0) {
            emit RewardsAccrued(onBehalfOf, accruedRewards);
            stakerRewardsToClaim[onBehalfOf] = stakerRewardsToClaim[onBehalfOf].add(accruedRewards);
        }

        stakersCooldowns[onBehalfOf] = getNextCooldownTimestamp(0, amount, onBehalfOf, balanceOfUser);

        _mint(onBehalfOf, amount);
        IERC20(STAKED_TOKEN).safeTransferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, onBehalfOf, amount);
    }

    /**
     * @dev Redeems staked tokens, and stop earning rewards
     * @param to Address to redeem to
     * @param amount Amount to redeem
     **/
    function redeem(address to, uint256 amount) external override nonReentrant {
        require(amount != 0, 'INVALID_ZERO_AMOUNT');
        require(to != address(0), 'REDEEM_ZERO_ADDRESS');
        //solium-disable-next-line
        uint256 cooldownStartTimestamp = stakersCooldowns[msg.sender];
        require(
            block.timestamp > cooldownStartTimestamp.add(COOLDOWN_SECONDS),
            'INSUFFICIENT_COOLDOWN'
        );
        require(
            block.timestamp.sub(cooldownStartTimestamp.add(COOLDOWN_SECONDS)) <= UNSTAKE_WINDOW,
            'UNSTAKE_WINDOW_FINISHED'
        );
        uint256 balanceOfMessageSender = balanceOf(msg.sender);

        uint256 amountToRedeem = (amount > balanceOfMessageSender) ? balanceOfMessageSender : amount;

        _updateCurrentUnclaimedRewards(msg.sender, balanceOfMessageSender, true);

        _burn(msg.sender, amountToRedeem);

        if (balanceOfMessageSender.sub(amountToRedeem) == 0) {
            stakersCooldowns[msg.sender] = 0;
        }

        IERC20(STAKED_TOKEN).safeTransfer(to, amountToRedeem);

        emit Redeem(msg.sender, to, amountToRedeem);
    }

    /**
     * @dev Activates the cooldown period to unstake
     * - It can't be called if the user is not staking
     **/
    function cooldown() external override {
        require(balanceOf(msg.sender) != 0, "INVALID_BALANCE_ON_COOLDOWN");
        //solium-disable-next-line
        stakersCooldowns[msg.sender] = block.timestamp;

        emit Cooldown(msg.sender);
    }

    /**
     * @dev Claims an `amount` of `REWARD_TOKEN` to the address `to`
     * @param to Address to stake for
     * @param amount Amount to stake
     **/
    function claimRewards(address to, uint256 amount) external override nonReentrant {
        uint256 newTotalRewards = _updateCurrentUnclaimedRewards(
            msg.sender,
            balanceOf(msg.sender),
            false
        );
        uint256 amountToClaim = (amount == type(uint256).max) ? newTotalRewards : amount;

        stakerRewardsToClaim[msg.sender] = newTotalRewards.sub(amountToClaim, "INVALID_AMOUNT");

        IERC20(REWARD_TOKEN).safeTransferFrom(REWARDS_VAULT, to, amountToClaim);

        emit RewardsClaimed(msg.sender, to, amountToClaim);
    }

    /**
     * @dev Internal ERC20 _transfer of the tokenized staked tokens
     * @param from Address to transfer from
     * @param to Address to transfer to
     * @param amount Amount to transfer
     **/
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        uint256 balanceOfFrom = balanceOf(from);
        // Sender
        _updateCurrentUnclaimedRewards(from, balanceOfFrom, true);

        // Recipient
        if (from != to) {
            uint256 balanceOfTo = balanceOf(to);
            _updateCurrentUnclaimedRewards(to, balanceOfTo, true);

            uint256 previousSenderCooldown = stakersCooldowns[from];
            stakersCooldowns[to] = getNextCooldownTimestamp(previousSenderCooldown, amount, to, balanceOfTo);
            // if cooldown was set and whole balance of sender was transferred - clear cooldown
            if (balanceOfFrom == amount && previousSenderCooldown != 0) {
                stakersCooldowns[from] = 0;
            }
        }

        super._transfer(from, to, amount);
    }

    /**
     * @dev Updates the user state related with his accrued rewards
     * @param user Address of the user
     * @param userBalance The current balance of the user
     * @param updateStorage Boolean flag used to update or not the stakerRewardsToClaim of the user
     * @return The unclaimed rewards that were added to the total accrued
     **/
    function _updateCurrentUnclaimedRewards(
        address user,
        uint256 userBalance,
        bool updateStorage
    ) internal returns (uint256) {
        uint256 accruedRewards = _updateUserAssetInternal(
            user,
            address(this),
            userBalance,
            totalSupply()
        );
        uint256 unclaimedRewards = stakerRewardsToClaim[user].add(accruedRewards);

        if (accruedRewards != 0) {
            if (updateStorage) {
                stakerRewardsToClaim[user] = unclaimedRewards;
            }
            emit RewardsAccrued(user, accruedRewards);
        }

        return unclaimedRewards;
    }

    /**
     * @dev Calculates the how is gonna be a new cooldown timestamp depending on the sender/receiver situation
     *  - If the timestamp of the sender is "better" or the timestamp of the recipient is 0, we take the one of the recipient
     *  - Weighted average of from/to cooldown timestamps if:
     *    # The sender doesn't have the cooldown activated (timestamp 0).
     *    # The sender timestamp is expired
     *    # The sender has a "worse" timestamp
     *  - If the receiver's cooldown timestamp expired (too old), the next is 0
     * @param fromCooldownTimestamp Cooldown timestamp of the sender
     * @param amountToReceive Amount
     * @param toAddress Address of the recipient
     * @param toBalance Current balance of the receiver
     * @return The new cooldown timestamp
     **/
    function getNextCooldownTimestamp(
        uint256 fromCooldownTimestamp,
        uint256 amountToReceive,
        address toAddress,
        uint256 toBalance
    ) public returns (uint256) {
        uint256 toCooldownTimestamp = stakersCooldowns[toAddress];
        if (toCooldownTimestamp == 0) {
            return 0;
        }

        uint256 minimalValidCooldownTimestamp = block.timestamp.sub(COOLDOWN_SECONDS).sub(
            UNSTAKE_WINDOW
        );

        if (minimalValidCooldownTimestamp > toCooldownTimestamp) {
            toCooldownTimestamp = 0;
        } else {
            uint256 fromCooldownTimestampFinal = (minimalValidCooldownTimestamp > fromCooldownTimestamp)
                ? block.timestamp
                : fromCooldownTimestamp;

            if (fromCooldownTimestampFinal < toCooldownTimestamp) {
                return toCooldownTimestamp;
            } else {
                toCooldownTimestamp = (
                    amountToReceive.mul(fromCooldownTimestampFinal).add(toBalance.mul(toCooldownTimestamp))
                )
                    .div(amountToReceive.add(toBalance));
            }
        }
        stakersCooldowns[toAddress] = toCooldownTimestamp;

        return toCooldownTimestamp;
    }

    /**
     * @dev Return the total rewards pending to claim by an staker
     * @param staker The staker address
     * @return The rewards
     */
    function getTotalRewardsBalance(address staker) external view returns (uint256) {
        DistributionTypes.UserStakeInput[] memory userStakeInputs = new DistributionTypes.UserStakeInput[](1);
        userStakeInputs[0] = DistributionTypes.UserStakeInput({
            underlyingAsset: address(this),
            stakedByUser: balanceOf(staker),
            totalStaked: totalSupply()
        });
        return stakerRewardsToClaim[staker].add(_getUnclaimedRewards(staker, userStakeInputs));
    }

    /**
     * StakedWell
     * 
     * Code below this line is copied verbatim from StakedWell.sol
     */

    /**    
     * @dev Called by the proxy contract
     **/
    function initialize(
        IERC20 stakedToken,
        IERC20 rewardToken,
        uint256 cooldownSeconds,
        uint256 unstakeWindow,
        address rewardsVault,
        address emissionManager,
        uint128 distributionDuration,
        address governance
    ) external initializer {
        __StakedMfam_init(
            stakedToken,
            rewardToken,
            cooldownSeconds,
            unstakeWindow,
            rewardsVault,
            emissionManager,
            distributionDuration,
            NAME,
            SYMBOL,
            DECIMALS,
            governance
        );
    }

    /**
     * ReentrancyGuardUpgradeable
     * 
     * Code below this line is copied verbatim from ReentrancyGuardUpgradeable.sol
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

    /**
     * Additional Storage Layout - StakedMFam.sol
     * 
     * Add fields that were originally in StakedMfam.sol, which inherited from this contract. This aligns all storage
     * in the contract.
     */

    string internal constant NAME = "Staked MFAM";
    string internal constant SYMBOL = "stkMFAM";
    uint8 internal constant DECIMALS = 18;

    /**
     * Additional Storage Layout - ReentrancyGuardUpgradeable.sol
     * 
     * Add fields that were originally in ReentrancyGuardUpgradeable.sol. These fields are extra and are added to the 
     * existing storage layout.
     */

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./interfaces/IERC20.sol";
import "./interfaces/IEcosystemReserve.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {Initializable} from "./utils/Initializable.sol";

/**
 * @title EcosystemReserve
 * 
 * This contract embeds logic for UpgradeableReentrancyGuard in the contract rather than inheriting. This is
 * to work around storage layout incompatibilities because the Moonriver contracts were deployed without a reentrancy
 * guard.
 *
 * @notice Stores all the mTokens kept for incentives, just adding different systems to whitelist
 * that will pull MFAM funds for their specific use case
 * @author Moonwell
 */
contract EcosystemReserveMoonriver is IEcosystemReserve, Initializable {
    /**
     * EcosystemReserveMoonriver
     * 
     * Code below this line is copied verbatim from EcosystemReserve.sol
     */

    using SafeERC20 for IERC20;

    address internal _fundsAdmin;

    event NewFundsAdmin(address indexed fundsAdmin);

    function getFundsAdmin() external view returns (address) {
        return _fundsAdmin;
    }

    modifier onlyFundsAdmin() {
        require(msg.sender == _fundsAdmin, "ONLY_BY_FUNDS_ADMIN");
        _;
    }

    function initialize(address reserveController) external initializer {
        require(reserveController != address(0), "ZERO_ADDRESS");
        _setFundsAdmin(reserveController);
    }

    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyFundsAdmin {
        token.approve(recipient, amount);
    }

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyFundsAdmin nonReentrant {
        token.transfer(recipient, amount);
    }

    function setFundsAdmin(address admin) external override onlyFundsAdmin {
        _setFundsAdmin(admin);
    }

    function _setFundsAdmin(address admin) internal {
        require(admin != address(0), "ZERO_ADDRESS");
        _fundsAdmin = admin;
        emit NewFundsAdmin(admin);
    }

    /**
     * ReentrancyGuardUpgradeable
     * 
     * Code below this line is copied verbatim from ReentrancyGuardUpgradeable.sol
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

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "../libraries/ERC20.sol";

contract FaucetERC20 is ERC20 {

    function mint(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {Context} from "./Context.sol";

/**
 * @dev From https://github.com/OpenZeppelin/openzeppelin-contracts
 * Contract module which provides a basic access control mechanism, where
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
    constructor() public {
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
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./interfaces/IEcosystemReserve.sol";
import "./interfaces/IERC20.sol";
import {Ownable} from "./libraries/Ownable.sol";

/*
 * @title EcosystemReserveController
 * @dev Proxy smart contract to control the EcosystemReserve, in order for the governance to call its
 * user-face functions (as the governance is also the proxy admin of the EcosystemReserve)
 * @author Moonwell
 */
contract EcosystemReserveController is Ownable {
    IEcosystemReserve public ECOSYSTEM_RESERVE;
    bool public initialized;

    function setEcosystemReserve(address ecosystemReserve) external onlyOwner {
        require(!initialized, "ECOSYSTEM_RESERVE has been initialized");
        initialized = true;
        ECOSYSTEM_RESERVE = IEcosystemReserve(ecosystemReserve);
    }

    function approve(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        ECOSYSTEM_RESERVE.approve(token, recipient, amount);
    }

    function transfer(IERC20 token, address recipient, uint256 amount) external onlyOwner {
        ECOSYSTEM_RESERVE.transfer(token, recipient, amount);
    }

    function setFundsAdmin(address admin) external onlyOwner {
        ECOSYSTEM_RESERVE.setFundsAdmin(admin);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import "./interfaces/IERC20.sol";
import "./interfaces/IEcosystemReserve.sol";
import {SafeERC20} from "./libraries/SafeERC20.sol";
import {Initializable} from "./utils/Initializable.sol";
import {ReentrancyGuardUpgradeable} from "./OpenZeppelin/ReentrancyGuardUpgradeable.sol";

/**
 * @title EcosystemReserve
 * @notice Stores all the mTokens kept for incentives, just adding different systems to whitelist
 * that will pull MFAM funds for their specific use case
 * @author Moonwell
 **/
contract EcosystemReserve is IEcosystemReserve, Initializable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    address internal _fundsAdmin;

    event NewFundsAdmin(address indexed fundsAdmin);

    function getFundsAdmin() external view returns (address) {
        return _fundsAdmin;
    }

    modifier onlyFundsAdmin() {
        require(msg.sender == _fundsAdmin, "ONLY_BY_FUNDS_ADMIN");
        _;
    }

    function initialize(address reserveController) external initializer {
        require(reserveController != address(0), "ZERO_ADDRESS");
        __ReentrancyGuard_init();
        _setFundsAdmin(reserveController);
    }

    function approve(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyFundsAdmin {
        token.approve(recipient, amount);
    }

    function transfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external override onlyFundsAdmin nonReentrant {
        token.transfer(recipient, amount);
    }

    function setFundsAdmin(address admin) external override onlyFundsAdmin {
        _setFundsAdmin(admin);
    }

    function _setFundsAdmin(address admin) internal {
        require(admin != address(0), "ZERO_ADDRESS");
        _fundsAdmin = admin;
        emit NewFundsAdmin(admin);
    }
}