/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

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


// File contracts/utils/Math.sol
library Math {

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? b : a;
    }


    function abs(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a > b) ? a - b : b - a;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}


// File contracts/RewardPool.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract RewardPool {

    IERC20 public immutable rewardsToken;
    IERC20 public immutable stakingToken;
    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public constant rewardsDuration = 1000000;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    address public rewardsDistribution;
    address public owner;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event RewardAdded(uint256 reward);
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Transfer(address from, address to, uint256 amount);
    event Approval(address _owner, address spender, uint256 amount);
    event OwnershipTransferred(address indexed currentOwner, address indexed newOwner);
    event DitributionTransferred(address indexed currentDistribution, address indexed newDistribution);

    constructor(
        address _rewardsToken,
        address _stakingToken,
        address _rewardsDistribution
    ) {
        rewardsToken = IERC20(_rewardsToken);
        stakingToken = IERC20(_stakingToken);
        rewardsDistribution = _rewardsDistribution;
        owner = msg.sender;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    modifier onlyRewardsDistribution() {
        require(msg.sender == rewardsDistribution, "RewardPool : Caller is not RewardsDistribution");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "RewardPool : Function called by unautorized user");
        _;
    }

    function transferOwnership(address account) external onlyOwner {
        require(account != address(0), "RewardPool : cannot transfer ownership to zero address");
        emit OwnershipTransferred(owner, account);
        owner = account;
    }

    function setDistribution(address account) external onlyOwner {
        require(account != address(0), "RewardPool : cannot set distribution to zero address");
        emit DitributionTransferred(rewardsDistribution, account);
        rewardsDistribution = account;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function allowance(address _owner, address spender) external view returns (uint256) {
        return _allowances[_owner][spender];
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, periodFinish);
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18 / _totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return _balances[account] * (rewardPerToken() - userRewardPerTokenPaid[account]) / 1e18 + rewards[account];
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate * rewardsDuration;
    }

    function getRewardRate() external view returns (uint256) {
        return rewardRate;
    }

    function getUserReward(address account) external view returns (uint256) {
        return rewards[account];
    }

    function deposit(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "RewardPool : Cannot stake 0");

        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        stakingToken.transferFrom(msg.sender, address(this), amount);
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "RewardPool : Cannot withdraw 0");

        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        stakingToken.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardsToken.transfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function transfer(address to, uint256 amount) external updateReward(msg.sender) updateReward(to) {
        require(to != address(0), "RewardPool : Cannot transfer to zero_address");
        require(to != msg.sender, "RewardPool : Cannot transfer to myself");

        _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external {
        require(spender != address(0), "RewardPool : Cannot approve to zero_address");
        require(spender != msg.sender, "RewardPool : Cannot approve to myself");

        _approve(msg.sender, spender, amount);
    }

    function transferFrom(address from, address to, uint256 amount) external updateReward(from) updateReward(to) {
        require(to != address(0), "RewardPool : Cannot transferFrom to zero_address");
        require(to != from, "RewardPool : Cannot transferFrom to myself");

        _transfer(from, to, amount);
        _approve(from, msg.sender, _allowances[from][msg.sender] - amount);
    }

    function notifyRewardAmount(uint256 reward) external onlyRewardsDistribution updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward / rewardsDuration;
        } else {
            uint256 remaining = periodFinish - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / rewardsDuration;
        }

        uint balance = rewardsToken.balanceOf(address(this));
        require(rewardRate <= balance / rewardsDuration, "RewardPool : Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + rewardsDuration;
        emit RewardAdded(reward);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        _balances[from] = _balances[from] - amount;
        _balances[to] = _balances[to] + amount;

        emit Transfer(from, to, amount);
    }

    function _approve(address _owner, address spender, uint256 amount) internal {
        _allowances[_owner][spender] = amount;

        emit Approval(_owner, spender, amount);
    }
}