// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.5.17;

import "./Math.sol";
import "./SafeMath.sol";
import "./ReentrancyGuard.sol";
import "./SafeERC20.sol";
import "./Owned.sol";
import "./Context.sol";


contract IRewardPool {
    function notifyRewards(uint reward) external;
}

contract Aggregator is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    /// Protocol developers rewards
    uint public constant FEE_FACTOR = 3;

    // Beneficial address
    address public beneficial;

    /// Reward token
    IERC20 public rewardToken;

    // Reward pool address
    address public rewardPool;

    constructor(address _token1, address _rewardPool) public {
        beneficial = msg.sender;
        
        rewardToken = IERC20(_token1);
        rewardPool = _rewardPool;
    }

    /// Capture tokens or any other tokens
    function capture(address _token) onlyOwner external {
        require(_token != address(rewardToken), "capture: can not capture reward tokens");

        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(beneficial, balance);
    }  

    function notifyRewards() onlyOwner nonReentrant external {
        uint reward = rewardToken.balanceOf(address(this));

        /// Split the governance and protocol developers rewards
        uint _developerRewards = reward.div(FEE_FACTOR);
        uint _governanceRewards = reward.sub(_developerRewards);

        rewardToken.safeTransfer(beneficial, _developerRewards);
        rewardToken.safeTransfer(rewardPool, _governanceRewards);

        IRewardPool(rewardPool).notifyRewards(_governanceRewards);
    }
}

contract RewardPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint;

    event TokenDeposit(address account, uint amount);
    event TokenWithdraw(address account, uint amount);
    event TokenClaim(address account, uint amount);
    event RewardAdded(uint reward);

    bytes32 public merkleRoot;

    uint public periodFinish = 0;
    uint public rewardRate = 0;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored = 0;
    uint public rewardsDuration = 7 days;

    // Beneficial address
    address public beneficial = address(this);

    // User award balance
    mapping(address => uint) public rewards;
    mapping(address => uint) public userRewardPerTokenPaid;

    /// Staking token
    IERC20 private _token0;

    /// Reward token
    IERC20 private _token1;

    /// Total rewards
    uint private _rewards;
    uint private _remainingRewards;

    /// Total amount of user staking tokens
    uint private _totalSupply;

    /// The amount of tokens staked
    mapping(address => uint) private _balances;

    /// The remaining withdrawals of staked tokens
    mapping(address => uint) internal withdrawalOf;  

    /// The remaining withdrawals of reward tokens
    mapping(address => uint) internal claimOf;

    address public rewardDistribution;

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardDistribution() {
        require(msg.sender == rewardDistribution, "Caller is not reward distribution");
        _;
    }
    
    constructor (address token0, address token1) public {
        require(token0 != address(0), "FeePool: zero address");
        require(token1 != address(0), "FeePool: zero address");

        _token0 = IERC20(token0);
        _token1 = IERC20(token1);
    }

    function setBeneficial(address _beneficial) onlyOwner external {
        require(_beneficial != address(this), "setBeneficial: can not send to self");
        require(_beneficial != address(0), "setBeneficial: can not burn tokens");
        beneficial = _beneficial;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardDistribution = _rewardDistribution;
    }
    
    /// Capture tokens or any other tokens
    function capture(address _token) onlyOwner external {
        require(_token != address(_token0), "capture: can not capture staking tokens");
        require(_token != address(_token1), "capture: can not capture reward tokens");
        require(beneficial != address(this), "capture: can not send to self");
        require(beneficial != address(0), "capture: can not burn tokens");
        uint balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(beneficial, balance);
    }  

    function _setMerkleRoot(bytes32 merkleRoot_) internal {
        merkleRoot = merkleRoot_;
    }

    function notifyRewards(uint reward)
        external
        onlyRewardDistribution
        updateReward(address(0))
    {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint remaining = periodFinish.sub(block.timestamp);
            uint leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = _token1.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "notifyRewards: provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    /// Deposit staking tokens
    function deposit(uint amount) 
        external 
        nonReentrant
        updateReward(msg.sender)
    {
        /// Verify the eligible wallet        
        require(amount > 0, "deposit: cannot stake 0");
        require(_token0.balanceOf(msg.sender) >= amount, "deposit: insufficient balance");
        
        _totalSupply = _totalSupply.add(amount);          
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        _token0.safeTransferFrom(msg.sender, address(this), amount);
        
        emit TokenDeposit(msg.sender, amount);
    }

    /// Withdraw staked tokens
    function withdraw(uint amount) 
        external 
        nonReentrant
        updateReward(msg.sender)
    {
        require(amount > 0, "withdraw: amount invalid");
        require(msg.sender != address(0), "withdraw: zero address");
        /// Not overflow
        require(_balances[msg.sender] >= amount);
        _totalSupply = _totalSupply.sub(amount);                
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        /// Keep track user withdraws
        withdrawalOf[msg.sender] = withdrawalOf[msg.sender].add(amount); 
        _token0.safeTransfer(msg.sender, amount);
        emit TokenWithdraw(msg.sender, amount);
    }

    /// Claim reward tokens
    function claim() 
        external 
        nonReentrant
        updateReward(msg.sender)
    {
        require(msg.sender != address(0), "claim: zero address");        
        uint reward = rewards[msg.sender];
        require(reward > 0, "claim: zero rewards");        
        require(_token1.balanceOf(address(this)) >= reward, "claim: insufficient balance");        

        rewards[msg.sender] = 0;
        claimOf[msg.sender] = claimOf[msg.sender].add(reward);
        _token1.safeTransfer(msg.sender, reward);
        emit TokenClaim(msg.sender, reward);
    }

    function getWithdrawalOf(address _stakeholder) external view returns (uint) {
        return withdrawalOf[_stakeholder];
    }

    function getClaimOf(address _stakeholder) external view returns (uint) {
        return claimOf[_stakeholder];
    }

    /// Get remaining rewards of the time period
    function remainingRewards() external view returns(uint) {
        return _remainingRewards;
    }

    /// Retrieve the stake for a stakeholder
    function stakeOf(address _stakeholder) external view returns (uint) {
        return _balances[_stakeholder];
    }

    /// Retrieve the stake for a stakeholder
    function rewardOf(address _stakeholder) external view returns (uint) {
        return earned(_stakeholder);
    }

    function lastTimeRewardApplicable() public view returns (uint) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint) {
        if (getTotalStakes() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored.add(
                lastTimeRewardApplicable()
                    .sub(lastUpdateTime)
                    .mul(rewardRate)
                    .mul(1e18)
                    .div(getTotalStakes())
            );
    }

    function earned(address account) public view returns (uint) {
        return balanceOf(account)
            .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
            .div(1e18)
            .add(rewards[account]);
    }

    /// The total supply of all staked tokens
    function getTotalStakes() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint) {
        return _balances[account];
    }     
}