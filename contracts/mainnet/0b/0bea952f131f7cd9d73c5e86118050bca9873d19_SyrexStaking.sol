/**
 *Submitted for verification at Etherscan.io on 2021-12-16
*/

pragma solidity ^0.8.10;

// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner() {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract SyrexStaking is Ownable {
    using SafeMath for uint256;

    uint256 public stakeDuration;
    uint256 public totalStaked;
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 private _totalSupply = 1e8 * 10**9;
    uint256 private _totalRewards = 1e7 * 10**9;

    struct Staker {
        address staker;
        uint256 start;
        uint256 staked;
        uint256 earned;
        uint256 period;
    }

    mapping(address => Staker) private _stakers;

    constructor (uint256 _stakeDuration, IERC20 _stakingToken, IERC20 _rewardToken) {
        stakeDuration = _stakeDuration.mul(1 days);
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
    }

    function isStaking(address stakerAddr) public view returns (bool) {
        return _stakers[stakerAddr].staker == stakerAddr;
    }

    function userStaked(address staker) public view returns (uint256) {
        return _stakers[staker].staked;
    }

    function userEarnedTotal(address staker) public view returns (uint256) {
        uint256 currentlyEarned = _userEarned(staker);
        uint256 previouslyEarned = _stakers[msg.sender].earned;

        if (previouslyEarned > 0) return currentlyEarned.add(previouslyEarned);
        return currentlyEarned;
    }

    function _userEarned(address staker) private view returns (uint256) {
        require(isStaking(staker), "User is not staking.");

        uint256 rewardPerDay = _rewardsPerDay(staker);
        uint256 secsPerDay = 1 days / 1 seconds;
        uint256 rewardsPerSec = rewardPerDay.div(secsPerDay);

        uint256 stakerSharePercentage = _sharePercentage(staker);

        uint256 stakersStartInSeconds = _stakers[staker].start.div(1 seconds);
        uint256 blockTimestampInSeconds = block.timestamp.div(1 seconds);
        uint256 secondsStaked = blockTimestampInSeconds.sub(stakersStartInSeconds);

        uint256 earned = rewardsPerSec.mul(stakerSharePercentage).mul(secondsStaked).div(10**9);

        return earned.div(10**9);
    }

    function _sharePercentage(address staker) private view returns (uint256) {
        uint256 stakerStaked = _stakers[staker].staked;
        uint256 stakerSharePercentage = stakerStaked.mul(10**9).div(totalStaked);

        return stakerSharePercentage;
    }

    function _periodInDays(address staker) private view returns (uint256) {
        uint256 periodInDays = _stakers[staker].period.div(1 days);

        return periodInDays;
    }
    
    function _rewardsPerDay(address staker) private view returns (uint256) {
        uint256 periodInDays = _periodInDays(staker);
        uint256 rewardsPerDay = _totalRewards.div(periodInDays);

        return rewardsPerDay.mul(10**9);
    }
 
    function stake(uint256 stakeAmount) external {
        // Check user is registered as staker
        if (isStaking(msg.sender)) {
            _stakers[msg.sender].staked += stakeAmount;
            _stakers[msg.sender].earned += _userEarned(msg.sender);
            _stakers[msg.sender].start = block.timestamp;
        } else {
            _stakers[msg.sender] = Staker(msg.sender, block.timestamp, stakeAmount, 0, stakeDuration);
        }

        totalStaked += stakeAmount;
        stakingToken.transferFrom(msg.sender, address(this), stakeAmount);
    }
    
    function claim() external {
        require(isStaking(msg.sender), "You are not staking!?");

        uint256 reward = userEarnedTotal(msg.sender);
        stakingToken.transfer(msg.sender, reward);

        _stakers[msg.sender].start = block.timestamp;
        _stakers[msg.sender].earned = 0;
    }

    function unstake() external {
        require(isStaking(msg.sender), "You are not staking!?");

        uint256 reward = userEarnedTotal(msg.sender);
        stakingToken.transfer(msg.sender, _stakers[msg.sender].staked.add(reward));

        totalStaked -= _stakers[msg.sender].staked;

        delete _stakers[msg.sender];
    }

    function extrendStakeDuration(uint256 duration) external onlyOwner() {
        require(duration > stakeDuration, "New duration must be bigger than current duration.");
        stakeDuration = duration;
    }

    function emergencyWithdrawToken(IERC20 token) external onlyOwner() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    receive() external payable {}
}