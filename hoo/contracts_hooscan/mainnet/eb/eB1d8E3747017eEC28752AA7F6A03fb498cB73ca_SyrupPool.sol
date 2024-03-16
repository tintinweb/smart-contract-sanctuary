// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './Ownable.sol';
import './ReentrancyGuard.sol';
import './SafeMath.sol';
import './SafeERC20.sol';
import './IERC20.sol';

contract SyrupPool is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    using SafeERC20 for IERC20;

    // The address of the smart chef factory
    address public POOL_FACTORY;

    // Whether a limit is set for users
    bool public hasUserLimit;

    // Whether it is initialized
    bool public isInitialized;

    // Accrued token per share
    uint256 public accTokenPerShare;

    // The block number when CAKE mining ends.
    uint256 public bonusEndBlock;

    // The block number when CAKE mining starts.
    uint256 public startBlock;

    // The block number of the last pool update
    uint256 public lastRewardBlock;

    uint256 public totalStaked;

    // The pool limit (0 if none)
    uint256 public poolLimitPerUser;

    // CAKE tokens created per block.
    uint256 public rewardPerBlock;

    // The precision factor
    uint256 public PRECISION_FACTOR;

    // The reward token
    IERC20 public rewardToken;

    // The staked token
    IERC20 public stakedToken;

    // Info of each user that stakes tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    struct UserInfo {
        uint256 amount; // How many staked tokens the user has provided

        uint256 rewardDebt; // Reward debt
    }

    event AdminTokenRecovery(address tokenRecovered, uint256 amount);

    event Deposit(address indexed user, uint256 amount);

    event EmergencyWithdraw(address indexed user, uint256 amount);

    event NewStartAndEndBlocks(uint256 startBlock, uint256 endBlock);

    event NewRewardPerBlock(uint256 rewardPerBlock);

    event NewPoolLimit(uint256 poolLimitPerUser);

    event RewardsStop(uint256 blockNumber);

    event RewardPaid(address indexed user, uint256 reward);

    event Withdraw(address indexed user, uint256 amount);

    constructor() {
        POOL_FACTORY = _msgSender();
    }

     function initialize(
         IERC20 _stakedToken,
         IERC20 _rewardToken,
         uint256 _rewardPerBlock,
         uint256 _startBlock,
         uint256 _bonusEndBlock,
         uint256 _poolLimitPerUser,
         address _admin) external onlyOwner {
        require(!isInitialized, "Already initialized");

        require(_msgSender() == POOL_FACTORY, "Not Pool factory");

        uint256 decimalsRewardToken = uint256(_rewardToken.decimals());

        require(decimalsRewardToken < 30, "Must be inferior to 30");

        // Make this contract initialized
        isInitialized = true;

        stakedToken = _stakedToken;

        rewardToken = _rewardToken;

        rewardPerBlock = _rewardPerBlock;

        startBlock = _startBlock;

        bonusEndBlock = _bonusEndBlock;

        if (_poolLimitPerUser > 0) {
            hasUserLimit = true;

            poolLimitPerUser = _poolLimitPerUser;
        }

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        PRECISION_FACTOR = uint256(10**(uint256(30).sub(decimalsRewardToken)));

        // Transfer ownership to the admin address who becomes owner of the contract
        transferOwnership(_admin);
    }

   /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param _tokenAddress: the address of the token to withdraw
     * @param _tokenAmount: the number of tokens to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address _tokenAddress, uint256 _tokenAmount) external onlyOwner {
        require(_tokenAddress != address(stakedToken), "Cannot be staked token");

        require(_tokenAddress != address(rewardToken), "Cannot be reward token");

        IERC20(_tokenAddress).safeTransfer(address(_msgSender()), _tokenAmount);

        emit AdminTokenRecovery(_tokenAddress, _tokenAmount);
    }

    /*
     * @notice Withdraw staked tokens without caring about rewards rewards
     * @dev Needs to be for emergency.
     */
    function emergencyWithdraw() external nonReentrant {
        UserInfo storage user = userInfo[_msgSender()];

        uint256 amountToTransfer = user.amount;

        user.amount = 0;

        user.rewardDebt = 0;

        if (amountToTransfer > 0) {
            stakedToken.safeTransfer(address(_msgSender()), amountToTransfer);

            totalStaked = totalStaked.sub(amountToTransfer);
        }

        emit EmergencyWithdraw(_msgSender(), user.amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner. Needs to be for emergency.
     */
    function emergencyRewardWithdraw(uint256 _amount) external onlyOwner {
        rewardToken.safeTransfer(address(_msgSender()), _amount);
    }

    /*
     * @notice Stop rewards
     * @dev Only callable by owner
     */
    function stopReward() external onlyOwner {
        bonusEndBlock = block.number;
    }

    /*
     * @notice Update pool limit per user
     * @dev Only callable by owner.
     * @param _hasUserLimit: whether the limit remains forced
     * @param _poolLimitPerUser: new pool limit per user
     */
    function updatePoolLimitPerUser(bool _hasUserLimit, uint256 _poolLimitPerUser) external onlyOwner {
        if (_hasUserLimit) {
            require(_poolLimitPerUser > poolLimitPerUser, "New limit must be higher");

            poolLimitPerUser = _poolLimitPerUser;
        } else {
            hasUserLimit = _hasUserLimit;
            
            poolLimitPerUser = 0;
        }

        emit NewPoolLimit(poolLimitPerUser);
    }

    /*
     * @notice Update reward per block
     * @dev Only callable by owner.
     * @param _rewardPerBlock: the reward per block
     */
    function updateRewardPerBlock(uint256 _rewardPerBlock) external onlyOwner {
        require(block.number < startBlock || startBlock == 0, "Pool has started");

        rewardPerBlock = _rewardPerBlock;

        emit NewRewardPerBlock(_rewardPerBlock);
    }

    /**
     * @notice It allows the admin to update start and end blocks
     * @dev This function is only callable by owner.
     * @param _startBlock: the new start block
     * @param _bonusEndBlock: the new end block
     */
    function updateStartAndEndBlocks(uint256 _startBlock, uint256 _bonusEndBlock) external onlyOwner {
        require(block.number < startBlock || startBlock == 0, "Pool has started");

        require(_startBlock < _bonusEndBlock, "New startBlock must be lower than new endBlock");
        
        require(block.number < _startBlock, "New startBlock must be higher than current block");

        startBlock = _startBlock;
        
        bonusEndBlock = _bonusEndBlock;

        // Set the lastRewardBlock as the startBlock
        lastRewardBlock = startBlock;

        emit NewStartAndEndBlocks(_startBlock, _bonusEndBlock);
    }

    /*
     * @notice Deposit staked tokens and collect reward tokens (if any)
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function deposit(uint256 _amount) external nonReentrant {
        require(startBlock > 0, "not initialized");

        UserInfo storage user = userInfo[_msgSender()];

        if (hasUserLimit) {
            require(_amount.add(user.amount) <= poolLimitPerUser, "User amount above limit");
        }

        _updatePool();

        if (user.amount > 0) {
            uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
          
            if (pending > 0) {
                rewardToken.safeTransfer(address(_msgSender()), pending);
            }
        }

        if (_amount > 0) {
            user.amount = user.amount.add(_amount);

            totalStaked = totalStaked.add(_amount);

            stakedToken.safeTransferFrom(address(_msgSender()), address(this), _amount);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);

        emit Deposit(_msgSender(), _amount);
    }

    /*
     * @notice Withdraw staked tokens and collect reward tokens
     * @param _amount: amount to withdraw (in rewardToken)
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(startBlock > 0, "not initialized");

        UserInfo storage user = userInfo[_msgSender()];

        require(user.amount >= _amount, "Amount to withdraw too high");

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);

            totalStaked = totalStaked.sub(_amount);

            stakedToken.safeTransfer(address(_msgSender()), _amount);

            emit Withdraw(_msgSender(), _amount);
        }

        if (pending > 0) {
            rewardToken.safeTransfer(address(_msgSender()), pending);

            emit RewardPaid(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
    }

    function getReward() public nonReentrant {
        require(startBlock > 0, "not initialized");

        UserInfo storage user = userInfo[_msgSender()];

        _updatePool();

        uint256 pending = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);

        if (pending > 0) {
            rewardToken.safeTransfer(address(_msgSender()), pending);

            emit RewardPaid(msg.sender, pending);
        }

        user.rewardDebt = user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR);
     }

    /*
     * @notice View function to see pending reward on frontend.
     * @param _user: user address
     * @return Pending reward for a given user
     */
    function pendingReward(address _user) external view returns (uint256) {
        require(startBlock > 0, "not initialized");

        UserInfo storage user = userInfo[_user];

        uint256 stakedTokenSupply = totalStaked; 

        if (block.number > lastRewardBlock && stakedTokenSupply != 0) {
            uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

            uint256 cakeReward = multiplier.mul(rewardPerBlock);

            uint256 adjustedTokenPerShare =
                accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));

            return user.amount.mul(adjustedTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
        }  
         
        return user.amount.mul(accTokenPerShare).div(PRECISION_FACTOR).sub(user.rewardDebt);
     }

     /*
     * @notice Update reward variables of the given pool to be up-to-date.
     */
    function _updatePool() internal {
        if (block.number <= lastRewardBlock) {
            return;
        }

        uint256 stakedTokenSupply = totalStaked;

        if (stakedTokenSupply == 0) {
            lastRewardBlock = block.number;

            return;
        }

        uint256 multiplier = _getMultiplier(lastRewardBlock, block.number);

        uint256 cakeReward = multiplier.mul(rewardPerBlock);

        accTokenPerShare = accTokenPerShare.add(cakeReward.mul(PRECISION_FACTOR).div(stakedTokenSupply));
     
        lastRewardBlock = block.number;
    }

    function _getMultiplier(uint256 _from, uint256 _to) internal view returns (uint256) {
      if (_to <= bonusEndBlock) {
            return _to.sub(_from);
      } 
        
      if (_from >= bonusEndBlock) {
          return 0;
      } 
    
      return bonusEndBlock.sub(_from); 
  }
}