// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/UintSet.sol";

contract FixStaking is AccessControl, Pausable {
    using UintSet for Set;

    event RemovePool(uint256 poolIndex);
    event SetMinMax(uint256 minStake, uint256 maxStake);
    event SetPenDay(uint256 penaltyDuration);
    event PoolFunded(uint256 poolIndex, uint256 fundAmount);
    event ReserveWithdrawed(uint256 poolIndex);
    event Claimed(
        address user,
        uint256 depositAmountIncludePen,
        uint256 reward,
        uint256 stakerIndex,
        uint256 poolIndex
    );
    event Deposit(
        address indexed staker,
        uint256 amount,
        uint256 startTime,
        uint256 closedTime,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );

    event Restake(
        address indexed staker,
        uint256 amount,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );

    event Withdraw(
        address indexed staker,
        uint256 withdrawAmount,
        uint256 reward,
        uint256 mainPenaltyAmount,
        uint256 subPenaltyAmount,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );

    event EmergencyWithdraw(
        address indexed staker,
        uint256 withdrawAmount,
        uint256 reward,
        uint256 mainPenaltyAmount,
        uint256 subPenaltyAmount,
        uint256 indexed poolIndex,
        uint256 indexed stakerIndex
    );
    event NewPool(
        uint256 indexed poolIndex,
        uint256 startTime,
        uint256 duration,
        uint256 apy,
        uint256 mainPenaltyRate,
        uint256 subPenaltyRate,
        uint256 lockedLimit,
        uint256 promisedReward,
        bool nftReward
    );

    struct PoolInfo {
        uint256 startTime;
        uint256 duration;
        uint256 apy;
        uint256 mainPenaltyRate;
        uint256 subPenaltyRate;
        uint256 lockedLimit;
        uint256 stakedAmount;
        uint256 reserve;
        uint256 promisedReward;
        bool nftReward;
    }

    struct StakerInfo {
        uint256 poolIndex;
        uint256 startTime;
        uint256 amount;
        uint256 lastIndex;
        uint256 pendingStart;
        uint256 reward;
        bool isFinished;
        bool pendingRequest;
    }

    mapping(address => mapping(uint256 => StakerInfo)) public stakers;
    mapping(address => uint256) public currentStakerIndex;

    // user address => pool index => total deposit amount
    mapping(address => mapping(uint256 => uint256)) public amountByPool;

    // Minumum amount the user can deposit in 1 pool.We will not look at the total amount deposited by the user into the pool.
    uint256 public minStake;

    // Maximum amount the user can deposit in 1 pool. We will look at the total amount the user deposited into the pool.
    uint256 public maxStake;

    // Time for penalized users have to wait.
    uint256 public penaltyDuration;
    // Pool Index => Pool Info
    PoolInfo[] public pools;

    IERC20 public token;
    uint256 private unlocked = 1;

    /**
     * @notice Checks if the pool exists
     */
    modifier isPoolExist(uint256 _poolIndex) {
        require(
            pools[_poolIndex].startTime > 0,
            "isPoolExist: This pool not exist"
        );
        _;
    }

    /**
     * @notice Checks if the already finish.
     */
    modifier isFinished(address _user, uint256 _stakerIndex) {
        StakerInfo memory staker = stakers[_user][_stakerIndex];
        require(
            staker.isFinished == false,
            "isFinished: This index already finished."
        );
        _;
    }

    /**
     * @notice Check if these values are valid
     */
    modifier isValid(
        uint256 _startTime,
        uint256 _duration,
        uint256 _apy
    ) {
        require(
            _startTime >= block.timestamp,
            "isValid: Start time must be greater than current time"
        );
        require(_duration != 0, "isValid: duration can not be ZERO.");
        require(_apy != 0, "isValid: Apy can not be ZERO.");

        _;
    }

    modifier lock() {
        require(unlocked == 1, "FixStaking: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _token) {
        require(_token != address(0), "FixStaking: token can not be ZERO.");
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = IERC20(_token);
    }

    /**
     * Pauses the contract
     */
    function pause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _pause();
    }

    /**
     * removes the pause
     */
    function unPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }

    /**
     * Sets minumum and maximum deposit amount for user
     */
    function setMinMaxStake(uint256 _minStake, uint256 _maxStake)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _minStake >= 0,
            "setMinMaxStake: minumum amount cannot be ZERO"
        );
        require(
            _maxStake > _minStake,
            "setMinMaxStake: maximum amount cannot be lower than minimum amount"
        );

        minStake = _minStake;
        maxStake = _maxStake;
        emit SetMinMax(_minStake, _maxStake);
    }

    /**
     * Admin can set penalty time with this function
     * @param _duration penalty time in seconds
     */
    function setPenaltyDuration(uint256 _duration)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _duration <= 5 days,
            "setPenaltyDuration: duration must be less than 5 days"
        );
        penaltyDuration = _duration;

        emit SetPenDay(_duration);
    }

    /**
     * Admin has to fund the pool for rewards. Using this function, he can finance any pool he wants.
     * @param _poolIndex the index of the pool it wants to fund.
     * @param _fundingAmount amount of funds to be added to the pool.
     */
    function fundPool(uint256 _poolIndex, uint256 _fundingAmount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isPoolExist(_poolIndex)
    {
        require(
            token.transferFrom(msg.sender, address(this), _fundingAmount),
            "fundPool: token transfer failed."
        );

        pools[_poolIndex].reserve += _fundingAmount;

        emit PoolFunded(_poolIndex, _fundingAmount);
    }

    /**
     * Used when tokens are accidentally sent to the contract.
     * @param _token address will be recover.
     */
    function withdrawERC20(address _token, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(
            _token != address(token),
            "withdrawERC20: token can not be Reward Token."
        );
        require(
            IERC20(_token).transfer(msg.sender, _amount),
            "withdrawERC20: Transfer failed"
        );
    }

    function withdrawFunds(uint256 _poolIndex, uint256 _amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        PoolInfo memory pool = pools[_poolIndex];
        require(
            pool.reserve - pool.promisedReward >= _amount,
            "withdrawFunds: Amount should be lower that promised rewards."
        );

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "withdrawFunds: token transfer failed."
        );
    }

    /**
     * With this function, the administrator can create an interest period.
     * Periods of 30 - 90 - 365 days can be created.
     *
     * Example:
     * -------------------------------------
     * | Apy ve altındakiler 1e16 %1 olacak şekilde ayarlanır.
     * | duration = 2592000                   => 30  Days
     * | apy = 100000000000000000             => %10 Monthly
     * | mainPenaltyRate = 100000000000000000 => %10 Main penalty rate
     * | subPenaltyRate = 50000000000000000   => %5  Sub penalty rate
     * |
     *  -------------------------------------
     *
     * @param _startTime in seconds.
     * @param _duration in seconds.
     * @param _apy 1 month rate should be 18 decimal.
     * @param _mainPenaltyRate Percentage of penalty to be deducted from the user's deposit amount.
     * @param _subPenaltyRate Percentage of penalty to be deducted from the reward won by the user.
     */
    function createPool(
        uint256 _startTime,
        uint256 _duration,
        uint256 _apy,
        uint256 _mainPenaltyRate,
        uint256 _subPenaltyRate,
        uint256 _lockedLimit,
        bool _nftReward
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isValid(_startTime, _duration, _apy)
    {
        PoolInfo memory pool = PoolInfo(
            _startTime,
            _duration,
            _apy,
            _mainPenaltyRate,
            _subPenaltyRate,
            _lockedLimit,
            0,
            0,
            0,
            _nftReward
        );

        pools.push(pool);

        uint256 poolIndex = pools.length - 1;

        emit NewPool(
            poolIndex,
            _startTime,
            _duration,
            _apy,
            _mainPenaltyRate,
            _subPenaltyRate,
            _lockedLimit,
            pool.promisedReward,
            _nftReward
        );
    }

    /**
     * The created period can be edited by the admin.
     * @param _poolIndex the index of the pool to be edited.
     * @param _startTime pool start time in seconds.
     * @param _duration pool duration time in seconds.
     * @param _apy the new apy ratio.
     * @param _mainPenaltyRate the new main penalty rate.
     * @param _subPenaltyRate the new sub penalty rate.
     * @param _lockedLimit maximum amount of tokens that can be locked for this pool
     * @dev Reverts if the pool is not empty.
     * @dev Reverts if the pool is not created before.
     */
    function editPool(
        uint256 _poolIndex,
        uint256 _startTime,
        uint256 _duration,
        uint256 _apy,
        uint256 _mainPenaltyRate,
        uint256 _subPenaltyRate,
        uint256 _lockedLimit,
        bool _nftReward
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isPoolExist(_poolIndex)
        isValid(_startTime, _duration, _apy)
    {
        require(
            _mainPenaltyRate == 0,
            "editPool: main penalty rate must be equal to 0"
        );
        PoolInfo storage pool = pools[_poolIndex];

        pool.startTime = _startTime;
        pool.duration = _duration;
        pool.apy = _apy;
        pool.mainPenaltyRate = _mainPenaltyRate;
        pool.subPenaltyRate = _subPenaltyRate;
        pool.lockedLimit = _lockedLimit;
        pool.nftReward = _nftReward;

        emit NewPool(
            _poolIndex,
            _startTime,
            _duration,
            _apy,
            _mainPenaltyRate,
            _subPenaltyRate,
            _lockedLimit,
            pool.promisedReward,
            _nftReward
        );
    }

    /**
     * The created period can be remove by the admin.
     * @param _poolIndex the index of the to be removed pool.
     * @dev Reverts if the pool is not empty.
     * @dev Reverts if the pool is not created before.
     */
    function removePool(uint256 _poolIndex)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
        isPoolExist(_poolIndex)
    {
        if (pools[_poolIndex].reserve > 0) {
            require(
                token.transfer(msg.sender, pools[_poolIndex].reserve),
                "removePool: transfer failed."
            );
        }

        delete pools[_poolIndex];

        emit RemovePool(_poolIndex);
    }

    /**
     * Users can deposit money into any pool they want.
     * @notice Each time the user makes a deposit, the structer is kept at a different stakerIndex so it can be in more than one or the same pool at the same time.
     * @notice Users can join the same pool more than once at the same time.
     * @notice Users can join different pools at the same time.
     * @param _amount amount of money to be deposited.
     * @param _poolIndex index of the period to be entered.
     * @dev reverts if the user tries to deposit it less than the minimum amount.
     * @dev reverts if the user tries to deposit more than the maximum amount into the one pool.
     * @dev reverts if the pool does not have enough funds.
     */
    function deposit(uint256 _amount, uint256 _poolIndex)
        external
        whenNotPaused
        lock
        isPoolExist(_poolIndex)
    {
        uint256 index = currentStakerIndex[msg.sender];
        StakerInfo storage staker = stakers[msg.sender][index];
        PoolInfo storage pool = pools[_poolIndex];
        uint256 reward = calculateRew(_amount, pool.apy, pool.duration);
        uint256 totStakedAmount = pool.stakedAmount + _amount;
        pool.promisedReward += reward;
        require(
            _amount >= minStake,
            "deposit: You cannot deposit below the minimum amount."
        );

        require(
            (amountByPool[msg.sender][_poolIndex] + _amount) <= maxStake,
            "deposit: You cannot deposit, have reached the maximum deposit amount."
        );
        require(
            pool.reserve >= reward,
            "deposit: This pool has no enough reward reserve"
        );
        require(
            pool.lockedLimit >= totStakedAmount,
            "deposit: The pool has reached its maximum capacity."
        );

        require(
            block.timestamp >= pool.startTime,
            "deposit: This pool hasn't started yet."
        );

        uint256 duration = pool.duration;
        uint256 timestamp = block.timestamp;

        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "deposit: Token transfer failed."
        );

        staker.startTime = timestamp;
        staker.amount = _amount;
        staker.poolIndex = _poolIndex;
        pool.stakedAmount += _amount;

        currentStakerIndex[msg.sender] += 1;
        amountByPool[msg.sender][_poolIndex] += _amount;

        emit Deposit(
            msg.sender,
            _amount,
            timestamp,
            (timestamp + duration),
            _poolIndex,
            index
        );
    }

    /**
     * Users can exit the period they are in at any time.
     * @notice Users who are not penalized can withdraw their money directly with this function. Users who are penalized should execut the claimPending function after this process.
     * @notice If the period has not finished, they will be penalized at the rate of mainPeanltyRate from their deposit.
     * @notice If the period has not finished, they will be penalized at the rate of subPenaltyRate from their rewards.
     * @notice Penalized users will be able to collect their rewards later with the claim function.
     * @param _stakerIndex of the period want to exit.
     * @dev reverts if the user's deposit amount is ZERO
     * @dev reverts if the pool does not have enough funds to cover the reward
     */
    function withdraw(uint256 _stakerIndex)
        external
        whenNotPaused
        lock
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo storage staker = stakers[msg.sender][_stakerIndex];
        PoolInfo storage pool = pools[staker.poolIndex];

        require(
            staker.pendingRequest == false,
            "withdraw: you have already requested claim."
        );
        require(staker.amount > 0, "withdraw: Insufficient amount.");

        uint256 closedTime = getClosedTime(msg.sender, _stakerIndex);
        uint256 duration = _getStakerDuration(closedTime, staker.startTime);
        uint256 reward = calculateRew(staker.amount, pool.apy, duration);
        // If the user tries exits before the pool end time they should be penalized
        (uint256 mainPen, uint256 subPen) = getPenalty(
            msg.sender,
            _stakerIndex
        );
        uint256 totalReward = (reward - subPen);
        uint256 totalWithdraw = (staker.amount + totalReward);

        staker.reward = totalReward;
        pool.reserve -= staker.reward;
        pool.promisedReward = pool.promisedReward <= totalReward
            ? 0
            : pool.promisedReward - totalReward;

        pool.stakedAmount -= staker.amount;
        amountByPool[msg.sender][staker.poolIndex] -= staker.amount;
        // ELSE user tries withdraw before the period end time he needs to be wait cooldown

        if (closedTime <= block.timestamp) {
            _transferAndRemove(msg.sender, totalWithdraw, _stakerIndex);
        } else {
            staker.pendingStart = block.timestamp;
            staker.pendingRequest = true;
        }

        emit Withdraw(
            msg.sender,
            totalReward,
            totalWithdraw,
            mainPen,
            subPen,
            staker.poolIndex,
            _stakerIndex
        );
    }

    /**
     * After the user has completed enough duration in the pool, he can stake to the same pool again with this function.
     * @notice The same stakerIndex is used to save gas.
     * @notice The reward he won from the pool will be added to the amount he deposited.
     */
    function restake(uint256 _stakerIndex)
        external
        whenNotPaused
        lock
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo storage staker = stakers[msg.sender][_stakerIndex];
        PoolInfo storage pool = pools[staker.poolIndex];

        uint256 poolIndex = staker.poolIndex;
        uint256 closedTime = getClosedTime(msg.sender, _stakerIndex);

        require(staker.amount > 0, "restake: Insufficient amount.");
        require(
            staker.pendingRequest == false,
            "restake: You have already requested claim."
        );
        require(
            block.timestamp >= closedTime,
            "restake: Time has not expired."
        );

        uint256 duration = _getStakerDuration(closedTime, staker.startTime);
        uint256 reward = calculateRew(staker.amount, pool.apy, duration);
        uint256 totalDeposit = staker.amount + reward;
        uint256 promisedReward = calculateRew(
            totalDeposit,
            pool.apy,
            pool.duration
        );
        pool.promisedReward += promisedReward;
        // we are checking only reward because staker amount currently staked.
        require(
            pool.reserve >=
                calculateRew(
                    pool.stakedAmount + reward,
                    pool.apy,
                    pool.duration
                ),
            "restake: This pool has no enough reward reserve"
        );

        require(
            (amountByPool[msg.sender][poolIndex] + reward) <= maxStake,
            "restake: You cannot deposit, have reached the maximum deposit amount."
        );

        pool.stakedAmount += reward;
        staker.startTime = block.timestamp;
        staker.amount = totalDeposit;
        amountByPool[msg.sender][poolIndex] += reward;

        emit Restake(msg.sender, totalDeposit, poolIndex, _stakerIndex);
    }

    /**
     * @notice Emergency function
     * Available only when the contract is paused. Users can withdraw their inside amount without receiving the rewards.
     */
    function emergencyWithdraw(uint256 _stakerIndex)
        external
        whenPaused
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo memory staker = stakers[msg.sender][_stakerIndex];
        PoolInfo storage pool = pools[staker.poolIndex];

        require(staker.amount > 0, "withdraw: Insufficient amount.");

        uint256 withdrawAmount = staker.amount;
        pool.stakedAmount -= withdrawAmount;
        pool.promisedReward -= calculateRew(
            withdrawAmount,
            pool.apy,
            pool.duration
        );
        amountByPool[msg.sender][staker.poolIndex] -= withdrawAmount;
        _transferAndRemove(msg.sender, withdrawAmount, _stakerIndex);
        emit EmergencyWithdraw(
            msg.sender,
            withdrawAmount,
            staker.reward,
            pool.mainPenaltyRate,
            pool.subPenaltyRate,
            staker.poolIndex,
            _stakerIndex
        );
    }

    /**
     * Users who have been penalized can withdraw their tokens with this function when the 4-day penalty period expires.
     * @param _stakerIndex of the period want to claim.
     */
    function claimPending(uint256 _stakerIndex)
        external
        whenNotPaused
        lock
        isFinished(msg.sender, _stakerIndex)
    {
        StakerInfo storage staker = stakers[msg.sender][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        require(staker.amount > 0, "claim: You do not have a pending amount.");

        require(
            block.timestamp >= staker.pendingStart + penaltyDuration,
            "claim: Please wait your time has not been up."
        );

        uint256 mainAmount = staker.amount;
        // If a penalty rate is defined that will be deducted from the amount deposited by the user
        // Deduct this penalty from the amount deposited by the user and transfer the penalty amount to the reward reserve.
        if (pool.mainPenaltyRate > 0) {
            (uint256 mainPen, ) = getPenalty(msg.sender, _stakerIndex);
            mainAmount = mainAmount - mainPen;
            pool.reserve += mainPen;
        }

        staker.pendingRequest = false;

        // There is no need to deduct the amount from the reward earned as much as the penalty rate.
        // We already did in the withdraw function.
        uint256 totalPending = mainAmount + staker.reward;
        pool.promisedReward -= staker.reward;

        _transferAndRemove(msg.sender, totalPending, _stakerIndex);

        emit Claimed(
            msg.sender,
            mainAmount,
            staker.reward,
            _stakerIndex,
            staker.poolIndex
        );
    }

    /**
     * Returns the penalty, if any, of the user whose address and index are given.
     * @param _staker address of the person whose penalty will be calculated.
     * @param _stakerIndex user index to be calculated.
     * @return mainPenalty penalty amount, to be deducted from the deposited amount by the user.
     * @return subPenalty penalty amount, to be deducted from the reward amount.
     */
    function getPenalty(address _staker, uint256 _stakerIndex)
        public
        view
        returns (uint256 mainPenalty, uint256 subPenalty)
    {
        StakerInfo memory staker = stakers[_staker][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        uint256 closedTime = getClosedTime(_staker, _stakerIndex);
        if (closedTime > block.timestamp) {
            uint256 duration = block.timestamp - staker.startTime;
            uint256 reward = calculateRew(staker.amount, pool.apy, duration);
            uint256 amountPen = (staker.amount * pool.mainPenaltyRate) / 1e18;
            uint256 rewardPen = (reward * pool.subPenaltyRate) / 1e18;

            return (amountPen, rewardPen);
        }
        return (0, 0);
    }

    /**
     * Calculates the current reward of the user whose address and index are given.
     * @param _amount amount of deposit.
     * @param _apy monthly rate.
     * @param _duration amount of time spent inside.
     * @return reward amount of earned by the user.
     */
    function calculateRew(
        uint256 _amount,
        uint256 _apy,
        uint256 _duration
    ) public pure returns (uint256) {
        uint256 rateToSec = (_apy * 1e36) / 30 days;
        uint256 percent = (rateToSec * _duration) / 1e18;
        return (_amount * percent) / 1e36;
    }

    /**
     * Calculates the current reward of the user whose address and index are given.
     * @param _staker address of the person whose reward will be calculated.
     * @param _stakerIndex user index to be calculated.
     * @return reward amount of earned by the user.
     * @return mainPenalty penalty amount, to be deducted from the deposited amount by the user.
     * @return subPenalty penalty amount, to be deducted from the reward amount.
     * @return closedTime user end time.
     * @return futureReward reward for completing the pool
     * @return stakerInf Information owned by the user for this index.
     */
    function stakerInfo(address _staker, uint256 _stakerIndex)
        external
        view
        returns (
            uint256 reward,
            uint256 mainPenalty,
            uint256 subPenalty,
            uint256 closedTime,
            uint256 futureReward,
            StakerInfo memory stakerInf
        )
    {
        StakerInfo memory staker = stakers[_staker][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        closedTime = getClosedTime(_staker, _stakerIndex);
        uint256 duration = _getStakerDuration(closedTime, staker.startTime);
        reward = calculateRew(staker.amount, pool.apy, duration);
        (mainPenalty, subPenalty) = getPenalty(_staker, _stakerIndex);
        futureReward = calculateRew(staker.amount, pool.apy, pool.duration);

        return (
            reward,
            mainPenalty,
            subPenalty,
            closedTime,
            futureReward,
            staker
        );
    }

    function getClosedTime(address _staker, uint256 _stakerIndex)
        public
        view
        returns (uint256)
    {
        StakerInfo memory staker = stakers[_staker][_stakerIndex];
        PoolInfo memory pool = pools[staker.poolIndex];

        uint256 closedTime = staker.startTime + pool.duration;

        return closedTime;
    }

    /**
     * Returns the available allocation for the given pool index.
     */
    function getAvaliableAllocation(uint256 _poolIndex)
        external
        view
        returns (uint256)
    {
        PoolInfo memory pool = pools[_poolIndex];

        return pool.lockedLimit - pool.stakedAmount;
    }

    /**
     * Returns a list of all pools.
     */
    function getPoolList() external view returns (PoolInfo[] memory) {
        return pools;
    }

    /**
     * Returns the total staked amount and remaining allocation all pools.
     * @notice We are aware of the gas problem that will occur with the for loop here. This won't be a problem as we won't have more than 10-20 pools.
     */
    function getTotStakedAndAlloc()
        external
        view
        returns (uint256 totStakedAmount, uint256 totAlloc)
    {
        for (uint256 i = 0; i < pools.length; i++) {
            PoolInfo memory pool = pools[i];

            totStakedAmount += pool.stakedAmount;
            totAlloc += pool.lockedLimit - pool.stakedAmount;
        }

        return (totStakedAmount, totAlloc);
    }

    function _getStakerDuration(uint256 _closedTime, uint256 _startTime)
        private
        view
        returns (uint256)
    {
        uint256 endTime = block.timestamp > _closedTime
            ? _closedTime
            : block.timestamp;
        uint256 duration = endTime - _startTime;

        return duration;
    }

    function _transferAndRemove(
        address _user,
        uint256 _transferAmount,
        uint256 _stakerIndex
    ) private {
        StakerInfo storage staker = stakers[_user][_stakerIndex];
        require(
            token.transfer(_user, _transferAmount),
            "_transferAndRemove: transfer failed."
        );

        staker.isFinished = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
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
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
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
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
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
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
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
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
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
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

struct Set {
    // Storage of set values
    uint256[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(uint256 => uint256) _indexes;
}

library UintSet {
    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Set storage set, uint256 value) internal returns (bool) {
        if (!contains(set, value)) {
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
    function remove(Set storage set, uint256 value) internal returns (bool) {
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
                uint256 lastvalue = set._values[lastIndex];

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
    function contains(Set storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(Set storage set) internal view returns (uint256) {
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
    function at(Set storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return set._values[index];
    }

    function getArray(Set storage set)
        internal
        view
        returns (uint256[] memory)
    {
        return set._values;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
     * bearer except when using {AccessControl-_setupRole}.
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
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

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
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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