// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./lib.sol";

interface LockToken {
    struct LockRecord {
        address user;
        uint256 tokenAmount;
        uint256 lockTokenAmount;
        uint256 lockBlockNumber;
        uint256 unlockBlockNumber;
        bool unlocked;
    }
    function denominator()external view returns(uint256);
    function stakeTokenRatio()external view returns(uint256);
    function  totalLockTokenAmount()external view returns(uint256 _totalLockTokenAmount);
    function getUserAllStakedToken(address _user) external view returns (uint256 _tokenAmount, uint256 _lockTokenAmount);
    function getLockRecord(uint256 _id) view external returns (address _user, uint256 _tokenAmount,
    uint256 _lockTokenAmount, uint256 _lockBlockNumber, uint256 _unlockBlockNumber, bool _unlocked);
    function lock(address _forUser, uint256 _amount, uint256 _lockTokenBlockNumber) external returns (uint256 _id) ;
    function unlock(address _forUser,uint256 _lockRecordId) external;
    function stake(address _forUser, uint256 _tokenAmount) external;
    function unstake(address _forUser, uint256 _tokenAmount) external;
}

contract StakingPool is Ownable, CheckContract, BaseMath {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant REWARD_PRECISION = 1e18;
    IERC20 public token;
    IERC20 public lockToken;
    LockToken public lockContract;
    uint256 public startBlock;
    uint256 public minimumLockAmount;

    mapping(IERC20 => uint256) public totalRewards;
    // the total rewards of tokens for per stake
    mapping(IERC20 => uint256) public totalRewardsPerStaked;
    mapping(IERC20 => bool) public tokens;

    // all the tokens being reward
    IERC20[] public rewardTokens;
    mapping(address => mapping (uint256 => bool)) public userLockId;
    mapping(address => mapping(IERC20 => uint256)) public userTokenSnapshots;

    // --- Events ---
    event LockTokenSet(IERC20 _lockToken);
    event TokenSet(IERC20 _token);
    event LockContractSet(LockToken _lockToken);
    event StartBlockSet(uint256 _startBlock);
    event AdminSet(address _account, bool _isAdmin);
    event MinimumLockQuantitySet(uint256 _minimumLockAmount);
    event Restart();
    event StakeChanged(address _staker, uint256 _newStake);
    event HarvestAll(address _staker);
    event Harvest(address _staker, IERC20 _tokenAddress, uint256 _tokenReward);
    event RewardUpdated(IERC20 _rewardtokenAddress, uint256 _reward, uint256 _tokenReward, uint256 addedTokenRewardPerLockToken);
    event totalLockTokenUpdated(uint256 _totalLockToken);
    event StakerSnapshotsUpdated(address _staker, IERC20 _token, uint256 _reward);
    event EmergencyStop(address _user, address _to);
    event UnstakeWithoutReward(address _user, uint256 _lockTokenAmount);
    event UnlockWithoutReward(address _user, uint256 _lockId);
    event AddRewardToken(IERC20 _newToken);
    event DelRewardToken(IERC20 _delToken);

    bool public stopped;
    modifier notStopped virtual {
        require(!stopped, "StakingPool: this pool is stopped!");
        _;
    }

    mapping(address => bool) public admins;
    modifier onlyAdmin virtual {
        require(admins[msg.sender] || msg.sender == owner());
        _;
    }

    modifier started virtual {
        require(startBlock <= block.number, "StakingPool: Pool not start!");
        _;
    }

    constructor(uint256 _startBlock, uint256 _minimumLockAmount)  {
        startBlock = _startBlock;
        minimumLockAmount = _minimumLockAmount;
        admins[msg.sender] = true;
        emit AdminSet(msg.sender, true);
    }

    function setStartBlock(uint256 _startBlock) external onlyOwner{
        startBlock = _startBlock;
        emit StartBlockSet(_startBlock);
    }

    function setAddresses
    (
        IERC20 _token,
        LockToken _lockContract,
        IERC20 _lockToken
    )
        external
        onlyOwner

    {
        checkContract(address(_token));
        checkContract(address(_lockContract));
        checkContract(address(_lockToken));
        token = _token;
        lockContract = _lockContract;
        lockToken = _lockToken;
        emit LockTokenSet(_lockToken);
        emit TokenSet(_token);
        emit LockContractSet(_lockContract);
    }

    function setAdmin(address _account, bool _isAdmin) external onlyOwner {
        admins[_account] = _isAdmin;
        emit AdminSet(_account, _isAdmin);
    }

    function setMinimumLockQuantity(uint256 _minimumLockAmount) external onlyOwner {
        minimumLockAmount = _minimumLockAmount;
        emit MinimumLockQuantitySet(_minimumLockAmount);
    }

    function lock(address _forUser, uint256 _amount, uint256 _lockTokenBlockNumber) external started notStopped {
        _requireNonZeroAmount(_amount);
        require(_forUser != address(0), 'StakingPool : _forUser can not be Zero');
        require(_amount >= minimumLockAmount, 'StakingPool : token amount must be greater than minimumLockAmount');
        harvestAll(_forUser);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        token.safeIncreaseAllowance(address(lockContract), _amount);
        lockContract.lock(_forUser, _amount, _lockTokenBlockNumber);
    }

    // If requested amount > stake, send their entire stake.
    function unlock(address _forUser, uint256 _lockRecordId) external {
        harvestAll(_forUser);
        unlockWithoutReward(_forUser, _lockRecordId);
    }

    function unlockWithoutReward(address _forUser, uint256 _lockRecordId) public {
        require(_forUser != address(0), 'StakingPool : _forUser can not be Zero');
        (, uint256 _userLockTokenAmount) = lockContract.getUserAllStakedToken(_forUser);
        if (_requireUserHasStake(_userLockTokenAmount)){
            (,,uint256 _lockTokenAmount,,,) = lockContract.getLockRecord(_lockRecordId);
            lockToken.safeTransferFrom(msg.sender, address(this), _lockTokenAmount);
            // lockToken.safeIncreaseAllowance(address(lockContract), _lockTokenAmount);
            lockContract.unlock(_forUser,_lockRecordId);
            emit UnlockWithoutReward(_forUser, _lockRecordId);
        }
    }

    function stake(address _forUser, uint256 _amount) external started notStopped {
        require(_forUser != address(0), 'StakingPool : _forUser can not be Zero');
        _requireNonZeroAmount(_amount);
        // require(_tokenAmount >= minimumLockAmount, 'StakingPool :  token amount must be greater than minimumLockAmount');
        harvestAll(_forUser);
        token.safeTransferFrom(msg.sender, address(this), _amount);
        token.safeIncreaseAllowance(address(lockContract), _amount);
        lockContract.stake(_forUser, _amount);
    }

    //unstake by token amount
    function unstake(address _forUser, uint256 _lockTokenAmount) external {
        harvestAll(_forUser);
        unstakeWithoutReward(_forUser, _lockTokenAmount);
    }

    //unstake by token amount
    function unstakeWithoutReward(address _forUser, uint256 _amount) public {
        require(_forUser != address(0), 'StakingPool: _forUser can not be Zero');
        //require(msg.sender != address(0), 'StakingPool: _forUser can not be Zero');
        require(_amount >= 0, 'StakingPool: token amount must be greater than Zero');
        uint256 lockTokenAmount = _amount.mul(lockContract.stakeTokenRatio()).div(lockContract.denominator());
        lockToken.safeTransferFrom(msg.sender, address(this), lockTokenAmount);
        // lockToken.safeIncreaseAllowance(address(lockContract), lockTokenAmount);
        lockContract.unstake(_forUser, _amount);
        emit UnstakeWithoutReward(_forUser, _amount);
    }

    function harvest(address _forUser, IERC20 _rewardToken) public {
        require(_forUser != address(0), 'StakingPool: _forUser can not be Zero');
        require(address(_rewardToken) != address(0), 'StakingPool: _rewardToken can not be Zero');
        require(tokens[_rewardToken], "StakingPool: _rewardToken not support!");
        (,uint256 _lockTokenAmount) = lockContract.getUserAllStakedToken(_forUser);
        if (_requireUserHasStake(_lockTokenAmount)){
            uint256 reward = _pendingReward(_rewardToken, _forUser);
            if(reward > 0){
                _rewardToken.safeTransfer(_forUser, reward);
                emit Harvest(_forUser, _rewardToken, reward);
                _updateUserSnapshot(_forUser, _rewardToken);
            }
        }
    }

    function harvestAll(address _forUser) public {
        require(_forUser != address(0), 'StakingPool: _forUser can not be Zero');
        for (uint256 i = 0; i < rewardTokens.length; i++){
            harvest(_forUser, rewardTokens[i]);
        }
        emit HarvestAll(_forUser);
    }

    function increaseTokenReward(IERC20 _token, uint256 _reward) external notStopped started onlyAdmin {
        require(address(_token) != address(0), 'StakingPool: _token can not be Zero');
        // _requireCallerIsBorrowerOperations();
        _requireNonZeroAmount(_reward);
        require(tokens[_token], "StakingPool : _token not supported!");
        require(_token.balanceOf(msg.sender) >= _reward, "StakingPool : reward is not enough!");
        _token.safeTransferFrom(msg.sender, address(this), _reward);
        totalRewards[token] = totalRewards[token].add(_reward);
        uint256 addedTokenRewardPerLockToken = 0;
        if (lockContract.totalLockTokenAmount() > 0) {
            addedTokenRewardPerLockToken = _reward.mul(REWARD_PRECISION).div(lockContract.totalLockTokenAmount());
            totalRewardsPerStaked[_token] = totalRewardsPerStaked[_token].add(addedTokenRewardPerLockToken);
        }
        emit RewardUpdated(_token, _reward, totalRewardsPerStaked[_token], addedTokenRewardPerLockToken);
    }

    // --- Pending reward functions ---
    function pendingReward(IERC20 _token, address _user) external view returns (uint256) {
        return _pendingReward(_token, _user);
    }

    function _pendingReward(IERC20 _token, address _user) internal view returns (uint256) {
        require(address(_token) != address(0), 'StakingPool: _token can not be Zero');
        require(address(_user) != address(0), 'StakingPool: _user can not be Zero');
        uint256 tokenSnapshot = userTokenSnapshots[_user][_token];
        (, uint256 _lockTokenAmount) = lockContract.getUserAllStakedToken(msg.sender);
         if (_requireUserHasStake(_lockTokenAmount)){
             return _lockTokenAmount.mul(totalRewardsPerStaked[_token].sub(tokenSnapshot)).div(REWARD_PRECISION);
         }else{
             return 0;
         }
    }

    function _updateUserSnapshot(address _user, IERC20 _rewardToken) internal {
        if (address(_user) != address(0) && address(_rewardToken) != address(0)){
            userTokenSnapshots[_user][_rewardToken] = totalRewardsPerStaked[_rewardToken];
            emit StakerSnapshotsUpdated(_user, _rewardToken, totalRewardsPerStaked[_rewardToken]);
        }
    }

    // --- Account auth functions ---
    function addRewardToken(IERC20 _newToken) external onlyOwner {
        require(!tokens[_newToken], "StakingPool : Token is existing!");
        require(address(_newToken) != address(0), "StakingPool : _newToken cannot be zero address");
        rewardTokens.push(_newToken);
        tokens[_newToken] = true;
        emit AddRewardToken(_newToken);
    }

    function delRewardToken(IERC20 _delToken) external onlyOwner {
        require(address(_delToken) != address(0), "StakingPool : _delToken cannot be zero address");
        require(totalRewards[_delToken] == 0, "StakingPool : this token have rewards!");
        tokens[_delToken] = false;
        for (uint256 i = 0; i < rewardTokens.length; i++){
            if (rewardTokens[i] == _delToken){
                for (uint256 j = i; j < rewardTokens.length - 1; j++) {
                    rewardTokens[j] = rewardTokens[j + 1];
                }
                rewardTokens.pop();
                break;
            }
        }
        emit DelRewardToken(_delToken);
    }

    function emergencyStop(address  _to) external onlyOwner {
        if (_to == address(0)) {
            _to = msg.sender;
        }
         for (uint256 i = 0; i < rewardTokens.length; i++){
            if (address(rewardTokens[i]) != address(0) && address(rewardTokens[i]) != address(token) && address(rewardTokens[i]) != address(lockToken)){
                uint256 addrBalance = rewardTokens[i].balanceOf(address(this));
                if (addrBalance > 0) {
                   rewardTokens[i].safeTransfer(_to, addrBalance);
                }
                totalRewardsPerStaked[rewardTokens[i]] = 0;
            }
        }
        stopped = true;
        emit EmergencyStop(msg.sender, _to);
    }

    function restart() external onlyOwner{
        stopped = true;
        emit Restart();
    }

    function _requireUserHasStake(uint256 _currentStake) internal pure returns(bool) {
         if (_currentStake > 0) {
            return true;
        }else{
            return false;
        }
    }

    function _requireNonZeroAmount(uint256 _amount) internal pure {
        require(_amount > 0, 'StakingPool : Amount must be non-zero');
    }
}