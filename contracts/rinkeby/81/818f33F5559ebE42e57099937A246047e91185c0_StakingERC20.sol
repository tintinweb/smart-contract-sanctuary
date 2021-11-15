// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

contract StakingERC20 {
    
    using SafeMath for uint256;
    ManagerRole public manager;

    struct StakeHolder {
        bool isClaimed;                 // Current Staking status
        uint256 amount;                 // Current active stake
        uint256 stakedBlock;            // Last staked block (if any)
        uint256 releaseBlock;           // Last claimed block (if any)
        uint256 claimedOn;              // Last time claimed
        uint256 rewards;                // Rewards
    }
    mapping (address => StakeHolder) public StakeHolders;
    
    address public stakeToken;

    bool public isStakingActive;
    bool public isStakingPaused;
    
    uint256 public stakingPool;
    uint256 public stakingPoolRewards;
    uint256 public stakingStartTime;
    uint256 public stakingDuration;
    uint256 public noOfStakingBlocks;
    uint256 public poolOpenTime;
    uint256 public stakingStartBlock;
    uint256 public stakingEndBlock;
    address private hotWallet;
    
    // 6440 is the avg no.of Ethereum Blocks per day, Applicable only for Ethereum network 
    uint256 public avgETHBlocksPerDay = 6440;
    uint256 public currentPool;

    event Staked(address _address, uint256 stakedTokens);
    event Claimed(address _address, uint256 stakedTokens, uint256 claimedTokens);

    /**
     * @param _stakingToken address of the Token which user stakes
     * @param _stakingPool is the total no.of tokens to meet the requirement to start the staking
     * @param _stakingPoolRewards is the total no.of rewards for the _rewardCapital
     * @param _poolOpenTime is the pool opening time (like count down)
     * @param _stakingStartTime is the starting block of staking in epoch
     * @param _stakingDuration is the statking duration of staking ex: 30 days, 60 days, 90 days... in days
     * @param _manager is to manage the managers of the contracts
     */
    constructor(address _stakingToken, uint256 _stakingPool, uint256 _stakingPoolRewards, uint256 _poolOpenTime, uint256 _stakingStartTime, uint256 _stakingDuration, ManagerRole _manager) {
        stakeToken= _stakingToken;
        stakingPool = _stakingPool;
        stakingPoolRewards = _stakingPoolRewards;
        poolOpenTime = _poolOpenTime;
        stakingStartTime = _stakingStartTime;
        stakingDuration = _stakingDuration;
        calculateBlocks(_stakingDuration);
        statkingStartsOn();
        stakingEndsOn();
        manager = _manager;
        isStakingActive = true;
        isStakingPaused = false;
        setHotWallet();
    }
    
    function calculateBlocks(uint256 _days) internal {
        // Comment in Testing
        // noOfStakingBlocks = 1;
        // noOfStakingBlocks = noOfStakingBlocks.mul(_days).mul(avgETHBlocksPerDay);

        // Comment in Production
        noOfStakingBlocks = 50;
    }

    function setHotWallet() internal {
        hotWallet = manager.getHotWallet();
    }
    
    function statkingStartsOn() internal {
        stakingStartBlock = currentBlockNumber();
    }
    
    function stakingEndsOn() internal {
        stakingEndBlock = stakingStartBlock.add(noOfStakingBlocks);
    }
    
    modifier onlyManager {
        require(manager.isManager(msg.sender), "Manager:: Unauthorized Access");
        _;
    }
    
    modifier onlyGovernance {
        require(manager.governance() == msg.sender, "Governance:: Unauthorized Access");
        _;
    }

    /**
     * @dev Stake Tokens
     */
    function stake(uint256 _noOfTokens) external {
        require(isStakingActive == true, "Stake:: Staking is not started");
        require(isStakingPaused == false, "Stake:: Staking is paused");
        require(_noOfTokens > 0, "Stake:: Can not stake Zero Tokens");
        require(currentBlockTimestamp() > poolOpenTime, "Stake:: Staking have not started for this pool");
        require(currentBlockTimestamp() < stakingStartTime, "Stake:: Staking Closed");
        require(stakingPool > currentPool, "Stake:: Staking Pool is Full");
        IERC20(stakeToken).transferFrom(msg.sender, address(this), _noOfTokens);
        updateStakingInfo(_noOfTokens);
        emit Staked(msg.sender, _noOfTokens);
    }
    
    /**
     * @dev Update Stake Info in StakeHolder
     */
    function updateStakingInfo(uint256 _noOfTokens) internal {
        StakeHolders[msg.sender].amount = StakeHolders[msg.sender].amount.add(_noOfTokens);
        StakeHolders[msg.sender].isClaimed = false;
        StakeHolders[msg.sender].stakedBlock = block.number;
        StakeHolders[msg.sender].releaseBlock = stakingEndBlock;
        StakeHolders[msg.sender].rewards = calculateStakingReward(_noOfTokens);
        currentPool = currentPool.add(_noOfTokens);
    }
    
    /**
     * @dev Calculate Staking Reward based on the stake
     */
    function calculateStakingReward(uint256 _noOfTokens) internal view returns (uint256) {
        uint256 userShareInPool = (_noOfTokens.mul(100)).div(stakingPool);
        return StakeHolders[msg.sender].rewards.add((userShareInPool.mul(stakingPoolRewards)).div(100));
    }
    
    /**
     * @dev claimStake to claim staking & also rewards
     */
    function claimStake() external {
        require(isStakingPaused == false, "ClaimStake:: Claiming is Paused");
        require(StakeHolders[msg.sender].isClaimed == false, "ClaimStake:: Already Claimed");
        require(StakeHolders[msg.sender].amount > 0, "ClaimStake:: Seems like haven't staked to claim");
        require(currentBlockNumber() > StakeHolders[msg.sender].releaseBlock, "ClaimStake:: You can not claim before staked duration");
        require(IERC20(stakeToken).balanceOf(address(this)) >= StakeHolders[msg.sender].amount, "ClaimStake:: Invalid Balance");
        require(IERC20(stakeToken).balanceOf(address(this)) >= StakeHolders[msg.sender].rewards, "ClaimStake:: Invalid Balance");
        uint256 claimedTokens = StakeHolders[msg.sender].amount;
        uint256 claimedRewards = StakeHolders[msg.sender].rewards;
        IERC20(stakeToken).transfer(msg.sender, StakeHolders[msg.sender].amount);
        IERC20(stakeToken).transfer(msg.sender, StakeHolders[msg.sender].rewards);
        updateClaimInfo();
        emit Claimed(msg.sender, claimedTokens, claimedRewards);
    }
    
    /**
     * @dev Update Claim Info in StakeHolder
     */
    function updateClaimInfo() internal {
        StakeHolders[msg.sender].isClaimed = true;
        StakeHolders[msg.sender].amount = 0;
        StakeHolders[msg.sender].rewards = 0;
        StakeHolders[msg.sender].releaseBlock = 0;
        StakeHolders[msg.sender].claimedOn = currentBlockTimestamp();
    }

    /**
     * @dev Pause Staking of the Tokens, this restrict user to stake and claim.
     */
    function pauseStaking() external onlyManager {
        isStakingPaused = true;
    }

    /**
     * @dev Unpause Staking of the Tokens, this allow user to stake and claim.
     */
    function unPauseStaking() external onlyManager {
        isStakingPaused = false;
    }

    /**
     * @dev Returns current Block Timestamp
     */
    function currentBlockTimestamp() internal view returns (uint256) {
        return block.timestamp;
    }

    /**
     * @dev Returns current Block Timestamp
     */
    function currentBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev Returns the claim status of the current active stake
     * @notice there will be only one active stake at all the time
     * @param _address of the user to whom you want to know the claim status
     */    
    function claimStatus(address _address) external view returns (bool) {
        return StakeHolders[_address].isClaimed;
    }

    /**
     * @dev Governance function to calculate the rewards to maintain in Contract
     * @notice this scenario never occur, but just to calculate the rewards
     */
    function rewardsToMaintain() external onlyManager view returns (uint256) {
        uint256 currentBalance = IERC20(stakeToken).balanceOf(address(this));
        uint256 total = stakingPool.add(stakingPoolRewards);
        return total.sub(currentBalance);
    }
    
    function safeWithdrawalBefore(uint256 _noOfTokens) external onlyManager {
        require(currentBlockNumber() < stakingEndBlock, "SafeWithdrawalBefore:: Invalid withdraw");
        require(IERC20(stakeToken).balanceOf(address(this)) >= _noOfTokens, "SafeWithdrawalBefore:: Invalid Balance");
        IERC20(stakeToken).transfer(hotWallet, _noOfTokens);
    }
    
    function safeWithdrawalAfter() external onlyManager {
        require(currentBlockNumber() > stakingEndBlock, "SafeWithdrawalAfter:: Invalid withdraw");
        uint256 total = stakingPool.add(stakingPoolRewards);
        require(IERC20(stakeToken).balanceOf(address(this)) >= total, "SafeWithdrawalAfter:; Invalid Balance");
        uint256 difference = IERC20(stakeToken).balanceOf(address(this)).sub(total);
        if(difference > 0) {
            IERC20(stakeToken).transfer(hotWallet, difference);   
        }
    }
}

contract ManagerRole {
    address public superAdmin;
    address _hotWallet;

    event ManagerAdded(address _manager, bool _status);
    event ManagerUpdated(address _manager, bool _status);
    
    constructor(address _wallet) {
        superAdmin = msg.sender;
        _hotWallet = _wallet;
    }
    
    modifier onlySuperAdmin {
        require(superAdmin == msg.sender, "Unauthorized Access");
        _;
    }

    struct Manager {
        address _manager;
        bool _isActive;
    }
    
    mapping (address => Manager) public managers;
    
    function addManager(address _address, bool _status) external onlySuperAdmin {
        require(_address != address(0), "Manager can't be the zero address");
        managers[_address]._manager = _address;
        managers[_address]._isActive = _status;
        emit ManagerAdded(_address, _status);
    }
    
    function getManager(address _address) view external returns (address, bool) {
        return(managers[_address]._manager, managers[_address]._isActive);
    }

    function isManager(address _address) external view returns(bool _status) {
        return(managers[_address]._isActive);
    }
    
    function updateManager(address _address, bool _status) external onlySuperAdmin {
        require(managers[_address]._isActive != _status);
        managers[_address]._isActive = _status;
        emit ManagerUpdated(_address, _status);
    }
    
    function governance() external view returns(address){
        return superAdmin;
    }
    
    function getHotWallet() external view returns(address) {
        return _hotWallet;
    }
    
    function setNewHotWallet(address _newHotWallet) external onlySuperAdmin {
        _hotWallet = _newHotWallet;
    }
    
}

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
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
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
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
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

