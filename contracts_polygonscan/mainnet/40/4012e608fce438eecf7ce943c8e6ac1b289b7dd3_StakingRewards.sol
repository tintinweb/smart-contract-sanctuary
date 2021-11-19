/**
 *Submitted for verification at polygonscan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract StakingRewards {
    IERC20 public KRL;
    uint256 private rewardRate = 9737802706552708;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userTimeLock;
    mapping(address => uint256) public userLastupdate;

    uint public _totalSupply;
    mapping(address => uint256) public _balances;

    constructor(address _KRL) {
        KRL = IERC20(_KRL);
    }

    function rewardPerToken() public view returns (uint256) {
        return rewardRate;
    }

    function earned(address account) public view returns (uint256) {
        uint256 __time = userLastupdate[account];
        uint256 stakedTime = block.timestamp - __time;
        uint256 totalReward = stakedTime * (rewardRate * _balances[account]) / 10 ** 42;
        return (totalReward - rewards[account]);
    }
    
    function estimate(uint256 _bal, uint256 _time, bool _wei) public view returns(uint256){
        if (_wei == true) {
            return (_time * (rewardRate * _bal) )/ 10 ** 42;
        }
        return (_time * (rewardRate * _bal)) / 10 ** 24;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function currentReward(address account) public view returns (uint256) {
        return rewards[account];
    }
    
    function totalRewardsEarned(address account) public view returns (uint256) {
        return userRewardPerTokenPaid[account];
    }
    
    function stakePeriod(address account) public view returns (uint256) {
        return userTimeLock[account] * 1 weeks;
    }
    
    function stake(uint _amount, uint duration) external {
        require(duration <= 52, 'Duration should be less than 52 weeks');
        if (_balances[msg.sender] > 1) {
            _getReward(msg.sender);
        }
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        userTimeLock[msg.sender] = duration;
        userLastupdate[msg.sender] = block.timestamp;
        rewards[msg.sender] = 0;
        KRL.transferFrom(msg.sender, address(this), _amount);
    }

    function withdraw(uint256 _amount) external {
        uint __time = userLastupdate[msg.sender] + (userTimeLock[msg.sender] * 1 weeks);
        require(block.timestamp >= __time, 'UserError: TOKEN LOCK PERIOD');
        if (_balances[msg.sender] > 1) {
            _getReward(msg.sender);
        }
        _totalSupply -= _amount;
        _balances[msg.sender] -= _amount;
        userLastupdate[msg.sender] = block.timestamp;
        rewards[msg.sender] = 0;
        KRL.transfer(msg.sender, _amount);
    }

    function getReward() external {
        _getReward(msg.sender);
    }
    
    function _getReward(address account) internal {
        uint reward = earned(account);
        rewards[account] += reward;
        userRewardPerTokenPaid[account] += reward;
        KRL.transfer(account, reward);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}