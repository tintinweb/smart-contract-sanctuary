// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";
import "./Address.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";

import "./IGEM.sol";
import "./Pausable.sol";

import "./IBEP20.sol";
import "./SafeBEP20.sol";

contract Temlple is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }
    // Info of each pool.
    struct PoolInfo {
        IBEP20 lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 lastRewardTimestamp; // Last block number that Rewards distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated Rewards per share, times 1e30. See below.
    }
    // The stake token
    IBEP20 public stakeToken;
    // The reward token
    IBEP20 public rewardToken;
    // Reward tokens created per block.
    uint256 public rewardPerSecond;
    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;
    // Info of each pool.
    PoolInfo public myPool;
    // Info of each user that stakes LP tokens.
    mapping(address => UserInfo) public userInfo;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when Reward mining starts.
    uint256 public startTimestamp;
    // The block number when mining ends.
    uint256 public bonusEndTimestamp;
    event Deposit(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);

    constructor(
        IBEP20 _stakeToken,
        IBEP20 _rewardToken,
        uint256 _rewardPerSecond,
        uint256 _startTimestamp,
        uint256 _bonusEndTimestamp
    ) {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        rewardPerSecond = _rewardPerSecond;
        startTimestamp = _startTimestamp;
        bonusEndTimestamp = _bonusEndTimestamp;
        // staking pool
        myPool = PoolInfo({
            lpToken: _stakeToken,
            allocPoint: 1000,
            lastRewardTimestamp: startTimestamp,
            accRewardTokenPerShare: 0
        });
        totalAllocPoint = 1000;
    }

    // Return reward multiplier over the given _from to _to block.
    function getMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndTimestamp) {
            return _to.sub(_from);
        } else if (_from >= bonusEndTimestamp) {
            return 0;
        } else {
            return bonusEndTimestamp.sub(_from);
        }
    }

    // View function to see pending Reward on frontend.
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokenPerShare = myPool.accRewardTokenPerShare;
        if (block.timestamp > myPool.lastRewardTimestamp && totalStaked != 0) {
            uint256 multiplier = getMultiplier(
                myPool.lastRewardTimestamp,
                block.timestamp
            );
            uint256 tokenReward = multiplier
                .mul(rewardPerSecond)
                .mul(myPool.allocPoint)
                .div(totalAllocPoint);
            accRewardTokenPerShare = accRewardTokenPerShare.add(
                tokenReward.mul(1e30).div(totalStaked)
            );
        }
        return
            user.amount.mul(accRewardTokenPerShare).div(1e30).sub(
                user.rewardDebt
            );
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool() public whenNotPaused {
        if (block.timestamp <= myPool.lastRewardTimestamp) {
            return;
        }
        if (totalStaked == 0) {
            myPool.lastRewardTimestamp = block.timestamp;
            return;
        }
        uint256 multiplier = getMultiplier(
            myPool.lastRewardTimestamp,
            block.timestamp
        );
        uint256 tokenReward = multiplier
            .mul(rewardPerSecond)
            .mul(myPool.allocPoint)
            .div(totalAllocPoint);
        myPool.accRewardTokenPerShare = myPool.accRewardTokenPerShare.add(
            tokenReward.mul(1e30).div(totalStaked)
        );
        myPool.lastRewardTimestamp = block.timestamp;
    }

    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) public whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];
        uint256 finalDepositAmount = 0;
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(myPool.accRewardTokenPerShare)
                .div(1e30)
                .sub(user.rewardDebt);
            if (pending > 0) {
                uint256 currentRewardBalance = rewardBalance();
                if (currentRewardBalance > 0) {
                    if (pending > currentRewardBalance) {
                        safeTransferReward(
                            address(msg.sender),
                            currentRewardBalance
                        );
                    } else {
                        safeTransferReward(address(msg.sender), pending);
                    }
                }
            }
        }
        if (_amount > 0) {
            uint256 preStakeBalance = totalStakeTokenBalance();
            myPool.lpToken.safeTransferFrom(
                address(msg.sender),
                address(this),
                _amount
            );
            finalDepositAmount = totalStakeTokenBalance().sub(preStakeBalance);
            user.amount = user.amount.add(finalDepositAmount);
            totalStaked = totalStaked.add(finalDepositAmount);
        }
        user.rewardDebt = user.amount.mul(myPool.accRewardTokenPerShare).div(
            1e30
        );
        emit Deposit(msg.sender, finalDepositAmount);
    }

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) public whenNotPaused {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool();
        uint256 pending = user
            .amount
            .mul(myPool.accRewardTokenPerShare)
            .div(1e30)
            .sub(user.rewardDebt);
        if (pending > 0) {
            uint256 currentRewardBalance = rewardBalance();
            if (currentRewardBalance > 0) {
                if (pending > currentRewardBalance) {
                    safeTransferReward(
                        address(msg.sender),
                        currentRewardBalance
                    );
                } else {
                    safeTransferReward(address(msg.sender), pending);
                }
            }
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            myPool.lpToken.safeTransfer(address(msg.sender), _amount);
            totalStaked = totalStaked.sub(_amount);
        }
        user.rewardDebt = user.amount.mul(myPool.accRewardTokenPerShare).div(
            1e30
        );
        emit Withdraw(msg.sender, _amount);
    }

    /// Obtain the reward balance of this contract
    /// @return wei balace of conract
    function rewardBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }

    // Deposit Rewards into contract
    function depositRewards(uint256 _amount) external {
        require(_amount > 0, "Deposit value must be greater than 0.");
        rewardToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        emit DepositRewards(_amount);
    }

    /// @param _to address to send reward token to
    /// @param _amount value of reward token to transfer
    function safeTransferReward(address _to, uint256 _amount) internal {
        rewardToken.safeTransfer(_to, _amount);
    }

    /* Admin Functions */
    /// @param _rewardPerSecond The amount of reward tokens to be given per block
    function setRewardPerSecond(uint256 _rewardPerSecond) external onlyOwner {
        rewardPerSecond = _rewardPerSecond;
    }

    /// @param  _bonusEndTimestamp The block when rewards will end
    function setBonusEndTimestamp(uint256 _bonusEndTimestamp)
        external
        onlyOwner
    {
        // new bonus end block must be greater than current
        bonusEndTimestamp = _bonusEndTimestamp;
    }

    /// @dev Obtain the stake token fees (if any) earned by reflect token
    function getStakeTokenFeeBalance() public view returns (uint256) {
        return totalStakeTokenBalance().sub(totalStaked);
    }

    /// @dev Obtain the stake balance of this contract
    /// @return wei balace of contract
    function totalStakeTokenBalance() public view returns (uint256) {
        // Return BEO20 balance
        return stakeToken.balanceOf(address(this));
    }

    /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees() external onlyOwner {
        uint256 stakeTokenFeeBalance = getStakeTokenFeeBalance();
        stakeToken.safeTransfer(msg.sender, stakeTokenFeeBalance);
        emit SkimStakeTokenFees(msg.sender, stakeTokenFeeBalance);
    }

    /* Emergency Functions */
    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        myPool.lpToken.safeTransfer(address(msg.sender), user.amount);
        totalStaked = totalStaked.sub(user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    // Withdraw reward. EMERGENCY ONLY.
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardBalance(), "not enough rewards");
        // Withdraw rewards
        safeTransferReward(address(msg.sender), _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    function emergencyRewardWithdrawTotal() external onlyOwner {
        uint256 _amount = rewardBalance();
        // Withdraw rewards
        safeTransferReward(address(msg.sender), _amount);
        emit EmergencyRewardWithdraw(msg.sender, _amount);
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }
}