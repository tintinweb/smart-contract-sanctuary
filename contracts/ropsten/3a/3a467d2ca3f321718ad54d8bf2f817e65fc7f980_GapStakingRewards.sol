/**
 *Submitted for verification at Etherscan.io on 2021-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.6;

library Math {
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function mint(address account, uint amount) external;

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function getRewardForDuration() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative

    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract RewardsDistributionRecipient is Ownable {
    address public rewardsDistribution;

    function notifyRewardAmount(uint256 reward) virtual external;

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "Caller is not RewardsDistribution contract");
        _;
    }

    function setRewardDistribution(address _rewardDistribution)
        external
        onlyOwner
    {
        rewardsDistribution = _rewardDistribution;
    }
}

contract GapStakingRewards is IStakingRewards, RewardsDistributionRecipient, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    IERC20 public rewardsToken;
    IERC20 public stakingToken;
    
    uint256 public periodFinish = 0;
    uint256 public rewardsDuration = 60 days;
    uint256 public minStake = 10e18;
    uint256 public tokenRewardRatio = 100;
    uint256 public freezeDuration = 14 days;

    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public rewardsPay;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => uint256) public initialStakeTime;

    constructor(
        address _rewardsDistribution,
        address _rewardsToken,
        address _stakingToken
    ) public {
        rewardsDistribution = _rewardsDistribution;
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    function lastTimeRewardApplicable() public view override returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }
    // reward by token
    function rewardPerToken() public view override returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
        rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    function earned(address account) public view override returns (uint256) {
        return _balances[account].mul(rewardPerToken().sub(userRewardPerTokenPaid[account])).div(1e18).add(rewards[account]);
    }

    function getRewardForDuration() external view override returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }
    
    function stakeOver() public view returns(uint256){
        if(periodFinish < block.timestamp){
            return 1;
        }
        return 0;
    }
  
    /* ========== MUTATIVE FUNCTIONS ========== */

    function onStake(address account, uint256 balanceBeforeStake, uint256 amount) internal{
        if (balanceBeforeStake < minStake && (balanceBeforeStake + amount) >= minStake)  {
            updateRewardInt(account);
        }
    }

    function stake(uint256 amount) external override nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        uint256 beforeStake = _balances[msg.sender];

        onStake(msg.sender, beforeStake, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        if (initialStakeTime[msg.sender] == 0) {
            initialStakeTime[msg.sender] = block.timestamp;
        }
        emit Staked(msg.sender, amount);
    }
    
    function onWithdraw(address account, uint256 balanceAfterWithdraw, uint256 amount) internal{
        if (balanceAfterWithdraw < minStake && (balanceAfterWithdraw + amount) >= minStake)  {
            updateRewardInt(account);
        }
    }
    
    function withdrawBalance(uint256 amount) internal{
        require(amount > 0, "Cannot withdraw 0");
        require(amount <= _balances[msg.sender], "Invalid withdraw amount");
        uint256 afterWithdraw = _balances[msg.sender].sub(amount);
        
        // update totalWeight base on my min stake
        onWithdraw(msg.sender, afterWithdraw, amount);

        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) public override nonReentrant updateReward(msg.sender) {
        require(initialStakeTime[msg.sender].add(freezeDuration) <= block.timestamp,"Freezed, cannot withdraw");
        withdrawBalance(amount);
    }
    
    function withdrawReward() internal{
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.safeTransfer(msg.sender, reward);
            uint256 payReward = rewardsPay[msg.sender];
            payReward = payReward.add(reward);
            rewardsPay[msg.sender] = payReward;
            emit RewardPaid(msg.sender, reward);
        }
    }
    
    function getReward() public override nonReentrant updateReward(msg.sender) {
        withdrawReward();
    }
    
    function exit() external override nonReentrant updateReward(msg.sender) {
        require(initialStakeTime[msg.sender].add(freezeDuration) <= block.timestamp,"Freezed, cannot exit");
        withdrawBalance(_balances[msg.sender]);
        withdrawReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function notifyRewardAmount(uint256 reward) external override onlyRewardsDistribution updateReward(address(0)) {
        require(reward > 0, "Invalid reward amount");
        rewardsToken.mint(address(this), reward);
        if(rewardRate == 0 || periodFinish <= block.timestamp){
            rewardRate = reward.div(rewardsDuration);
            periodFinish = block.timestamp.add(rewardsDuration);
        }
        else{
            uint256 times = reward.div(rewardRate);
            periodFinish = periodFinish.add(times);
        }
        lastUpdateTime = block.timestamp;
        emit RewardAdded(reward);
    }
    
    function updateRewardInt(address account) internal{
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address account) {
        updateRewardInt(account);
        _;
    }
    modifier onlyNotifyOne(){
        require(periodFinish == 0,"Just allow notify one time!");
        _;
    }
    /* ========== EVENTS ========== */

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    
}