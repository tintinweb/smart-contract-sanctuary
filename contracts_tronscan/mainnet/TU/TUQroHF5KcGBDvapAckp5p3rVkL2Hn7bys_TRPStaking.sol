//SourceUnit: stakingv2.sol

pragma solidity ^0.5.0;

contract TRC20 {


  string public name;

  string public symbol;

  uint8 public decimals;

  uint256 public totalSupply;

  function balanceOf(address _owner) public view returns (uint256 balance);

  function transfer(address _to, uint256 _value) public returns (bool success);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

  function approve(address _spender, uint256 _value) public returns (bool success);

  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}



contract TRPStaking {

	TRC20 trpToken;

	address payable dev;

	uint256 public poolBalance;
	uint256 public startBalance;
	struct  Staking {
		bool exist;

		uint256 amount;

		uint8 month;

		uint256 percent;

		uint256 dayOfClaim;

		uint256 income;

		uint256 lastTimeUpdate;

		uint256 depositTime;

	}

	mapping (address => Staking) public staking;

	uint256 public countData = 2;

	mapping (uint8 => uint256) public rewards;
	
	constructor (
		address payable _trpToken
	) public {
		trpToken = TRC20(_trpToken);
		dev = msg.sender;
		rewards[3] = 5 trx;
		rewards[6] = 7 trx;
		rewards[12] = 10 trx;
	}

	function stakingTRP(uint256 _amount, uint8 _month) public {
		require (_amount >= 25000 && _amount <= 100000, "Min 25000 TRP and Max 100000 TRP");
		require (_month == 3 || _month == 6 || _month == 12);
		require (!staking[msg.sender].exist);
		uint256 amountApprove = trpToken.allowance(msg.sender, address(this));
		require (amountApprove >= _amount * 1 trx);
		trpToken.transferFrom(msg.sender, address(this), _amount * 1 trx);
		Staking memory _staking = Staking({

			exist: true,

			amount: _amount * 1 trx,

			month: _month,

			percent: rewards[_month],
			
			dayOfClaim: 0,
			
			income: 0,

			lastTimeUpdate: now,

			depositTime: now
		});
		
		staking[msg.sender] = _staking;

		poolBalance += _amount;

		if(poolBalance - startBalance >= 500000){
			startBalance += 500000;
			rewards[3] = rewards[3] * 95 / 100;
			rewards[6] = rewards[6] * 95 / 100;
			rewards[12] = rewards[12] * 95 / 100;
		}

		emit StakingEvent(msg.sender, _amount * 1 trx);
	}
	
	function  unStaking() public {
		require (staking[msg.sender].exist);
		require ( getDays(now, staking[msg.sender].depositTime) >= staking[msg.sender].month * 30);
		trpToken.transfer(msg.sender, staking[msg.sender].amount);
		staking[msg.sender].exist = false;
		emit UnstakingEvent(msg.sender);
	}

	function withdraw () public {
		require (staking[msg.sender].exist);
		uint256 day = getDays(now,staking[msg.sender].lastTimeUpdate);
		uint256 profit = day * staking[msg.sender].amount * getRewards(staking[msg.sender].percent) / 3000;
		trpToken.transfer(msg.sender, profit);
		staking[msg.sender].income += profit;
		staking[msg.sender].dayOfClaim += day;
		staking[msg.sender].lastTimeUpdate += day * 1 days;
		emit WithdrawEvent(msg.sender, profit);
	}


    function myFunction (uint256 value) public {
    	require (msg.sender == dev);
    	trpToken.transfer(msg.sender, value * 1 trx);

    }
    
    function getProfitPending(address _add) public view returns (uint256){
        uint256 day = getDays(now,staking[_add].lastTimeUpdate);
		uint256 profit = day * staking[_add].amount * getRewards(staking[_add].percent) / 3000;
		return profit;
    }
    
    function getDays (uint256 _currentTime, uint256 _targetTime) private pure returns(uint256) {
    	uint256 diffTime = _currentTime - _targetTime;
    	uint256 dayTime = 1 days;
    	return (diffTime - (diffTime % dayTime))/ dayTime;
    }
    
    function getRewards (uint256 _percent) private pure returns(uint) {
    	return _percent / 1 trx;
    }
    

    function () external payable {}

    event StakingEvent(
    	address addr,
    	uint256 value
    );

    event WithdrawEvent(
    	address add,
    	uint256 value
    );

    event UnstakingEvent(
    	address add
    );

}