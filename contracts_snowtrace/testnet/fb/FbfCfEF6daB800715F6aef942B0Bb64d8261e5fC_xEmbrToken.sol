// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;
pragma abicoder v2;

import { IxEmbr } from "./interfaces/IxEmbr.sol";
import { xEmbrVotingToken } from "./xEmbrVotingToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Root } from "../../shared/Root.sol";
import { InitializableReentrancyGuard } from "../../shared/InitializableReentrancyGuard.sol";
import "./deps/xEmbrStructs.sol";

/**
 * @title xEmbrToken
 * @notice xEmbrToken is a non-transferrable ERC20 token that allows users to stake and withdraw, earning voting rights.
 * Scaled balance is determined by quests a user completes, and the length of time they keep the raw balance wrapped.
 * Stakers can unstake, after the elapsed cooldown period, and before the end of the unstake window. Users voting/earning
 * power is slashed during this time, and they may face a redemption fee if they leave early.
 * Voting power can be used for a number of things: voting in the mStable DAO/emission dials, boosting rewards, earning
 * rewards here. While a users "balance" is unique to themselves, they can choose to delegate their voting power (which will apply
 * to voting in the mStable DAO and emission dials).
 * @author mStable
 * @dev Only whitelisted contracts can communicate with this contract, in order to avoid having tokenised wrappers that
 * could potentially circumvent our unstaking procedure.
 **/
contract xEmbrToken is xEmbrVotingToken, InitializableReentrancyGuard {
    using SafeERC20 for IERC20;

    /// @notice Core token that is staked and tracked (e.g. MTA)
    IERC20 public immutable STAKED_TOKEN;
    /// @notice Seconds a user must wait after she initiates her cooldown before withdrawal is possible
    uint256 public immutable COOLDOWN_SECONDS;
    /// @notice Window in which it is possible to withdraw, following the cooldown period
    uint256 public immutable UNSTAKE_WINDOW;
    /// @notice A week
    uint256 private constant ONE_WEEK = 7 days;

    /// @notice Whitelisted smart contract integrations
    mapping(address => bool) public whitelistedWrappers;

    event Staked(address indexed user, uint256 amount, address delegatee);
    event Withdraw(address indexed user, address indexed to, uint256 amount);
    event Cooldown(address indexed user, uint256 percentage);
    event CooldownExited(address indexed user);
    event SlashRateChanged(uint256 newRate);
    event Recollateralised();
    event WrapperWhitelisted(address wallet);
    event WrapperBlacklisted(address wallet);

    /***************************************
                    INIT
    ****************************************/

    /**
     * @param _fulcrum System fulcrum
     * @param _questManager Centralised manager of quests
     * @param _stakedToken Core token that is staked and tracked (e.g. MTA)
     * @param _cooldownSeconds Seconds a user must wait after she initiates her cooldown before withdrawal is possible
     * @param _unstakeWindow Window in which it is possible to withdraw, following the cooldown period
     * @param _hasPriceCoeff true if raw staked amount is multiplied by price coeff to get staked amount. eg BPT Staked Token
     */
    constructor(
        address _fulcrum,
        address _questManager,
        address _stakedToken,
        uint256 _cooldownSeconds,
        uint256 _unstakeWindow,
        bool _hasPriceCoeff
    ) xEmbrVotingToken(_fulcrum, _stakedToken, _questManager, _hasPriceCoeff) {
        STAKED_TOKEN = IERC20(_stakedToken);
        COOLDOWN_SECONDS = _cooldownSeconds;
        UNSTAKE_WINDOW = _unstakeWindow;
    }

    /**
     * @param _nameArg Token name
     * @param _symbolArg Token symbol
     * @param _rewardsDistributorArg mStable Rewards Distributor
     */
    function __xEmbrToken_init(
        bytes32 _nameArg,
        bytes32 _symbolArg,
        address _rewardsDistributorArg
    ) public initializer {
        __xEmbr_init(_nameArg, _symbolArg, _rewardsDistributorArg);
        _initializeReentrancyGuard();
    }

    /**
     * @dev Only whitelisted contracts can call core fns. mStable governors can whitelist and de-whitelist wrappers.
     * Access may be given to yield optimisers to boost rewards, but creating unlimited and ungoverned wrappers is unadvised.
     */
    modifier assertNotContract() {
        _assertNotContract();
        _;
    }

    function _assertNotContract() internal view {
        if (_msgSender() != tx.origin) {
            require(whitelistedWrappers[_msgSender()], "Not a whitelisted contract");
        }
    }

    /***************************************
                    ACTIONS
    ****************************************/

    /**
     * @dev Stake an `_amount` of STAKED_TOKEN in the system. This amount is added to the users stake and
     * boosts their voting power.
     * @param _amount Units of STAKED_TOKEN to stake
     */
    function stake(uint256 _amount) external {
        _transferAndStake(_amount, address(0), false);
    }

    /**
     * @dev Stake an `_amount` of STAKED_TOKEN in the system. This amount is added to the users stake and
     * boosts their voting power.
     * @param _amount Units of STAKED_TOKEN to stake
     * @param _exitCooldown Bool signalling whether to take this opportunity to end any outstanding cooldown and
     * return the user back to their full voting power
     */
    function stake(uint256 _amount, bool _exitCooldown) external {
        _transferAndStake(_amount, address(0), _exitCooldown);
    }

    /**
     * @dev Stake an `_amount` of STAKED_TOKEN in the system. This amount is added to the users stake and
     * boosts their voting power. Take the opportunity to change delegatee.
     * @param _amount Units of STAKED_TOKEN to stake
     * @param _delegatee Address of the user to whom the sender would like to delegate their voting power
     */
    function stake(uint256 _amount, address _delegatee) external {
        _transferAndStake(_amount, _delegatee, false);
    }

    /**
     * @dev Transfers tokens from sender before calling `_settleStake`
     */
    function _transferAndStake(
        uint256 _amount,
        address _delegatee,
        bool _exitCooldown
    ) internal {
        STAKED_TOKEN.safeTransferFrom(_msgSender(), address(this), _amount);
        _settleStake(_amount, _delegatee, _exitCooldown);
    }

    /**
     * @dev Internal stake fn. Can only be called by whitelisted contracts/EOAs and only before a recollateralisation event.
     * NOTE - Assumes tokens have already been transferred
     * @param _amount Units of STAKED_TOKEN to stake
     * @param _delegatee Address of the user to whom the sender would like to delegate their voting power
     * @param _exitCooldown Bool signalling whether to take this opportunity to end any outstanding cooldown and
     * return the user back to their full voting power
     */
    function _settleStake(
        uint256 _amount,
        address _delegatee,
        bool _exitCooldown
    ) internal assertNotContract {
        require(_amount != 0, "INVALID_ZERO_AMOUNT");

        // 1. Apply the delegate if it has been chosen (else it defaults to the sender)
        if (_delegatee != address(0)) {
            _delegate(_msgSender(), _delegatee);
        }

        // 2. Deal with cooldown
        //      If a user is currently in a cooldown period, re-calculate their cooldown timestamp
        Balance memory oldBalance = _balances[_msgSender()];
        //      If we have missed the unstake window, or the user has chosen to exit the cooldown,
        //      then reset the timestamp to 0
        bool exitCooldown = _exitCooldown ||
            (oldBalance.cooldownTimestamp > 0 &&
                block.timestamp >
                (oldBalance.cooldownTimestamp + COOLDOWN_SECONDS + UNSTAKE_WINDOW));
        if (exitCooldown) {
            emit CooldownExited(_msgSender());
        }

        // 3. Settle the stake by depositing the STAKED_TOKEN and minting voting power
        _mintRaw(_msgSender(), _amount, exitCooldown);

        emit Staked(_msgSender(), _amount, _delegatee);
    }

    /**
     * @dev Withdraw raw tokens from the system, following an elapsed cooldown period.
     * Note - May be subject to a transfer fee, depending on the users weightedTimestamp
     * @param _amount Units of raw token to withdraw
     * @param _recipient Address of beneficiary who will receive the raw tokens
     * @param _amountIncludesFee Is the `_amount` specified inclusive of any applicable redemption fee?
     * @param _exitCooldown Should we take this opportunity to exit the cooldown period?
     **/
    function withdraw(
        uint256 _amount,
        address _recipient,
        bool _amountIncludesFee,
        bool _exitCooldown
    ) external {
        _withdraw(_amount, _recipient, _amountIncludesFee, _exitCooldown);
    }

    /**
     * @dev Withdraw raw tokens from the system, following an elapsed cooldown period.
     * Note - May be subject to a transfer fee, depending on the users weightedTimestamp
     * @param _amount Units of raw token to withdraw
     * @param _recipient Address of beneficiary who will receive the raw tokens
     * @param _amountIncludesFee Is the `_amount` specified inclusive of any applicable redemption fee?
     * @param _exitCooldown Should we take this opportunity to exit the cooldown period?
     **/
    function _withdraw(
        uint256 _amount,
        address _recipient,
        bool _amountIncludesFee,
        bool _exitCooldown
    ) internal assertNotContract {
        require(_amount != 0, "INVALID_ZERO_AMOUNT");
        
        // 1. If no recollateralisation has occured, the user must be within their UNSTAKE_WINDOW period in order to withdraw
        Balance memory oldBalance = _balances[_msgSender()];
        require(
            block.timestamp > oldBalance.cooldownTimestamp + COOLDOWN_SECONDS,
            "INSUFFICIENT_COOLDOWN"
        );
        require(
            block.timestamp - (oldBalance.cooldownTimestamp + COOLDOWN_SECONDS) <=
                UNSTAKE_WINDOW,
            "UNSTAKE_WINDOW_FINISHED"
        );

        // 2. Get current balance
        Balance memory balance = _balances[_msgSender()];

        // 3. Apply redemption fee
        //      e.g. (55e18 / 5e18) - 2e18 = 9e18 / 100 = 9e16
        uint256 feeRate = calcRedemptionFeeRate(balance.weightedTimestamp);
        //      fee = amount * 1e18 / feeRate
        //      totalAmount = amount + fee
        uint256 totalWithdraw = _amountIncludesFee
            ? _amount
            : (_amount * (1e18 + feeRate)) / 1e18;
        uint256 userWithdrawal = (totalWithdraw * 1e18) / (1e18 + feeRate);

        //      Check for percentage withdrawal
        uint256 maxWithdrawal = oldBalance.cooldownUnits;
        require(totalWithdraw <= maxWithdrawal, "Exceeds max withdrawal");

        // 4. Exit cooldown if the user has specified, or if they have withdrawn everything
        // Otherwise, update the percentage remaining proportionately
        bool exitCooldown = _exitCooldown || totalWithdraw == maxWithdrawal;

        // 5. Settle the withdrawal by burning the voting tokens
        _burnRaw(_msgSender(), totalWithdraw, exitCooldown, false);
        //      Log any redemption fee to the rewards contract
        _notifyAdditionalReward( 2**256 - 1, totalWithdraw - userWithdrawal);
        //      Finally transfer tokens back to recipient
        STAKED_TOKEN.safeTransfer(_recipient, userWithdrawal);

        emit Withdraw(_msgSender(), _recipient, _amount);
    }

    /**
     * @dev Enters a cooldown period, after which (and before the unstake window elapses) a user will be able
     * to withdraw part or all of their staked tokens. Note, during this period, a users voting power is significantly reduced.
     * If a user already has a cooldown period, then it will reset to the current block timestamp, so use wisely.
     * @param _units Units of stake to cooldown for
     **/
    function startCooldown(uint256 _units) external {
        _startCooldown(_units);
    }

    /**
     * @dev Ends the cooldown of the sender and give them back their full voting power. This can be used to signal that
     * the user no longer wishes to exit the system. Note, the cooldown can also be reset, more smoothly, as part of a stake or
     * withdraw transaction.
     **/
    function endCooldown() external {
        require(_balances[_msgSender()].cooldownTimestamp != 0, "No cooldown");

        _exitCooldownPeriod(_msgSender());

        emit CooldownExited(_msgSender());
    }

    /**
     * @dev Enters a cooldown period, after which (and before the unstake window elapses) a user will be able
     * to withdraw part or all of their staked tokens. Note, during this period, a users voting power is significantly reduced.
     * If a user already has a cooldown period, then it will reset to the current block timestamp, so use wisely.
     * @param _units Units of stake to cooldown for
     **/
    function _startCooldown(uint256 _units) internal {
        require(balanceOf(_msgSender()) != 0, "INVALID_BALANCE_ON_COOLDOWN");

        _enterCooldownPeriod(_msgSender(), _units);

        emit Cooldown(_msgSender(), _units);
    }

    /***************************************
                    ADMIN
    ****************************************/

    /**
     * @dev Allows governance to whitelist a smart contract to interact with the StakedToken (for example a yield aggregator or simply
     * a Gnosis SAFE or other)
     * @param _wrapper Address of the smart contract to list
     **/
    function whitelistWrapper(address _wrapper) external onlyGovernor {
        whitelistedWrappers[_wrapper] = true;

        emit WrapperWhitelisted(_wrapper);
    }

    /**
     * @dev Allows governance to blacklist a smart contract to end it's interaction with the StakedToken
     * @param _wrapper Address of the smart contract to blacklist
     **/
    function blackListWrapper(address _wrapper) external onlyGovernor {
        whitelistedWrappers[_wrapper] = false;

        emit WrapperBlacklisted(_wrapper);
    }

    /***************************************
            BACKWARDS COMPATIBILITY
    ****************************************/

    /**
     * @dev Allows for backwards compatibility with createLock fn, giving basic args to stake
     * @param _value Units to stake
     **/
    function createLock(
        uint256 _value,
        uint256 /* _unlockTime */
    ) external {
        _transferAndStake(_value, address(0), false);
    }

    /**
     * @dev Allows for backwards compatibility with increaseLockAmount fn by simply staking more
     * @param _value Units to stake
     **/
    function increaseLockAmount(uint256 _value) external {
        require(balanceOf(_msgSender()) != 0, "Nothing to increase");
        _transferAndStake(_value, address(0), false);
    }

    /**
     * @dev Backwards compatibility. Previously a lock would run out and a user would call this. Now, it will take 2 calls
     * to exit in order to leave. The first will initiate the cooldown period, and the second will execute a full withdrawal.
     **/
    function exit() external virtual {
        // Since there is no immediate exit here, this can be called twice
        // If there is no cooldown, or the cooldown has passed the unstake window, enter cooldown
        uint128 ts = _balances[_msgSender()].cooldownTimestamp;
        if (ts == 0 || block.timestamp > ts + COOLDOWN_SECONDS + UNSTAKE_WINDOW) {
            (uint256 raw, uint256 cooldownUnits) = rawBalanceOf(_msgSender());
            _startCooldown(raw + cooldownUnits);
        }
        // Else withdraw all available
        else {
            _withdraw(_balances[_msgSender()].cooldownUnits, _msgSender(), true, false);
        }
    }

    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev fee = sqrt(300/x)-2.5, where x = weeks since user has staked
     * @param _weightedTimestamp The users weightedTimestamp
     * @return _feeRate where 1% == 1e16
     */
    function calcRedemptionFeeRate(uint32 _weightedTimestamp)
        public
        view
        returns (uint256 _feeRate)
    {
        uint256 weeksStaked = ((block.timestamp - _weightedTimestamp) * 1e18) / ONE_WEEK;
        if (weeksStaked > 3e18) {
            // e.g. weeks = 1  = sqrt(300e18) = 17320508075
            // e.g. weeks = 10 = sqrt(30e18) =   5477225575
            // e.g. weeks = 26 = sqrt(11.5) =    3391164991
            _feeRate = Root.sqrt(300e36 / weeksStaked) * 1e7;
            // e.g. weeks = 1  = 173e15 - 25e15 = 148e15 or 14.8%
            // e.g. weeks = 10 =  55e15 - 25e15 = 30e15 or 3%
            // e.g. weeks = 26 =  34e15 - 25e15 = 9e15 or 0.9%
            _feeRate = _feeRate < 25e15 ? 0 : _feeRate - 25e15;
        } else {
            _feeRate = 75e15;
        }
    }

    uint256[48] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../deps/xEmbrStructs.sol";

interface IxEmbr {
    // GETTERS
    function COOLDOWN_SECONDS() external view returns (uint256);

    function UNSTAKE_WINDOW() external view returns (uint256);

    function STAKED_TOKEN() external view returns (IERC20);

    function getRewardToken(uint256 _tid) external view returns (address);

    function getActiveIndex(uint256 _tid) external view returns (uint256);

    function pendingAdditionalReward() external view returns (uint256);

    function whitelistedWrappers(address) external view returns (bool);

    function balanceData(address _account) external view returns (Balance memory);

    function balanceOf(address _account) external view returns (uint256);

    function rawBalanceOf(address _account) external view returns (uint256, uint256);

    function calcRedemptionFeeRate(uint32 _weightedTimestamp)
        external
        view
        returns (uint256 _feeRate);

    function safetyData()
        external
        view
        returns (uint128 collateralisationRatio, uint128 slashingPercentage);

    function delegates(address account) external view returns (address);

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    function getVotes(address account) external view returns (uint256);

    // HOOKS/PERMISSIONED
    function applyQuestMultiplier(address _account, uint8 _newMultiplier) external;

    // ADMIN
    function whitelistWrapper(address _wrapper) external;

    function blackListWrapper(address _wrapper) external;

    function changeSlashingPercentage(uint256 _newRate) external;

    function emergencyRecollateralisation() external;

    function setGovernanceHook(address _newHook) external;

    // USER
    function stake(uint256 _amount) external;

    function stake(uint256 _amount, address _delegatee) external;

    function stake(uint256 _amount, bool _exitCooldown) external;

    function withdraw(
        uint256 _amount,
        address _recipient,
        bool _amountIncludesFee,
        bool _exitCooldown
    ) external;

    function delegate(address delegatee) external;

    function startCooldown(uint256 _units) external;

    function endCooldown() external;

    function reviewTimestamp(address _account) external;

    function claimReward() external;

    function claimReward(address _to) external;

    // Backwards compatibility
    function createLock(uint256 _value, uint256) external;

    function exit() external;

    function increaseLockAmount(uint256 _value) external;

    function increaseLockLength(uint256) external;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { MathUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { ECDSAUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import { xEmbr } from "./xEmbr.sol";
import { IGovernanceHook } from "./interfaces/IGovernanceHook.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title xEmbrVotingToken
 * @notice xEmbr is a checkpointed Voting Token derived from OpenZeppelin "ERC20VotesUpgradable"
 * @author mStable
 * @dev Forked from https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/f9cdbd7d82d45a614ee98a5dc8c08fb4347d0fea/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol
 * Changes:
 *   - Inherits custom xEmbr rather than basic ERC20
 *     - Removal of `Permit` functionality & `delegatebySig`
 *   - Override `delegates` fn as described in their docs
 *   - Prettier formatting
 *   - Addition of `totalSupply` method to get latest totalSupply
 *   - Move totalSupply checkpoints to `afterTokenTransfer`
 *   - Add _governanceHook hook
 */
abstract contract xEmbrVotingToken is Initializable, xEmbr {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    IGovernanceHook private _governanceHook;

    event GovernanceHookChanged(address indexed hook);

    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to an account's voting power.
     */
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    constructor(
        address _fulcrum,
        address _embr,
        address _questManager,
        bool _hasPriceCoeff
    ) xEmbr(_fulcrum, _embr, _questManager, _hasPriceCoeff) {}

    function __xEmbrVotingToken_init() internal initializer {}

    /**
     * @dev
     */
    function setGovernanceHook(address _newHook) external onlyGovernor {
        _governanceHook = IGovernanceHook(_newHook);

        emit GovernanceHookChanged(_newHook);
    }

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos)
        public
        view
        virtual
        returns (Checkpoint memory)
    {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address the `delegator` is currently delegating to.
     * Return the `delegator` account if not delegating to anyone.
     * @param delegator the account that is delegating the votes from
     * @return delegatee that is receiving the delegated votes
     */
    function delegates(address delegator) public view virtual returns (address) {
        // Override as per https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/master/contracts/token/ERC20/extensions/ERC20VotesUpgradeable.sol#L23
        // return _delegates[account];
        address delegatee = _delegates[delegator];
        return delegatee == address(0) ? delegator : delegatee;
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Total sum of all scaled balances
     */
    function totalSupply() public view override returns (uint256) {
        uint256 len = _totalSupplyCheckpoints.length;
        if (len == 0) return 0;
        return _totalSupplyCheckpoints[len - 1].votes;
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber)
        private
        view
        returns (uint256)
    {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     * If `delegatee` is zero, the sender gets the voting power.
     * @param delegatee account that gets the voting power.
     */
    function delegate(address delegatee) public virtual {
        return _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        // mint or burn, update total supply
        if (from == address(0) || to == address(0)) {
            _writeCheckpoint(_totalSupplyCheckpoints, to == address(0) ? _subtract : _add, amount);
        }

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegatee = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);

        _delegates[delegator] = delegatee;
        delegatee = delegates(delegator);

        emit DelegateChanged(delegator, currentDelegatee, delegatee);

        _moveVotingPower(currentDelegatee, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _checkpoints[src],
                    _subtract,
                    amount
                );
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(
                    _checkpoints[dst],
                    _add,
                    amount
                );
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }

            if (address(_governanceHook) != address(0)) {
                _governanceHook.moveVotingPowerHook(src, dst, amount);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCast.toUint224(newWeight);
        } else {
            ckpts.push(
                Checkpoint({
                    fromBlock: SafeCast.toUint32(block.number),
                    votes: SafeCast.toUint224(newWeight)
                })
            );
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    uint256[46] private __gap;
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

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

library Root {
    /**
     * @dev Returns the square root of a given number
     * @param x Input
     * @return y Square root of Input
     */
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) {
                xx >>= 128;
                r <<= 64;
            }
            if (xx >= 0x10000000000000000) {
                xx >>= 64;
                r <<= 32;
            }
            if (xx >= 0x100000000) {
                xx >>= 32;
                r <<= 16;
            }
            if (xx >= 0x10000) {
                xx >>= 16;
                r <<= 8;
            }
            if (xx >= 0x100) {
                xx >>= 8;
                r <<= 4;
            }
            if (xx >= 0x10) {
                xx >>= 4;
                r <<= 2;
            }
            if (xx >= 0x8) {
                r <<= 1;
            }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint256(r < r1 ? r : r1);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract InitializableReentrancyGuard {
    bool private _notEntered;

    function _initializeReentrancyGuard() internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
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
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

struct Balance {
    /// units of staking token that has been deposited and consequently wrapped
    uint88 raw;
    /// (block.timestamp - weightedTimestamp) represents the seconds a user has had their full raw balance wrapped.
    /// If they deposit or withdraw, the weightedTimestamp is dragged towards block.timestamp proportionately
    uint32 weightedTimestamp;
    /// multiplier awarded for staking for a long time
    uint8 timeMultiplier;
    /// multiplier duplicated from QuestManager
    uint8 questMultiplier;
    /// Time at which the relative cooldown began
    uint32 cooldownTimestamp;
    /// Units up for cooldown
    uint88 cooldownUnits;
}

struct QuestBalance {
    /// last timestamp at which the user made a write action to this contract
    uint32 lastAction;
    /// permanent multiplier applied to an account, awarded for PERMANENT QuestTypes
    uint8 permMultiplier;
    /// multiplier that decays after each "season" (~9 months) by 75%, to avoid multipliers getting out of control
    uint8 seasonMultiplier;
}

/// @notice Quests can either give permanent rewards or only for the season
enum QuestType {
    PERMANENT,
    SEASONAL
}

/// @notice Quests can be turned off by the questMaster. All those who already completed remain
enum QuestStatus {
    ACTIVE,
    EXPIRED
}
struct Quest {
    /// Type of quest rewards
    QuestType model;
    /// Multiplier, from 1 == 1.01x to 100 == 2.00x
    uint8 multiplier;
    /// Is the current quest valid?
    QuestStatus status;
    /// Expiry date in seconds for the quest
    uint32 expiry;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import { SafeCastExtended } from "../../shared/SafeCastExtended.sol";
import { ILockedERC20 } from "./interfaces/ILockedERC20.sol";
import { HeadlessStakingRewards } from "../../rewards/staking/HeadlessStakingRewards.sol";
import { IQuestManager } from "./interfaces/IQuestManager.sol";
import "./deps/xEmbrStructs.sol";

/**
 * @title xEmbr
 * @notice xEmbr is a non-transferrable ERC20 token that has both a raw balance and a scaled balance.
 * Scaled balance is determined by quests a user completes, and the length of time they keep the raw balance wrapped.
 * QuestMasters can add new quests for stakers to complete, for which they are rewarded with permanent or seasonal multipliers.
 * @author mStable
 * @dev Originally forked from openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol
 * Changes:
 *   - Removed the transfer, transferFrom, approve fns to make non-transferrable
 *   - Removed `_allowances` storage
 *   - Removed `_beforeTokenTransfer` hook
 *   - Replaced standard uint256 balance with a single struct containing all data from which the scaledBalance can be derived
 *   - Quest system implemented that tracks a users quest status and applies multipliers for them
 **/
abstract contract xEmbr is
    ILockedERC20,
    Initializable,
    ContextUpgradeable,
    HeadlessStakingRewards
{
    /// @notice name of this token (ERC20)
    bytes32 private _name;
    /// @notice symbol of this token (ERC20)
    bytes32 private _symbol;
    /// @notice number of decimals of this token (ERC20)
    uint8 public constant override decimals = 18;

    /// @notice User balance structs containing all data needed to scale balance
    mapping(address => Balance) internal _balances;
    /// @notice Most recent price coefficients per user
    mapping(address => uint256) internal _userPriceCoeff;
    /// @notice Quest Manager
    IQuestManager public immutable questManager;
    /// @notice Has variable price
    bool public immutable hasPriceCoeff;

    /***************************************
                    INIT
    ****************************************/

    /**
     * @param _fulcrum System fulcrum
     * @param _embr Embr Token
     * @param _questManager Centralised manager of quests
     * @param _hasPriceCoeff true if raw staked amount is multiplied by price coeff to get staked amount. eg BPT Staked Token
     */
    constructor(
        address _fulcrum,
        address _embr,
        address _questManager,
        bool _hasPriceCoeff
    ) HeadlessStakingRewards(_fulcrum, _embr) {
        questManager = IQuestManager(_questManager);
        hasPriceCoeff = _hasPriceCoeff;
    }

    /**
     * @param _nameArg Token name
     * @param _symbolArg Token symbol
     * @param _rewardsDistributorArg mStable Rewards Distributor
     */
    function __xEmbr_init(
        bytes32 _nameArg,
        bytes32 _symbolArg,
        address _rewardsDistributorArg
    ) internal initializer {
        __Context_init_unchained();
        _name = _nameArg;
        _symbol = _symbolArg;
        HeadlessStakingRewards._initialize(_rewardsDistributorArg);
    }

    /**
     * @dev Checks that _msgSender is the quest Manager
     */
    modifier onlyQuestManager() {
        require(_msgSender() == address(questManager), "Not verified");
        _;
    }

    /***************************************
                    VIEWS
    ****************************************/

    function name() public view override returns (string memory) {
        return bytes32ToString(_name);
    }

    function symbol() public view override returns (string memory) {
        return bytes32ToString(_symbol);
    }

    /**
     * @dev Total sum of all scaled balances
     * In this instance, leave to the child token.
     */
    function totalSupply()
        public
        view
        virtual
        override(HeadlessStakingRewards, ILockedERC20)
        returns (uint256);

    /**
     * @dev Simply gets scaled balance
     * @return scaled balance for user
     */
    function balanceOf(address _account)
        public
        view
        virtual
        override(HeadlessStakingRewards, ILockedERC20)
        returns (uint256)
    {
        return _getBalance(_account, _balances[_account]);
    }

    /**
     * @dev Simply gets raw balance
     * @return raw balance for user
     */
    function rawBalanceOf(address _account) public view returns (uint256, uint256) {
        return (_balances[_account].raw, _balances[_account].cooldownUnits);
    }

    /**
     * @dev Scales the balance of a given user by applying multipliers
     */
    function _getBalance(address _account, Balance memory _balance)
        internal
        view
        returns (uint256 balance)
    {
        // e.g. raw = 1000, questMultiplier = 40, timeMultiplier = 30. Cooldown of 60%
        // e.g. 1000 * (100 + 40) / 100 = 1400
        balance = (_balance.raw * (100 + _balance.questMultiplier)) / 100;
        // e.g. 1400 * (100 + 30) / 100 = 1820
        balance = (balance * (100 + _balance.timeMultiplier)) / 100;

        if (hasPriceCoeff) {
            // e.g. 1820 * 16000 / 10000 = 2912
            balance = (balance * _userPriceCoeff[_account]) / 10000;
        }
    }

    /**
     * @notice Raw staked balance without any multipliers
     */
    function balanceData(address _account) external view returns (Balance memory) {
        return _balances[_account];
    }

    /**
     * @notice Raw staked balance without any multipliers
     */
    function userPriceCoeff(address _account) external view returns (uint256) {
        return _userPriceCoeff[_account];
    }

    /***************************************
                    QUESTS
    ****************************************/

    /**
     * @dev Called by anyone to poke the timestamp of a given account. This allows users to
     * effectively 'claim' any new timeMultiplier, but will revert if there is no change there.
     */
    function reviewTimestamp(address _account) external {
        _reviewWeightedTimestamp(_account);
    }

    /**
     * @dev Adds the multiplier awarded from quest completion to a users data, taking the opportunity
     * to check time multipliers etc.
     * @param _account Address of user that should be updated
     * @param _newMultiplier New Quest Multiplier
     */
    function applyQuestMultiplier(address _account, uint8 _newMultiplier)
        external
        onlyQuestManager
    {
        require(_account != address(0), "Invalid address");

        // 1. Get current balance & update questMultiplier, only if user has a balance
        Balance memory oldBalance = _balances[_account];
        uint256 oldScaledBalance = _getBalance(_account, oldBalance);
        if (oldScaledBalance > 0) {
            _applyQuestMultiplier(_account, oldBalance, oldScaledBalance, _newMultiplier);
        }
    }

    /**
     * @dev Gets the multiplier awarded for a given weightedTimestamp
     * @param _ts WeightedTimestamp of a user
     * @return timeMultiplier Ranging from 20 (0.2x) to 60 (0.6x)
     */
    function _timeMultiplier(uint32 _ts) internal view returns (uint8 timeMultiplier) {
        // If the user has no ts yet, they are not in the system
        if (_ts == 0) return 0;

        uint256 hodlLength = block.timestamp - _ts;
        if (hodlLength < 13 weeks) {
            // 0-3 months = 1x
            return 0;
        } else if (hodlLength < 26 weeks) {
            // 3 months = 1.2x
            return 20;
        } else if (hodlLength < 52 weeks) {
            // 6 months = 1.3x
            return 30;
        } else if (hodlLength < 78 weeks) {
            // 12 months = 1.4x
            return 40;
        } else if (hodlLength < 104 weeks) {
            // 18 months = 1.5x
            return 50;
        } else {
            // > 24 months = 1.6x
            return 60;
        }
    }

    function _getPriceCoeff() internal virtual returns (uint256) {
        return 10000;
    }

    /***************************************
                BALANCE CHANGES
    ****************************************/

    /**
     * @dev Adds the multiplier awarded from quest completion to a users data, taking the opportunity
     * to check time multiplier.
     * @param _account Address of user that should be updated
     * @param _newMultiplier New Quest Multiplier
     */
    function _applyQuestMultiplier(
        address _account,
        Balance memory _oldBalance,
        uint256 _oldScaledBalance,
        uint8 _newMultiplier
    ) private updateRewards(_account) {
        // 1. Set the questMultiplier
        _balances[_account].questMultiplier = _newMultiplier;

        // 2. Take the opportunity to set weighted timestamp, if it changes
        _balances[_account].timeMultiplier = _timeMultiplier(_oldBalance.weightedTimestamp);

        // 3. Update scaled balance
        _settleScaledBalance(_account, _oldScaledBalance);
    }

    /**
     * @dev Entering a cooldown period means a user wishes to withdraw. With this in mind, their balance
     * should be reduced until they have shown more commitment to the system
     * @param _account Address of user that should be cooled
     * @param _units Units to cooldown for
     */
    function _enterCooldownPeriod(address _account, uint256 _units)
        internal
        updateRewards(_account)
    {
        require(_account != address(0), "Invalid address");

        // 1. Get current balance
        (Balance memory oldBalance, uint256 oldScaledBalance) = _prepareOldBalance(_account);
        uint88 totalUnits = oldBalance.raw + oldBalance.cooldownUnits;
        require(_units > 0 && _units <= totalUnits, "Must choose between 0 and 100%");

        // 2. Set weighted timestamp and enter cooldown
        _balances[_account].timeMultiplier = _timeMultiplier(oldBalance.weightedTimestamp);
        // e.g. 1e18 / 1e16 = 100, 2e16 / 1e16 = 2, 1e15/1e16 = 0
        _balances[_account].raw = totalUnits - SafeCastExtended.toUint88(_units);

        // 3. Set cooldown data
        _balances[_account].cooldownTimestamp = SafeCastExtended.toUint32(block.timestamp);
        _balances[_account].cooldownUnits = SafeCastExtended.toUint88(_units);

        // 4. Update scaled balance
        _settleScaledBalance(_account, oldScaledBalance);
    }

    /**
     * @dev Exiting the cooldown period explicitly resets the users cooldown window and their balance
     * @param _account Address of user that should be exited
     */
    function _exitCooldownPeriod(address _account) internal updateRewards(_account) {
        require(_account != address(0), "Invalid address");

        // 1. Get current balance
        (Balance memory oldBalance, uint256 oldScaledBalance) = _prepareOldBalance(_account);

        // 2. Set weighted timestamp and exit cooldown
        _balances[_account].timeMultiplier = _timeMultiplier(oldBalance.weightedTimestamp);
        _balances[_account].raw += oldBalance.cooldownUnits;

        // 3. Set cooldown data
        _balances[_account].cooldownTimestamp = 0;
        _balances[_account].cooldownUnits = 0;

        // 4. Update scaled balance
        _settleScaledBalance(_account, oldScaledBalance);
    }

    /**
     * @dev Pokes the weightedTimestamp of a given user and checks if it entitles them
     * to a better timeMultiplier. If not, it simply reverts as there is nothing to update.
     * @param _account Address of user that should be updated
     */
    function _reviewWeightedTimestamp(address _account) internal updateRewards(_account) {
        require(_account != address(0), "Invalid address");

        // 1. Get current balance
        (Balance memory oldBalance, uint256 oldScaledBalance) = _prepareOldBalance(_account);

        // 2. Set weighted timestamp, if it changes
        uint8 newTimeMultiplier = _timeMultiplier(oldBalance.weightedTimestamp);
        require(newTimeMultiplier != oldBalance.timeMultiplier, "Nothing worth poking here");
        _balances[_account].timeMultiplier = newTimeMultiplier;

        // 3. Update scaled balance
        _settleScaledBalance(_account, oldScaledBalance);
    }

    /**
     * @dev Called to mint from raw tokens. Adds raw to a users balance, and then propagates the scaledBalance.
     * Importantly, when a user stakes more, their weightedTimestamp is reduced proportionate to their stake.
     * @param _account Address of user to credit
     * @param _rawAmount Raw amount of tokens staked
     * @param _exitCooldown Should we end any cooldown?
     */
    function _mintRaw(
        address _account,
        uint256 _rawAmount,
        bool _exitCooldown
    ) internal updateRewards(_account) {
        require(_account != address(0), "ERC20: mint to the zero address");

        // 1. Get and update current balance
        (Balance memory oldBalance, uint256 oldScaledBalance) = _prepareOldBalance(_account);
        uint88 totalRaw = oldBalance.raw + oldBalance.cooldownUnits;
        _balances[_account].raw = oldBalance.raw + SafeCastExtended.toUint88(_rawAmount);

        // 2. Exit cooldown if necessary
        if (_exitCooldown) {
            _balances[_account].raw += oldBalance.cooldownUnits;
            _balances[_account].cooldownTimestamp = 0;
            _balances[_account].cooldownUnits = 0;
        }

        // 3. Set weighted timestamp
        //  i) For new _account, set up weighted timestamp
        if (oldBalance.weightedTimestamp == 0) {
            _balances[_account].weightedTimestamp = SafeCastExtended.toUint32(block.timestamp);
            _mintScaled(_account, _getBalance(_account, _balances[_account]));
            return;
        }
        //  ii) For previous minters, recalculate time held
        //      Calc new weighted timestamp
        uint256 oldWeightedSecondsHeld = (block.timestamp - oldBalance.weightedTimestamp) *
            totalRaw;
        uint256 newSecondsHeld = oldWeightedSecondsHeld / (totalRaw + (_rawAmount / 2));
        uint32 newWeightedTs = SafeCastExtended.toUint32(block.timestamp - newSecondsHeld);
        _balances[_account].weightedTimestamp = newWeightedTs;

        uint8 timeMultiplier = _timeMultiplier(newWeightedTs);
        _balances[_account].timeMultiplier = timeMultiplier;

        // 3. Update scaled balance
        _settleScaledBalance(_account, oldScaledBalance);
    }

    /**
     * @dev Called to burn a given amount of raw tokens.
     * @param _account Address of user
     * @param _rawAmount Raw amount of tokens to remove
     * @param _exitCooldown Exit the cooldown?
     * @param _finalise Has recollateralisation happened? If so, everything is cooled down
     */
    function _burnRaw(
        address _account,
        uint256 _rawAmount,
        bool _exitCooldown,
        bool _finalise
    ) internal updateRewards(_account) {
        require(_account != address(0), "ERC20: burn from zero address");

        // 1. Get and update current balance
        (Balance memory oldBalance, uint256 oldScaledBalance) = _prepareOldBalance(_account);
        uint256 totalRaw = oldBalance.raw + oldBalance.cooldownUnits;
        // 1.1. If _finalise, move everything to cooldown
        if (_finalise) {
            _balances[_account].raw = 0;
            _balances[_account].cooldownUnits = SafeCastExtended.toUint88(totalRaw);
            oldBalance.cooldownUnits = SafeCastExtended.toUint88(totalRaw);
        }
        // 1.2. Update
        require(oldBalance.cooldownUnits >= _rawAmount, "ERC20: burn amount > balance");
        unchecked {
            _balances[_account].cooldownUnits -= SafeCastExtended.toUint88(_rawAmount);
        }

        // 2. If we are exiting cooldown, reset the balance
        if (_exitCooldown) {
            _balances[_account].raw += _balances[_account].cooldownUnits;
            _balances[_account].cooldownTimestamp = 0;
            _balances[_account].cooldownUnits = 0;
        }

        // 3. Set back scaled time
        // e.g. stake 10 for 100 seconds, withdraw 5.
        //      secondsHeld = (100 - 0) * (10 - 0.625) = 937.5
        uint256 secondsHeld = (block.timestamp - oldBalance.weightedTimestamp) *
            (totalRaw - (_rawAmount / 8));
        //      newWeightedTs = 937.5 / 100 = 93.75
        uint256 newSecondsHeld = secondsHeld / totalRaw;
        uint32 newWeightedTs = SafeCastExtended.toUint32(block.timestamp - newSecondsHeld);
        _balances[_account].weightedTimestamp = newWeightedTs;

        uint8 timeMultiplier = _timeMultiplier(newWeightedTs);
        _balances[_account].timeMultiplier = timeMultiplier;

        // 4. Update scaled balance
        _settleScaledBalance(_account, oldScaledBalance);
    }

    /***************************************
                    PRIVATE
    updateReward should already be called by now
    ****************************************/

    /**
     * @dev Fetches the balance of a given user, scales it, and also takes the opportunity
     * to check if the season has just finished between now and their last action.
     * @param _account Address of user to fetch
     * @return oldBalance struct containing all balance information
     * @return oldScaledBalance scaled balance after applying multipliers
     */
    function _prepareOldBalance(address _account)
        private
        returns (Balance memory oldBalance, uint256 oldScaledBalance)
    {
        // Get the old balance
        oldBalance = _balances[_account];
        oldScaledBalance = _getBalance(_account, oldBalance);
        // Take the opportunity to check for season finish
        _balances[_account].questMultiplier = questManager.checkForSeasonFinish(_account);
        if (hasPriceCoeff) {
            _userPriceCoeff[_account] = SafeCastExtended.toUint16(_getPriceCoeff());
        }
    }

    /**
     * @dev Settles the scaled balance of a given account. The reason this is done here, is because
     * in each of the write functions above, there is the chance that a users balance can go down,
     * requiring to burn sacled tokens. This could happen at the end of a season when multipliers are slashed.
     * This is called after updating all multipliers etc.
     * @param _account Address of user that should be updated
     * @param _oldScaledBalance Previous scaled balance of the user
     */
    function _settleScaledBalance(address _account, uint256 _oldScaledBalance) private {
        uint256 newScaledBalance = _getBalance(_account, _balances[_account]);
        if (newScaledBalance > _oldScaledBalance) {
            _mintScaled(_account, newScaledBalance - _oldScaledBalance);
        }
        // This can happen if the user moves back a time class, but is unlikely to result in a negative mint
        else {
            _burnScaled(_account, _oldScaledBalance - newScaledBalance);
        }
    }

    /**
     * @dev Propagates the minting of the tokens downwards.
     * @param _account Address of user that has minted
     * @param _amount Amount of scaled tokens minted
     */
    function _mintScaled(address _account, uint256 _amount) private {
        emit Transfer(address(0), _account, _amount);

        _afterTokenTransfer(address(0), _account, _amount);
    }

    /**
     * @dev Propagates the burning of the tokens downwards.
     * @param _account Address of user that has burned
     * @param _amount Amount of scaled tokens burned
     */
    function _burnScaled(address _account, uint256 _amount) private {
        emit Transfer(_account, address(0), _amount);

        _afterTokenTransfer(_account, address(0), _amount);
    }

    /***************************************
                    HOOKS
    ****************************************/

    /**
     * @dev Triggered after a user claims rewards from the HeadlessStakingRewards. Used
     * to check for season finish. If it has not, then do not spend gas updating the other vars.
     * @param _account Address of user that has burned
     */
    function _claimRewardHook(address _account) internal override {
        uint8 newMultiplier = questManager.checkForSeasonFinish(_account);
        bool priceCoeffChanged = hasPriceCoeff
            ? _getPriceCoeff() != _userPriceCoeff[_account]
            : false;
        if (newMultiplier != _balances[_account].questMultiplier || priceCoeffChanged) {
            // 1. Get current balance & trigger season finish
            uint256 oldScaledBalance = _getBalance(_account, _balances[_account]);
            _balances[_account].questMultiplier = newMultiplier;
            if (priceCoeffChanged) {
                _userPriceCoeff[_account] = SafeCastExtended.toUint16(_getPriceCoeff());
            }
            // 3. Update scaled balance
            _settleScaledBalance(_account, oldScaledBalance);
        }
    }

    /**
     * @dev Unchanged from OpenZeppelin. Used in child contracts to react to any balance changes.
     */
    function _afterTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual {}

    /***************************************
                    Utils
    ****************************************/

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint256 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

    uint256[46] private __gap;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

interface IGovernanceHook {
    function moveVotingPowerHook(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

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
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastExtended {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(
            value >= type(int128).min && value <= type(int128).max,
            "SafeCast: value doesn't fit in 128 bits"
        );
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(
            value >= type(int64).min && value <= type(int64).max,
            "SafeCast: value doesn't fit in 64 bits"
        );
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(
            value >= type(int32).min && value <= type(int32).max,
            "SafeCast: value doesn't fit in 32 bits"
        );
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(
            value >= type(int16).min && value <= type(int16).max,
            "SafeCast: value doesn't fit in 16 bits"
        );
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(
            value >= type(int8).min && value <= type(int8).max,
            "SafeCast: value doesn't fit in 8 bits"
        );
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface ILockedERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

// Internal
import { InitializableRewardsDistributionRecipient } from "../InitializableRewardsDistributionRecipient.sol";
import { StableMath } from "../../shared/StableMath.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

// Libs
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title  HeadlessStakingRewards
 * @author mStable
 * @notice Rewards stakers of a given LP token with REWARDS_TOKEN, on a pro-rata basis
 * @dev Forked from `StakingRewards.sol`
 *      Changes:
 *          - `pendingAdditionalReward` added to support accumulation of any extra staking token
 *          - Removal of `StakingTokenWrapper`, instead, deposits and withdrawals are made in child contract,
 *            and balances are read from there through the abstract functions
 */
abstract contract HeadlessStakingRewards is
    ContextUpgradeable,
    InitializableRewardsDistributionRecipient
{
    using SafeERC20 for IERC20;
    using StableMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice tokens the rewards are distributed in.
    IERC20[] public rewardTokens;
    IERC20 public immutable embr;

    // Constants
    uint256 private constant maxActiveRewardTokens = 10;
    uint256 private constant WEEK = 7 days;
    uint256 private constant redemptionIndex = 2**256 - 1;

    /// @notice List of tokens supported by the protocol
    EnumerableSet.AddressSet private rewardTokenAddresses;
    uint256 public override activeTokenCount = 0; 

    /// @notice length of each staking period in seconds. 7 days = 604,800; 3 months = 7,862,400
    uint256 public constant DURATION = 1 weeks;

    struct Data {
        /// Timestamp for current period finish
        uint32 periodFinish;
        /// Last time any user took action
        uint32 lastUpdateTime;
        /// RewardRate for the rest of the period
        uint96 rewardRate;
        /// Ever increasing rewardPerToken rate, based on % of total supply
        uint96 rewardPerTokenStored;
    }

    struct UserData {
        uint128 rewardPerTokenPaid;
        uint128 rewards;
        uint128 rewardsPaid;
    }

    struct RewardInfo { 
        uint256 current;
        uint256 last;
        uint256 expiry;
    }

    /// @notice list of active and expire index's for reward tokens.
    mapping(uint256 => RewardInfo) public activeRewardInfo;
    mapping(uint256 => Data) public globalData;
    mapping(uint256 => mapping(address => UserData)) public userData;
    mapping(uint256 => uint256) public pendingAdditionalReward;

    event RewardAdded(uint256 reward, address indexed rewardToken);
    event RewardPaid(address indexed user, address indexed to, address indexed rewardToken, uint256 reward);
    event LogTokenAddition(uint256 indexed rtid, address indexed rewardToken);
    event LogTokenUpdate(address indexed lastAddress, uint256 expiry, address indexed newAddress, uint256 newIndex);


    /**
     * @param _fulcrum mStable system Fulcrum address
     */
    constructor(address _fulcrum, address _embrAddress)
        InitializableRewardsDistributionRecipient(_fulcrum)
    {
        embr = IERC20(_embrAddress);
    }

    /**
     * @dev Initialization function for upgradable proxy contract.
     *      This function should be called via Proxy just after contract deployment.
     *      To avoid variable shadowing appended `Arg` after arguments name.
     * @param _rewardsDistributorArg mStable Reward Distributor contract address
     */
    function _initialize(address _rewardsDistributorArg) internal virtual override {
        InitializableRewardsDistributionRecipient._initialize(_rewardsDistributorArg);
    }

    /**
     * @dev Adds new reward token if max reward tokens not exceeded.
     */
    function add(address _rewardTokens) 
        external 
        onlyRewardsDistributor 
    {
        require(
            !rewardTokenAddresses.contains(_rewardTokens),
            "add: Reward Token already added"
        );
        require(
            activeTokenCount < 10, 
            "add: Max tokens"
        );

        IERC20 feeToken = IERC20(_rewardTokens);
        
        rewardTokens.push(feeToken);
        RewardInfo memory init = RewardInfo({
            current: rewardTokens.length - 1,
            last: 0,
            expiry: 0
        });

        activeRewardInfo[rewardTokens.length - 1] = init;
        rewardTokenAddresses.add(_rewardTokens);
        activeTokenCount++;
        
        emit LogTokenAddition(
            rewardTokens.length,
            _rewardTokens
        );
    }

    /**
     * @dev Updates existing active token index to new reward token.
     *      Adds to rewardTokens index if doesn't exist, otherwise
     *      reuses expires token
     */
    function update(
        uint256 _id, 
        address _rewardToken,
        uint256 _index
    ) external onlyRewardsDistributor {
        RewardInfo memory rToken = activeRewardInfo[_id];
        uint256 currentTime = block.timestamp;
        
        require(currentTime >= rToken.expiry, "update: previous not expired");

        uint256 last = rToken.current;
        uint256 current = 0;
        address previousAddress = address(rewardTokens[_id]);
        if(rewardTokenAddresses.contains(_rewardToken)) { 
            require(address(rewardTokens[_index]) == _rewardToken, "update: token does not match index");
            current = _index;
        } else { 
            IERC20 feeToken = IERC20(_rewardToken);
            rewardTokens.push(feeToken);
            rewardTokenAddresses.add(_rewardToken);

            current = rewardTokens.length;

            emit LogTokenAddition(
                current,
                _rewardToken
            );
        }
        
        rToken.last = last;
        rToken.current = current;
        rToken.expiry = block.timestamp + WEEK;
        activeRewardInfo[_id] = rToken;

        emit LogTokenUpdate(previousAddress, rToken.expiry, _rewardToken, rewardTokens.length);
    }

    /** @dev Updates the reward for a given address, before executing function */
    modifier updateReward(uint256 _tid, address _account) {
        _updateReward(_tid, _account);
        _;
    }

    /** @dev Updates the rewards for a given address, before executing function */
    modifier updateRewards(address _account) {
        _updateReward(redemptionIndex, _account);
        for(uint256 i = 0; i < activeTokenCount; i++) {
            _updateReward(i, _account);
        }
        _;
    }

    function _updateReward(uint256 _tid, address _account) internal {
        // Setting of global vars
        uint256 currentIndex = _tid == redemptionIndex ? redemptionIndex : activeRewardInfo[_tid].current;
        (uint256 newRewardPerToken, uint256 lastApplicableTime) = _rewardPerToken(currentIndex);
        // If statement protects against loss in initialisation case
        if (newRewardPerToken > 0) {
            globalData[currentIndex].rewardPerTokenStored = SafeCast.toUint96(newRewardPerToken);
            globalData[currentIndex].lastUpdateTime = SafeCast.toUint32(lastApplicableTime);

            // Setting of personal vars based on new globals
            if (_account != address(0)) {
                userData[currentIndex][_account] = UserData({
                    rewardPerTokenPaid: SafeCast.toUint128(newRewardPerToken),
                    rewards: SafeCast.toUint128(_earned(currentIndex, _account, newRewardPerToken)),
                    rewardsPaid: userData[currentIndex][_account].rewardsPaid
                });

            }
        }
    }

    /***************************************
                    ACTIONS
    ****************************************/

    /**
     * @dev Claims outstanding rewards for the sender.
     * First updates outstanding reward allocation and then transfers.
     */
    function claimReward(uint256 _tid, address _to) public {
        _claimReward(_tid, _to);
    }

    /**
     * @dev Claims outstanding rewards for the sender.
     * First updates outstanding reward allocation and then transfers.
     */
     function claimReward(uint256 _tid) public {
        _claimReward(_tid, _msgSender());
    }

    /**
     * @dev Claims outstanding rewards for the sender.
     * First updates outstanding reward allocation and then transfers.
     */
    function claimRedemptionReward() public {
        _claimRedemptionRewards(_msgSender());
    }

    /**
     * @dev Claims outstanding rewards for the sender.
     * First updates outstanding reward allocation and then transfers.
     */
    function claimExpiredReward(uint256 _tid) public {
        _claimExpiredReward(_tid, _msgSender());
    }

    /**
     * @dev Claims outstanding rewards for the sender for all reward tokens.
     * First updates outstanding reward allocation and then transfers.
     */
    function claimRewards() 
        public  
        updateRewards(_msgSender()) 
    {
        _claimRewards(_msgSender());
    }

    function _claimRewards(address sender) 
        private 
    {
        _claimRedemptionRewards(sender);
        for (uint256 i = 0; i < activeTokenCount; i++) {
           _claimReward(i, sender);
        }
    }

    function _claimExpiredReward(
        uint256 _tid, 
        address sender
    ) 
        private 
    {
        require(activeRewardInfo[_tid].expiry > block.timestamp, "claimExpiredReward: time expired");

        uint256 currentIndex = activeRewardInfo[_tid].last;
        (uint256 newRewardPerToken, uint256 lastApplicableTime) = _rewardPerToken(currentIndex);
        // If statement protects against loss in initialisation case
        if (newRewardPerToken > 0) {
            globalData[currentIndex].rewardPerTokenStored = SafeCast.toUint96(newRewardPerToken);
            globalData[currentIndex].lastUpdateTime = SafeCast.toUint32(lastApplicableTime);

            // Setting of personal vars based on new globals
            if (sender != address(0)) {
                userData[currentIndex][sender] = UserData({
                    rewardPerTokenPaid: SafeCast.toUint128(newRewardPerToken),
                    rewards: SafeCast.toUint128(_earned(currentIndex, sender, newRewardPerToken)),
                    rewardsPaid: userData[currentIndex][sender].rewardsPaid
                });

            }
        }

        uint256 reward = userData[currentIndex][sender].rewards;
        if (reward > 0) {
            userData[currentIndex][sender].rewards = 0;
            embr.safeTransfer(sender, reward);
            userData[currentIndex][sender].rewardsPaid =  userData[currentIndex][sender].rewardsPaid + SafeCast.toUint128(reward);

            emit RewardPaid(sender, sender, address(rewardTokens[currentIndex]), reward);
        }     
    }


    function _claimRedemptionRewards(address _to) private { 
        uint256 redemptionReward = userData[redemptionIndex][_msgSender()].rewards;
        if (redemptionReward > 0) {
            userData[redemptionIndex][_msgSender()].rewards = 0;
            embr.safeTransfer(_to, redemptionReward);
            userData[redemptionIndex][_msgSender()].rewardsPaid =  userData[redemptionIndex][_msgSender()].rewardsPaid + SafeCast.toUint128(redemptionReward);

            emit RewardPaid(_to, _to, address(embr), redemptionReward);
        }
    }

    function _claimReward(uint256 _tid, address _to) internal updateReward(_tid, _msgSender()) {
        uint128 reward = userData[_tid][_msgSender()].rewards;
        uint256 currentIndex = _tid == redemptionIndex ? redemptionIndex : activeRewardInfo[_tid].current;
        if (reward > 0) {
            userData[currentIndex][_msgSender()].rewards = 0;
            rewardTokens[currentIndex].safeTransfer(_to, reward);
            userData[currentIndex][_msgSender()].rewardsPaid =  userData[currentIndex][_msgSender()].rewardsPaid + reward;

            emit RewardPaid(_to, _to,address(rewardTokens[currentIndex]), reward);
        }
        _claimRewardHook(_msgSender());
    }

    /***************************************
                    GETTERS
    ****************************************/

    /**
     * @dev Gets the RewardsToken
     */
    function getActiveIndex(uint256 _tid) external view override returns (uint256) {
        return activeRewardInfo[_tid].current;
    }

    /**
     * @dev Gets the RewardsToken
     */
    function getRewardToken(uint256 _tid) external view override returns (IERC20) {
        return rewardTokens[_tid];
    }

    //function getRewardToken() external view override returns (IERC20) {
    //    return REWARDS_TOKEN;
    //}

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function lastTimeRewardApplicable(uint256 _tid) public view returns (uint256) {
        uint256 currentIndex = _tid == redemptionIndex ? redemptionIndex : activeRewardInfo[_tid].current;
        return StableMath.min(block.timestamp, globalData[currentIndex].periodFinish);
    }

    /**
     * @dev Gets the last applicable timestamp for this reward period
     */
    function _lastTimeRewardApplicable(uint32 _periodFinish) internal view returns (uint256) {
        return StableMath.min(block.timestamp, _periodFinish);
    }

    /**
     * @dev Calculates the amount of unclaimed rewards per token since last update,
     * and sums with stored to give the new cumulative reward per token
     * @return 'Reward' per staked token
     */
    function rewardPerToken(uint256 _tid) public view returns (uint256) {
        uint256 currentIndex = _tid == redemptionIndex ? redemptionIndex : activeRewardInfo[_tid].current;
        (uint256 rewardPerToken_, ) = _rewardPerToken(currentIndex);
        return rewardPerToken_;
    }

    function _rewardPerToken(uint256 _tid)
        internal
        view
        returns (uint256 rewardPerToken_, uint256 lastTimeRewardApplicable_)
    {
        Data memory data = globalData[_tid];
        uint256 lastApplicableTime = _lastTimeRewardApplicable(data.periodFinish); // + 1 SLOAD

        uint256 timeDelta = lastApplicableTime - data.lastUpdateTime; // + 1 SLOAD
        // If this has been called twice in the same block, shortcircuit to reduce gas
        if (timeDelta == 0) {
            return (data.rewardPerTokenStored, lastApplicableTime);
        }
        // new reward units to distribute = rewardRate * timeSinceLastUpdate
        uint256 rewardUnitsToDistribute = data.rewardRate * timeDelta; // + 1 SLOAD
        uint256 supply = totalSupply(); // + 1 SLOAD
        // If there is no StakingToken liquidity, avoid div(0)
        // If there is nothing to distribute, short circuit
        if (supply == 0 || rewardUnitsToDistribute == 0) {
            return (data.rewardPerTokenStored, lastApplicableTime);
        }
        // new reward units per token = (rewardUnitsToDistribute * 1e18) / totalTokens
        uint256 unitsToDistributePerToken = rewardUnitsToDistribute.divPrecisely(supply);
        // return summed rate
        return (data.rewardPerTokenStored + unitsToDistributePerToken, lastApplicableTime); // + 1 SLOAD
    }

    /**
     * @dev Calculates the amount of unclaimed rewards a user has earned
     * @param _account User address
     * @return Total reward amount earned
     */
    function earned(uint256 _tid, address _account) public view returns (uint256) {
        uint256 currentIndex = _tid == redemptionIndex ? redemptionIndex : activeRewardInfo[_tid].current;
        return _earned(currentIndex, _account, rewardPerToken(currentIndex));
    }

    function _earned(uint256 _currentIndex, address _account, uint256 _currentRewardPerToken)
        internal
        view
        returns (uint256)
    {
        // current rate per token - rate user previously received
        uint256 userRewardDelta = _currentRewardPerToken - userData[_currentIndex][_account].rewardPerTokenPaid; // + 1 SLOAD
        // Short circuit if there is nothing new to distribute
        if (userRewardDelta == 0) {
            return userData[_currentIndex][_account].rewards;
        }
        // new reward = staked tokens * difference in rate
        uint256 userNewReward = balanceOf(_account).mulTruncate(userRewardDelta); // + 1 SLOAD
        // add to previous rewards
        return userData[_currentIndex][_account].rewards + userNewReward;
    }

    /***************************************
                    ABSTRACT
    ****************************************/

    function balanceOf(address account) public view virtual returns (uint256);

    function totalSupply() public view virtual returns (uint256);

    function _claimRewardHook(address account) internal virtual;

    /***************************************
                    ADMIN
    ****************************************/

    /**
     * @dev Notifies the contract that new rewards have been added.
     * Calculates an updated rewardRate based on the rewards in period.
     * @param _reward Units of RewardToken that have been added to the pool
     */
    function notifyRewardAmount(uint256 _tid, uint256 _reward)
        external
        override
        onlyRewardsDistributor
        updateReward(_tid, address(0))
    {
        uint256 currentTime = block.timestamp;
        uint256 currentIndex = _tid;
        require(_tid + 1 <= rewardTokens.length, "Outside of index");

        // Pay and reset the pendingAdditionalRewards
        if (pendingAdditionalReward[currentIndex] > 1) {
            _reward += (pendingAdditionalReward[currentIndex] - 1);
            pendingAdditionalReward[currentIndex] = 1;
        }

        // If previous period over, reset rewardRate
        if (currentTime >= globalData[currentIndex].periodFinish) {
            globalData[currentIndex].rewardRate = SafeCast.toUint96(_reward / DURATION);
        }
        // If additional reward to existing period, calc sum
        else {
            uint256 remainingSeconds = globalData[currentIndex].periodFinish - currentTime;
            uint256 leftover = remainingSeconds * globalData[currentIndex].rewardRate;
            globalData[currentIndex].rewardRate = SafeCast.toUint96((_reward + leftover) / DURATION);
        }

        globalData[currentIndex].lastUpdateTime = SafeCast.toUint32(currentTime);
        globalData[currentIndex].periodFinish = SafeCast.toUint32(currentTime + DURATION);

        address rewardTknAddress = _tid == redemptionIndex ? address(embr) : address(rewardTokens[currentIndex]);
        emit RewardAdded(_reward, rewardTknAddress);
    }

    /**
     * @dev Called by the child contract to notify of any additional rewards that have accrued.
     *      Trusts that this is called honestly.
     * @param _tid token index of additional rewards
     * @param _additionalReward Units of additional RewardToken to add at the next notification
     */
    function _notifyAdditionalReward(uint256 _tid, uint256 _additionalReward) internal virtual {
        require(_additionalReward < 1e24, "Cannot notify with more than a million units");

        pendingAdditionalReward[_tid] += _additionalReward;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import "../deps/xEmbrStructs.sol";

interface IQuestManager {
    event QuestAdded(
        address questMaster,
        uint256 id,
        QuestType model,
        uint16 multiplier,
        QuestStatus status,
        uint32 expiry
    );
    event QuestCompleteQuests(address indexed user, uint256[] ids);
    event QuestCompleteUsers(uint256 indexed questId, address[] accounts);
    event QuestExpired(uint16 indexed id);
    event QuestMaster(address oldQuestMaster, address newQuestMaster);
    event QuestSeasonEnded();
    event QuestSigner(address oldQuestSigner, address newQuestSigner);
    event StakedTokenAdded(address stakedToken);

    // GETTERS
    function balanceData(address _account) external view returns (QuestBalance memory);

    function getQuest(uint256 _id) external view returns (Quest memory);

    function hasCompleted(address _account, uint256 _id) external view returns (bool);

    function questMaster() external view returns (address);

    function seasonEpoch() external view returns (uint32);

    // ADMIN
    function addQuest(
        QuestType _model,
        uint8 _multiplier,
        uint32 _expiry
    ) external;

    function addStakedToken(address _stakedToken) external;

    function expireQuest(uint16 _id) external;

    function setQuestMaster(address _newQuestMaster) external;

    function setQuestSigner(address _newQuestSigner) external;

    function startNewQuestSeason() external;

    // USER
    function completeUserQuests(
        address _account,
        uint256[] memory _ids,
        bytes calldata _signature
    ) external;

    function completeQuestUsers(
        uint256 _questId,
        address[] memory _accounts,
        bytes calldata _signature
    ) external;

    function checkForSeasonFinish(address _account) external returns (uint8 newQuestMultiplier);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ImmutableModule } from "../shared/ImmutableModule.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IRewardsDistributionRecipient } from "../interfaces/IRewardsDistributionRecipient.sol";

/**
 * @title  RewardsDistributionRecipient
 * @author Originally: Synthetix (forked from /Synthetixio/synthetix/contracts/RewardsDistributionRecipient.sol)
 *         Changes by: mStable
 * @notice RewardsDistributionRecipient gets notified of additional rewards by the rewardsDistributor
 * @dev    Changes: Addition of Module and abstract `getRewardToken` func + cosmetic
 */
abstract contract InitializableRewardsDistributionRecipient is
    IRewardsDistributionRecipient,
    ImmutableModule
{
    // This address has the ability to distribute the rewards
    address public rewardsDistributor;

    constructor(address _fulcrum) ImmutableModule(_fulcrum) {}

    /** @dev Recipient is a module, governed by mStable governance */
    function _initialize(address _rewardsDistributor) internal virtual {
        rewardsDistributor = _rewardsDistributor;
    }

    /**
     * @dev Only the rewards distributor can notify about rewards
     */
    modifier onlyRewardsDistributor() {
        require(msg.sender == rewardsDistributor, "Caller is not reward distributor");
        _;
    }

    /**
     * @dev Change the rewardsDistributor - only called by mStable governor
     * @param _rewardsDistributor   Address of the new distributor
     */
    function setRewardsDistribution(address _rewardsDistributor) external onlyGovernor {
        rewardsDistributor = _rewardsDistributor;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title   StableMath
 * @author  mStable
 * @notice  A library providing safe mathematical operations to multiply and
 *          divide with standardised precision.
 * @dev     Derives from OpenZeppelin's SafeMath lib and uses generic system
 *          wide variables for managing precision.
 */
library StableMath {
    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @dev Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x) internal pure returns (uint256) {
        return x * FULL_SCALE;
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(
        uint256 x,
        uint256 y,
        uint256 scale
    ) internal pure returns (uint256) {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        // return 9e36 / 1e18 = 9e18
        return (x * y) / scale;
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x * y;
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled + FULL_SCALE - 1;
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil / FULL_SCALE;
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y) internal pure returns (uint256) {
        // e.g. 8e18 * 1e18 = 8e36
        // e.g. 8e36 / 10e18 = 8e17
        return (x * FULL_SCALE) / y;
    }

    /***************************************
                  RATIO FUNCS
    ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio) internal pure returns (uint256) {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x * ratio;
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled + RATIO_SCALE - 1;
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil / RATIO_SCALE;
    }

    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return c    Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio) internal pure returns (uint256 c) {
        // e.g. 1e14 * 1e8 = 1e22
        // return 1e22 / 1e12 = 1e10
        return (x * RATIO_SCALE) / ratio;
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y) internal pure returns (uint256) {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound) internal pure returns (uint256) {
        return x > upperBound ? upperBound : x;
    }
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
library EnumerableSet {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { ModuleKeys } from "./ModuleKeys.sol";
import { IFulcrum } from "../interfaces/IFulcrum.sol";

/**
 * @title   ImmutableModule
 * @author  mStable
 * @dev     Subscribes to module updates from a given publisher and reads from its registry.
 *          Contract is used for upgradable proxy contracts.
 */
abstract contract ImmutableModule is ModuleKeys {
    IFulcrum public immutable fulcrum;

    /**
     * @dev Initialization function for upgradable proxy contracts
     * @param _fulcrum Fulcrum contract address
     */
    constructor(address _fulcrum) {
        require(_fulcrum != address(0), "Fulcrum address is zero");
        fulcrum = IFulcrum(_fulcrum);
    }

    /**
     * @dev Modifier to allow function calls only from the Governor.
     */
    modifier onlyGovernor() {
        _onlyGovernor();
        _;
    }

    function _onlyGovernor() internal view {
        require(msg.sender == _governor(), "Only governor can execute");
    }

    /**
     * @dev Modifier to allow function calls only from the Governor or the Keeper EOA.
     */
    modifier onlyKeeperOrGovernor() {
        _keeperOrGovernor();
        _;
    }

    function _keeperOrGovernor() internal view {
        require(msg.sender == _keeper() || msg.sender == _governor(), "Only keeper or governor");
    }

    /**
     * @dev Modifier to allow function calls only from the Governance.
     *      Governance is either Governor address or Governance address.
     */
    modifier onlyGovernance() {
        require(
            msg.sender == _governor() || msg.sender == _governance(),
            "Only governance can execute"
        );
        _;
    }

    /**
     * @dev Returns Governor address from the Fulcrum
     * @return Address of Governor Contract
     */
    function _governor() internal view returns (address) {
        return fulcrum.governor();
    }

    /**
     * @dev Returns Governance Module address from the Fulcrum
     * @return Address of the Governance (Phase 2)
     */
    function _governance() internal view returns (address) {
        return fulcrum.getModule(KEY_GOVERNANCE);
    }

    /**
     * @dev Return Keeper address from the Fulcrum.
     *      This account is used for operational transactions that
     *      don't need multiple signatures.
     * @return  Address of the Keeper externally owned account.
     */
    function _keeper() internal view returns (address) {
        return fulcrum.getModule(KEY_KEEPER);
    }

    /**
     * @dev Return ProxyAdmin Module address from the Fulcrum
     * @return Address of the ProxyAdmin Module contract
     */
    function _proxyAdmin() internal view returns (address) {
        return fulcrum.getModule(KEY_PROXY_ADMIN);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsDistributionRecipient {
    function notifyRewardAmount(uint256 _tid, uint256 reward) external;

    function getRewardToken(uint256 _tid) external view returns (IERC20);

    function getActiveIndex(uint256 _tid) external view returns (uint256);

    function activeTokenCount() external view returns (uint256);
}

interface IRewardsRecipientWithPlatformToken {
    function notifyRewardAmount(uint256 _tid, uint256 reward) external;

    function getRewardToken(uint256 _tid) external view returns (IERC20);

    function getActiveIndex(uint256 _tid) external view returns (uint256);

    function getPlatformToken() external view returns (IERC20);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title  ModuleKeys
 * @author mStable
 * @notice Provides system wide access to the byte32 represntations of system modules
 *         This allows each system module to be able to reference and update one another in a
 *         friendly way
 * @dev    keccak256() values are hardcoded to avoid re-evaluation of the constants at runtime.
 */
contract ModuleKeys {
    // Governance
    // ===========
    // keccak256("Governance");
    bytes32 internal constant KEY_GOVERNANCE =
        0x9409903de1e6fd852dfc61c9dacb48196c48535b60e25abf92acc92dd689078d;
    //keccak256("Staking");
    bytes32 internal constant KEY_STAKING =
        0x1df41cd916959d1163dc8f0671a666ea8a3e434c13e40faef527133b5d167034;
    //keccak256("ProxyAdmin");
    bytes32 internal constant KEY_PROXY_ADMIN =
        0x96ed0203eb7e975a4cbcaa23951943fa35c5d8288117d50c12b3d48b0fab48d1;

    // mStable
    // =======
    // keccak256("OracleHub");
    bytes32 internal constant KEY_ORACLE_HUB =
        0x8ae3a082c61a7379e2280f3356a5131507d9829d222d853bfa7c9fe1200dd040;
    // keccak256("Manager");
    bytes32 internal constant KEY_MANAGER =
        0x6d439300980e333f0256d64be2c9f67e86f4493ce25f82498d6db7f4be3d9e6f;
    //keccak256("Recollateraliser");
    bytes32 internal constant KEY_RECOLLATERALISER =
        0x39e3ed1fc335ce346a8cbe3e64dd525cf22b37f1e2104a755e761c3c1eb4734f;
    //keccak256("MetaToken");
    bytes32 internal constant KEY_META_TOKEN =
        0xea7469b14936af748ee93c53b2fe510b9928edbdccac3963321efca7eb1a57a2;
    // keccak256("SavingsManager");
    bytes32 internal constant KEY_SAVINGS_MANAGER =
        0x12fe936c77a1e196473c4314f3bed8eeac1d757b319abb85bdda70df35511bf1;
    // keccak256("Liquidator");
    bytes32 internal constant KEY_LIQUIDATOR =
        0x1e9cb14d7560734a61fa5ff9273953e971ff3cd9283c03d8346e3264617933d4;
    // keccak256("InterestValidator");
    bytes32 internal constant KEY_INTEREST_VALIDATOR =
        0xc10a28f028c7f7282a03c90608e38a4a646e136e614e4b07d119280c5f7f839f;
    // keccak256("Keeper");
    bytes32 internal constant KEY_KEEPER =
        0x4f78afe9dfc9a0cb0441c27b9405070cd2a48b490636a7bdd09f355e33a5d7de;
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IFulcrum
 * @dev Basic interface for interacting with the Fulcrum i.e. SystemKernel
 */
interface IFulcrum {
    function governor() external view returns (address);

    function getModule(bytes32 key) external view returns (address);

    function proposeModule(bytes32 _key, address _addr) external;

    function cancelProposedModule(bytes32 _key) external;

    function acceptProposedModule(bytes32 _key) external;

    function acceptProposedModules(bytes32[] calldata _keys) external;

    function requestLockModule(bytes32 _key) external;

    function cancelLockModule(bytes32 _key) external;

    function lockModule(bytes32 _key) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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