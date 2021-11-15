// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../interfaces/IReign.sol";
import "../libraries/LibReignStorage.sol";
import "diamond-libraries/contracts/libraries/LibOwnership.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReignFacet {
    using SafeMath for uint256;

    uint256 public constant MAX_LOCK = 365 days * 2; //two years
    uint256 public constant BASE_STAKE_MULTIPLIER = 1 * 10**18;
    uint128 public constant BASE_BALANCE_MULTIPLIER = uint128(1 * 10**18);

    mapping(uint128 => bool) private _isInitialized;
    mapping(uint128 => uint256) private _initialisedAt;
    mapping(address => uint256) private _balances;

    event Deposit(address indexed user, uint256 amount, uint256 newBalance);
    event Withdraw(
        address indexed user,
        uint256 amountWithdrew,
        uint256 amountLeft
    );
    event Lock(address indexed user, uint256 timestamp);
    event Delegate(address indexed from, address indexed to);
    event DelegatedPowerIncreased(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 to_newDelegatedPower
    );
    event DelegatedPowerDecreased(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 to_newDelegatedPower
    );
    event InitEpoch(address indexed caller, uint128 indexed epochId);

    function initReign(
        address _reignToken,
        uint256 _epoch1Start,
        uint256 _epochDuration
    ) public {
        require(
            _reignToken != address(0),
            "Reign Token address must not be 0x0"
        );

        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();

        require(!ds.initialized, "Reign: already initialized");
        LibOwnership.enforceIsContractOwner();

        ds.initialized = true;

        ds.reign = IERC20(_reignToken);
        ds.epoch1Start = _epoch1Start;
        ds.epochDuration = _epochDuration;
    }

    // deposit allows a user to add more reign to his staked balance
    function deposit(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");

        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        uint256 allowance = ds.reign.allowance(msg.sender, address(this));
        require(allowance >= amount, "Token allowance too small");

        _balances[msg.sender] = _balances[msg.sender].add(amount);

        _updateStake(ds.userStakeHistory[msg.sender], _balances[msg.sender]);
        _increaseEpochBalance(ds.userBalanceHistory[msg.sender], amount);
        _updateLockedReign(reignStaked().add(amount));

        address delegatedTo = userDelegatedTo(msg.sender);
        if (delegatedTo != address(0)) {
            uint256 newDelegatedPower = delegatedPower(delegatedTo).add(amount);
            _updateDelegatedPower(
                ds.delegatedPowerHistory[delegatedTo],
                newDelegatedPower
            );

            emit DelegatedPowerIncreased(
                msg.sender,
                delegatedTo,
                amount,
                newDelegatedPower
            );
        }

        ds.reign.transferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount, _balances[msg.sender]);
    }

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(
            userLockedUntil(msg.sender) <= block.timestamp,
            "User balance is locked"
        );

        uint256 balance = balanceOf(msg.sender);
        require(balance >= amount, "Insufficient balance");

        _balances[msg.sender] = balance.sub(amount);

        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();

        _updateStake(ds.userStakeHistory[msg.sender], _balances[msg.sender]);
        _decreaseEpochBalance(ds.userBalanceHistory[msg.sender], amount);
        _updateLockedReign(reignStaked().sub(amount));

        address delegatedTo = userDelegatedTo(msg.sender);
        if (delegatedTo != address(0)) {
            uint256 newDelegatedPower = delegatedPower(delegatedTo).sub(amount);
            _updateDelegatedPower(
                ds.delegatedPowerHistory[delegatedTo],
                newDelegatedPower
            );

            emit DelegatedPowerDecreased(
                msg.sender,
                delegatedTo,
                amount,
                newDelegatedPower
            );
        }

        ds.reign.transfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, balance.sub(amount));
    }

    // lock a user's currently staked balance until timestamp
    function lock(uint256 timestamp) public {
        require(timestamp > block.timestamp, "Timestamp must be in the future");
        require(timestamp <= block.timestamp + MAX_LOCK, "Timestamp too big");
        require(balanceOf(msg.sender) > 0, "Sender has no balance");

        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        LibReignStorage.Stake[] storage checkpoints = ds.userStakeHistory[
            msg.sender
        ];
        LibReignStorage.Stake storage currentStake = checkpoints[
            checkpoints.length - 1
        ];
        if (!epochIsInitialized(getEpoch())) {
            _initEpoch(getEpoch());
        }

        require(
            timestamp > currentStake.expiryTimestamp,
            "New timestamp lower than current lock timestamp"
        );

        _updateUserLock(checkpoints, timestamp);

        emit Lock(msg.sender, timestamp);
    }

    function depositAndLock(uint256 amount, uint256 timestamp) public {
        deposit(amount);
        lock(timestamp);
    }

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) public {
        require(msg.sender != to, "Can't delegate to self");

        uint256 senderBalance = balanceOf(msg.sender);
        require(senderBalance > 0, "No balance to delegate");

        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();

        emit Delegate(msg.sender, to);

        address delegatedTo = userDelegatedTo(msg.sender);
        if (delegatedTo != address(0)) {
            uint256 newDelegatedPower = delegatedPower(delegatedTo).sub(
                senderBalance
            );
            _updateDelegatedPower(
                ds.delegatedPowerHistory[delegatedTo],
                newDelegatedPower
            );

            emit DelegatedPowerDecreased(
                msg.sender,
                delegatedTo,
                senderBalance,
                newDelegatedPower
            );
        }

        if (to != address(0)) {
            uint256 newDelegatedPower = delegatedPower(to).add(senderBalance);
            _updateDelegatedPower(
                ds.delegatedPowerHistory[to],
                newDelegatedPower
            );

            emit DelegatedPowerIncreased(
                msg.sender,
                to,
                senderBalance,
                newDelegatedPower
            );
        }

        _updateUserDelegatedTo(ds.userStakeHistory[msg.sender], to);
    }

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() public {
        return delegate(address(0));
    }

    /*
     *   VIEWS
     */

    // balanceOf returns the current REIGN balance of a user (bonus not included)
    function balanceOf(address user) public view returns (uint256) {
        return _balances[user];
    }

    // balanceAtTs returns the amount of REIGN that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        LibReignStorage.Stake memory stake = stakeAtTs(user, timestamp);

        return stake.amount;
    }

    // balanceAtTs returns the amount of REIGN that the user currently staked (bonus NOT included)
    function getEpochUserBalance(address user, uint128 epochId)
        public
        view
        returns (uint256)
    {
        LibReignStorage.EpochBalance memory epochBalance = balanceCheckAtEpoch(
            user,
            epochId
        );

        return getEpochEffectiveBalance(epochBalance);
    }

    // this returns the effective balance accounting for user entering the pool after epoch start
    function getEpochEffectiveBalance(LibReignStorage.EpochBalance memory c)
        internal
        pure
        returns (uint256)
    {
        return
            _getEpochBalance(c).mul(c.multiplier).div(BASE_BALANCE_MULTIPLIER);
    }

    // balanceCheckAtEpoch returns the EpochBalance checkpoint object of the user that was valid at epoch
    function balanceCheckAtEpoch(address user, uint128 epochId)
        public
        view
        returns (LibReignStorage.EpochBalance memory)
    {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        LibReignStorage.EpochBalance[] storage balanceHistory = ds
            .userBalanceHistory[user];

        if (balanceHistory.length == 0 || epochId < balanceHistory[0].epochId) {
            return
                LibReignStorage.EpochBalance(
                    epochId,
                    BASE_BALANCE_MULTIPLIER,
                    0,
                    0
                );
        }

        uint256 min = 0;
        uint256 max = balanceHistory.length - 1;

        if (epochId >= balanceHistory[max].epochId) {
            return balanceHistory[max];
        }

        // binary search of the value in the array
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (balanceHistory[mid].epochId <= epochId) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return balanceHistory[min];
    }

    // balanceCheckAtEpoch returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp)
        public
        view
        returns (LibReignStorage.Stake memory)
    {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        LibReignStorage.Stake[] storage stakeHistory = ds.userStakeHistory[
            user
        ];

        if (stakeHistory.length == 0 || timestamp < stakeHistory[0].timestamp) {
            return
                LibReignStorage.Stake(
                    block.timestamp,
                    0,
                    block.timestamp,
                    address(0),
                    BASE_STAKE_MULTIPLIER
                );
        }

        uint256 min = 0;
        uint256 max = stakeHistory.length - 1;

        if (timestamp >= stakeHistory[max].timestamp) {
            return stakeHistory[max];
        }

        // binary search of the value in the array
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (stakeHistory[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return stakeHistory[min];
    }

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) public view returns (uint256) {
        return votingPowerAtTs(user, block.timestamp);
    }

    // votingPowerAtEpoch returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        LibReignStorage.Stake memory stake = stakeAtTs(user, timestamp);

        uint256 ownVotingPower;

        // if the user delegated his voting power to another user, then he doesn't have any voting power left
        if (stake.delegatedTo != address(0)) {
            ownVotingPower = 0;
        } else {
            ownVotingPower = stake.amount;
        }

        uint256 delegatedVotingPower = delegatedPowerAtTs(user, timestamp);
        return ownVotingPower.add(delegatedVotingPower);
    }

    // reignStaked returns the total raw amount of REIGN staked at the current block
    function reignStaked() public view returns (uint256) {
        return reignStakedAtTs(block.timestamp);
    }

    // reignStakedAtEpoch returns the total raw amount of REIGN users have deposited into the contract
    // it does not include any bonus
    function reignStakedAtTs(uint256 timestamp) public view returns (uint256) {
        return
            _checkpointSearch(
                LibReignStorage.reignStorage().reignStakedHistory,
                timestamp
            );
    }

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) public view returns (uint256) {
        return delegatedPowerAtTs(user, block.timestamp);
    }

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp)
        public
        view
        returns (uint256)
    {
        return
            _checkpointSearch(
                LibReignStorage.reignStorage().delegatedPowerHistory[user],
                timestamp
            );
    }

    // same as multiplierAtTs but for the current block timestamp
    function stakingBoost(address user) public view returns (uint256) {
        return stakingBoostAtEpoch(user, getEpoch());
    }

    // stakingBoostAtEpoch calculates the multiplier at a given epoch based on the user's stake a the
    // given timestamp at which the epoch was initialised
    function stakingBoostAtEpoch(address user, uint128 epochId)
        public
        view
        returns (uint256)
    {
        uint256 epochTime;
        // if _initialisedAt[epochId] == 0 then the epoch has not yet been initialized
        // this guarantees that no deposits or lock updates happend since last epoch and we can safely use the latest checkpoint
        if (epochId == getEpoch() || _initialisedAt[epochId] == 0) {
            epochTime = block.timestamp;
        } else {
            epochTime = _initialisedAt[epochId];
        }
        LibReignStorage.Stake memory stake = stakeAtTs(user, epochTime);
        if (block.timestamp > stake.expiryTimestamp) {
            return BASE_STAKE_MULTIPLIER;
        }

        return stake.stakingBoost;
    }

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) public view returns (uint256) {
        LibReignStorage.Stake memory stake = stakeAtTs(user, block.timestamp);

        return stake.expiryTimestamp;
    }

    // userDelegatedTo returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) public view returns (address) {
        LibReignStorage.Stake memory stake = stakeAtTs(user, block.timestamp);

        return stake.delegatedTo;
    }

    // returns the last time a user interacted with the contract by deposit or withdraw
    function userLastAction(address user) public view returns (uint256) {
        LibReignStorage.Stake memory stake = stakeAtTs(user, block.timestamp);

        return stake.timestamp;
    }

    /*
     * Returns the id of the current epoch derived from block.timestamp
     */
    function getEpoch() public view returns (uint128) {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();

        if (block.timestamp < ds.epoch1Start) {
            return 0;
        }

        return
            uint128((block.timestamp - ds.epoch1Start) / ds.epochDuration + 1);
    }

    /*
     * Returns the percentage of time left in the current epoch
     */
    function currentEpochMultiplier() public view returns (uint128) {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();
        uint128 currentEpoch = getEpoch();
        uint256 currentEpochEnd = ds.epoch1Start +
            currentEpoch *
            ds.epochDuration;
        uint256 timeLeft = currentEpochEnd - block.timestamp;
        uint128 multiplier = uint128(
            (timeLeft * BASE_BALANCE_MULTIPLIER) / ds.epochDuration
        );

        return multiplier;
    }

    function computeNewMultiplier(
        uint256 prevBalance,
        uint128 prevMultiplier,
        uint256 amount,
        uint128 currentMultiplier
    ) public pure returns (uint128) {
        uint256 prevAmount = prevBalance.mul(prevMultiplier).div(
            BASE_BALANCE_MULTIPLIER
        );
        uint256 addAmount = amount.mul(currentMultiplier).div(
            BASE_BALANCE_MULTIPLIER
        );
        uint128 newMultiplier = uint128(
            prevAmount.add(addAmount).mul(BASE_BALANCE_MULTIPLIER).div(
                prevBalance.add(amount)
            )
        );

        return newMultiplier;
    }

    function epochIsInitialized(uint128 epochId) public view returns (bool) {
        return _isInitialized[epochId];
    }

    /*
     *   INTERNAL
     */

    // _updateStake manages an array of stake checkpoints
    // if there's already a checkpoint for the same timestamp, the amount is updated
    // otherwise, a new checkpoint is inserted
    function _updateStake(
        LibReignStorage.Stake[] storage checkpoints,
        uint256 amount
    ) internal {
        if (checkpoints.length == 0) {
            checkpoints.push(
                LibReignStorage.Stake(
                    block.timestamp,
                    amount,
                    block.timestamp,
                    address(0),
                    BASE_STAKE_MULTIPLIER
                )
            );
        } else {
            LibReignStorage.Stake storage old = checkpoints[
                checkpoints.length - 1
            ];

            if (old.timestamp == block.timestamp) {
                old.amount = amount;
            } else {
                checkpoints.push(
                    LibReignStorage.Stake(
                        block.timestamp,
                        amount,
                        old.expiryTimestamp,
                        old.delegatedTo,
                        old.stakingBoost
                    )
                );
            }
        }
    }

    // _increaseEpochBalance manages an array of checkpoints
    // if there's already a checkpoint for the same timestamp, the amount is updated
    // otherwise, a new checkpoint is inserted
    function _increaseEpochBalance(
        LibReignStorage.EpochBalance[] storage epochBalances,
        uint256 amount
    ) internal {
        uint128 currentEpoch = getEpoch();
        uint128 currentMultiplier = currentEpochMultiplier();
        if (!epochIsInitialized(currentEpoch)) {
            _initEpoch(currentEpoch);
        }

        // if there's no checkpoint yet, it means the user didn't have any activity
        // we want to store checkpoints both for the current epoch and next epoch because
        // if a user does a withdraw, the current epoch can also be modified and
        // we don't want to insert another checkpoint in the middle of the array as that could be expensive
        if (epochBalances.length == 0) {
            epochBalances.push(
                LibReignStorage.EpochBalance(
                    currentEpoch,
                    currentMultiplier,
                    0,
                    amount
                )
            );

            epochBalances.push(
                LibReignStorage.EpochBalance(
                    currentEpoch + 1, //for next epoch
                    BASE_BALANCE_MULTIPLIER,
                    amount, //start balance is amount
                    0 // new deposit of amount is made
                )
            );
        } else {
            LibReignStorage.EpochBalance storage old = epochBalances[
                epochBalances.length - 1
            ];
            uint256 lastIndex = epochBalances.length - 1;

            // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
            // add a checkpoint for the previous epoch and the current one
            if (old.epochId < currentEpoch) {
                uint128 multiplier = computeNewMultiplier(
                    _getEpochBalance(old),
                    BASE_BALANCE_MULTIPLIER,
                    amount,
                    currentMultiplier
                );
                //update the stake with new multiplier and amount
                epochBalances.push(
                    LibReignStorage.EpochBalance(
                        currentEpoch,
                        multiplier,
                        _getEpochBalance(old),
                        amount
                    )
                );

                //add a fresh checkpoint for next epoch
                epochBalances.push(
                    LibReignStorage.EpochBalance(
                        currentEpoch + 1,
                        BASE_BALANCE_MULTIPLIER,
                        _balances[msg.sender],
                        0
                    )
                );
            }
            // the last action happened in the current epoch, update values and add a new checkpoint
            // for the current epoch
            else if (old.epochId == currentEpoch) {
                old.multiplier = computeNewMultiplier(
                    _getEpochBalance(old),
                    old.multiplier,
                    amount,
                    currentMultiplier
                );
                old.newDeposits = old.newDeposits.add(amount);

                epochBalances.push(
                    LibReignStorage.EpochBalance(
                        currentEpoch + 1,
                        BASE_BALANCE_MULTIPLIER,
                        _balances[msg.sender],
                        0
                    )
                );
            }
            // the last action happened in the previous epoch, just upate the value
            else {
                if (
                    lastIndex >= 1 &&
                    epochBalances[lastIndex - 1].epochId == currentEpoch
                ) {
                    epochBalances[lastIndex - 1]
                        .multiplier = computeNewMultiplier(
                        _getEpochBalance(epochBalances[lastIndex - 1]),
                        epochBalances[lastIndex - 1].multiplier,
                        amount,
                        currentMultiplier
                    );
                    epochBalances[lastIndex - 1].newDeposits = epochBalances[
                        lastIndex - 1
                    ].newDeposits.add(amount);
                }

                epochBalances[lastIndex].startBalance = _balances[msg.sender];
            }
        }
    }

    // _decreaseEpochBalance manages an array of checkpoints
    // if there's already a checkpoint for the same timestamp, the amount is updated
    // otherwise, a new checkpoint is inserted
    function _decreaseEpochBalance(
        LibReignStorage.EpochBalance[] storage epochBalances,
        uint256 amount
    ) internal {
        uint128 currentEpoch = getEpoch();

        if (!epochIsInitialized(currentEpoch)) {
            _initEpoch(currentEpoch);
        }

        // we can't have a situation in which there is a withdraw with no checkpoint

        LibReignStorage.EpochBalance storage old = epochBalances[
            epochBalances.length - 1
        ];
        uint256 lastIndex = epochBalances.length - 1;

        // the last action happened in an older epoch (e.g. a deposit in epoch 3, current epoch is >=5)
        // add a checkpoint for the previous epoch and the current one
        if (old.epochId < currentEpoch) {
            //update the stake with new multiplier and amount
            epochBalances.push(
                LibReignStorage.EpochBalance(
                    currentEpoch,
                    BASE_BALANCE_MULTIPLIER,
                    _balances[msg.sender],
                    0
                )
            );
        }
        // there was a deposit in the current epoch
        else if (old.epochId == currentEpoch) {
            old.multiplier = BASE_BALANCE_MULTIPLIER;
            old.startBalance = _balances[msg.sender];
            old.newDeposits = 0;
        }
        // there was a deposit in the `epochId - 1` epoch => we have a checkpoint for the current epoch
        else {
            LibReignStorage.EpochBalance
                storage currentEpochCheckpoint = epochBalances[lastIndex - 1];

            uint256 balanceBefore = getEpochEffectiveBalance(
                currentEpochCheckpoint
            );
            // in case of withdraw, we have 2 branches:
            // 1. the user withdraws less than he added in the current epoch
            // 2. the user withdraws more than he added in the current epoch (including 0)
            if (amount < currentEpochCheckpoint.newDeposits) {
                uint128 avgDepositMultiplier = uint128(
                    balanceBefore
                        .sub(currentEpochCheckpoint.startBalance)
                        .mul(BASE_BALANCE_MULTIPLIER)
                        .div(currentEpochCheckpoint.newDeposits)
                );

                currentEpochCheckpoint.newDeposits = currentEpochCheckpoint
                    .newDeposits
                    .sub(amount);

                currentEpochCheckpoint.multiplier = computeNewMultiplier(
                    currentEpochCheckpoint.startBalance,
                    BASE_BALANCE_MULTIPLIER,
                    currentEpochCheckpoint.newDeposits,
                    avgDepositMultiplier
                );
            } else {
                currentEpochCheckpoint.startBalance = currentEpochCheckpoint
                    .startBalance
                    .sub(amount.sub(currentEpochCheckpoint.newDeposits));
                currentEpochCheckpoint.newDeposits = 0;
                currentEpochCheckpoint.multiplier = BASE_BALANCE_MULTIPLIER;
            }

            epochBalances[lastIndex].startBalance = _balances[msg.sender];
        }
    }

    // _updateUserLock updates the expiry timestamp on the user's stake
    // it assumes that if the user already has a balance, which is checked for in the lock function
    // then there must be at least 1 checkpoint
    function _updateUserLock(
        LibReignStorage.Stake[] storage checkpoints,
        uint256 expiryTimestamp
    ) internal {
        LibReignStorage.Stake storage old = checkpoints[checkpoints.length - 1];

        if (old.timestamp < block.timestamp) {
            checkpoints.push(
                LibReignStorage.Stake(
                    block.timestamp,
                    old.amount,
                    expiryTimestamp,
                    old.delegatedTo,
                    _lockingBoost(block.timestamp, expiryTimestamp)
                )
            );
        } else {
            old.expiryTimestamp = expiryTimestamp;
            old.stakingBoost = _lockingBoost(block.timestamp, expiryTimestamp);
        }
    }

    // _updateUserDelegatedTo updates the delegateTo property on the user's stake
    // it assumes that if the user already has a balance, which is checked for in the delegate function
    // then there must be at least 1 checkpoint
    function _updateUserDelegatedTo(
        LibReignStorage.Stake[] storage checkpoints,
        address to
    ) internal {
        LibReignStorage.Stake storage old = checkpoints[checkpoints.length - 1];

        if (old.timestamp < block.timestamp) {
            checkpoints.push(
                LibReignStorage.Stake(
                    block.timestamp,
                    old.amount,
                    old.expiryTimestamp,
                    to,
                    old.stakingBoost
                )
            );
        } else {
            old.delegatedTo = to;
        }
    }

    // _updateDelegatedPower updates the power delegated TO the user in the checkpoints history
    function _updateDelegatedPower(
        LibReignStorage.Checkpoint[] storage checkpoints,
        uint256 amount
    ) internal {
        if (
            checkpoints.length == 0 ||
            checkpoints[checkpoints.length - 1].timestamp < block.timestamp
        ) {
            checkpoints.push(
                LibReignStorage.Checkpoint(block.timestamp, amount)
            );
        } else {
            LibReignStorage.Checkpoint storage old = checkpoints[
                checkpoints.length - 1
            ];
            old.amount = amount;
        }
    }

    // _updateLockedReign stores the new `amount` into the REIGN locked history
    function _updateLockedReign(uint256 amount) internal {
        LibReignStorage.Storage storage ds = LibReignStorage.reignStorage();

        if (
            ds.reignStakedHistory.length == 0 ||
            ds.reignStakedHistory[ds.reignStakedHistory.length - 1].timestamp <
            block.timestamp
        ) {
            ds.reignStakedHistory.push(
                LibReignStorage.Checkpoint(block.timestamp, amount)
            );
        } else {
            LibReignStorage.Checkpoint storage old = ds.reignStakedHistory[
                ds.reignStakedHistory.length - 1
            ];
            old.amount = amount;
        }
    }

    /*
     *   INTERNAL READ
     */

    // _stakeMultiplier calculates the multiplier for the given lockup
    function _lockingBoost(uint256 from, uint256 to)
        internal
        pure
        returns (uint256)
    {
        uint256 diff = to.sub(from); // underflow is checked for in lock()

        // for two year lock(MAX_LOCK) users get 50% boost, for 1 year they get 25%
        return (
            BASE_STAKE_MULTIPLIER.add(
                (diff.mul(BASE_STAKE_MULTIPLIER).div(MAX_LOCK)).div(2)
            )
        );
    }

    //initialises and epoch, and stores the init time
    function _initEpoch(uint128 epochId) internal {
        _isInitialized[epochId] = true;
        _initialisedAt[epochId] = block.timestamp;

        emit InitEpoch(msg.sender, epochId);
    }

    function _getEpochBalance(LibReignStorage.EpochBalance memory c)
        internal
        pure
        returns (uint256)
    {
        return c.startBalance.add(c.newDeposits);
    }

    // _checkpointSearch executes a binary search on a list of checkpoints that's sorted chronologically
    // looking for the closest checkpoint that matches the specified timestamp
    function _checkpointSearch(
        LibReignStorage.Checkpoint[] storage checkpoints,
        uint256 timestamp
    ) internal view returns (uint256) {
        if (checkpoints.length == 0 || timestamp < checkpoints[0].timestamp) {
            return 0;
        }

        uint256 min = 0;
        uint256 max = checkpoints.length - 1;

        if (timestamp >= checkpoints[max].timestamp) {
            return checkpoints[max].amount;
        }

        // binary search of the value in the array
        while (max > min) {
            uint256 mid = (max + min + 1) / 2;
            if (checkpoints[mid].timestamp <= timestamp) {
                min = mid;
            } else {
                max = mid - 1;
            }
        }

        return checkpoints[min].amount;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "../libraries/LibReignStorage.sol";

interface IReign {
    function BASE_MULTIPLIER() external view returns (uint256);

    // deposit allows a user to add more bond to his staked balance
    function deposit(uint256 amount) external;

    // withdraw allows a user to withdraw funds if the balance is not locked
    function withdraw(uint256 amount) external;

    // lock a user's currently staked balance until timestamp & add the bonus to his voting power
    function lock(uint256 timestamp) external;

    // delegate allows a user to delegate his voting power to another user
    function delegate(address to) external;

    // stopDelegate allows a user to take back the delegated voting power
    function stopDelegate() external;

    // lock the balance of a proposal creator until the voting ends; only callable by DAO
    function lockCreatorBalance(address user, uint256 timestamp) external;

    // balanceOf returns the current BOND balance of a user (bonus not included)
    function balanceOf(address user) external view returns (uint256);

    // balanceAtTs returns the amount of BOND that the user currently staked (bonus NOT included)
    function balanceAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakeAtTs returns the Stake object of the user that was valid at `timestamp`
    function stakeAtTs(address user, uint256 timestamp)
        external
        view
        returns (LibReignStorage.Stake memory);

    // votingPower returns the voting power (bonus included) + delegated voting power for a user at the current block
    function votingPower(address user) external view returns (uint256);

    // votingPowerAtTs returns the voting power (bonus included) + delegated voting power for a user at a point in time
    function votingPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // bondStaked returns the total raw amount of BOND staked at the current block
    function reignStaked() external view returns (uint256);

    // reignStakedAtTs returns the total raw amount of BOND users have deposited into the contract
    // it does not include any bonus
    function reignStakedAtTs(uint256 timestamp) external view returns (uint256);

    // delegatedPower returns the total voting power that a user received from other users
    function delegatedPower(address user) external view returns (uint256);

    // delegatedPowerAtTs returns the total voting power that a user received from other users at a point in time
    function delegatedPowerAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // stakingBoost calculates the multiplier on the user's stake at the current timestamp
    function stakingBoost(address user) external view returns (uint256);

    // stackingBoostAtTs calculates the multiplier at a given timestamp based on the user's stake a the given timestamp
    function stackingBoostAtTs(address user, uint256 timestamp)
        external
        view
        returns (uint256);

    // userLockedUntil returns the timestamp until the user's balance is locked
    function userLockedUntil(address user) external view returns (uint256);

    // userDidDelegate returns the address to which a user delegated their voting power; address(0) if not delegated
    function userDelegatedTo(address user) external view returns (address);

    // returns the last timestamp in which the user intercated with the staking contarct
    function userLastAction(address user) external view returns (uint256);

    // reignCirculatingSupply returns the current circulating supply of BOND
    function reignCirculatingSupply() external view returns (uint256);

    function getEpochDuration() external view returns (uint256);

    function getEpoch1Start() external view returns (uint256);

    function getCurrentEpoch() external view returns (uint128);

    function stakingBoostAtEpoch(address, uint128)
        external
        view
        returns (uint256);

    function getEpochUserBalance(address, uint128)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library LibReignStorage {

    bytes32 constant STORAGE_POSITION = keccak256("org.sovreign.reign.storage");

    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct EpochBalance {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
        uint256 stakingBoost;
    }

    struct Storage {
        bool initialized;
        // mapping of user address to history of Stake objects
        // every user action creates a new object in the history
        mapping(address => Stake[]) userStakeHistory;
        mapping(address => EpochBalance[]) userBalanceHistory;
        mapping(address => uint128) lastWithdrawEpochId;
        // array of reign staked Checkpoint
        // deposits/withdrawals create a new object in the history (max one per block)
        Checkpoint[] reignStakedHistory;
        // mapping of user address to history of delegated power
        // every delegate/stopDelegate call create a new checkpoint (max one per block)
        mapping(address => Checkpoint[]) delegatedPowerHistory;
        IERC20 reign; // the reign Token
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function reignStorage() internal pure returns (Storage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./LibDiamondStorage.sol";

library LibOwnership {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage.diamondStorage();

        address previousOwner = ds.contractOwner;
        require(previousOwner != _newOwner, "Previous owner and new owner must be different");

        ds.contractOwner = _newOwner;

        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage.diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() view internal {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner, "Must be contract owner");
    }

    modifier onlyOwner {
        require(msg.sender == LibDiamondStorage.diamondStorage().contractOwner, "Must be contract owner");
        _;
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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;

        // ERC165
        mapping(bytes4 => bool) supportedInterfaces;

        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

