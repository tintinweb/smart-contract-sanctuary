pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./SafeERC20.sol";
import "./Math.sol";
import "./StakePoolStorge.sol";

contract IRewardDistributionRecipient is Ownable {
    address public rewardDistribution;

    function notifyRewardAmount(uint256 reward) external;

    modifier onlyRewardDistribution() {
        require(
            _msgSender() == rewardDistribution,
            "Caller is not reward distribution"
        );
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
}

contract LPTokenWrapper {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 internal tokenAddr;
    uint256 internal _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount, address account) internal {
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        tokenAddr.safeTransferFrom(account, address(this), amount);
    }

    function withdraw(uint256 amount, address account) internal {
        _totalSupply = _totalSupply.sub(amount);
        _balances[account] = _balances[account].sub(amount);
        tokenAddr.safeTransfer(account, amount);
    }
}

contract StakePool is
    LPTokenWrapper,
    IRewardDistributionRecipient,
    StakePoolStorge
{
    IERC20 internal Token = IERC20(rewardTokenAddress);

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRelease(
        address indexed sender,
        address indexed user,
        uint256 reward
    );
    event Rescue(address indexed dst, uint256 sad);
    event RescueToken(address indexed dst, address indexed token, uint256 sad);
    event SetInviter(address indexed dst, address indexed inviter);

    /**
     * @notice Initialize the stake contract
     * @param _erc20 ERC20 token address
     * @param _startTime The timestamp of the start of the contract
     * @param _rewardClaimDelay The time for the withdrawal of the proceeds to arrive in the account
     * @param _minTokenAmount The minimum number of tokens to earn
     * @param _minInviterStakeTokenAmount The number of tokens for which the smallest inviter receives revenue
     * @param _inviterRewardRate The interest rate at which the inviter receives the income
     * @param _lockDelayTime Withdrawal lock time
     */
    constructor(
        address _erc20,
        uint256 _startTime,
        uint256 _rewardClaimDelay,
        uint256 _minTokenAmount,
        uint256 _minInviterStakeTokenAmount,
        uint256 _inviterRewardRate,
        uint256 _lockDelayTime
    ) public {
        tokenAddr = IERC20(_erc20);
        rewardDistribution = _msgSender();

        startTime = _startTime;
        rewardClaimDelay = _rewardClaimDelay;
        minTokenAmount = _minTokenAmount;
        minInviterStakeTokenAmount = _minInviterStakeTokenAmount;
        inviterRewardRate = _inviterRewardRate;
        lockDelayTime = _lockDelayTime;
    }

    /**
     * @notice Check if the start time is reached
     */
    modifier checkStart() {
        require(block.timestamp >= startTime, "Not start");
        _;
    }

    /**
     * @notice Update user's reward data and reward date
     * @param account User's account address
     * @param stakeAmount Number of stake token amount
     */
    modifier updateReward(address account, uint256 stakeAmount) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            if (lockDelayTime > 0 && stakeAmount > 0) {
                LockRecord memory stakeRecordStruct = LockRecord(
                    stakeAmount,
                    block.timestamp + lockDelayTime
                );
                userStakeInfo[account].stakeLockRecords.push(stakeRecordStruct);
            }

            uint256 newReward = _getRewardStored(account);
            address inviter = userStakeInfo[account].inviter;
            if (newReward > 0 && userStakeInfo[account].inviter != address(0)) {
                userStakeInfo[inviter].rewards = _getInviterReward(
                    newReward,
                    inviter
                );
            }

            userStakeInfo[account].rewards = earned(account);
            userStakeInfo[account]
                .userRewardPerTokenStored = rewardPerTokenStored;
        }
        _;
    }

    /**
     * @notice Get the latest timestamp from the current
     */
    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    /**
     * @notice Get the number of rewards for each token between two times
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(totalSupply())
            );
    }

    /**
     * @notice The number of rewards received by the inviter
     * @param reward Rewards for children
     * @param inviter Inviter address
     */
    function _getInviterReward(uint256 reward, address inviter)
        internal
        view
        returns (uint256)
    {
        if (balanceOf(inviter) >= minInviterStakeTokenAmount) {
            return
                reward.mul(inviterRewardRate).div(10000).add(
                    userStakeInfo[inviter].rewards
                );
        } else {
            return userStakeInfo[inviter].rewards;
        }
    }

    /**
     * @notice Get the latest amount of rewards in total
     * @param account User's address
     */
    function earned(address account) public view returns (uint256) {
        return _getRewardStored(account).add(userStakeInfo[account].rewards);
    }

    /**
     * @notice Get the number of rewards currently received
     * @param account User's address
     */
    function _getRewardStored(address account) internal view returns (uint256) {
        if (balanceOf(account) >= minTokenAmount) {
            return
                balanceOf(account)
                    .mul(
                        rewardPerToken().sub(
                            userStakeInfo[account].userRewardPerTokenStored
                        )
                    )
                    .div(1e18);
        } else {
            return 0;
        }
    }

    /**
     * @notice stake visibility is public as overriding LPTokenWrapper's stake() function
     * @param amount The number of tokens that users need to stake
     */
    function stake(uint256 amount)
        public
        updateReward(msg.sender, amount)
        checkStart
    {
        require(amount > 0, "Cannot stake 0");
        require(
            userStakeInfo[msg.sender].inviter != address(0),
            "Inviter must not 0"
        );
        super.stake(amount, msg.sender);
        emit Staked(msg.sender, amount);
    }

    /**
     * @notice withdraw visibility is public as overriding LPTokenWrapper's withdraw() function
     * @param amount The number of tokens that users need to withdraw
     */
    function withdraw(uint256 amount, uint256 index)
        public
        updateReward(msg.sender, 0)
        checkStart
    {
        if (lockDelayTime > 0) {
            require(
                userStakeInfo[msg.sender].stakeLockRecords.length > index,
                "Index error"
            );

            uint256 _endTime = userStakeInfo[msg.sender]
                .stakeLockRecords[index]
                .endTime;
            uint256 _amount = userStakeInfo[msg.sender]
                .stakeLockRecords[index]
                .amount;

            require(
                _endTime <= block.timestamp,
                "The amount withdrawn has not been released"
            );
            require(
                _amount > 0,
                "The withdrawal amount must be greater than 0"
            );

            super.withdraw(_amount, msg.sender);
            _delStakeLockRecordByIndex(msg.sender, index);
            emit Withdrawn(msg.sender, _amount);
        } else {
            require(amount > 0, "Cannot withdraw 0");
            super.withdraw(amount, msg.sender);
            emit Withdrawn(msg.sender, amount);
        }
    }

    /**
     * @notice Delete expired stake data from user data
     * @param _account User's address
     * @param _index stakeLockRecords index
     */
    function _delStakeLockRecordByIndex(address _account, uint256 _index)
        internal
    {
        uint256 len = userStakeInfo[_account].stakeLockRecords.length;
        for (uint256 i = _index; i < len - 1; i++) {
            userStakeInfo[_account].stakeLockRecords[i] = userStakeInfo[
                _account
            ].stakeLockRecords[i + 1];
        }
        delete userStakeInfo[_account].stakeLockRecords[len - 1];
        userStakeInfo[_account].stakeLockRecords.length--;
    }

    /**
     * @notice Claim the reward,If you turn on delayed arrival, you will enter the delayed record list,
     * @notice After the timing ends, a manual release of rewards is required
     * @param account User's address
     */
    function claimReward(address account) public updateReward(msg.sender, 0) {
        require(block.timestamp >= startTime, "Not yet started");
        require(account != address(0), "Invalid accound address");

        uint256 _amount = userStakeInfo[account].rewards;
        require(_amount > 0, "True reward error");

        if (rewardClaimDelay > 0) {
            LockRecord memory rewardDelayRecordStruct = LockRecord(
                _amount,
                block.timestamp + rewardClaimDelay
            );
            userStakeInfo[account].rewardDelayRecords.push(
                rewardDelayRecordStruct
            );
        } else {
            Token.safeTransfer(account, _amount);
        }

        userStakeInfo[account].rewards = _amount.sub(_amount);
        emit RewardClaimed(account, _amount);
    }

    /**
     * @notice Release all expired rewards
     *  @param account User's address
     */
    function releaseReward(address account) public {
        require(account != address(0), "Invalid accound address");

        uint256 startIndex = rewardClearIndex[account];
        uint256 index = 0;
        uint256 amount = 0;

        for (
            uint256 i = startIndex;
            i < userStakeInfo[account].rewardDelayRecords.length;
            i++
        ) {
            if (
                userStakeInfo[account].rewardDelayRecords[i].endTime <=
                block.timestamp
            ) {
                index = i.add(1);
                amount = amount.add(
                    userStakeInfo[account].rewardDelayRecords[i].amount
                );
                delete userStakeInfo[account].rewardDelayRecords[i];
            } else {
                break;
            }
        }
        require(amount > 0, "Release amount must be greater than 0");
        if (index == userStakeInfo[account].rewardDelayRecords.length) {
            delete userStakeInfo[account].rewardDelayRecords;
            index = 0;
        }

        rewardClearIndex[account] = index;
        Token.safeTransfer(account, amount);
        emit RewardRelease(msg.sender, account, amount);
    }

    /**
     * @notice Redemption pool for reward injection
     *  @param rate Number of  reward rate
     */
    function notifyRewardAmount(uint256 rate)
        external
        onlyRewardDistribution
        updateReward(address(0), 0)
    {
        if (block.timestamp > startTime) {
            // if (block.timestamp >= periodFinish) {
            //     rewardRate = reward.div(DURATION);
            // } else {
            //     uint256 remaining = periodFinish.sub(block.timestamp);
            //     uint256 leftover = remaining.mul(rewardRate);
            //     rewardRate = reward.add(leftover).div(DURATION);
            // }
            // lastUpdateTime = block.timestamp;
            // emit RewardAdded(rate);
        } else {
            // rewardRate = reward.div(DURATION);
            lastUpdateTime = startTime;
            // emit RewardAdded(rate);
        }
        periodFinish = startTime.add(DURATION);
        rewardRate = rate;
        emit RewardAdded(rate);
    }

    /**
     * @notice setInviter Can bind referrer's address
     */
    function setInviter(address inviter_) public {
        require(inviter_ != address(0), "The inviter's address must not 0");
        require(
            userStakeInfo[msg.sender].inviter == address(0),
            "The inviter's address already exists"
        );
        require(
            inviter_ != msg.sender,
            "The inviter cannot be bound as himself"
        );
        require(
            userStakeInfo[inviter_].inviter != msg.sender,
            "The inviter has bound the sender address"
        );
        if (inviter_ != address(this)) {
            require(
                balanceOf(inviter_) > 0,
                "The inviter has not stake tokens"
            );
        }

        userStakeInfo[msg.sender].inviter = inviter_;
        emit SetInviter(msg.sender, inviter_);
    }

    /**
     * @notice Get the user's stake record list
     * @param account User's address
     */
    function getUserStakeRecords(address account)
        public
        view
        returns (LockRecord[] memory)
    {
        return userStakeInfo[account].stakeLockRecords;
    }

    /**
     * @notice Get the user's reward delayed record list
     * @param account User's address
     */
    function getUserRewardRecords(address account)
        public
        view
        returns (LockRecord[] memory)
    {
        return userStakeInfo[account].rewardDelayRecords;
    }

    /**
     * @notice rescue simple transfered ETH.
     */
    function rescue(address payable to_, uint256 amount_) external onlyOwner {
        require(to_ != address(0), "To must not 0");
        require(amount_ > 0, "Amount must gt 0");

        to_.transfer(amount_);
        emit Rescue(to_, amount_);
    }

    /**
     * @notice rescue simple transfered unrelated token.
     */
    function rescueToken(
        address to_,
        IERC20 token_,
        uint256 amount_
    ) external onlyOwner {
        require(to_ != address(0), "To must not 0");
        require(amount_ > 0, "Amount must gt 0");

        token_.transfer(to_, amount_);
        emit RescueToken(to_, address(token_), amount_);
    }
}