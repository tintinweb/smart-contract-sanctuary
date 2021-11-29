// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";

contract FundzFarming is AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct CommonStakingInfo {
        uint256 rewardsPerEpoch;
        uint256 startTime;
        uint256 epochDuration;
        uint256 rewardsPerDeposit;
        uint256 rewardProduced;
        uint256 produceTime;
        uint256 pastProduced;
        uint256 totalStaked;
        uint256 totalDistributed;
        uint256 fineCoolDownTime;
        uint256 finePercent;
        uint256 accumulatedFine;
        address depositToken;
        address rewardToken;
    }

    struct Staker {
        uint256 amount;
        uint256 rewardAllowed;
        uint256 rewardDebt;
        uint256 distributed;
        uint256 noFineUnstakeOpenSince;
        uint256 requestedUnstakeAmount;
    }

    mapping(address => Staker) public stakers;

    // ERC20 DLD token staking to the contract
    // and DLS token earned by stakers as reward.
    IERC20 public depositToken;
    IERC20 public rewardToken;

    // Common contract configuration variables.
    uint256 public rewardsPerEpoch;
    uint256 public startTime;
    uint256 public epochDuration;

    uint256 public rewardsPerDeposit;
    uint256 public rewardProduced;
    uint256 public produceTime;
    uint256 public pastProduced;

    uint256 public totalStaked;
    uint256 public totalDistributed;

    uint256 public constant precision = 10**20;
    uint256 public finePercent; // calcs with precision
    uint256 public fineCoolDownTime;
    uint256 public accumulatedFine;

    bool public isStakeAvailable = true;
    bool public isUnstakeAvailable = true;
    bool public isClaimAvailable = true;

    event TokensStaked(
        uint256 amount,
        uint256 timestamp,
        address indexed sender
    );
    event TokensClaimed(
        uint256 amount,
        uint256 timestamp,
        address indexed sender
    );
    event TokensUnstaked(
        uint256 amount,
        uint256 fineAmount_,
        uint256 timestamp,
        address indexed sender
    );
    event RequestedTokensUnstake(
        uint256 amount,
        uint256 requestApplyTimestamp,
        uint256 timestamp,
        address indexed sender
    );

    /**
     *@param _rewardsPerEpoch number of rewards per epoch
     *@param _startTime staking start time
     *@param _epochDuration epoch duration in seconds
     *@param _fineCoolDownTime time after which you can unstake without commission
     *@param _finePercent commission for withdrawing funds without request
     *@param _depositToken address deposit token
     *@param _rewardToken address reward token
     */
    constructor(
        uint256 _rewardsPerEpoch,
        uint256 _startTime,
        uint256 _epochDuration,
        uint256 _fineCoolDownTime,
        uint256 _finePercent,
        address _depositToken,
        address _rewardToken
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        rewardsPerEpoch = _rewardsPerEpoch;
        startTime = _startTime;

        epochDuration = _epochDuration;

        produceTime = _startTime;

        fineCoolDownTime = _fineCoolDownTime;
        finePercent = _finePercent;

        rewardToken = IERC20(_rewardToken);
        depositToken = IERC20(_depositToken);
    }

    /**
     *@dev change FineCoolDownTime
     *@param _fineCoolDownTime time after which you can unstake without commission
     */
    function changeParamFineCoolDownTime(uint256 _fineCoolDownTime)
        external
        onlyRole(ADMIN_ROLE)
    {
        fineCoolDownTime = _fineCoolDownTime;
    }

    /**
     *@dev change DepositToken
     *@param _depositToken deposit token
     */
    function updateDepositToken(address _depositToken)
        external
        onlyRole(ADMIN_ROLE)
    {
        depositToken = IERC20(_depositToken);
    }

    /**
     *@dev change FinePercent
     *@param _finePercent fine percent
     */
    function updateFinePercent(uint256 _finePercent)
        external
        onlyRole(ADMIN_ROLE)
    {
        finePercent = _finePercent;
    }

    /**
     *@dev change StartTime
     *@param _startTime Start Time
     */
    function updateStartTime(uint256 _startTime)
        external
        onlyRole(ADMIN_ROLE)
    {
        startTime = _startTime;
    }

    /**
     *@dev take the commission, can only be used by the admin
     */
    function withdrawFine() external onlyRole(ADMIN_ROLE) {
        require(accumulatedFine > 0, "Farming: accumulated fine is zero");
        IERC20(depositToken).safeTransfer(msg.sender, accumulatedFine);
        accumulatedFine = 0;
    }

    /**
     *@dev withdraw token to sender by token address, if sender is admin
     *@param _token address token
     *@param _amount amount
     */
    function withdrawToken(address _token, uint256 _amount)
        external
        onlyRole(ADMIN_ROLE)
    {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    /**
     *@dev set staking state (in terms of STM)
     *@param _isStakeAvailable block stake
     *@param _isUnstakeAvailable block unstake
     *@param _isClaimAvailable block claim
     */
    function setAvailability(
        bool _isStakeAvailable,
        bool _isUnstakeAvailable,
        bool _isClaimAvailable
    ) external onlyRole(ADMIN_ROLE) {
        if (isStakeAvailable != _isStakeAvailable)
            isStakeAvailable = _isStakeAvailable;
        if (isUnstakeAvailable != _isUnstakeAvailable)
            isUnstakeAvailable = _isUnstakeAvailable;
        if (isClaimAvailable != _isClaimAvailable)
            isClaimAvailable = _isClaimAvailable;
    }

    /**
     *@dev setReward - sets amount of reward during `distributionTime`
     *@param _amount amount of reward
     */
    function setReward(uint256 _amount) external onlyRole(ADMIN_ROLE) {
        pastProduced = _produced();
        produceTime = block.timestamp;
        rewardsPerEpoch = _amount;
    }

    /**
     *@dev make stake
     *@param _amount how many tokens to send
     */
    function stake(uint256 _amount) external {
        require(isStakeAvailable, "Farming: stake is not available now");
        require(
            block.timestamp > startTime,
            "Farming: stake time has not come yet"
        );

        IERC20(depositToken).safeTransferFrom(
            msg.sender,
            address(this),
            _amount
        );

        if (totalStaked > 0) {
            update();
        }
        Staker storage staker = stakers[msg.sender];
        staker.rewardDebt += (_amount * rewardsPerDeposit) / 1e20;

        totalStaked += _amount;
        staker.amount += _amount;

        update();
        emit TokensStaked(_amount, block.timestamp, msg.sender);
    }

    /**
     *@dev pick up a stake
     *@param _amount how many tokens to pick up
     */
    function unstake(uint256 _amount) external nonReentrant {
        require(isUnstakeAvailable, "Farming: unstake is not available now");
        Staker storage staker = stakers[msg.sender];

        require(
            staker.amount >= _amount,
            "Farming: not enough tokens to unstake"
        );

        update();

        staker.rewardAllowed += ((_amount * rewardsPerDeposit) / 1e20);
        staker.amount -= _amount;

        uint256 unstakeAmount;
        uint256 fineAmount;

        if (
            staker.noFineUnstakeOpenSince > block.timestamp ||
            _amount > staker.requestedUnstakeAmount
        ) {
            fineAmount = (finePercent * _amount) / precision;
            unstakeAmount = _amount - fineAmount;
            accumulatedFine += fineAmount;
        } else {
            unstakeAmount = _amount;
            staker.requestedUnstakeAmount -= _amount;
        }

        IERC20(depositToken).safeTransfer(msg.sender, unstakeAmount);
        totalStaked -= _amount;

        emit TokensUnstaked(
            unstakeAmount,
            fineAmount,
            block.timestamp,
            msg.sender
        );
    }

    /**
     *@dev make a request for withdrawal of funds without commission
     *@param amount amount
     */
    function requestUnstakeWithoutFine(uint256 amount) external {
        require(isUnstakeAvailable, "Farming: unstake is not available now");
        Staker storage staker = stakers[msg.sender];
        require(
            staker.amount >= amount,
            "Farming: not enough tokens to unstake"
        );

        require(
            staker.requestedUnstakeAmount <= amount,
            "Farming: you already have request with greater or equal amount"
        );

        staker.noFineUnstakeOpenSince = block.timestamp + fineCoolDownTime;
        staker.requestedUnstakeAmount = amount;
        emit RequestedTokensUnstake(
            amount,
            staker.noFineUnstakeOpenSince,
            block.timestamp,
            msg.sender
        );
    }

    /**
     *  @dev claim available rewards
     */
    function claim() external nonReentrant {
        require(isClaimAvailable, "Farming: claim is not available now");
        if (totalStaked > 0) update();

        uint256 reward_ = _calcReward(msg.sender, rewardsPerDeposit);
        require(reward_ > 0, "Farming: nothing to claim");

        Staker storage staker = stakers[msg.sender];

        staker.distributed += reward_;
        totalDistributed += reward_;

        IERC20(rewardToken).safeTransfer(msg.sender, reward_);
        emit TokensClaimed(reward_, block.timestamp, msg.sender);
    }

    /// @dev core function, must be invoked after any balances changed
    function update() public {
        uint256 rewardProducedAtNow_ = _produced();
        if (rewardProducedAtNow_ > rewardProduced) {
            uint256 producedNew_ = rewardProducedAtNow_ - rewardProduced;
            if (totalStaked > 0) {
                rewardsPerDeposit =
                    rewardsPerDeposit +
                    ((producedNew_ * 1e20) / totalStaked);
            }
            rewardProduced += producedNew_;
        }
    }

    /**
     *@dev get information about staking
     *@return returning structure CommonStakingInfo
     */
    function getCommonStakingInfo()
        external
        view
        returns (CommonStakingInfo memory)
    {
        return
            CommonStakingInfo({
                rewardsPerEpoch: rewardsPerEpoch,
                startTime: startTime,
                epochDuration: epochDuration,
                rewardsPerDeposit: rewardsPerDeposit,
                rewardProduced: rewardProduced,
                produceTime: produceTime,
                pastProduced: pastProduced,
                totalStaked: totalStaked,
                totalDistributed: totalDistributed,
                fineCoolDownTime: fineCoolDownTime,
                finePercent: finePercent,
                accumulatedFine: accumulatedFine,
                depositToken: address(depositToken),
                rewardToken: address(rewardToken)
            });
    }

    /**
     *@dev get information about user
     *@param _user address user
     *@return returning structure Staker
     */
    function getUserInfo(address _user) external view returns (Staker memory) {
        Staker memory staker = stakers[_user];
        staker.rewardAllowed = getRewardInfo(_user);
        return staker;
    }

    /**
     *@dev returns available reward of staker
     *@param _user address user
     *@return returns available reward
     */
    function getRewardInfo(address _user) public view returns (uint256) {
        uint256 rewardsPerDeposit_ = rewardsPerDeposit;
        if (totalStaked > 0) {
            uint256 rewardProducedAtNow_ = _produced();
            if (rewardProducedAtNow_ > rewardProduced) {
                uint256 producedNew_ = rewardProducedAtNow_ - rewardProduced;
                rewardsPerDeposit_ += ((producedNew_ * 1e20) / totalStaked);
            }
        }
        uint256 reward = _calcReward(_user, rewardsPerDeposit_);

        return reward;
    }

    /// @dev calculates the necessary parameters for staking
    function _produced() internal view returns (uint256) {
        return
            pastProduced +
            (rewardsPerEpoch * (block.timestamp - produceTime)) /
            epochDuration;
    }

    /**
     * @dev calculates available reward_
     */
    function _calcReward(address _user, uint256 _tps)
        internal
        view
        returns (uint256)
    {
        Staker memory staker_ = stakers[_user];
        return
            ((staker_.amount * _tps) / 1e20) +
            staker_.rewardAllowed -
            staker_.distributed -
            staker_.rewardDebt;
    }
}