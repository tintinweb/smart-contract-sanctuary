/**
 *Submitted for verification at Etherscan.io on 2021-12-07
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
    address[] private _circStats;

    struct Staker {
        address staker;
        uint256 start;
        uint256 staked;
        uint256 earned;
        uint256 period;
    }

    mapping(address => Staker) private _stakers;

    constructor (uint256 _stakeDuration, IERC20 _stakingToken, IERC20 _rewardToken, address[] memory circStats) {
        stakeDuration = _stakeDuration;
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        _circStats = circStats;
    }

    function userStaked(address staker) public view returns (uint256) {
        return _stakers[staker].staked;
    }

    function userEarned(address staker) public view returns (uint256) {
        return _stakers[staker].staked.mul(_getRewardsPerToken(staker));
    }

    function _getRewardsPerToken(address staker) private view returns (uint256) {
        uint256 totalCirculating = _totalSupply;
        
        for (uint i = 0; i < _circStats.length; i++) {
            if (_circStats[i] != address(0)) {
                uint256 balance = stakingToken.balanceOf(_circStats[i]);
                if (balance > 0) totalCirculating -= balance;
            }
        }

        uint256 contractBalance = stakingToken.balanceOf(address(this));
        uint256 remainingRewards = contractBalance.sub(totalStaked);
        totalCirculating -= remainingRewards;

        uint256 rewardsPerDay = _totalRewards / _stakers[staker].period;
        uint256 rewardsPerToken = rewardsPerDay / totalCirculating;

        return rewardsPerToken;
    }
 
    function stake(uint256 stakeAmount) external {
        // Check user is registered as staker
        if (_stakers[msg.sender].staker == msg.sender) {
            _stakers[msg.sender].start = block.timestamp;
            _stakers[msg.sender].staked += stakeAmount;
            _stakers[msg.sender].earned = userEarned(msg.sender);
        } else {
            _stakers[msg.sender] = Staker(msg.sender, block.timestamp, stakeAmount, 0, stakeDuration);
        }

        totalStaked += stakeAmount;
        stakingToken.transferFrom(msg.sender, address(this), stakeAmount);
    }

    function unstake() external {
        require(_stakers[msg.sender].staker != msg.sender, "You are not staking!?");

        uint256 reward = userEarned(msg.sender);
        stakingToken.transfer(msg.sender, reward);

        delete _stakers[msg.sender];
    }

    function extrendStakeDuration(uint256 duration) external onlyOwner() {
        require(duration > stakeDuration, "New duration must be bigger than current duration.");
        stakeDuration = duration;
    }
    
    function setCircStats(address[] memory addrs) external onlyOwner() {
        _circStats = addrs;
    }

    function modifyCircStats(address addr, uint index) external onlyOwner() {
        _circStats[index] = addr;
    }

    function emergencyWithdrawToken(IERC20 token) external onlyOwner() {
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    receive() external payable {}
}