// Contracts by dYdX Foundation. Individual files are released under different licenses.
//
// https://dydx.community
// https://github.com/dydxfoundation/governance-contracts
//
// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../dependencies/open-zeppelin/SafeERC20.sol';
import { IERC20 } from '../../interfaces/IERC20.sol';
import { SM1Admin } from '../v1_1/impl/SM1Admin.sol';
import { SM1Getters } from '../v1_1/impl/SM1Getters.sol';
import { SM1Operators } from '../v1_1/impl/SM1Operators.sol';
import { SM1Slashing } from '../v1_1/impl/SM1Slashing.sol';
import { SM1Staking } from '../v1_1/impl/SM1Staking.sol';

/**
 * @title SafetyModuleV2
 * @author dYdX
 *
 * @notice Contract for staking tokens, which may be slashed by the permissioned slasher.
 *
 *  NOTE: Most functions will revert if epoch zero has not started.
 */
contract SafetyModuleV2 is
  SM1Slashing,
  SM1Operators,
  SM1Admin,
  SM1Getters
{
  using SafeERC20 for IERC20;

  // ============ Constants ============

  string public constant EIP712_DOMAIN_NAME = 'dYdX Safety Module';

  string public constant EIP712_DOMAIN_VERSION = '1';

  bytes32 public constant EIP712_DOMAIN_SCHEMA_HASH = keccak256(
    'EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'
  );

  // ============ Constructor ============

  constructor(
    IERC20 stakedToken,
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    SM1Staking(stakedToken, rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {}

  // ============ External Functions ============

  /**
   * @notice Initializer for v2, intended to fix the deployment bug that affected v1.
   *
   *  Responsible for the following:
   *
   *    1. Funds recovery and staker compensation:
   *        - Transfer all Safety Module DYDX to the recovery contract.
   *        - Transfer compensation amount from the rewards treasury to the recovery contract.
   *
   *    2. Storage recovery and cleanup:
   *        - Set the _EXCHANGE_RATE_ to EXCHANGE_RATE_BASE.
   *        - Clean up invalid storage values at slots 115 and 125.
   *
   * @param  recoveryContract            The address of the contract which will distribute
   *                                     recovered funds to stakers.
   * @param  recoveryCompensationAmount  Amount to transfer out of the rewards treasury, for staker
   *                                     compensation, on top of the return of staked funds.
   */
  function initialize(
    address recoveryContract,
    uint256 recoveryCompensationAmount
  )
    external
    initializer
  {
    // Funds recovery and staker compensation.
    uint256 balance = STAKED_TOKEN.balanceOf(address(this));
    STAKED_TOKEN.safeTransfer(recoveryContract, balance);
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, recoveryContract, recoveryCompensationAmount);

    // Storage recovery and cleanup.
    __SM1ExchangeRate_init();
    // solhint-disable-next-line no-inline-assembly
    assembly {
      sstore(115, 0)
      sstore(125, 0)
    }
  }

  // ============ Internal Functions ============

  /**
   * @dev Returns the revision of the implementation contract.
   *
   * @return The revision number.
   */
  function getRevision()
    internal
    pure
    override
    returns (uint256)
  {
    return 2;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import { IERC20 } from '../../interfaces/IERC20.sol';
import { SafeMath } from './SafeMath.sol';
import { Address } from './Address.sol';

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

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    require(
      (value == 0) || (token.allowance(address(this), spender) == 0),
      'SafeERC20: approve from non-zero to non-zero allowance'
    );
    callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
  }

  function callOptionalReturn(IERC20 token, bytes memory data) private {
    require(address(token).isContract(), 'SafeERC20: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = address(token).call(data);
    require(success, 'SafeERC20: low-level call failed');

    if (returndata.length > 0) {
      // Return data is optional
      // solhint-disable-next-line max-line-length
      require(abi.decode(returndata, (bool)), 'SafeERC20: ERC20 operation did not succeed');
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1Roles } from './SM1Roles.sol';
import { SM1StakedBalances } from './SM1StakedBalances.sol';

/**
 * @title SM1Admin
 * @author dYdX
 *
 * @dev Admin-only functions.
 */
abstract contract SM1Admin is
  SM1StakedBalances,
  SM1Roles
{
  using SafeMath for uint256;

  // ============ External Functions ============

  /**
   * @notice Set the parameters defining the function from timestamp to epoch number.
   *
   *  The formula used is `n = floor((t - b) / a)` where:
   *    - `n` is the epoch number
   *    - `t` is the timestamp (in seconds)
   *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
   *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
   *
   *  Reverts if epoch zero already started, and the new parameters would change the current epoch.
   *  Reverts if epoch zero has not started, but would have had started under the new parameters.
   *
   * @param  interval  The length `a` of an epoch, in seconds.
   * @param  offset    The offset `b`, i.e. the start of epoch zero, in seconds.
   */
  function setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    if (!hasEpochZeroStarted()) {
      require(
        block.timestamp < offset,
        'SM1Admin: Started epoch zero'
      );
      _setEpochParameters(interval, offset);
      return;
    }

    // We must settle the total active balance to ensure the index is recorded at the epoch
    // boundary as needed, before we make any changes to the epoch formula.
    _settleTotalActiveBalance();

    // Update the epoch parameters. Require that the current epoch number is unchanged.
    uint256 originalCurrentEpoch = getCurrentEpoch();
    _setEpochParameters(interval, offset);
    uint256 newCurrentEpoch = getCurrentEpoch();
    require(
      originalCurrentEpoch == newCurrentEpoch,
      'SM1Admin: Changed epochs'
    );
  }

  /**
   * @notice Set the blackout window, during which one cannot request withdrawals of staked funds.
   */
  function setBlackoutWindow(
    uint256 blackoutWindow
  )
    external
    onlyRole(EPOCH_PARAMETERS_ROLE)
    nonReentrant
  {
    _setBlackoutWindow(blackoutWindow);
  }

  /**
   * @notice Set the emission rate of rewards.
   *
   * @param  emissionPerSecond  The new number of rewards tokens given out per second.
   */
  function setRewardsPerSecond(
    uint256 emissionPerSecond
  )
    external
    onlyRole(REWARDS_RATE_ROLE)
    nonReentrant
  {
    uint256 totalStaked = 0;
    if (hasEpochZeroStarted()) {
      // We must settle the total active balance to ensure the index is recorded at the epoch
      // boundary as needed, before we make any changes to the emission rate.
      totalStaked = _settleTotalActiveBalance();
    }
    _setRewardsPerSecond(emissionPerSecond, totalStaked);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { Math } from '../../../utils/Math.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1Storage } from './SM1Storage.sol';

/**
 * @title SM1Getters
 * @author dYdX
 *
 * @dev Some external getter functions.
 */
abstract contract SM1Getters is
  SM1Storage
{
  using SafeMath for uint256;

  // ============ External Functions ============

  /**
   * @notice The parameters specifying the function from timestamp to epoch number.
   *
   * @return The parameters struct with `interval` and `offset` fields.
   */
  function getEpochParameters()
    external
    view
    returns (SM1Types.EpochParameters memory)
  {
    return _EPOCH_PARAMETERS_;
  }

  /**
   * @notice The period of time at the end of each epoch in which withdrawals cannot be requested.
   *
   * @return The blackout window duration, in seconds.
   */
  function getBlackoutWindow()
    external
    view
    returns (uint256)
  {
    return _BLACKOUT_WINDOW_;
  }

  /**
   * @notice Get the domain separator used for EIP-712 signatures.
   *
   * @return The EIP-712 domain separator.
   */
  function getDomainSeparator()
    external
    view
    returns (bytes32)
  {
    return _DOMAIN_SEPARATOR_;
  }

  /**
   * @notice The value of one underlying token, in the units used for staked balances, denominated
   *  as a mutiple of EXCHANGE_RATE_BASE for additional precision.
   *
   *  To convert from an underlying amount to a staked amount, multiply by the exchange rate.
   *
   * @return The exchange rate.
   */
  function getExchangeRate()
    external
    view
    returns (uint256)
  {
    return _EXCHANGE_RATE_;
  }

  /**
   * @notice Get an exchange rate snapshot.
   *
   * @param  index  The index number of the exchange rate snapshot.
   *
   * @return The snapshot struct with `blockNumber` and `value` fields.
   */
  function getExchangeRateSnapshot(
    uint256 index
  )
    external
    view
    returns (SM1Types.Snapshot memory)
  {
    return _EXCHANGE_RATE_SNAPSHOTS_[index];
  }

  /**
   * @notice Get the number of exchange rate snapshots.
   *
   * @return The number of snapshots that have been taken of the exchange rate.
   */
  function getExchangeRateSnapshotCount()
    external
    view
    returns (uint256)
  {
    return _EXCHANGE_RATE_SNAPSHOT_COUNT_;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { SM1Roles } from './SM1Roles.sol';
import { SM1Staking } from './SM1Staking.sol';

/**
 * @title SM1Operators
 * @author dYdX
 *
 * @dev Actions which may be called by authorized operators, nominated by the contract owner.
 *
 *  There are two types of operators. These should be smart contracts, which can be used to
 *  provide additional functionality to users:
 *
 *  STAKE_OPERATOR_ROLE:
 *
 *    This operator is allowed to request withdrawals and withdraw funds on behalf of stakers. This
 *    role could be used by a smart contract to provide a staking interface with additional
 *    features, for example, optional lock-up periods that pay out additional rewards (from a
 *    separate rewards pool).
 *
 *  CLAIM_OPERATOR_ROLE:
 *
 *    This operator is allowed to claim rewards on behalf of stakers. This role could be used by a
 *    smart contract to provide an interface for claiming rewards from multiple incentive programs
 *    at once.
 */
abstract contract SM1Operators is
  SM1Staking,
  SM1Roles
{
  using SafeMath for uint256;

  // ============ Events ============

  event OperatorStakedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrawalRequestedFor(
    address indexed staker,
    uint256 amount,
    address operator
  );

  event OperatorWithdrewStakeFor(
    address indexed staker,
    address recipient,
    uint256 amount,
    address operator
  );

  event OperatorClaimedRewardsFor(
    address indexed staker,
    address recipient,
    uint256 claimedRewards,
    address operator
  );

  // ============ External Functions ============

  /**
   * @notice Request a withdrawal on behalf of a staker.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  staker       The staker whose stake to request a withdrawal for.
   * @param  stakeAmount  The amount of stake to move from the active to the inactive balance.
   */
  function requestWithdrawalFor(
    address staker,
    uint256 stakeAmount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _requestWithdrawal(staker, stakeAmount);
    emit OperatorWithdrawalRequestedFor(staker, stakeAmount, msg.sender);
  }

  /**
   * @notice Withdraw a staker's stake, and send to the specified recipient.
   *
   * @param  staker       The staker whose stake to withdraw.
   * @param  recipient    The address that should receive the funds.
   * @param  stakeAmount  The amount of stake to withdraw from the staker's inactive balance.
   */
  function withdrawStakeFor(
    address staker,
    address recipient,
    uint256 stakeAmount
  )
    external
    onlyRole(STAKE_OPERATOR_ROLE)
    nonReentrant
  {
    _withdrawStake(staker, recipient, stakeAmount);
    emit OperatorWithdrewStakeFor(staker, recipient, stakeAmount, msg.sender);
  }

  /**
   * @notice Claim rewards on behalf of a staker, and send them to the specified recipient.
   *
   * @param  staker     The staker whose rewards to claim.
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewardsFor(
    address staker,
    address recipient
  )
    external
    onlyRole(CLAIM_OPERATOR_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 rewards = _settleAndClaimRewards(staker, recipient); // Emits an event internally.
    emit OperatorClaimedRewardsFor(staker, recipient, rewards, msg.sender);
    return rewards;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1Roles } from './SM1Roles.sol';
import { SM1Staking } from './SM1Staking.sol';

/**
 * @title SM1Slashing
 * @author dYdX
 *
 * @dev Provides the slashing function for removing funds from the contract.
 *
 *  SLASHING:
 *
 *   All funds in the contract, active or inactive, are slashable. Slashes are recorded by updating
 *   the exchange rate, and to simplify the technical implementation, we disallow full slashes.
 *   To reduce the possibility of overflow in the exchange rate, we place an upper bound on the
 *   fraction of funds that may be slashed in a single slash.
 *
 *   Warning: Slashing is not possible if the slash would cause the exchange rate to overflow.
 *
 *  REWARDS AND GOVERNANCE POWER ACCOUNTING:
 *
 *   Since all slashes are accounted for by a global exchange rate, slashes do not require any
 *   update to staked balances. The earning of rewards is unaffected by slashes.
 *
 *   Governance power takes slashes into account by using snapshots of the exchange rate inside
 *   the getPowerAtBlock() function. Note that getPowerAtBlock() returns the governance power as of
 *   the end of the specified block.
 */
abstract contract SM1Slashing is
  SM1Staking,
  SM1Roles
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The maximum fraction of funds that may be slashed in a single slash (numerator).
  uint256 public constant MAX_SLASH_NUMERATOR = 95;

  /// @notice The maximum fraction of funds that may be slashed in a single slash (denominator).
  uint256 public constant MAX_SLASH_DENOMINATOR = 100;

  // ============ Events ============

  event Slashed(
    uint256 amount,
    address recipient,
    uint256 newExchangeRate
  );

  // ============ External Functions ============

  /**
   * @notice Slash staked token balances and withdraw those funds to the specified address.
   *
   * @param  requestedSlashAmount  The request slash amount, denominated in the underlying token.
   * @param  recipient             The address to receive the slashed tokens.
   *
   * @return The amount slashed, denominated in the underlying token.
   */
  function slash(
    uint256 requestedSlashAmount,
    address recipient
  )
    external
    onlyRole(SLASHER_ROLE)
    nonReentrant
    returns (uint256)
  {
    uint256 underlyingBalance = STAKED_TOKEN.balanceOf(address(this));

    if (underlyingBalance == 0) {
      return 0;
    }

    // Get the slash amount and remaining amount. Note that remainingAfterSlash is nonzero.
    uint256 maxSlashAmount = underlyingBalance.mul(MAX_SLASH_NUMERATOR).div(MAX_SLASH_DENOMINATOR);
    uint256 slashAmount = Math.min(requestedSlashAmount, maxSlashAmount);
    uint256 remainingAfterSlash = underlyingBalance.sub(slashAmount);

    if (slashAmount == 0) {
      return 0;
    }

    // Update the exchange rate.
    //
    // Warning: Can revert if the max exchange rate is exceeded.
    uint256 newExchangeRate = updateExchangeRate(underlyingBalance, remainingAfterSlash);

    // Transfer the slashed token.
    STAKED_TOKEN.safeTransfer(recipient, slashAmount);

    emit Slashed(slashAmount, recipient, newExchangeRate);
    return slashAmount;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1ERC20 } from './SM1ERC20.sol';
import { SM1StakedBalances } from './SM1StakedBalances.sol';

/**
 * @title SM1Staking
 * @author dYdX
 *
 * @dev External functions for stakers. See SM1StakedBalances for details on staker accounting.
 *
 *  UNDERLYING AND STAKED AMOUNTS:
 *
 *   We distinguish between underlying amounts and stake amounts. An underlying amount is denoted
 *   in the original units of the token being staked. A stake amount is adjusted by the exchange
 *   rate, which can increase due to slashing. Before any slashes have occurred, the exchange rate
 *   is equal to one.
 */
abstract contract SM1Staking is
  SM1StakedBalances,
  SM1ERC20
{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Events ============

  event Staked(
    address indexed staker,
    address spender,
    uint256 underlyingAmount,
    uint256 stakeAmount
  );

  event WithdrawalRequested(
    address indexed staker,
    uint256 stakeAmount
  );

  event WithdrewStake(
    address indexed staker,
    address recipient,
    uint256 underlyingAmount,
    uint256 stakeAmount
  );

  // ============ Constants ============

  IERC20 public immutable STAKED_TOKEN;

  // ============ Constructor ============

  constructor(
    IERC20 stakedToken,
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    SM1StakedBalances(rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {
    STAKED_TOKEN = stakedToken;
  }

  // ============ External Functions ============

  /**
   * @notice Deposit and stake funds. These funds are active and start earning rewards immediately.
   *
   * @param  underlyingAmount  The amount of underlying token to stake.
   */
  function stake(
    uint256 underlyingAmount
  )
    external
    nonReentrant
  {
    _stake(msg.sender, underlyingAmount);
  }

  /**
   * @notice Deposit and stake on behalf of another address.
   *
   * @param  staker            The staker who will receive the stake.
   * @param  underlyingAmount  The amount of underlying token to stake.
   */
  function stakeFor(
    address staker,
    uint256 underlyingAmount
  )
    external
    nonReentrant
  {
    _stake(staker, underlyingAmount);
  }

  /**
   * @notice Request to withdraw funds. Starting in the next epoch, the funds will be “inactive”
   *  and available for withdrawal. Inactive funds do not earn rewards.
   *
   *  Reverts if we are currently in the blackout window.
   *
   * @param  stakeAmount  The amount of stake to move from the active to the inactive balance.
   */
  function requestWithdrawal(
    uint256 stakeAmount
  )
    external
    nonReentrant
  {
    _requestWithdrawal(msg.sender, stakeAmount);
  }

  /**
   * @notice Withdraw the sender's inactive funds, and send to the specified recipient.
   *
   * @param  recipient    The address that should receive the funds.
   * @param  stakeAmount  The amount of stake to withdraw from the sender's inactive balance.
   */
  function withdrawStake(
    address recipient,
    uint256 stakeAmount
  )
    external
    nonReentrant
  {
    _withdrawStake(msg.sender, recipient, stakeAmount);
  }

  /**
   * @notice Withdraw the max available inactive funds, and send to the specified recipient.
   *
   *  This is less gas-efficient than querying the max via eth_call and calling withdrawStake().
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The withdrawn amount.
   */
  function withdrawMaxStake(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    uint256 stakeAmount = getStakeAvailableToWithdraw(msg.sender);
    _withdrawStake(msg.sender, recipient, stakeAmount);
    return stakeAmount;
  }

  /**
   * @notice Settle and claim all rewards, and send them to the specified recipient.
   *
   *  Call this function with eth_call to query the claimable rewards balance.
   *
   * @param  recipient  The address that should receive the funds.
   *
   * @return The number of rewards tokens claimed.
   */
  function claimRewards(
    address recipient
  )
    external
    nonReentrant
    returns (uint256)
  {
    return _settleAndClaimRewards(msg.sender, recipient); // Emits an event internally.
  }

  // ============ Public Functions ============

  /**
   * @notice Get the amount of stake available for a given staker to withdraw.
   *
   * @param  staker  The address whose balance to check.
   *
   * @return The staker's stake amount that is inactive and available to withdraw.
   */
  function getStakeAvailableToWithdraw(
    address staker
  )
    public
    view
    returns (uint256)
  {
    // Note that the next epoch inactive balance is always at least that of the current epoch.
    return getInactiveBalanceCurrentEpoch(staker);
  }

  // ============ Internal Functions ============

  function _stake(
    address staker,
    uint256 underlyingAmount
  )
    internal
  {
    // Convert using the exchange rate.
    uint256 stakeAmount = stakeAmountFromUnderlyingAmount(underlyingAmount);

    // Update staked balances and delegate snapshots.
    _increaseCurrentAndNextActiveBalance(staker, stakeAmount);
    _moveDelegatesForTransfer(address(0), staker, stakeAmount);

    // Transfer token from the sender.
    STAKED_TOKEN.safeTransferFrom(msg.sender, address(this), underlyingAmount);

    emit Staked(staker, msg.sender, underlyingAmount, stakeAmount);
    emit Transfer(address(0), msg.sender, stakeAmount);
  }

  function _requestWithdrawal(
    address staker,
    uint256 stakeAmount
  )
    internal
  {
    require(
      !inBlackoutWindow(),
      'SM1Staking: Withdraw requests restricted in the blackout window'
    );

    // Get the staker's requestable amount and revert if there is not enough to request withdrawal.
    uint256 requestableBalance = getActiveBalanceNextEpoch(staker);
    require(
      stakeAmount <= requestableBalance,
      'SM1Staking: Withdraw request exceeds next active balance'
    );

    // Move amount from active to inactive in the next epoch.
    _moveNextBalanceActiveToInactive(staker, stakeAmount);

    emit WithdrawalRequested(staker, stakeAmount);
  }

  function _withdrawStake(
    address staker,
    address recipient,
    uint256 stakeAmount
  )
    internal
  {
    // Get staker withdrawable balance and revert if there is not enough to withdraw.
    uint256 withdrawableBalance = getInactiveBalanceCurrentEpoch(staker);
    require(
      stakeAmount <= withdrawableBalance,
      'SM1Staking: Withdraw amount exceeds staker inactive balance'
    );

    // Update staked balances and delegate snapshots.
    _decreaseCurrentAndNextInactiveBalance(staker, stakeAmount);
    _moveDelegatesForTransfer(staker, address(0), stakeAmount);

    // Convert using the exchange rate.
    uint256 underlyingAmount = underlyingAmountFromStakeAmount(stakeAmount);

    // Transfer token to the recipient.
    STAKED_TOKEN.safeTransfer(recipient, underlyingAmount);

    emit Transfer(msg.sender, address(0), stakeAmount);
    emit WithdrewStake(staker, recipient, underlyingAmount, stakeAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

library SM1Types {
  /**
   * @dev The parameters used to convert a timestamp to an epoch number.
   */
  struct EpochParameters {
    uint128 interval;
    uint128 offset;
  }

  /**
   * @dev Snapshot of a value at a specific block, used to track historical governance power.
   */
  struct Snapshot {
    uint256 blockNumber;
    uint256 value;
  }

  /**
   * @dev A balance, possibly with a change scheduled for the next epoch.
   *
   * @param  currentEpoch         The epoch in which the balance was last updated.
   * @param  currentEpochBalance  The balance at epoch `currentEpoch`.
   * @param  nextEpochBalance     The balance at epoch `currentEpoch + 1`.
   */
  struct StoredBalance {
    uint16 currentEpoch;
    uint240 currentEpochBalance;
    uint240 nextEpochBalance;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SM1Storage } from './SM1Storage.sol';

/**
 * @title SM1Roles
 * @author dYdX
 *
 * @dev Defines roles used in the SafetyModuleV1 contract. The hierarchy of roles and powers
 *  of each role are described below.
 *
 *  Roles:
 *
 *    OWNER_ROLE
 *      | -> May add or remove addresses from any of the roles below.
 *      |
 *      +-- SLASHER_ROLE
 *      |     -> Can slash staked token balances and withdraw those funds.
 *      |
 *      +-- EPOCH_PARAMETERS_ROLE
 *      |     -> May set epoch parameters such as the interval, offset, and blackout window.
 *      |
 *      +-- REWARDS_RATE_ROLE
 *      |     -> May set the emission rate of rewards.
 *      |
 *      +-- CLAIM_OPERATOR_ROLE
 *      |     -> May claim rewards on behalf of a user.
 *      |
 *      +-- STAKE_OPERATOR_ROLE
 *            -> May manipulate user's staked funds (e.g. perform withdrawals on behalf of a user).
 */
abstract contract SM1Roles is SM1Storage {
  bytes32 public constant OWNER_ROLE = keccak256('OWNER_ROLE');
  bytes32 public constant SLASHER_ROLE = keccak256('SLASHER_ROLE');
  bytes32 public constant EPOCH_PARAMETERS_ROLE = keccak256('EPOCH_PARAMETERS_ROLE');
  bytes32 public constant REWARDS_RATE_ROLE = keccak256('REWARDS_RATE_ROLE');
  bytes32 public constant CLAIM_OPERATOR_ROLE = keccak256('CLAIM_OPERATOR_ROLE');
  bytes32 public constant STAKE_OPERATOR_ROLE = keccak256('STAKE_OPERATOR_ROLE');

  function __SM1Roles_init() internal {
    // Assign roles to the sender.
    //
    // The STAKE_OPERATOR_ROLE and CLAIM_OPERATOR_ROLE roles are not initially assigned.
    // These can be assigned to other smart contracts to provide additional functionality for users.
    _setupRole(OWNER_ROLE, msg.sender);
    _setupRole(SLASHER_ROLE, msg.sender);
    _setupRole(EPOCH_PARAMETERS_ROLE, msg.sender);
    _setupRole(REWARDS_RATE_ROLE, msg.sender);

    // Set OWNER_ROLE as the admin of all roles.
    _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
    _setRoleAdmin(SLASHER_ROLE, OWNER_ROLE);
    _setRoleAdmin(EPOCH_PARAMETERS_ROLE, OWNER_ROLE);
    _setRoleAdmin(REWARDS_RATE_ROLE, OWNER_ROLE);
    _setRoleAdmin(CLAIM_OPERATOR_ROLE, OWNER_ROLE);
    _setRoleAdmin(STAKE_OPERATOR_ROLE, OWNER_ROLE);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1Rewards } from './SM1Rewards.sol';

/**
 * @title SM1StakedBalances
 * @author dYdX
 *
 * @dev Accounting of staked balances.
 *
 *  NOTE: Functions may revert if epoch zero has not started.
 *
 *  NOTE: All amounts dealt with in this file are denominated in staked units, which because of the
 *   exchange rate, may not correspond one-to-one with the underlying token. See SM1Staking.sol.
 *
 *  STAKED BALANCE ACCOUNTING:
 *
 *   A staked balance is in one of two states:
 *     - active: Earning staking rewards; cannot be withdrawn by staker; may be slashed.
 *     - inactive: Not earning rewards; can be withdrawn by the staker; may be slashed.
 *
 *   A staker may have a combination of active and inactive balances. The following operations
 *   affect staked balances as follows:
 *     - deposit:            Increase active balance.
 *     - request withdrawal: At the end of the current epoch, move some active funds to inactive.
 *     - withdraw:           Decrease inactive balance.
 *     - transfer:           Move some active funds to another staker.
 *
 *   To encode the fact that a balance may be scheduled to change at the end of a certain epoch, we
 *   store each balance as a struct of three fields: currentEpoch, currentEpochBalance, and
 *   nextEpochBalance.
 *
 *  REWARDS ACCOUNTING:
 *
 *   Active funds earn rewards for the period of time that they remain active. This means, after
 *   requesting a withdrawal of some funds, those funds will continue to earn rewards until the end
 *   of the epoch. For example:
 *
 *     epoch: n        n + 1      n + 2      n + 3
 *            |          |          |          |
 *            +----------+----------+----------+-----...
 *               ^ t_0: User makes a deposit.
 *                          ^ t_1: User requests a withdrawal of all funds.
 *                                  ^ t_2: The funds change state from active to inactive.
 *
 *   In the above scenario, the user would earn rewards for the period from t_0 to t_2, varying
 *   with the total staked balance in that period. If the user only request a withdrawal for a part
 *   of their balance, then the remaining balance would continue earning rewards beyond t_2.
 *
 *   User rewards must be settled via SM1Rewards any time a user's active balance changes. Special
 *   attention is paid to the the epoch boundaries, where funds may have transitioned from active
 *   to inactive.
 *
 *  SETTLEMENT DETAILS:
 *
 *   Internally, this module uses the following types of operations on stored balances:
 *     - Load:            Loads a balance, while applying settlement logic internally to get the
 *                        up-to-date result. Returns settlement results without updating state.
 *     - Store:           Stores a balance.
 *     - Load-for-update: Performs a load and applies updates as needed to rewards accounting.
 *                        Since this is state-changing, it must be followed by a store operation.
 *     - Settle:          Performs load-for-update and store operations.
 *
 *   This module is responsible for maintaining the following invariants to ensure rewards are
 *   calculated correctly:
 *     - When an active balance is loaded for update, if a rollover occurs from one epoch to the
 *       next, the rewards index must be settled up to the boundary at which the rollover occurs.
 *     - Because the global rewards index is needed to update the user rewards index, the total
 *       active balance must be settled before any staker balances are settled or loaded for update.
 *     - A staker's balance must be settled before their rewards are settled.
 */
abstract contract SM1StakedBalances is
  SM1Rewards
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Constructor ============

  constructor(
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  )
    SM1Rewards(rewardsToken, rewardsTreasury, distributionStart, distributionEnd)
  {}

  // ============ Public Functions ============

  /**
   * @notice Get the current active balance of a staker.
   */
  function getActiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (SM1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(
      _ACTIVE_BALANCES_[staker]
    );
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch active balance of a staker.
   */
  function getActiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (SM1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(
      _ACTIVE_BALANCES_[staker]
    );
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total active balance.
   */
  function getTotalActiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (SM1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(
      _TOTAL_ACTIVE_BALANCE_
    );
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total active balance.
   */
  function getTotalActiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    (SM1Types.StoredBalance memory balance, , , ) = _loadActiveBalance(
      _TOTAL_ACTIVE_BALANCE_
    );
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceCurrentEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    SM1Types.StoredBalance memory balance = _loadInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch inactive balance of a staker.
   * @dev The balance is converted via the index to token units.
   */
  function getInactiveBalanceNextEpoch(
    address staker
  )
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    SM1Types.StoredBalance memory balance = _loadInactiveBalance(_INACTIVE_BALANCES_[staker]);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current total inactive balance.
   */
  function getTotalInactiveBalanceCurrentEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    SM1Types.StoredBalance memory balance = _loadInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.currentEpochBalance);
  }

  /**
   * @notice Get the next epoch total inactive balance.
   */
  function getTotalInactiveBalanceNextEpoch()
    public
    view
    returns (uint256)
  {
    if (!hasEpochZeroStarted()) {
      return 0;
    }
    SM1Types.StoredBalance memory balance = _loadInactiveBalance(_TOTAL_INACTIVE_BALANCE_);
    return uint256(balance.nextEpochBalance);
  }

  /**
   * @notice Get the current transferable balance for a user. The user can
   *  only transfer their balance that is not currently inactive or going to be
   *  inactive in the next epoch. Note that this means the user's transferable funds
   *  are their active balance of the next epoch.
   *
   * @param  account  The account to get the transferable balance of.
   *
   * @return The user's transferable balance.
   */
  function getTransferableBalance(
    address account
  )
    public
    view
    returns (uint256)
  {
    return getActiveBalanceNextEpoch(account);
  }

  // ============ Internal Functions ============

  function _increaseCurrentAndNextActiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 oldTotalBalance = _increaseCurrentAndNextBalances(address(0), true, amount);
    uint256 oldUserBalance = _increaseCurrentAndNextBalances(staker, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(staker, oldUserBalance, oldTotalBalance);
  }

  function _moveNextBalanceActiveToInactive(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the active balance for the next epoch.
    // Always settle total active balance before settling a staker active balance.
    _decreaseNextBalance(address(0), true, amount);
    _decreaseNextBalance(staker, true, amount);

    // Increase the inactive balance for the next epoch.
    _increaseNextBalance(address(0), false, amount);
    _increaseNextBalance(staker, false, amount);

    // Note that we don't need to settle rewards since the current active balance did not change.
  }

  function _transferCurrentAndNextActiveBalance(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Move current and next active balances from sender to recipient.
    uint256 oldSenderBalance = _decreaseCurrentAndNextBalances(sender, true, amount);
    uint256 oldRecipientBalance = _increaseCurrentAndNextBalances(recipient, true, amount);

    // When an active balance changes at current timestamp, settle rewards to the current timestamp.
    _settleUserRewardsUpToNow(sender, oldSenderBalance, totalBalance);
    _settleUserRewardsUpToNow(recipient, oldRecipientBalance, totalBalance);
  }

  function _decreaseCurrentAndNextInactiveBalance(
    address staker,
    uint256 amount
  )
    internal
  {
    // Decrease the inactive balance for the next epoch.
    _decreaseCurrentAndNextBalances(address(0), false, amount);
    _decreaseCurrentAndNextBalances(staker, false, amount);

    // Note that we don't settle rewards since active balances are not affected.
  }

  function _settleTotalActiveBalance()
    internal
    returns (uint256)
  {
    return _settleBalance(address(0), true);
  }

  function _settleAndClaimRewards(
    address staker,
    address recipient
  )
    internal
    returns (uint256)
  {
    // Always settle total active balance before settling a staker active balance.
    uint256 totalBalance = _settleTotalActiveBalance();

    // Always settle staker active balance before settling staker rewards.
    uint256 userBalance = _settleBalance(staker, true);

    // Settle rewards balance since we want to claim the full accrued amount.
    _settleUserRewardsUpToNow(staker, userBalance, totalBalance);

    // Claim rewards balance.
    return _claimRewards(staker, recipient);
  }

  // ============ Private Functions ============

  /**
   * @dev Load a balance for update and then store it.
   */
  function _settleBalance(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (uint256)
  {
    SM1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    SM1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 currentBalance = uint256(balance.currentEpochBalance);

    _storeBalance(balancePtr, balance);
    return currentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    SM1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    SM1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.add(amount).toUint240();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint240();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseCurrentAndNextBalances(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
    returns (uint256)
  {
    SM1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    SM1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    uint256 originalCurrentBalance = uint256(balance.currentEpochBalance);
    balance.currentEpochBalance = originalCurrentBalance.sub(amount).toUint240();
    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint240();

    _storeBalance(balancePtr, balance);
    return originalCurrentBalance;
  }

  /**
   * @dev Settle a balance while applying an increase.
   */
  function _increaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    SM1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    SM1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).add(amount).toUint240();

    _storeBalance(balancePtr, balance);
  }

  /**
   * @dev Settle a balance while applying a decrease.
   */
  function _decreaseNextBalance(
    address maybeStaker,
    bool isActiveBalance,
    uint256 amount
  )
    private
  {
    SM1Types.StoredBalance storage balancePtr = _getBalancePtr(maybeStaker, isActiveBalance);
    SM1Types.StoredBalance memory balance =
      _loadBalanceForUpdate(balancePtr, maybeStaker, isActiveBalance);

    balance.nextEpochBalance = uint256(balance.nextEpochBalance).sub(amount).toUint240();

    _storeBalance(balancePtr, balance);
  }

  function _getBalancePtr(
    address maybeStaker,
    bool isActiveBalance
  )
    private
    view
    returns (SM1Types.StoredBalance storage)
  {
    // Active.
    if (isActiveBalance) {
      if (maybeStaker != address(0)) {
        return _ACTIVE_BALANCES_[maybeStaker];
      }
      return _TOTAL_ACTIVE_BALANCE_;
    }

    // Inactive.
    if (maybeStaker != address(0)) {
      return _INACTIVE_BALANCES_[maybeStaker];
    }
    return _TOTAL_INACTIVE_BALANCE_;
  }

  /**
   * @dev Load a balance for updating.
   *
   *  IMPORTANT: This function may modify state, and so the balance MUST be stored afterwards.
   *    - For active balances:
   *      - If a rollover occurs, rewards are settled up to the epoch boundary.
   *
   * @param  balancePtr       A storage pointer to the balance.
   * @param  maybeStaker      The user address, or address(0) to update total balance.
   * @param  isActiveBalance  Whether the balance is an active balance.
   */
  function _loadBalanceForUpdate(
    SM1Types.StoredBalance storage balancePtr,
    address maybeStaker,
    bool isActiveBalance
  )
    private
    returns (SM1Types.StoredBalance memory)
  {
    // Active balance.
    if (isActiveBalance) {
      (
        SM1Types.StoredBalance memory balance,
        uint256 beforeRolloverEpoch,
        uint256 beforeRolloverBalance,
        bool didRolloverOccur
      ) = _loadActiveBalance(balancePtr);
      if (didRolloverOccur) {
        // Handle the effect of the balance rollover on rewards. We must partially settle the index
        // up to the epoch boundary where the change in balance occurred. We pass in the balance
        // from before the boundary.
        if (maybeStaker == address(0)) {
          // If it's the total active balance...
          _settleGlobalIndexUpToEpoch(beforeRolloverBalance, beforeRolloverEpoch);
        } else {
          // If it's a user active balance...
          _settleUserRewardsUpToEpoch(maybeStaker, beforeRolloverBalance, beforeRolloverEpoch);
        }
      }
      return balance;
    }

    // Inactive balance.
    return _loadInactiveBalance(balancePtr);
  }

  function _loadActiveBalance(
    SM1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (
      SM1Types.StoredBalance memory,
      uint256,
      uint256,
      bool
    )
  {
    SM1Types.StoredBalance memory balance = balancePtr;

    // Return these as they may be needed for rewards settlement.
    uint256 beforeRolloverEpoch = uint256(balance.currentEpoch);
    uint256 beforeRolloverBalance = uint256(balance.currentEpochBalance);
    bool didRolloverOccur = false;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      didRolloverOccur = balance.currentEpochBalance != balance.nextEpochBalance;

      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return (balance, beforeRolloverEpoch, beforeRolloverBalance, didRolloverOccur);
  }

  function _loadInactiveBalance(
    SM1Types.StoredBalance storage balancePtr
  )
    private
    view
    returns (SM1Types.StoredBalance memory)
  {
    SM1Types.StoredBalance memory balance = balancePtr;

    // Roll the balance forward if needed.
    uint256 currentEpoch = getCurrentEpoch();
    if (currentEpoch > uint256(balance.currentEpoch)) {
      balance.currentEpoch = currentEpoch.toUint16();
      balance.currentEpochBalance = balance.nextEpochBalance;
    }

    return balance;
  }

  /**
   * @dev Store a balance.
   */
  function _storeBalance(
    SM1Types.StoredBalance storage balancePtr,
    SM1Types.StoredBalance memory balance
  )
    private
  {
    // Note: This should use a single `sstore` when compiler optimizations are enabled.
    balancePtr.currentEpoch = balance.currentEpoch;
    balancePtr.currentEpochBalance = balance.currentEpochBalance;
    balancePtr.nextEpochBalance = balance.nextEpochBalance;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import {
  AccessControlUpgradeable
} from '../../../dependencies/open-zeppelin/AccessControlUpgradeable.sol';
import { ReentrancyGuard } from '../../../utils/ReentrancyGuard.sol';
import { VersionedInitializable } from '../../../utils/VersionedInitializable.sol';
import { SM1Types } from '../lib/SM1Types.sol';

/**
 * @title SM1Storage
 * @author dYdX
 *
 * @dev Storage contract. Contains or inherits from all contract with storage.
 */
abstract contract SM1Storage is
  AccessControlUpgradeable,
  ReentrancyGuard,
  VersionedInitializable
{
  // ============ Epoch Schedule ============

  /// @dev The parameters specifying the function from timestamp to epoch number.
  SM1Types.EpochParameters internal _EPOCH_PARAMETERS_;

  /// @dev The period of time at the end of each epoch in which withdrawals cannot be requested.
  uint256 internal _BLACKOUT_WINDOW_;

  // ============ Staked Token ERC20 ============

  /// @dev Allowances for ERC-20 transfers.
  mapping(address => mapping(address => uint256)) internal _ALLOWANCES_;

  // ============ Governance Power Delegation ============

  /// @dev Domain separator for EIP-712 signatures.
  bytes32 internal _DOMAIN_SEPARATOR_;

  /// @dev Mapping from (owner) => (next valid nonce) for EIP-712 signatures.
  mapping(address => uint256) internal _NONCES_;

  /// @dev Snapshots and delegates for governance voting power.
  mapping(address => mapping(uint256 => SM1Types.Snapshot)) internal _VOTING_SNAPSHOTS_;
  mapping(address => uint256) internal _VOTING_SNAPSHOT_COUNTS_;
  mapping(address => address) internal _VOTING_DELEGATES_;

  /// @dev Snapshots and delegates for governance proposition power.
  mapping(address => mapping(uint256 => SM1Types.Snapshot)) internal _PROPOSITION_SNAPSHOTS_;
  mapping(address => uint256) internal _PROPOSITION_SNAPSHOT_COUNTS_;
  mapping(address => address) internal _PROPOSITION_DELEGATES_;

  // ============ Rewards Accounting ============

  /// @dev The emission rate of rewards.
  uint256 internal _REWARDS_PER_SECOND_;

  /// @dev The cumulative rewards earned per staked token. (Shared storage slot.)
  uint224 internal _GLOBAL_INDEX_;

  /// @dev The timestamp at which the global index was last updated. (Shared storage slot.)
  uint32 internal _GLOBAL_INDEX_TIMESTAMP_;

  /// @dev The value of the global index when the user's staked balance was last updated.
  mapping(address => uint256) internal _USER_INDEXES_;

  /// @dev The user's accrued, unclaimed rewards (as of the last update to the user index).
  mapping(address => uint256) internal _USER_REWARDS_BALANCES_;

  /// @dev The value of the global index at the end of a given epoch.
  mapping(uint256 => uint256) internal _EPOCH_INDEXES_;

  // ============ Staker Accounting ============

  /// @dev The active balance by staker.
  mapping(address => SM1Types.StoredBalance) internal _ACTIVE_BALANCES_;

  /// @dev The total active balance of stakers.
  SM1Types.StoredBalance internal _TOTAL_ACTIVE_BALANCE_;

  /// @dev The inactive balance by staker.
  mapping(address => SM1Types.StoredBalance) internal _INACTIVE_BALANCES_;

  /// @dev The total inactive balance of stakers.
  SM1Types.StoredBalance internal _TOTAL_INACTIVE_BALANCE_;

  // ============ Exchange Rate ============

  /// @dev The value of one underlying token, in the units used for staked balances, denominated
  ///  as a mutiple of EXCHANGE_RATE_BASE for additional precision.
  uint256 internal _EXCHANGE_RATE_;

  /// @dev Historical snapshots of the exchange rate, in each block that it has changed.
  mapping(uint256 => SM1Types.Snapshot) internal _EXCHANGE_RATE_SNAPSHOTS_;

  /// @dev Number of snapshots of the exchange rate.
  uint256 internal _EXCHANGE_RATE_SNAPSHOT_COUNT_;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './Context.sol';
import './Strings.sol';
import './ERC165.sol';

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
abstract contract AccessControlUpgradeable is Context, IAccessControlUpgradeable, ERC165 {
  struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
  }

  mapping(bytes32 => RoleData) private _roles;

  bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

  /**
   * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
   *
   * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
   * {RoleAdminChanged} not being emitted signaling this.
   *
   * _Available since v3.1._
   */
  event RoleAdminChanged(
    bytes32 indexed role,
    bytes32 indexed previousAdminRole,
    bytes32 indexed newAdminRole
  );

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
    return
      interfaceId == type(IAccessControlUpgradeable).interfaceId ||
      super.supportsInterface(interfaceId);
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
    if (!hasRole(role, account)) {
      revert(
        string(
          abi.encodePacked(
            'AccessControl: account ',
            Strings.toHexString(uint160(account), 20),
            ' is missing role ',
            Strings.toHexString(uint256(role), 32)
          )
        )
      );
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
  function grantRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
  function revokeRole(bytes32 role, address account)
    public
    virtual
    override
    onlyRole(getRoleAdmin(role))
  {
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
    require(account == _msgSender(), 'AccessControl: can only renounce roles for self');

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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @title ReentrancyGuard
 * @author dYdX
 *
 * @dev Updated ReentrancyGuard library designed to be used with Proxy Contracts.
 */
abstract contract ReentrancyGuard {
  uint256 private constant NOT_ENTERED = 1;
  uint256 private constant ENTERED = uint256(int256(-1));

  uint256 private _STATUS_;

  constructor()
    internal
  {
    _STATUS_ = NOT_ENTERED;
  }

  modifier nonReentrant() {
    require(_STATUS_ != ENTERED, 'ReentrancyGuard: reentrant call');
    _STATUS_ = ENTERED;
    _;
    _STATUS_ = NOT_ENTERED;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

/**
 * @title VersionedInitializable
 * @author Aave, inspired by the OpenZeppelin Initializable contract
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 *
 */
abstract contract VersionedInitializable {
    /**
   * @dev Indicates that the contract has been initialized.
   */
    uint256 internal lastInitializedRevision = 0;

   /**
   * @dev Modifier to use in the initializer function of a contract.
   */
    modifier initializer() {
        uint256 revision = getRevision();
        require(revision > lastInitializedRevision, "Contract instance has already been initialized");

        lastInitializedRevision = revision;

        _;

    }

    /// @dev returns the revision number of the contract.
    /// Needs to be defined in the inherited class as a constant.
    function getRevision() internal pure virtual returns(uint256);


    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

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
pragma solidity 0.7.5;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant alphabet = '0123456789abcdef';

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
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
      return '0x00';
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
    buffer[0] = '0';
    buffer[1] = 'x';
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = alphabet[value & 0xf];
      value >>= 4;
    }
    require(value == 0, 'Strings: hex length insufficient');
    return string(buffer);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

import './IERC165.sol';

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
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(IERC165).interfaceId;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

/**
 * @dev Methods for downcasting unsigned integers, reverting on overflow.
 */
library SafeCast {

  /**
   * @dev Downcast to a uint16, reverting on overflow.
   */
  function toUint16(
    uint256 a
  )
    internal
    pure
    returns (uint16)
  {
    uint16 b = uint16(a);
    require(
      uint256(b) == a,
      'SafeCast: toUint16 overflow'
    );
    return b;
  }

  /**
   * @dev Downcast to a uint32, reverting on overflow.
   */
  function toUint32(
    uint256 a
  )
    internal
    pure
    returns (uint32)
  {
    uint32 b = uint32(a);
    require(
      uint256(b) == a,
      'SafeCast: toUint32 overflow'
    );
    return b;
  }

  /**
   * @dev Downcast to a uint128, reverting on overflow.
   */
  function toUint128(
    uint256 a
  )
    internal
    pure
    returns (uint128)
  {
    uint128 b = uint128(a);
    require(
      uint256(b) == a,
      'SafeCast: toUint128 overflow'
    );
    return b;
  }

  /**
   * @dev Downcast to a uint224, reverting on overflow.
   */
  function toUint224(
    uint256 a
  )
    internal
    pure
    returns (uint224)
  {
    uint224 b = uint224(a);
    require(
      uint256(b) == a,
      'SafeCast: toUint224 overflow'
    );
    return b;
  }

  /**
   * @dev Downcast to a uint240, reverting on overflow.
   */
  function toUint240(
    uint256 a
  )
    internal
    pure
    returns (uint240)
  {
    uint240 b = uint240(a);
    require(
      uint256(b) == a,
      'SafeCast: toUint240 overflow'
    );
    return b;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeERC20 } from '../../../dependencies/open-zeppelin/SafeERC20.sol';
import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { Math } from '../../../utils/Math.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { SM1EpochSchedule } from './SM1EpochSchedule.sol';

/**
 * @title SM1Rewards
 * @author dYdX
 *
 * @dev Manages the distribution of token rewards.
 *
 *  Rewards are distributed continuously. After each second, an account earns rewards `r` according
 *  to the following formula:
 *
 *      r = R * s / S
 *
 *  Where:
 *    - `R` is the rewards distributed globally each second, also called the “emission rate.”
 *    - `s` is the account's staked balance in that second (technically, it is measured at the
 *      end of the second)
 *    - `S` is the sum total of all staked balances in that second (again, measured at the end of
 *      the second)
 *
 *  The parameter `R` can be configured by the contract owner. For every second that elapses,
 *  exactly `R` tokens will accrue to users, save for rounding errors, and with the exception that
 *  while the total staked balance is zero, no tokens will accrue to anyone.
 *
 *  The accounting works as follows: A global index is stored which represents the cumulative
 *  number of rewards tokens earned per staked token since the start of the distribution.
 *  The value of this index increases over time, and there are two factors affecting the rate of
 *  increase:
 *    1) The emission rate (in the numerator)
 *    2) The total number of staked tokens (in the denominator)
 *
 *  Whenever either factor changes, in some timestamp T, we settle the global index up to T by
 *  calculating the increase in the index since the last update using the OLD values of the factors:
 *
 *    indexDelta = timeDelta * emissionPerSecond * INDEX_BASE / totalStaked
 *
 *  Where `INDEX_BASE` is a scaling factor used to allow more precision in the storage of the index.
 *
 *  For each user we store an accrued rewards balance, as well as a user index, which is a cache of
 *  the global index at the time that the user's accrued rewards balance was last updated. Then at
 *  any point in time, a user's claimable rewards are represented by the following:
 *
 *    rewards = _USER_REWARDS_BALANCES_[user] + userStaked * (
 *                settledGlobalIndex - _USER_INDEXES_[user]
 *              ) / INDEX_BASE
 */
abstract contract SM1Rewards is
  SM1EpochSchedule
{
  using SafeCast for uint256;
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  // ============ Constants ============

  /// @dev Additional precision used to represent the global and user index values.
  uint256 private constant INDEX_BASE = 10**18;

  /// @notice The rewards token.
  IERC20 public immutable REWARDS_TOKEN;

  /// @notice Address to pull rewards from. Must have provided an allowance to this contract.
  address public immutable REWARDS_TREASURY;

  /// @notice Start timestamp (inclusive) of the period in which rewards can be earned.
  uint256 public immutable DISTRIBUTION_START;

  /// @notice End timestamp (exclusive) of the period in which rewards can be earned.
  uint256 public immutable DISTRIBUTION_END;

  // ============ Events ============

  event RewardsPerSecondUpdated(
    uint256 emissionPerSecond
  );

  event GlobalIndexUpdated(
    uint256 index
  );

  event UserIndexUpdated(
    address indexed user,
    uint256 index,
    uint256 unclaimedRewards
  );

  event ClaimedRewards(
    address indexed user,
    address recipient,
    uint256 claimedRewards
  );

  // ============ Constructor ============

  constructor(
    IERC20 rewardsToken,
    address rewardsTreasury,
    uint256 distributionStart,
    uint256 distributionEnd
  ) {
    require(
      distributionEnd >= distributionStart,
      'SM1Rewards: Invalid parameters'
    );
    REWARDS_TOKEN = rewardsToken;
    REWARDS_TREASURY = rewardsTreasury;
    DISTRIBUTION_START = distributionStart;
    DISTRIBUTION_END = distributionEnd;
  }

  // ============ External Functions ============

  /**
   * @notice The current emission rate of rewards.
   *
   * @return The number of rewards tokens issued globally each second.
   */
  function getRewardsPerSecond()
    external
    view
    returns (uint256)
  {
    return _REWARDS_PER_SECOND_;
  }

  // ============ Internal Functions ============

  /**
   * @dev Initialize the contract.
   */
  function __SM1Rewards_init()
    internal
  {
    _GLOBAL_INDEX_TIMESTAMP_ = Math.max(block.timestamp, DISTRIBUTION_START).toUint32();
  }

  /**
   * @dev Set the emission rate of rewards.
   *
   *  IMPORTANT: Do not call this function without settling the total staked balance first, to
   *  ensure that the index is settled up to the epoch boundaries.
   *
   * @param  emissionPerSecond  The new number of rewards tokens to give out each second.
   * @param  totalStaked        The total staked balance.
   */
  function _setRewardsPerSecond(
    uint256 emissionPerSecond,
    uint256 totalStaked
  )
    internal
  {
    _settleGlobalIndexUpToNow(totalStaked);
    _REWARDS_PER_SECOND_ = emissionPerSecond;
    emit RewardsPerSecondUpdated(emissionPerSecond);
  }

  /**
   * @dev Claim tokens, sending them to the specified recipient.
   *
   *  Note: In order to claim all accrued rewards, the total and user staked balances must first be
   *  settled before calling this function.
   *
   * @param  user       The user's address.
   * @param  recipient  The address to send rewards to.
   *
   * @return The number of rewards tokens claimed.
   */
  function _claimRewards(
    address user,
    address recipient
  )
    internal
    returns (uint256)
  {
    uint256 accruedRewards = _USER_REWARDS_BALANCES_[user];
    _USER_REWARDS_BALANCES_[user] = 0;
    REWARDS_TOKEN.safeTransferFrom(REWARDS_TREASURY, recipient, accruedRewards);
    emit ClaimedRewards(user, recipient, accruedRewards);
    return accruedRewards;
  }

  /**
   * @dev Settle a user's rewards up to the latest global index as of `block.timestamp`. Triggers a
   *  settlement of the global index up to `block.timestamp`. Should be called with the OLD user
   *  and total balances.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user during the period since the last user index
   *                      update.
   * @param  totalStaked  Total tokens staked by all users during the period since the last global
   *                      index update.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToNow(
    address user,
    uint256 userStaked,
    uint256 totalStaked
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _settleGlobalIndexUpToNow(totalStaked);
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle a user's rewards up to an epoch boundary. Should be used to partially settle a
   *  user's rewards if their balance was known to have changed on that epoch boundary.
   *
   * @param  user         The user's address.
   * @param  userStaked   Tokens staked by the user. Should be accurate for the time period
   *                      since the last update to this user and up to the end of the
   *                      specified epoch.
   * @param  epochNumber  Settle the user's rewards up to the end of this epoch.
   *
   * @return The user's accrued rewards, including past unclaimed rewards, up to the end of the
   *  specified epoch.
   */
  function _settleUserRewardsUpToEpoch(
    address user,
    uint256 userStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 globalIndex = _EPOCH_INDEXES_[epochNumber];
    return _settleUserRewardsUpToIndex(user, userStaked, globalIndex);
  }

  /**
   * @dev Settle the global index up to the end of the given epoch.
   *
   *  IMPORTANT: This function should only be called under conditions which ensure the following:
   *    - `epochNumber` < the current epoch number
   *    - `_GLOBAL_INDEX_TIMESTAMP_ < settleUpToTimestamp`
   *    - `_EPOCH_INDEXES_[epochNumber] = 0`
   */
  function _settleGlobalIndexUpToEpoch(
    uint256 totalStaked,
    uint256 epochNumber
  )
    internal
    returns (uint256)
  {
    uint256 settleUpToTimestamp = getStartOfEpoch(epochNumber.add(1));

    uint256 globalIndex = _settleGlobalIndexUpToTimestamp(totalStaked, settleUpToTimestamp);
    _EPOCH_INDEXES_[epochNumber] = globalIndex;
    return globalIndex;
  }

  // ============ Private Functions ============

  /**
   * @dev Updates the global index, reflecting cumulative rewards given out per staked token.
   *
   * @param  totalStaked          The total staked balance, which should be constant in the interval
   *                              since the last update to the global index.
   *
   * @return The new global index.
   */
  function _settleGlobalIndexUpToNow(
    uint256 totalStaked
  )
    private
    returns (uint256)
  {
    return _settleGlobalIndexUpToTimestamp(totalStaked, block.timestamp);
  }

  /**
   * @dev Helper function which settles a user's rewards up to a global index. Should be called
   *  any time a user's staked balance changes, with the OLD user and total balances.
   *
   * @param  user            The user's address.
   * @param  userStaked      Tokens staked by the user during the period since the last user index
   *                         update.
   * @param  newGlobalIndex  The new index value to bring the user index up to. MUST NOT be less
   *                         than the user's index.
   *
   * @return The user's accrued rewards, including past unclaimed rewards.
   */
  function _settleUserRewardsUpToIndex(
    address user,
    uint256 userStaked,
    uint256 newGlobalIndex
  )
    private
    returns (uint256)
  {
    uint256 oldAccruedRewards = _USER_REWARDS_BALANCES_[user];
    uint256 oldUserIndex = _USER_INDEXES_[user];

    if (oldUserIndex == newGlobalIndex) {
      return oldAccruedRewards;
    }

    uint256 newAccruedRewards;
    if (userStaked == 0) {
      // Note: Even if the user's staked balance is zero, we still need to update the user index.
      newAccruedRewards = oldAccruedRewards;
    } else {
      // Calculate newly accrued rewards since the last update to the user's index.
      uint256 indexDelta = newGlobalIndex.sub(oldUserIndex);
      uint256 accruedRewardsDelta = userStaked.mul(indexDelta).div(INDEX_BASE);
      newAccruedRewards = oldAccruedRewards.add(accruedRewardsDelta);

      // Update the user's rewards.
      _USER_REWARDS_BALANCES_[user] = newAccruedRewards;
    }

    // Update the user's index.
    _USER_INDEXES_[user] = newGlobalIndex;
    emit UserIndexUpdated(user, newGlobalIndex, newAccruedRewards);
    return newAccruedRewards;
  }

  /**
   * @dev Updates the global index, reflecting cumulative rewards given out per staked token.
   *
   * @param  totalStaked          The total staked balance, which should be constant in the interval
   *                              (_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp).
   * @param  settleUpToTimestamp  The timestamp up to which to settle rewards. It MUST satisfy
   *                              `settleUpToTimestamp <= block.timestamp`.
   *
   * @return The new global index.
   */
  function _settleGlobalIndexUpToTimestamp(
    uint256 totalStaked,
    uint256 settleUpToTimestamp
  )
    private
    returns (uint256)
  {
    uint256 oldGlobalIndex = uint256(_GLOBAL_INDEX_);

    // The goal of this function is to calculate rewards earned since the last global index update.
    // These rewards are earned over the time interval which is the intersection of the intervals
    // [_GLOBAL_INDEX_TIMESTAMP_, settleUpToTimestamp] and [DISTRIBUTION_START, DISTRIBUTION_END].
    //
    // We can simplify a bit based on the assumption:
    //   `_GLOBAL_INDEX_TIMESTAMP_ >= DISTRIBUTION_START`
    //
    // Get the start and end of the time interval under consideration.
    uint256 intervalStart = uint256(_GLOBAL_INDEX_TIMESTAMP_);
    uint256 intervalEnd = Math.min(settleUpToTimestamp, DISTRIBUTION_END);

    // Return early if the interval has length zero (incl. case where intervalEnd < intervalStart).
    if (intervalEnd <= intervalStart) {
      return oldGlobalIndex;
    }

    // Note: If we reach this point, we must update _GLOBAL_INDEX_TIMESTAMP_.

    uint256 emissionPerSecond = _REWARDS_PER_SECOND_;

    if (emissionPerSecond == 0 || totalStaked == 0) {
      // Ensure a log is emitted if the timestamp changed, even if the index does not change.
      _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
      emit GlobalIndexUpdated(oldGlobalIndex);
      return oldGlobalIndex;
    }

    // Calculate the change in index over the interval.
    uint256 timeDelta = intervalEnd.sub(intervalStart);
    uint256 indexDelta = timeDelta.mul(emissionPerSecond).mul(INDEX_BASE).div(totalStaked);

    // Calculate, update, and return the new global index.
    uint256 newGlobalIndex = oldGlobalIndex.add(indexDelta);

    // Update storage. (Shared storage slot.)
    _GLOBAL_INDEX_TIMESTAMP_ = intervalEnd.toUint32();
    _GLOBAL_INDEX_ = newGlobalIndex.toUint224();

    emit GlobalIndexUpdated(newGlobalIndex);
    return newGlobalIndex;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../dependencies/open-zeppelin/SafeMath.sol';

/**
 * @title Math
 * @author dYdX
 *
 * @dev Library for non-standard Math functions.
 */
library Math {
  using SafeMath for uint256;

  // ============ Library Functions ============

  /**
   * @dev Return `ceil(numerator / denominator)`.
   */
  function divRoundUp(
    uint256 numerator,
    uint256 denominator
  )
    internal
    pure
    returns (uint256)
  {
    if (numerator == 0) {
      // SafeMath will check for zero denominator
      return SafeMath.div(0, denominator);
    }
    return numerator.sub(1).div(denominator).add(1);
  }

  /**
   * @dev Returns the minimum between a and b.
   */
  function min(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    return a < b ? a : b;
  }

  /**
   * @dev Returns the maximum between a and b.
   */
  function max(
    uint256 a,
    uint256 b
  )
    internal
    pure
    returns (uint256)
  {
    return a > b ? a : b;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { SafeCast } from '../lib/SafeCast.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1Storage } from './SM1Storage.sol';

/**
 * @title SM1EpochSchedule
 * @author dYdX
 *
 * @dev Defines a function from block timestamp to epoch number.
 *
 *  The formula used is `n = floor((t - b) / a)` where:
 *    - `n` is the epoch number
 *    - `t` is the timestamp (in seconds)
 *    - `b` is a non-negative offset, indicating the start of epoch zero (in seconds)
 *    - `a` is the length of an epoch, a.k.a. the interval (in seconds)
 *
 *  Note that by restricting `b` to be non-negative, we limit ourselves to functions in which epoch
 *  zero starts at a non-negative timestamp.
 *
 *  The recommended epoch length and blackout window are 28 and 7 days respectively; however, these
 *  are modifiable by the admin, within the specified bounds.
 */
abstract contract SM1EpochSchedule is
  SM1Storage
{
  using SafeCast for uint256;
  using SafeMath for uint256;

  // ============ Events ============

  event EpochParametersChanged(
    SM1Types.EpochParameters epochParameters
  );

  event BlackoutWindowChanged(
    uint256 blackoutWindow
  );

  // ============ Initializer ============

  function __SM1EpochSchedule_init(
    uint256 interval,
    uint256 offset,
    uint256 blackoutWindow
  )
    internal
  {
    require(
      block.timestamp < offset,
      'SM1EpochSchedule: Epoch zero must start after initialization'
    );
    _setBlackoutWindow(blackoutWindow);
    _setEpochParameters(interval, offset);
  }

  // ============ Public Functions ============

  /**
   * @notice Get the epoch at the current block timestamp.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The current epoch number.
   */
  function getCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    return offsetTimestamp.div(interval);
  }

  /**
   * @notice Get the time remaining in the current epoch.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The number of seconds until the next epoch.
   */
  function getTimeRemainingInCurrentEpoch()
    public
    view
    returns (uint256)
  {
    (uint256 interval, uint256 offsetTimestamp) = _getIntervalAndOffsetTimestamp();
    uint256 timeElapsedInEpoch = offsetTimestamp.mod(interval);
    return interval.sub(timeElapsedInEpoch);
  }

  /**
   * @notice Given an epoch number, get the start of that epoch. Calculated as `t = (n * a) + b`.
   *
   * @return The timestamp in seconds representing the start of that epoch.
   */
  function getStartOfEpoch(
    uint256 epochNumber
  )
    public
    view
    returns (uint256)
  {
    SM1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);
    return epochNumber.mul(interval).add(offset);
  }

  /**
   * @notice Check whether we are at or past the start of epoch zero.
   *
   * @return Boolean `true` if the current timestamp is at least the start of epoch zero,
   *  otherwise `false`.
   */
  function hasEpochZeroStarted()
    public
    view
    returns (bool)
  {
    SM1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 offset = uint256(epochParameters.offset);
    return block.timestamp >= offset;
  }

  /**
   * @notice Check whether we are in a blackout window, where withdrawal requests are restricted.
   *  Note that before epoch zero has started, there are no blackout windows.
   *
   * @return Boolean `true` if we are in a blackout window, otherwise `false`.
   */
  function inBlackoutWindow()
    public
    view
    returns (bool)
  {
    return hasEpochZeroStarted() && getTimeRemainingInCurrentEpoch() <= _BLACKOUT_WINDOW_;
  }

  // ============ Internal Functions ============

  function _setEpochParameters(
    uint256 interval,
    uint256 offset
  )
    internal
  {
    SM1Types.EpochParameters memory epochParameters =
      SM1Types.EpochParameters({interval: interval.toUint128(), offset: offset.toUint128()});
    _EPOCH_PARAMETERS_ = epochParameters;
    emit EpochParametersChanged(epochParameters);
  }

  function _setBlackoutWindow(
    uint256 blackoutWindow
  )
    internal
  {
    _BLACKOUT_WINDOW_ = blackoutWindow;
    emit BlackoutWindowChanged(blackoutWindow);
  }

  // ============ Private Functions ============

  /**
   * @dev Helper function to read params from storage and apply offset to the given timestamp.
   *  Recall that the formula for epoch number is `n = (t - b) / a`.
   *
   *  NOTE: Reverts if epoch zero has not started.
   *
   * @return The values `a` and `(t - b)`.
   */
  function _getIntervalAndOffsetTimestamp()
    private
    view
    returns (uint256, uint256)
  {
    SM1Types.EpochParameters memory epochParameters = _EPOCH_PARAMETERS_;
    uint256 interval = uint256(epochParameters.interval);
    uint256 offset = uint256(epochParameters.offset);

    require(
      block.timestamp >= offset,
      'SM1EpochSchedule: Epoch zero has not started'
    );

    uint256 offsetTimestamp = block.timestamp.sub(offset);
    return (interval, offsetTimestamp);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { IERC20 } from '../../../interfaces/IERC20.sol';
import { IERC20Detailed } from '../../../interfaces/IERC20Detailed.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1GovernancePowerDelegation } from './SM1GovernancePowerDelegation.sol';
import { SM1StakedBalances } from './SM1StakedBalances.sol';

/**
 * @title SM1ERC20
 * @author dYdX
 *
 * @dev ERC20 interface for staked tokens. Implements governance functionality for the tokens.
 *
 *  Also allows a user with an active stake to transfer their staked tokens to another user,
 *  even if they would otherwise be restricted from withdrawing.
 */
abstract contract SM1ERC20 is
  SM1StakedBalances,
  SM1GovernancePowerDelegation,
  IERC20Detailed
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice EIP-712 typehash for token approval via EIP-2612 permit.
  bytes32 public constant PERMIT_TYPEHASH = keccak256(
    'Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)'
  );

  // ============ External Functions ============

  function name()
    external
    pure
    override
    returns (string memory)
  {
    return 'Staked DYDX';
  }

  function symbol()
    external
    pure
    override
    returns (string memory)
  {
    return 'stkDYDX';
  }

  function decimals()
    external
    pure
    override
    returns (uint8)
  {
    return 18;
  }

  /**
   * @notice Get the total supply of staked balances.
   *
   *  Note that due to the exchange rate, this is different than querying the total balance of
   *  underyling token staked to this contract.
   *
   * @return The sum of all staked balances.
   */
  function totalSupply()
    external
    view
    override
    returns (uint256)
  {
    return getTotalActiveBalanceCurrentEpoch() + getTotalInactiveBalanceCurrentEpoch();
  }

  /**
   * @notice Get a user's staked balance.
   *
   *  Note that due to the exchange rate, one unit of staked balance may not be equivalent to one
   *  unit of the underlying token. Also note that a user's staked balance is different from a
   *  user's transferable balance.
   *
   * @param  account  The account to get the balance of.
   *
   * @return The user's staked balance.
   */
  function balanceOf(
    address account
  )
    public
    view
    override(SM1GovernancePowerDelegation, IERC20)
    returns (uint256)
  {
    return getActiveBalanceCurrentEpoch(account) + getInactiveBalanceCurrentEpoch(account);
  }

  function transfer(
    address recipient,
    uint256 amount
  )
    external
    override
    nonReentrant
    returns (bool)
  {
    _transfer(msg.sender, recipient, amount);
    return true;
  }

  function allowance(
    address owner,
    address spender
  )
    external
    view
    override
    returns (uint256)
  {
    return _ALLOWANCES_[owner][spender];
  }

  function approve(
    address spender,
    uint256 amount
  )
    external
    override
    returns (bool)
  {
    _approve(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  )
    external
    override
    nonReentrant
    returns (bool)
  {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      msg.sender,
      _ALLOWANCES_[sender][msg.sender].sub(amount, 'SM1ERC20: transfer amount exceeds allowance')
    );
    return true;
  }

  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    external
    returns (bool)
  {
    _approve(msg.sender, spender, _ALLOWANCES_[msg.sender][spender].add(addedValue));
    return true;
  }

  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    external
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _ALLOWANCES_[msg.sender][spender].sub(
        subtractedValue,
        'SM1ERC20: Decreased allowance below zero'
      )
    );
    return true;
  }

  /**
   * @notice Implements the permit function as specified in EIP-2612.
   *
   * @param  owner     Address of the token owner.
   * @param  spender   Address of the spender.
   * @param  value     Amount of allowance.
   * @param  deadline  Expiration timestamp for the signature.
   * @param  v         Signature param.
   * @param  r         Signature param.
   * @param  s         Signature param.
   */
  function permit(
    address owner,
    address spender,
    uint256 value,
    uint256 deadline,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
  {
    require(
      owner != address(0),
      'SM1ERC20: INVALID_OWNER'
    );
    require(
      block.timestamp <= deadline,
      'SM1ERC20: INVALID_EXPIRATION'
    );
    uint256 currentValidNonce = _NONCES_[owner];
    bytes32 digest = keccak256(
      abi.encodePacked(
        '\x19\x01',
        _DOMAIN_SEPARATOR_,
        keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, currentValidNonce, deadline))
      )
    );
    require(
      owner == ecrecover(digest, v, r, s),
      'SM1ERC20: INVALID_SIGNATURE'
    );
    _NONCES_[owner] = currentValidNonce.add(1);
    _approve(owner, spender, value);
  }

  // ============ Internal Functions ============

  function _transfer(
    address sender,
    address recipient,
    uint256 amount
  )
    internal
  {
    require(
      sender != address(0),
      'SM1ERC20: Transfer from address(0)'
    );
    require(
      recipient != address(0),
      'SM1ERC20: Transfer to address(0)'
    );
    require(
      getTransferableBalance(sender) >= amount,
      'SM1ERC20: Transfer exceeds next epoch active balance'
    );

    // Update staked balances and delegate snapshots.
    _transferCurrentAndNextActiveBalance(sender, recipient, amount);
    _moveDelegatesForTransfer(sender, recipient, amount);

    emit Transfer(sender, recipient, amount);
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  )
    internal
  {
    require(
      owner != address(0),
      'SM1ERC20: Approve from address(0)'
    );
    require(
      spender != address(0),
      'SM1ERC20: Approve to address(0)'
    );

    _ALLOWANCES_[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

import { IERC20 } from './IERC20.sol';

/**
 * @dev Interface for ERC20 including metadata
 **/
interface IERC20Detailed is IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import {
  IGovernancePowerDelegationERC20
} from '../../../interfaces/IGovernancePowerDelegationERC20.sol';
import { SM1Types } from '../lib/SM1Types.sol';
import { SM1ExchangeRate } from './SM1ExchangeRate.sol';
import { SM1Storage } from './SM1Storage.sol';

/**
 * @title SM1GovernancePowerDelegation
 * @author dYdX
 *
 * @dev Provides support for two types of governance powers which are separately delegatable.
 *  Provides functions for delegation and for querying a user's power at a certain block number.
 *
 *  Internally, makes use of staked balances denoted in staked units, but returns underlying token
 *  units from the getPowerAtBlock() and getPowerCurrent() functions.
 *
 *  This is based on, and is designed to match, Aave's implementation, which is used in their
 *  governance token and staked token contracts.
 */
abstract contract SM1GovernancePowerDelegation is
  SM1ExchangeRate,
  IGovernancePowerDelegationERC20
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice EIP-712 typehash for delegation by signature of a specific governance power type.
  bytes32 public constant DELEGATE_BY_TYPE_TYPEHASH = keccak256(
    'DelegateByType(address delegatee,uint256 type,uint256 nonce,uint256 expiry)'
  );

  /// @notice EIP-712 typehash for delegation by signature of all governance powers.
  bytes32 public constant DELEGATE_TYPEHASH = keccak256(
    'Delegate(address delegatee,uint256 nonce,uint256 expiry)'
  );

  // ============ External Functions ============

  /**
   * @notice Delegates a specific governance power of the sender to a delegatee.
   *
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function delegateByType(
    address delegatee,
    DelegationType delegationType
  )
    external
    override
  {
    _delegateByType(msg.sender, delegatee, delegationType);
  }

  /**
   * @notice Delegates all governance powers of the sender to a delegatee.
   *
   * @param  delegatee  The address to delegate power to.
   */
  function delegate(
    address delegatee
  )
    external
    override
  {
    _delegateByType(msg.sender, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(msg.sender, delegatee, DelegationType.PROPOSITION_POWER);
  }

  /**
   * @dev Delegates specific governance power from signer to `delegatee` using an EIP-712 signature.
   *
   * @param  delegatee       The address to delegate votes to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   * @param  nonce           The signer's nonce for EIP-712 signatures on this contract.
   * @param  expiry          Expiration timestamp for the signature.
   * @param  v               Signature param.
   * @param  r               Signature param.
   * @param  s               Signature param.
   */
  function delegateByTypeBySig(
    address delegatee,
    DelegationType delegationType,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
  {
    bytes32 structHash = keccak256(
      abi.encode(DELEGATE_BY_TYPE_TYPEHASH, delegatee, uint256(delegationType), nonce, expiry)
    );
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', _DOMAIN_SEPARATOR_, structHash));
    address signer = ecrecover(digest, v, r, s);
    require(
      signer != address(0),
      'SM1GovernancePowerDelegation: INVALID_SIGNATURE'
    );
    require(
      nonce == _NONCES_[signer]++,
      'SM1GovernancePowerDelegation: INVALID_NONCE'
    );
    require(
      block.timestamp <= expiry,
      'SM1GovernancePowerDelegation: INVALID_EXPIRATION'
    );
    _delegateByType(signer, delegatee, delegationType);
  }

  /**
   * @dev Delegates both governance powers from signer to `delegatee` using an EIP-712 signature.
   *
   * @param  delegatee  The address to delegate votes to.
   * @param  nonce      The signer's nonce for EIP-712 signatures on this contract.
   * @param  expiry     Expiration timestamp for the signature.
   * @param  v          Signature param.
   * @param  r          Signature param.
   * @param  s          Signature param.
   */
  function delegateBySig(
    address delegatee,
    uint256 nonce,
    uint256 expiry,
    uint8 v,
    bytes32 r,
    bytes32 s
  )
    external
  {
    bytes32 structHash = keccak256(abi.encode(DELEGATE_TYPEHASH, delegatee, nonce, expiry));
    bytes32 digest = keccak256(abi.encodePacked('\x19\x01', _DOMAIN_SEPARATOR_, structHash));
    address signer = ecrecover(digest, v, r, s);
    require(
      signer != address(0),
      'SM1GovernancePowerDelegation: INVALID_SIGNATURE'
    );
    require(
      nonce == _NONCES_[signer]++,
      'SM1GovernancePowerDelegation: INVALID_NONCE'
    );
    require(
      block.timestamp <= expiry,
      'SM1GovernancePowerDelegation: INVALID_EXPIRATION'
    );
    _delegateByType(signer, delegatee, DelegationType.VOTING_POWER);
    _delegateByType(signer, delegatee, DelegationType.PROPOSITION_POWER);
  }

  /**
   * @notice Returns the delegatee of a user.
   *
   * @param  delegator       The address of the delegator.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function getDelegateeByType(
    address delegator,
    DelegationType delegationType
  )
    external
    override
    view
    returns (address)
  {
    (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);

    return _getDelegatee(delegator, delegates);
  }

  /**
   * @notice Returns the current power of a user. The current power is the power delegated
   *  at the time of the last snapshot.
   *
   * @param  user            The user whose power to query.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerCurrent(
    address user,
    DelegationType delegationType
  )
    external
    override
    view
    returns (uint256)
  {
    return getPowerAtBlock(user, block.number, delegationType);
  }

  /**
   * @notice Get the next valid nonce for EIP-712 signatures.
   *
   *  This nonce should be used when signing for any of the following functions:
   *   - permit()
   *   - delegateByTypeBySig()
   *   - delegateBySig()
   */
  function nonces(
    address owner
  )
    external
    view
    returns (uint256)
  {
    return _NONCES_[owner];
  }

  // ============ Public Functions ============

  function balanceOf(
    address account
  )
    public
    view
    virtual
    returns (uint256);

  /**
   * @notice Returns the power of a user at a certain block, denominated in underlying token units.
   *
   * @param  user            The user whose power to query.
   * @param  blockNumber     The block number at which to get the user's power.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   *
   * @return The user's governance power of the specified type, in underlying token units.
   */
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  )
    public
    override
    view
    returns (uint256)
  {
    (
      mapping(address => mapping(uint256 => SM1Types.Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotCounts,
      // unused: delegates
    ) = _getDelegationDataByType(delegationType);

    uint256 stakeAmount = _findValueAtBlock(
      snapshots[user],
      snapshotCounts[user],
      blockNumber,
      0
    );
    uint256 exchangeRate = _findValueAtBlock(
      _EXCHANGE_RATE_SNAPSHOTS_,
      _EXCHANGE_RATE_SNAPSHOT_COUNT_,
      blockNumber,
      EXCHANGE_RATE_BASE
    );
    return underlyingAmountFromStakeAmountWithExchangeRate(stakeAmount, exchangeRate);
  }

  // ============ Internal Functions ============

  /**
   * @dev Delegates one specific power to a delegatee.
   *
   * @param  delegator       The user whose power to delegate.
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _delegateByType(
    address delegator,
    address delegatee,
    DelegationType delegationType
  )
    internal
  {
    require(
      delegatee != address(0),
      'SM1GovernancePowerDelegation: INVALID_DELEGATEE'
    );

    (, , mapping(address => address) storage delegates) = _getDelegationDataByType(delegationType);
    uint256 delegatorBalance = balanceOf(delegator);
    address previousDelegatee = _getDelegatee(delegator, delegates);

    delegates[delegator] = delegatee;

    _moveDelegatesByType(previousDelegatee, delegatee, delegatorBalance, delegationType);
    emit DelegateChanged(delegator, delegatee, delegationType);
  }

  /**
   * @dev Update delegate snapshots whenever staked tokens are transfered, minted, or burned.
   *
   * @param  from          The sender.
   * @param  to            The recipient.
   * @param  stakedAmount  The amount being transfered, denominated in staked units.
   */
  function _moveDelegatesForTransfer(
    address from,
    address to,
    uint256 stakedAmount
  )
    internal
  {
    address votingPowerFromDelegatee = _getDelegatee(from, _VOTING_DELEGATES_);
    address votingPowerToDelegatee = _getDelegatee(to, _VOTING_DELEGATES_);

    _moveDelegatesByType(
      votingPowerFromDelegatee,
      votingPowerToDelegatee,
      stakedAmount,
      DelegationType.VOTING_POWER
    );

    address propositionPowerFromDelegatee = _getDelegatee(from, _PROPOSITION_DELEGATES_);
    address propositionPowerToDelegatee = _getDelegatee(to, _PROPOSITION_DELEGATES_);

    _moveDelegatesByType(
      propositionPowerFromDelegatee,
      propositionPowerToDelegatee,
      stakedAmount,
      DelegationType.PROPOSITION_POWER
    );
  }

  /**
   * @dev Moves power from one user to another.
   *
   * @param  from            The user from which delegated power is moved.
   * @param  to              The user that will receive the delegated power.
   * @param  amount          The amount of power to be moved.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function _moveDelegatesByType(
    address from,
    address to,
    uint256 amount,
    DelegationType delegationType
  )
    internal
  {
    if (from == to) {
      return;
    }

    (
      mapping(address => mapping(uint256 => SM1Types.Snapshot)) storage snapshots,
      mapping(address => uint256) storage snapshotCounts,
      // unused: delegates
    ) = _getDelegationDataByType(delegationType);

    if (from != address(0)) {
      mapping(uint256 => SM1Types.Snapshot) storage fromSnapshots = snapshots[from];
      uint256 fromSnapshotCount = snapshotCounts[from];
      uint256 previousBalance = 0;

      if (fromSnapshotCount != 0) {
        previousBalance = fromSnapshots[fromSnapshotCount - 1].value;
      }

      uint256 newBalance = previousBalance.sub(amount);
      snapshotCounts[from] = _writeSnapshot(
        fromSnapshots,
        fromSnapshotCount,
        newBalance
      );

      emit DelegatedPowerChanged(from, newBalance, delegationType);
    }

    if (to != address(0)) {
      mapping(uint256 => SM1Types.Snapshot) storage toSnapshots = snapshots[to];
      uint256 toSnapshotCount = snapshotCounts[to];
      uint256 previousBalance = 0;

      if (toSnapshotCount != 0) {
        previousBalance = toSnapshots[toSnapshotCount - 1].value;
      }

      uint256 newBalance = previousBalance.add(amount);
      snapshotCounts[to] = _writeSnapshot(
        toSnapshots,
        toSnapshotCount,
        newBalance
      );

      emit DelegatedPowerChanged(to, newBalance, delegationType);
    }
  }

  /**
   * @dev Returns delegation data (snapshot, snapshotCount, delegates) by delegation type.
   *
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   *
   * @return The mapping of each user to a mapping of snapshots.
   * @return The mapping of each user to the total number of snapshots for that user.
   * @return The mapping of each user to the user's delegate.
   */
  function _getDelegationDataByType(
    DelegationType delegationType
  )
    internal
    view
    returns (
      mapping(address => mapping(uint256 => SM1Types.Snapshot)) storage,
      mapping(address => uint256) storage,
      mapping(address => address) storage
    )
  {
    if (delegationType == DelegationType.VOTING_POWER) {
      return (
        _VOTING_SNAPSHOTS_,
        _VOTING_SNAPSHOT_COUNTS_,
        _VOTING_DELEGATES_
      );
    } else {
      return (
        _PROPOSITION_SNAPSHOTS_,
        _PROPOSITION_SNAPSHOT_COUNTS_,
        _PROPOSITION_DELEGATES_
      );
    }
  }

  /**
   * @dev Returns the delegatee of a user. If a user never performed any delegation, their
   *  delegated address will be 0x0, in which case we return the user's own address.
   *
   * @param  delegator  The address of the user for which return the delegatee.
   * @param  delegates  The mapping of delegates for a particular type of delegation.
   */
  function _getDelegatee(
    address delegator,
    mapping(address => address) storage delegates
  )
    internal
    view
    returns (address)
  {
    address previousDelegatee = delegates[delegator];

    if (previousDelegatee == address(0)) {
      return delegator;
    }

    return previousDelegatee;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;

interface IGovernancePowerDelegationERC20 {

  enum DelegationType {
    VOTING_POWER,
    PROPOSITION_POWER
  }

  /**
   * @dev Emitted when a user delegates governance power to another user.
   *
   * @param  delegator       The delegator.
   * @param  delegatee       The delegatee.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  event DelegateChanged(
    address indexed delegator,
    address indexed delegatee,
    DelegationType delegationType
  );

  /**
   * @dev Emitted when an action changes the delegated power of a user.
   *
   * @param  user            The user whose delegated power has changed.
   * @param  amount          The new amount of delegated power for the user.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  event DelegatedPowerChanged(address indexed user, uint256 amount, DelegationType delegationType);

  /**
   * @dev Delegates a specific governance power to a delegatee.
   *
   * @param  delegatee       The address to delegate power to.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function delegateByType(address delegatee, DelegationType delegationType) external virtual;

  /**
   * @dev Delegates all governance powers to a delegatee.
   *
   * @param  delegatee  The user to which the power will be delegated.
   */
  function delegate(address delegatee) external virtual;

  /**
   * @dev Returns the delegatee of an user.
   *
   * @param  delegator       The address of the delegator.
   * @param  delegationType  The type of delegation (VOTING_POWER, PROPOSITION_POWER).
   */
  function getDelegateeByType(address delegator, DelegationType delegationType)
    external
    view
    virtual
    returns (address);

  /**
   * @dev Returns the current delegated power of a user. The current power is the power delegated
   *  at the time of the last snapshot.
   *
   * @param  user            The user whose power to query.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerCurrent(address user, DelegationType delegationType)
    external
    view
    virtual
    returns (uint256);

  /**
   * @dev Returns the delegated power of a user at a certain block.
   *
   * @param  user            The user whose power to query.
   * @param  blockNumber     The block number at which to get the user's power.
   * @param  delegationType  The type of power (VOTING_POWER, PROPOSITION_POWER).
   */
  function getPowerAtBlock(
    address user,
    uint256 blockNumber,
    DelegationType delegationType
  )
    external
    view
    virtual
    returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SafeMath } from '../../../dependencies/open-zeppelin/SafeMath.sol';
import { SM1Snapshots } from './SM1Snapshots.sol';
import { SM1Storage } from './SM1Storage.sol';

/**
 * @title SM1ExchangeRate
 * @author dYdX
 *
 * @dev Performs math using the exchange rate, which converts between underlying units of the token
 *  that was staked (e.g. STAKED_TOKEN.balanceOf(account)), and staked units, used by this contract
 *  for all staked balances (e.g. this.balanceOf(account)).
 *
 *  OVERVIEW:
 *
 *   The exchange rate is stored as a multiple of EXCHANGE_RATE_BASE, and represents the number of
 *   staked balance units that each unit of underlying token is worth. Before any slashes have
 *   occurred, the exchange rate is equal to one. The exchange rate can increase with each slash,
 *   indicating that staked balances are becoming less and less valuable, per unit, relative to the
 *   underlying token.
 *
 *  AVOIDING OVERFLOW AND UNDERFLOW:
 *
 *   Staked balances are represented internally as uint240, so the result of an operation returning
 *   a staked balances must return a value less than 2^240. Intermediate values in calcuations are
 *   represented as uint256, so all operations within a calculation must return values under 2^256.
 *
 *   In the functions below operating on the exchange rate, we are strategic in our choice of the
 *   order of multiplication and division operations, in order to avoid both overflow and underflow.
 *
 *   We use the following assumptions and principles to implement this module:
 *     - (ASSUMPTION) An amount denoted in underlying token units is never greater than 10^28.
 *     - If the exchange rate is greater than 10^46, then we may perform division on the exchange
 *         rate before performing multiplication, provided that the denominator is not greater
 *         than 10^28 (to ensure a result with at least 18 decimals of precision). Specifically,
 *         we use EXCHANGE_RATE_MAY_OVERFLOW as the cutoff, which is a number greater than 10^46.
 *     - Since staked balances are stored as uint240, we cap the exchange rate to ensure that a
 *         staked balance can never overflow (using the assumption above).
 */
abstract contract SM1ExchangeRate is
  SM1Snapshots,
  SM1Storage
{
  using SafeMath for uint256;

  // ============ Constants ============

  /// @notice The assumed upper bound on the total supply of the staked token.
  uint256 public constant MAX_UNDERLYING_BALANCE = 1e28;

  /// @notice Base unit used to represent the exchange rate, for additional precision.
  uint256 public constant EXCHANGE_RATE_BASE = 1e18;

  /// @notice Cutoff where an exchange rate may overflow after multiplying by an underlying balance.
  /// @dev Approximately 1.2e49
  uint256 public constant EXCHANGE_RATE_MAY_OVERFLOW = (2 ** 256 - 1) / MAX_UNDERLYING_BALANCE;

  /// @notice Cutoff where a stake amount may overflow after multiplying by EXCHANGE_RATE_BASE.
  /// @dev Approximately 1.2e59
  uint256 public constant STAKE_AMOUNT_MAY_OVERFLOW = (2 ** 256 - 1) / EXCHANGE_RATE_BASE;

  /// @notice Max exchange rate.
  /// @dev Approximately 1.8e62
  uint256 public constant MAX_EXCHANGE_RATE = (
    ((2 ** 240 - 1) / MAX_UNDERLYING_BALANCE) * EXCHANGE_RATE_BASE
  );

  // ============ Initializer ============

  function __SM1ExchangeRate_init()
    internal
  {
    _EXCHANGE_RATE_ = EXCHANGE_RATE_BASE;
  }

  function stakeAmountFromUnderlyingAmount(
    uint256 underlyingAmount
  )
    internal
    view
    returns (uint256)
  {
    uint256 exchangeRate = _EXCHANGE_RATE_;

    if (exchangeRate > EXCHANGE_RATE_MAY_OVERFLOW) {
      uint256 exchangeRateUnbased = exchangeRate.div(EXCHANGE_RATE_BASE);
      return underlyingAmount.mul(exchangeRateUnbased);
    } else {
      return underlyingAmount.mul(exchangeRate).div(EXCHANGE_RATE_BASE);
    }
  }

  function underlyingAmountFromStakeAmount(
    uint256 stakeAmount
  )
    internal
    view
    returns (uint256)
  {
    return underlyingAmountFromStakeAmountWithExchangeRate(stakeAmount, _EXCHANGE_RATE_);
  }

  function underlyingAmountFromStakeAmountWithExchangeRate(
    uint256 stakeAmount,
    uint256 exchangeRate
  )
    internal
    pure
    returns (uint256)
  {
    if (stakeAmount > STAKE_AMOUNT_MAY_OVERFLOW) {
      // Note that this case implies that exchangeRate > EXCHANGE_RATE_MAY_OVERFLOW.
      uint256 exchangeRateUnbased = exchangeRate.div(EXCHANGE_RATE_BASE);
      return stakeAmount.div(exchangeRateUnbased);
    } else {
      return stakeAmount.mul(EXCHANGE_RATE_BASE).div(exchangeRate);
    }
  }

  function updateExchangeRate(
    uint256 numerator,
    uint256 denominator
  )
    internal
    returns (uint256)
  {
    uint256 oldExchangeRate = _EXCHANGE_RATE_;

    // Avoid overflow.
    // Note that the numerator and denominator are both denominated in underlying token units.
    uint256 newExchangeRate;
    if (oldExchangeRate > EXCHANGE_RATE_MAY_OVERFLOW) {
      newExchangeRate = oldExchangeRate.div(denominator).mul(numerator);
    } else {
      newExchangeRate = oldExchangeRate.mul(numerator).div(denominator);
    }

    require(
      newExchangeRate <= MAX_EXCHANGE_RATE,
      'SM1ExchangeRate: Max exchange rate exceeded'
    );

    _EXCHANGE_RATE_SNAPSHOT_COUNT_ = _writeSnapshot(
      _EXCHANGE_RATE_SNAPSHOTS_,
      _EXCHANGE_RATE_SNAPSHOT_COUNT_,
      newExchangeRate
    );

    _EXCHANGE_RATE_ = newExchangeRate;
    return newExchangeRate;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.7.5;
pragma abicoder v2;

import { SM1Types } from '../lib/SM1Types.sol';
import { SM1Storage } from './SM1Storage.sol';

/**
 * @title SM1Snapshots
 * @author dYdX
 *
 * @dev Handles storage and retrieval of historical values by block number.
 *
 *  Note that the snapshot stored at a given block number represents the value as of the end of
 *  that block.
 */
abstract contract SM1Snapshots {

  /**
   * @dev Writes a snapshot of a value at the current block.
   *
   * @param  snapshots      Storage mapping from snapshot index to snapshot struct.
   * @param  snapshotCount  The total number of snapshots in the provided mapping.
   * @param  newValue       The new value to snapshot at the current block.
   *
   * @return The new snapshot count.
   */
  function _writeSnapshot(
    mapping(uint256 => SM1Types.Snapshot) storage snapshots,
    uint256 snapshotCount,
    uint256 newValue
  )
    internal
    returns (uint256)
  {
    uint256 currentBlock = block.number;

    if (
      snapshotCount != 0 &&
      snapshots[snapshotCount - 1].blockNumber == currentBlock
    ) {
      // If there was a previous snapshot for this block, overwrite it.
      snapshots[snapshotCount - 1].value = newValue;
      return snapshotCount;
    } else {
      snapshots[snapshotCount] = SM1Types.Snapshot(currentBlock, newValue);
      return snapshotCount + 1;
    }
  }

  /**
   * @dev Search for the snapshot value at a given block. Uses binary search.
   *
   *  Reverts if `blockNumber` is greater than the current block number.
   *
   * @param  snapshots      Storage mapping from snapshot index to snapshot struct.
   * @param  snapshotCount  The total number of snapshots in the provided mapping.
   * @param  blockNumber    The block number to search for.
   * @param  initialValue   The value to return if `blockNumber` is before the earliest snapshot.
   *
   * @return The snapshot value at the specified block number.
   */
  function _findValueAtBlock(
    mapping(uint256 => SM1Types.Snapshot) storage snapshots,
    uint256 snapshotCount,
    uint256 blockNumber,
    uint256 initialValue
  )
    internal
    view
    returns (uint256)
  {
    require(
      blockNumber <= block.number,
      'SM1Snapshots: INVALID_BLOCK_NUMBER'
    );

    if (snapshotCount == 0) {
      return initialValue;
    }

    // Check earliest snapshot.
    if (blockNumber < snapshots[0].blockNumber) {
      return initialValue;
    }

    // Check latest snapshot.
    if (blockNumber >= snapshots[snapshotCount - 1].blockNumber) {
      return snapshots[snapshotCount - 1].value;
    }

    uint256 lower = 0;
    uint256 upper = snapshotCount - 1;
    while (upper > lower) {
      uint256 center = upper - (upper - lower) / 2; // Ceil, avoiding overflow.
      SM1Types.Snapshot memory snapshot = snapshots[center];
      if (snapshot.blockNumber == blockNumber) {
        return snapshot.value;
      } else if (snapshot.blockNumber < blockNumber) {
        lower = center;
      } else {
        upper = center - 1;
      }
    }
    return snapshots[lower].value;
  }
}

