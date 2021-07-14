/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath : subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
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
contract StakingReward {
    using SafeMath for uint256;
    address public owner;
    IERC20 public tokenAAddress;
    IERC20 public tokenBAddress;
    struct Stake {
        uint256 amount;
        uint256 stakeTime;
    }
    mapping(address => Stake) public stakes;
    mapping(address => uint256) public rewards;
    constructor(IERC20 _tokenAAddress, IERC20 _tokenBAddress) {
        owner = msg.sender;
        tokenAAddress = _tokenAAddress;
        tokenBAddress = _tokenBAddress;
    }
    function stake(uint256 _amount) public {
        require(msg.sender != owner, "Owner of the contract cannot stake");
        require(_amount > 0, "Staked amount cannot be zero");
        require(stakes[msg.sender].amount == 0, "User already has staked");
        require(IERC20(tokenAAddress).balanceOf(msg.sender) >= _amount, "Not enough balance to stake tokens");
        // Approve the staking contract so that it can transfer tokens from msg.sender to TokenB contract
        IERC20(tokenAAddress).transferFrom(msg.sender, address(this), _amount);
        // TokenA(tokenAAddress).transfer(address(this), _amount);
        stakes[msg.sender].stakeTime = block.timestamp;
        stakes[msg.sender].amount = _amount;
    }
    function reward() public returns(uint256) {
        require(stakes[msg.sender].amount > 0, "User has not staked");
        uint256 _reward =_giveReward(msg.sender);
        return _reward;
    }
    function withdraw() public {
        require(stakes[msg.sender].amount > 0, "User has not staked");
        // if(rewards[msg.sender] == 0) {
            _giveReward(msg.sender);
        // }
        IERC20(tokenAAddress).transfer(msg.sender, stakes[msg.sender].amount);
        delete stakes[msg.sender];
        // delete rewards[msg.sender];
    }
    function _giveReward(address _user) private returns(uint256) {
        uint256 _amount = stakes[_user].amount;
        uint256 noOfDays = ((block.timestamp).sub(stakes[_user].stakeTime)).div(1 days);
        noOfDays = (noOfDays == 0) ? 1 : noOfDays;
        uint256 _rewardedAmount = (noOfDays.mul(_amount)).div(100);
        require( IERC20(tokenBAddress).balanceOf(address(this)) > _rewardedAmount, "Not enough balance to give reward");
        IERC20(tokenBAddress).transfer(_user, _rewardedAmount);
        rewards[_user] = rewards[_user].add(_rewardedAmount);
        return _rewardedAmount;
    }
}