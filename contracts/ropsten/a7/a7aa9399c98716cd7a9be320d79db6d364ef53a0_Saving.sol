/**
 *Submitted for verification at Etherscan.io on 2021-02-15
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint balance);
    function transfer(address to, uint amount) external returns (bool);
    
    function allowance(address account, address from) external view returns (uint256);
    function approve(address from, uint amount) external returns (bool);
    function transferFrom(address from, address to, uint amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed account, address indexed from, uint amount);
}

contract TokenWraper {
    ERC20Interface public _token = ERC20Interface(0xBd3f621732288233aa355b9E1445b77637Df8036);

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    function _save(uint256 amount) internal {
        _token.transferFrom(msg.sender, address(this), amount);
        _totalSupply += amount;
        _balances[msg.sender] += amount;
    }

    function _withdraw(uint256 amount) internal {
        _token.transfer(msg.sender, amount);
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
    }
}

contract Saving is TokenWraper {
    address public founder;
    uint256 public timeLock = 1 hours; // return unix epoch
    uint256 public percentRewardYearly; // % yearly
    mapping(address => uint256) public claimRewardTimestamp;
    mapping(address => uint256) public lockedUntil;
    uint256 public rewardBalance;
    
    ERC20Interface public token = ERC20Interface(0xBd3f621732288233aa355b9E1445b77637Df8036);
    
    event Saved(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event Donate(address indexed user, uint256 reward);
    
    modifier isFounder() {
        require(msg.sender == founder);
        _;
    }
    
    constructor(uint256 _percentRewardYearly) {
        percentRewardYearly = _percentRewardYearly;
        founder = msg.sender;
    }
    
    function setNewFounder(address newAddress) public isFounder {
        founder = newAddress;
    }
    
    function setPercentRewardYearly(uint256 _percent) public isFounder {
        percentRewardYearly = _percent;
    }
    
    function _rewardEarnedPerSecond(address account) public view returns(uint256) {
        uint256 _savedAccount = balanceOf(account);
        uint256 _expectedRewardYearly = _savedAccount * percentRewardYearly;
        _expectedRewardYearly = _expectedRewardYearly / 100;
        uint256 _yearly = 1 days;
        uint256 _reward = _expectedRewardYearly / _yearly;
        return _reward;
    }
    
    function donation(uint256 _amount) public {
        require(_amount > 0, "Cannot save 0");
        super._save(_amount);
        rewardBalance += _amount;
        emit Donate(msg.sender, _amount);
    }
    
    function rewardEarned(address account) public view returns(uint256) {
        uint256 _rewardPerSecond = _rewardEarnedPerSecond(account);
        uint256 _claimRewardTimestamp = claimRewardTimestamp[account];
        uint256 _currentTime = block.timestamp;
        uint256 _rangeTime = _currentTime - _claimRewardTimestamp;
        uint256 _rewardEarned = _rewardPerSecond * _rangeTime;
        return _rewardEarned;
    }
    
    function save(uint256 _amount) public {
        require(_amount > 0, "Cannot save 0");
        super._save(_amount);
        uint256 _currentTime = block.timestamp;
        claimRewardTimestamp[msg.sender] = _currentTime;
        lockedUntil[msg.sender] = _currentTime + timeLock;
        emit Saved(msg.sender, _amount);
    }
    
    function withdraw(uint256 _amount) public {
        require(lockedUntil[msg.sender] > 0, "No user found.");
        require(lockedUntil[msg.sender] < block.timestamp, "Not unlocked yet.");
        require(_amount > 0, "Cannot withdraw 0");
        super._withdraw(_amount);
        emit Withdrawn(msg.sender, _amount);
    }
    
    function getReward() public {
        uint256 _rewardEarned = rewardEarned(msg.sender);
        require(rewardBalance > _rewardEarned, "Reward balance not enough.");
        if (_rewardEarned > 0) {
            token.transfer(msg.sender, _rewardEarned);
            rewardBalance -= _rewardEarned;
            claimRewardTimestamp[msg.sender] = block.timestamp;
            emit RewardPaid(msg.sender, _rewardEarned);
        }
    }
}