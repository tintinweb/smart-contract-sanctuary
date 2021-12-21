/**
 *Submitted for verification at Etherscan.io on 2021-12-21
*/

/**
 *Submitted for verification at Etherscan.io on 2017-10-10
*/
// SPDX-License-Identifier: GPL-3.0

pragma solidity >0.7.0 <0.9.0;

contract TestCoin {
    string public symbol = "TCN";
    string public name = "Testcoin";
    uint8 public constant decimals = 8;
    uint256 _totalSupply = 0;
	uint256 _maxTotalSupply = 2100000000000000; // 最大供应量
	uint256 _miningReward = 100000000; // 1 BTCM - To be halved every 4 years  挖矿奖励
	uint256 _maxMiningReward = 5000000000; // 50 BTCM - To be halved every 4 years
	uint256 _rewardHalvingTimePeriod = 126227704; //4 years
	uint256 _nextRewardHalving = block.timestamp + _rewardHalvingTimePeriod;
	uint256 _rewardTimePeriod = 600; //10 minutes
	uint256 _rewardStart = block.timestamp;
	uint256 _rewardEnd = block.timestamp + _rewardTimePeriod;
	uint256 _currentMined = 0;
    address owner;

    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    function totalSupply() public view returns (uint256) {        
		return _totalSupply;
    }
 
 // 获取指定地址的余额
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
 
 // 给一个地址发送指定代币
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
 // 指定发送地址 和 接收地址 和 发送代币数量
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) public returns (bool success) {
        if (balances[_from] >= _amount
            && allowed[_from][msg.sender] >= _amount
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[_from] -= _amount;
            allowed[_from][msg.sender] -= _amount;
            balances[_to] += _amount;
            emit Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
 // 授权一个地址可使用的代币
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }
 
 // 
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function Mine() public returns (bool success)
	{
		// 判断现在时间 是否小于奖励结束时间  挖出的
		if (block.timestamp < _rewardEnd && _currentMined >= _maxMiningReward)
			revert();
		else if (block.timestamp >= _rewardEnd)
		{
			_rewardStart = block.timestamp;
			_rewardEnd = block.timestamp + _rewardTimePeriod;
			_currentMined = 0;
		}
	
		if (block.timestamp >= _nextRewardHalving)
		{
			_nextRewardHalving = block.timestamp + _rewardHalvingTimePeriod;
			_miningReward = _miningReward / 2;
			_maxMiningReward = _maxMiningReward / 2;
			_currentMined = 0;
			_rewardStart = block.timestamp;
			_rewardEnd = block.timestamp + _rewardTimePeriod;
		}	
		
		if ((_currentMined < _maxMiningReward) && (_totalSupply < _maxTotalSupply))
		{
			balances[msg.sender] += _miningReward;
			_currentMined += _miningReward;
			_totalSupply += _miningReward;
			emit Transfer(address(this), msg.sender, _miningReward);
			return true;
		}				
		return false;
	}
	
	function MaxTotalSupply()public view returns(uint256)
	{
		return _maxTotalSupply;
	}
	
	function MiningReward()public view returns(uint256)
	{
		return _miningReward;
	}
	
	function MaxMiningReward() public view returns(uint256)
	{
		return _maxMiningReward;
	}
	
	function RewardHalvingTimePeriod() public view returns(uint256)
	{
		return _rewardHalvingTimePeriod;
	}
	
	function NextRewardHalving() public view returns(uint256)
	{
		return _nextRewardHalving;
	}
	
	function RewardTimePeriod() public view returns(uint256)
	{
		return _rewardTimePeriod;
	}
	
	function RewardStart() public view returns(uint256)
	{
		return _rewardStart;
	}
	
	function RewardEnd() public view returns(uint256)
	{
		return _rewardEnd;
	}
	
	function CurrentMined() public view returns(uint256)
	{
		return _currentMined;
	}
	
	function TimeNow() public view returns(uint256)
	{
		return block.timestamp;
	}

    function ownerbalancereturner() public {
        owner = msg.sender; 
    }

    function getOwnerBalance()  public view returns (uint) {
        return owner.balance;
    }
}