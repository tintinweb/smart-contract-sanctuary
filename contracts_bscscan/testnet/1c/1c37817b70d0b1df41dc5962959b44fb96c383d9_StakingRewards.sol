/**
 *Submitted for verification at BscScan.com on 2021-10-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// Crypto Cars World Staking v1.0

contract StakingRewards {
    IERC20 public stakingToken;
    
    uint public rewardRate = 115800;
    uint public lastUpdateTime;
    uint public rewardPerTokenStored;
    uint public lockedTime = 1209600; // 14 days
    uint public initialTime = 604800; // 7 days
    
    address public owner;
    address public recipient;
    
    bool public isAvailable = true;
    
    mapping(address => uint) public userRewardPerTokenPaid;
    mapping(address => uint) public rewards;
    mapping(address => uint) public stakeStart;

    uint public _totalSupply;
    mapping(address => uint) public _balances;
    
    
    event StartStaked(address indexed owner, uint _amount, uint _time);
    event WitdrawStaked(address indexed owner, uint _amount, uint _time, bool _withPenalty);
    event WitdrawRewards(address indexed owner, uint _amount, uint _time, bool _withPenalty);
    
    
    constructor(address _stakingToken, address _recipient) {
        owner = msg.sender;
        stakingToken = IERC20(_stakingToken);
        recipient = _recipient;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }
    function changeRecipient(address _newRecipient) external onlyOwner{
        recipient = _newRecipient;
    }
    
    
    function pause() public onlyOwner{
        isAvailable = false;
    }
    function unpause() public onlyOwner{
        isAvailable = true;
    }
    
    function rewardPerToken() public view returns (uint) {
        if (_totalSupply == 0) {
            return 0;
        }
        return
            rewardPerTokenStored +
            (((block.timestamp - lastUpdateTime) * rewardRate * 1e6) / _totalSupply);
    }

    function earned(address account) public view returns (uint) {
        return
            ((_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e6) +
            rewards[account];
    }
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
        _;
    }
    
    function changeRate(uint _newRate) public onlyOwner{
        rewardRate = _newRate;
    }
    
    function stake(uint _amount) external updateReward(msg.sender) {
        require(isAvailable == true, "The Staking is Paused");
        _totalSupply += _amount;
        _balances[msg.sender] += _amount;
        stakeStart[msg.sender] = block.timestamp;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        
        emit StartStaked(msg.sender, _amount, block.timestamp);
    }
    
    function withdraw(uint256 _amount) external updateReward(msg.sender) {
        require( (block.timestamp - stakeStart[msg.sender]) >= initialTime, "Not time yet" ); 
        require(_balances[msg.sender] > 0, "You don't have any tokens Staked");
        require(_balances[msg.sender] >= _amount, "You don't have enought tokens in Staking");
        
        if((block.timestamp - stakeStart[msg.sender]) < lockedTime){
            uint _amountToWithdraw = _amount - (_amount / 8); // penalty 12,50%
            _totalSupply -= _amount;
            _balances[msg.sender] -= _amount;
            stakingToken.transfer(msg.sender, _amountToWithdraw);
            
            emit WitdrawStaked(msg.sender, _amountToWithdraw, block.timestamp, true);
            
        }else{
            _totalSupply -= _amount;
            _balances[msg.sender] -= _amount;
            stakingToken.transfer(msg.sender, _amount); // without penalty
            
            emit WitdrawStaked(msg.sender, _amount, block.timestamp, false);
            
        }
        
    }

    function getReward() external updateReward(msg.sender) {
        require( (block.timestamp - stakeStart[msg.sender]) >= initialTime, "Not time yet" ); 
        
        if((block.timestamp - stakeStart[msg.sender]) < lockedTime){
            uint reward = rewards[msg.sender] - (rewards[msg.sender] / 8); // penalty 12,50%
            rewards[msg.sender] = 0;
            stakingToken.transfer(msg.sender, reward);
            
            emit WitdrawRewards(msg.sender, reward, block.timestamp, true);
            
        }else{
            uint reward = rewards[msg.sender];
            rewards[msg.sender] = 0;
            stakingToken.transfer(msg.sender, reward); // without penalty
            
            emit WitdrawRewards(msg.sender, reward, block.timestamp, false);
        }
        
    }
    
    
    function changeLockedTime(uint _newLockedTime) public onlyOwner{
        lockedTime = _newLockedTime;
    }
    
    function changeInitialReward(uint _newInitialReward) public onlyOwner{
        initialTime = _newInitialReward;
    }
    
    function getStaked(address _account) external view returns(uint){
        return _balances[_account];
    }
    
    function withdrawOwner(uint _amount) external onlyOwner{
        stakingToken.transfer(owner, _amount);
    }
    function withdrawRecipient(uint _amount) external{
        require(msg.sender == owner || msg.sender == recipient, "You are not allowed");
        stakingToken.transfer(recipient, _amount);
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