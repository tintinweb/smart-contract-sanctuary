pragma solidity ^0.4.18;

contract BitcoinGalaxy {
    string public symbol = "BTCG";
    string public name = "BitcoinGalaxy";
    uint8 public constant decimals = 8;
    uint256 _totalSupply = 0;
	uint256 _maxTotalSupply = 2100000000000000;
	uint256 _adminsupply = 500000000000000;//Admin Supply of 5 Million Coins
	uint256 _miningReward = 10000000000; //1 BTCG - To be halved every 4 years
	uint256 _maxMiningReward = 1000000000000; //50 BTCG - To be halved every 4 years
	uint256 _rewardHalvingTimePeriod = 126227704; //4 years
	uint256 _nextRewardHalving = now + _rewardHalvingTimePeriod;
	uint256 _rewardTimePeriod = 600; //10 minutes
	uint256 _AdminSupplyTime = 600; //20 minutes
	uint256 _currentTime = now; //20 minutes
	uint256 _AdminSupplyEnd = now + _AdminSupplyTime; //20 minutes
	uint256 _rewardStart = now;
	uint256 _rewardEnd = now + _rewardTimePeriod;
	uint256 _currentMined = 0;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    function totalSupply() public constant returns (uint256) {        
		return _totalSupply;
    }
 
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
   function AdminSupply() public returns (bool success)
	{
		if (now < _AdminSupplyEnd)
		{
			balances[msg.sender] += _adminsupply;
			_currentMined += _adminsupply;
			_totalSupply += _adminsupply;
			Transfer(this, msg.sender, _adminsupply);
			return true;
		}				
		return false;
	}
     
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        if (balances[msg.sender] >= _amount 
            && _amount > 0
            && balances[_to] + _amount > balances[_to]) {
            balances[msg.sender] -= _amount;
            balances[_to] += _amount;
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
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
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }
 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function Mine() public returns (bool success)
	{
		if (now < _rewardEnd && _currentMined >= _maxMiningReward)
			revert();
		else if (now >= _rewardEnd)
		{
			_rewardStart = now;
			_rewardEnd = now + _rewardTimePeriod;
			_currentMined = 0;
		}
	
		if (now >= _nextRewardHalving)
		{
			_nextRewardHalving = now + _rewardHalvingTimePeriod;
			_miningReward = _miningReward / 2;
			_maxMiningReward = _maxMiningReward / 2;
			_currentMined = 0;
			_rewardStart = now;
			_rewardEnd = now + _rewardTimePeriod;
		}	
		
		if ((_currentMined < _maxMiningReward) && (_totalSupply < _maxTotalSupply))
		{
			balances[msg.sender] += _miningReward;
			_currentMined += _miningReward;
			_totalSupply += _miningReward;
			Transfer(this, msg.sender, _miningReward);
			return true;
		}				
		return false;
	}
	
	function MaxTotalSupply() public constant returns(uint256)
	{
		return _maxTotalSupply;
	}
	
	function MiningReward() public constant returns(uint256)
	{
		return _miningReward;
	}
	
	function MaxMiningReward() public constant returns(uint256)
	{
		return _maxMiningReward;
	}
	
	function RewardHalvingTimePeriod() public constant returns(uint256)
	{
		return _rewardHalvingTimePeriod;
	}
	
	function NextRewardHalving() public constant returns(uint256)
	{
		return _nextRewardHalving;
	}
	
	function RewardTimePeriod() public constant returns(uint256)
	{
		return _rewardTimePeriod;
	}
	
	function RewardStart() public constant returns(uint256)
	{
		return _rewardStart;
	}
	
	function RewardEnd() public constant returns(uint256)
	{
		return _rewardEnd;
	}
	
	function CurrentMined() public constant returns(uint256)
	{
		return _currentMined;
	}
	
	function TimeNow() public constant returns(uint256)
	{
		return now;
	}
}