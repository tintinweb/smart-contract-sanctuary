// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "SafeERC20.sol";
import "Ownable.sol";
import "Initializable.sol";

contract ProjDF is Ownable, Initializable {
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount;             // How many tokens the user has provided.
        uint256 blockStaked;        // What block the user staked in on.
        uint256 rewardDebt;         // Reward debt. See explanation below.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Rewards to distribute per block.
        uint256 firstRewardBlock;  // First block number that Rewards distribution occurs.
        uint256 accRewardTokenPerShare; // Accumulated Rewards per share, times 1e30. See below.
    }

    // In the event that further config is required, deposits can start disabled.
    bool public depositsEnabled = true;

    // The stake token
    IERC20 public STAKE_TOKEN;
    // The reward token
    IERC20 public REWARD_TOKEN;
    // Fees address
    address payable public feeAddress;

    // Reward tokens created per block.
    uint256 public rewardPerBlock;

    // Keep track of number of tokens staked in case the contract earns reflect fees
    uint256 public totalStaked = 0;

    // Deposit fee (if applicable), 100 = 1%.
    uint256 public depositFee = 0;
    // Max deposit fee (default: 5%).
    uint256 private maxDepositFee = 500;

    // Lockup time (if applicable) in blocks. (Polygon = 2S/Block)
    uint256 public harvestLockupBlocks = 0;
    // Max lockup blocks for vesting (default: 1 month on Polygon)
    uint256 private maxHarvestLockupBlocks = 1300000;

    // Minimum amount of blocks that must pass before a withdrawal is not considered "early"
    uint256 public earlyWithdrawalBlocks = 0;
    // Max blocks for early withdrawal (default: 1 week on Polygon)
    uint256 private maxEarlyWithdrawalBlocks = 300000;
    // Fee for exiting early (if applicable)
    uint public earlyWithdrawalFee = 0;
    // Max fee for exiting early (default: 2%)
    uint private maxEarlyWithdrawalFee = 200;

    // Info of each pool.
    PoolInfo public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping (address => UserInfo) public userInfo;
    // Total allocation poitns. Must be the sum of all allocation points in all pools.
    uint256 private totalAllocPoint = 0;
    // The block number when Reward mining starts.
    uint256 public startBlock;
    // The block number when mining ends.
    uint256 public endBlock;

    // Denotes if an owner-level rewards withdrawal has been requested
    bool public rewardsWithdrawalRequested = false;
    // Denotes which block rewards can be withdrawn at owner-level
    uint256 public rewardsWithdrawalBlock = 0;
    // Blocks required to wait until owner-level request to withdraw rewards. Default: 4 hours
    uint256 public blocksRequiredForWithdrawalRequest = 7200;

    // Block smart contracts from depositing tokens (nb: will also block multisig wallets)
    bool blockSmartContracts = false;

    event Deposit(address indexed user, uint256 amount);
    event DepositRewards(uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event SkimStakeTokenFees(address indexed user, uint256 amount);
    event LogUpdatePool(uint256 endBlock, uint256 rewardPerBlock);
    event EmergencyRewardWithdraw(address indexed user, uint256 amount);
    event EmergencySweepWithdraw(address indexed user, IERC20 indexed token, uint256 amount);
    event StartBlockUpdated(uint256 newStartBlock);
    event EarlyWithdrawalFeeSet(uint256 earlyWithdrawalFee);
    event DepositFeeSet(uint256 depositFee);
    event HarvestLockupBlocksSet(uint256 blocks);
    event EarlyWithdrawalBlocksSet(uint256 earlyWithdrawalBlocks);
    event FeeTaken(address indexed feeAddress, uint256 tokensTransferred);
    event RewardsWithdrawalRequested(uint256 unlockBlock);
    event RewardsWithdrawn();
    event DepositsEnabled();

    /// @dev Modifier which prevents execution if emissions have already begun.
    modifier beforeStart {
        require(startBlock > block.number, 'This action can only be executed before emissions have begun!');
        _;
    }

    function initialize(
        IERC20 _stakeToken,
        IERC20 _rewardToken,
        uint256 _rewardPerBlock,
        uint256 _startBlock,
        uint256 _endBlock,
        bool _depositsEnabled,
        bool _blockSmartContracts,
        address payable _feeAddress
    ) external initializer
    {
        STAKE_TOKEN = _stakeToken;
        REWARD_TOKEN = _rewardToken;
        rewardPerBlock = _rewardPerBlock;
        startBlock = _startBlock;
        endBlock = _endBlock;
        depositsEnabled = _depositsEnabled;
        blockSmartContracts = _blockSmartContracts;
        feeAddress = _feeAddress;

        // staking pool
        poolInfo = PoolInfo({
        lpToken: _stakeToken,
        allocPoint: 1000,
        firstRewardBlock: startBlock,
        accRewardTokenPerShare: 0
        });

        totalAllocPoint = 1000;
    }

    /// Return reward multiplier over the given _from to _to block.
    /// @param _from Starting block
    /// @param _to Ending block
    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= endBlock) {
            return _to - _from;
        } else if (_from >= endBlock) {
            return 0;
        } else {
            return endBlock - _from;
        }
    }

    /// Determines if a user can withdraw following any minimum staking period
    /// @param _stakedInBlock Block which the user staked in on
    /// @return True if minimum staking period has passed, otherwise false
    function canWithdrawWithoutLockup(uint256 _stakedInBlock) public view returns(bool) {
        uint256 noPenaltyBlock = harvestLockupBlocks + _stakedInBlock;
        if (block.number > noPenaltyBlock) {
            return true;
        }
        return false;
    }

    /// Determines if a user can withdraw without penalty following any minimum staking period
    /// @param _stakedInBlock Block which the user staked in on
    /// @return True if minimum staking period has passed, otherwise false
    function canWithdrawWithoutPenalty(uint256 _stakedInBlock) public view returns(bool) {
        uint256 noPenaltyBlock = earlyWithdrawalBlocks + _stakedInBlock;
        if (block.number > noPenaltyBlock) {
            return true;
        }
        return false;
    }

    /// View pending rewards
    /// @param _user Wallet ID of staked user
    /// @return Pending rewards
    function pendingReward(address _user) external view returns (uint256) {
        UserInfo storage user = userInfo[_user];
        uint256 accRewardTokenPerShare = poolInfo.accRewardTokenPerShare;
        if (block.number > poolInfo.firstRewardBlock && totalStaked != 0) {
            uint256 multiplier = getMultiplier(poolInfo.firstRewardBlock, block.number);
            uint256 tokenReward = multiplier * rewardPerBlock * poolInfo.allocPoint / totalAllocPoint;
            accRewardTokenPerShare = accRewardTokenPerShare + (tokenReward * 1e30 / totalStaked);
        }
        return user.amount * accRewardTokenPerShare / 1e30 - user.rewardDebt;
    }

    /// Update reward variables of the given pool to be up-to-date.
    function updatePool() public {
        if (block.number <= poolInfo.firstRewardBlock) {
            return;
        }
        if (totalStaked == 0) {
            poolInfo.firstRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(poolInfo.firstRewardBlock, block.number);
        uint256 tokenReward = multiplier * rewardPerBlock * poolInfo.allocPoint / totalAllocPoint;
        poolInfo.accRewardTokenPerShare = poolInfo.accRewardTokenPerShare + (tokenReward * 1e30 / totalStaked);
        poolInfo.firstRewardBlock = block.number;
    }


    /// Deposit staking token into the contract to earn rewards.
    /// @dev Since this contract needs to be supplied with rewards we are
    ///  sending the balance of the contract if the pending rewards are higher
    /// @param _amount The amount of staking tokens to deposit
    function deposit(uint256 _amount) public {
        require(depositsEnabled, 'Deposits have not yet been enabled.');
        if (blockSmartContracts) {
            require(msg.sender == tx.origin, "Smart Contracts cannot interact with this pool.");
        }
        UserInfo storage user = userInfo[msg.sender];
        uint256 finalDepositAmount = 0;
        updatePool();
        if (user.amount > 0) {
            uint256 pending = user.amount * poolInfo.accRewardTokenPerShare / 1e30 - user.rewardDebt;
            if(pending > 0) {
                uint256 currentRewardBalance = rewardBalance();
                if(currentRewardBalance > 0 && canWithdrawWithoutLockup(user.blockStaked)) {
                    if(pending > currentRewardBalance) {
                        safeTransferReward(address(msg.sender), currentRewardBalance);
                    } else {
                        safeTransferReward(address(msg.sender), pending);
                    }
                }
            }
        }
        if (_amount > 0) {
            uint256 preStakeBalance = STAKE_TOKEN.balanceOf(address(this));
            if (depositFee > 0) {
                uint256 _depositFee = _amount * depositFee / 10000;
                poolInfo.lpToken.safeTransferFrom(address(msg.sender), address(feeAddress), _depositFee);
                _amount = _amount - _depositFee;
                emit FeeTaken(feeAddress, _depositFee);
            }
            poolInfo.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            finalDepositAmount = STAKE_TOKEN.balanceOf(address(this)) - preStakeBalance;
            user.blockStaked = block.number;
            user.amount = user.amount + finalDepositAmount;
            totalStaked = totalStaked + finalDepositAmount;
        }
        user.rewardDebt = user.amount * poolInfo.accRewardTokenPerShare / 1e30;

        emit Deposit(msg.sender, finalDepositAmount);
    }

    /// Withdraw rewards and/or staked tokens. Pass a 0 amount to withdraw only rewards
    /// @param _amount The amount of staking tokens to withdraw
    function withdraw(uint256 _amount) public {
        UserInfo storage user = userInfo[msg.sender];
        require(user.amount >= _amount, "Error: insufficient output amount");
        require(canWithdrawWithoutLockup(user.blockStaked), "The minimum timespan for withdrawals has not yet passed.");
        updatePool();
        uint256 pending = user.amount * poolInfo.accRewardTokenPerShare / 1e30 - user.rewardDebt;
        if(pending > 0) {
            uint256 currentRewardBalance = rewardBalance();
            if(currentRewardBalance > 0) {
                if(pending > currentRewardBalance) {
                    safeTransferReward(address(msg.sender), currentRewardBalance);
                } else {
                    safeTransferReward(address(msg.sender), pending);
                }
            }
        }
        if(_amount > 0) {
            if (earlyWithdrawalFee > 0 && !canWithdrawWithoutPenalty(user.blockStaked)) {
                uint256 withdrawalFee = _amount * earlyWithdrawalFee / 10000;
                poolInfo.lpToken.safeTransferFrom(address(this), address(feeAddress), withdrawalFee);
                _amount = _amount - withdrawalFee;
                emit FeeTaken(feeAddress, withdrawalFee);
            }
            user.amount = user.amount - _amount;
            poolInfo.lpToken.safeTransfer(address(msg.sender), _amount);
            totalStaked = totalStaked - _amount;
        }

        user.rewardDebt = user.amount * poolInfo.accRewardTokenPerShare / 1e30;

        emit Withdraw(msg.sender, _amount);
    }

    /// Obtain the reward balance of this contract
    /// @return wei balace of contract
    function rewardBalance() public view returns (uint256) {
        uint256 balance = REWARD_TOKEN.balanceOf(address(this));
        if (STAKE_TOKEN == REWARD_TOKEN)
            return balance - totalStaked;
        return balance;
    }

    /// Deposit Rewards into contract
    /// @param _amount Amount of tokens to deposit
    function depositRewards(uint256 _amount) external {
        require(_amount > 0, 'Deposit value must be greater than 0.');
        REWARD_TOKEN.safeTransferFrom(address(msg.sender), address(this), _amount);
        emit DepositRewards(_amount);
    }

    /// @param _to address to send reward token to
    /// @param _amount value of reward token to transfer
    function safeTransferReward(address _to, uint256 _amount) internal {
        REWARD_TOKEN.safeTransfer(_to, _amount);
    }

    /// @dev Obtain the stake balance of this contract
    function totalStakeTokenBalance() public view returns (uint256) {
        if (STAKE_TOKEN == REWARD_TOKEN)
            return totalStaked;
        return STAKE_TOKEN.balanceOf(address(this));
    }

    /// @dev Obtain the stake token fees (if any) earned by reflect token
    function getStakeTokenFeeBalance() public view returns (uint256) {
        return STAKE_TOKEN.balanceOf(address(this)) - totalStaked;
    }

    /* Admin Functions */

    /// @param _rewardPerBlock The amount of reward tokens to be given per block
    function setRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        rewardPerBlock = _rewardPerBlock;
        emit LogUpdatePool(endBlock, rewardPerBlock);
    }

    /// @dev Remove excess stake tokens earned by reflect fees
    function skimStakeTokenFees() external onlyOwner {
        uint256 stakeTokenFeeBalance = getStakeTokenFeeBalance();
        STAKE_TOKEN.safeTransfer(msg.sender, stakeTokenFeeBalance);
        emit SkimStakeTokenFees(msg.sender, stakeTokenFeeBalance);
    }

    /// @param  _endBlock The block when rewards will end
    function setEndBlock(uint256 _endBlock) external onlyOwner {
        require(_endBlock > endBlock, 'New end block must be greater than the current.');
        endBlock = _endBlock;
        emit LogUpdatePool(endBlock, rewardPerBlock);
    }

    /// @param _startBlock The block when rewards will start
    function setStartBlock(uint256 _startBlock) external onlyOwner beforeStart {
        startBlock = _startBlock;
        poolInfo.firstRewardBlock = _startBlock;
        emit StartBlockUpdated(_startBlock);
    }

    /// @param _depositFee Deposit fee for staked tokens, in hundredths of a percent
    function setDepositFee(uint256 _depositFee) external onlyOwner beforeStart {
        require(_depositFee <= maxDepositFee, 'Cannot exceed max deposit fee!');
        depositFee = _depositFee;
        emit DepositFeeSet(depositFee);
    }

    /// @param _earlyWithdrawalFee Withdrawal fee for leaving staking early, in hundredths of a percent
    function setEarlyWithdrawalFee(uint256 _earlyWithdrawalFee) external onlyOwner beforeStart {
        require (_earlyWithdrawalFee <= maxEarlyWithdrawalFee, 'Cannot exceed max early withdrawal fee!');
        earlyWithdrawalFee = _earlyWithdrawalFee;
        emit EarlyWithdrawalFeeSet(earlyWithdrawalFee);
    }

    /// @param _earlyWithdrawalBlocks Amount of blocks that must pass before a user can un-stake without penalty
    function setEarlyWithdrawalBlocks(uint256 _earlyWithdrawalBlocks) external onlyOwner beforeStart {
        require (_earlyWithdrawalBlocks <= maxEarlyWithdrawalBlocks, 'Cannot exceed max early withdrawal blocks!');
        earlyWithdrawalBlocks = _earlyWithdrawalBlocks;
        emit EarlyWithdrawalFeeSet(earlyWithdrawalFee);
    }

    /// @param _harvestLockupBlocks Amount of blocks that must pass before a user can un-stake
    function setHarvestLockupBlocks(uint256 _harvestLockupBlocks) external onlyOwner beforeStart {
        require(_harvestLockupBlocks <= maxHarvestLockupBlocks, 'Cannot exceed max harvest lockup blocks!');
        harvestLockupBlocks = _harvestLockupBlocks;
        emit HarvestLockupBlocksSet(harvestLockupBlocks);
    }

    /// @dev Enable deposits for staking
    function enableDeposits() external onlyOwner {
        depositsEnabled = true;
        emit DepositsEnabled();
    }

    /* Emergency Functions */

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw() external {
        UserInfo storage user = userInfo[msg.sender];
        poolInfo.lpToken.safeTransfer(address(msg.sender), user.amount);
        totalStaked = totalStaked - user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        emit EmergencyWithdraw(msg.sender, user.amount);
    }

    /// @dev Request removal of rewards balance, in the event a redeploy or otherwise is required.
    /// This should only be called in the case of an emergency, with the intention of disabling the pool.
    function requestRewardsWithdrawal() external onlyOwner {
        earlyWithdrawalFee = 0;
        earlyWithdrawalBlocks = 0;
        harvestLockupBlocks = 0;
        depositFee = 0;
        depositsEnabled = false;
        rewardsWithdrawalRequested = true;
        rewardsWithdrawalBlock = block.number + blocksRequiredForWithdrawalRequest;
        emit RewardsWithdrawalRequested(rewardsWithdrawalBlock);
    }

    /// @dev Withdraw rewards
    function rewardsWithdrawal() external onlyOwner {
        require(rewardsWithdrawalRequested, 'Rewards withdrawal not yet requested!');
        require(block.number > rewardsWithdrawalBlock, 'Not yet reached the rewards withdrawal block!');
        uint256 currentRewardBalance = rewardBalance();
        if(currentRewardBalance > 0) {
            safeTransferReward(address(msg.sender), currentRewardBalance);
        }
        emit RewardsWithdrawn();
    }

    /// @notice A public function to sweep accidental BEP20 transfers to this contract.
    ///   Tokens are sent to owner
    /// @param token The address of the BEP20 token to sweep
    function sweepToken(IERC20 token) external onlyOwner {
        require(address(token) != address(STAKE_TOKEN), "can not sweep stake token");
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
        emit EmergencySweepWithdraw(msg.sender, token, balance);
    }

}