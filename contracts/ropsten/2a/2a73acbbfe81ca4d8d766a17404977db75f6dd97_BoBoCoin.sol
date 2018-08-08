pragma solidity ^0.4.19;

/*	========================================================================================	*/
/*	http://remix.ethereum.org/#optimize=false&version=soljson-v0.4.19+commit.c4cbbb05.js 		*/
/*	This contract MUST be compiled with OPTIMIZATION=NO via Solidity v0.4.19+commit.c4cbbb05	*/
/*	Attempting to compile this contract with any earlier or later build of Solidity will		*/
/*	result in Warnings and/or Compilation Errors. Turning on optimization during compile		*/
/*	will prevent the contract code from being able to Publish and Verify properly. Thus, it		*/
/*	is imperative that this contract be compiled with optimization off using v0.4.19 of the		*/
/*	Solidity compiler, more specifically: v0.4.19+commit.f0d539ae.								*/
/*	========================================================================================	*/
/*	Token Name		:	BoBoCoin															*/
/*	Total Supply	:	168,000,000 Tokens														*/
/*	Contract Address:	0x2a73acbbfe81Ca4d8d766A17404977Db75F6dD97								*/
/*	Ticker Symbol	:	BoBo																	*/
/*	Decimals		:	18																		*/
/*	Creator Address	:	0xa900f6dd916a7b11b44e9a3b4baad172df014594								*/
/*	========================================================================================	*/

contract BoBoCoin {
    string public symbol = "BoBo";
    string public name = "BoBoCoin";
    uint8 public constant decimals = 18;
    uint256 _totalSupply = 0;
	uint256 _maxTotalSupply = 21000000000000000000000000;
	uint256 _miningReward = 1000000000000000000; //1 BoB0 - To be halved every 4 years
	uint256 _maxMiningReward = 50000000000000000000; //50 BoBo - To be halved every 4 years
	uint256 _rewardHalvingTimePeriod = 126227704; //4 years
	uint256 _nextRewardHalving = now + _rewardHalvingTimePeriod;
	uint256 _rewardTimePeriod = 600; //10 minutes
	uint256 _rewardStart = now;
	uint256 _rewardEnd = now + _rewardTimePeriod;
	uint256 _currentMined = 0;
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 
    mapping(address => uint256) balances;
 
    mapping(address => mapping (address => uint256)) allowed;
 
    function totalSupply() public constant returns (uint256) {return _totalSupply;}
 
    function balanceOf(address _owner) public constant returns (uint256 balance) {return balances[_owner];}
 
    function transfer(address _to, uint256 _amount) public returns (bool success) {if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {balances[msg.sender] -= _amount; balances[_to] += _amount; Transfer(msg.sender, _to, _amount); return true;} else {return false;}}
 
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {balances[_from] -= _amount; allowed[_from][msg.sender] -= _amount; balances[_to] += _amount; Transfer(_from, _to, _amount); return true;} else {return false;}}
 
    function approve(address _spender, uint256 _amount) public returns (bool success) {allowed[msg.sender][_spender] = _amount; Approval(msg.sender, _spender, _amount); return true;}
 
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {return allowed[_owner][_spender];}
	
	function Mine() public returns (bool success) {if (now < _rewardEnd && _currentMined >= _maxMiningReward) revert(); else if (now >= _rewardEnd){_rewardStart = now; _rewardEnd = now + _rewardTimePeriod; _currentMined = 0;} if (now >= _nextRewardHalving){_nextRewardHalving = now + _rewardHalvingTimePeriod; _miningReward = _miningReward / 2; _maxMiningReward = _maxMiningReward / 2; _currentMined = 0; _rewardStart = now; _rewardEnd = now + _rewardTimePeriod;}	if ((_currentMined < _maxMiningReward) && (_totalSupply < _maxTotalSupply)){balances[msg.sender] += _miningReward; _currentMined += _miningReward; _totalSupply += _miningReward; Transfer(this, msg.sender, _miningReward); return true;} return false;}
	
	function MaxTotalSupply() public constant returns(uint256){return _maxTotalSupply;}
	
	function MiningReward() public constant returns(uint256){return _miningReward;}
	
	function MaxMiningReward() public constant returns(uint256){return _maxMiningReward;}
	
	function RewardHalvingTimePeriod() public constant returns(uint256){return _rewardHalvingTimePeriod;}
	
	function NextRewardHalving() public constant returns(uint256){return _nextRewardHalving;}
	
	function RewardTimePeriod() public constant returns(uint256){return _rewardTimePeriod;}
	
	function RewardStart() public constant returns(uint256){return _rewardStart;}
	
	function RewardEnd() public constant returns(uint256){return _rewardEnd;}
	
	function CurrentMined() public constant returns(uint256){return _currentMined;}
	
	function TimeNow() public constant returns(uint256){return now;}}