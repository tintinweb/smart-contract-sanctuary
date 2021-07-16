//SourceUnit: FoodTron.sol

// https://tronfood.store/
// Start Tue Mar 02 2021 17:00:00 GMT+0000
// The minimum deposit amount is 200 trx.
// Maximum investment amount 200000 trx.
// Profit per day:
//  - 200 	- 1200 trx 		- 	1%
//  - 1201 	- 5000 trx 		- 	1.1%
//  - 5001 	- 12000 trx 	- 	1.3%
//  - 12001 - 25000 trx 	- 	1.7%
//  - 25001 - 60000 trx 	- 	2.3%
//  - 60001 - 200000 trx 	- 	3.3%
// 0.1% daily bonus without withdrow
// 3% max daily bonus without withdrow
// Delivery cost - 5% of the investment amount
// Delivery time - 24 hours
// During delivery, the daily bonus is not reset after withdrawal
// Developers take 10% (7,3) fees from each deposit 
// Referral Tier - 4% - 2% -1%

pragma solidity ^0.6.0;

contract FoodTron {
	using SafeMath for uint256;

	uint256 constant public START_TIME = 1614704400; // start
	uint256 constant public INVEST_MIN_AMOUNT = 200000000;//min 200 trx for investing
	uint256 constant public INVEST_MAX_AMOUNT = 200000000000;//Maximum investment amount 200000 trx.
	uint256 constant public MAX_HOLD_BONUS = 30;//max daily bonus without withdrow
	uint256 constant public COST_DELIVERY = 50;//delivery cost 5% of the total investment
	uint256[] public REFERRAL_PERCENTS = [40, 20, 10];//1lvl=4%,2lvl=2%,3lvl=1%
	uint256 constant public MARKETING_FEE = 70;//7% to marketing wallet
	uint256 constant public PROJECT_FEE = 30;//3% to project wallet
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public marketingBank;
	uint256 public projectBank;

	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 timestamp;
	}

	struct User {
		Deposit[] deposits;
		uint256 withdrawn;
		uint256 checkpoint;
		uint256 tw;
		uint256 delivery;
		uint256[3] fromref;
		uint256 fromref_balance;
		address referrer;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
	}

	function invest(address referrer) public payable {
		require(block.timestamp >= START_TIME,"Start Tue Mar 02 2021 17:00:00 GMT+0000");
		require(msg.value >= INVEST_MIN_AMOUNT,"Min amount 200 trx");
		require(msg.value + getUserTotalInvested(msg.sender) <= INVEST_MAX_AMOUNT,"Total maximum investment amount 200,000 trx");
		marketingBank = marketingBank.add((msg.value).mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectBank = projectBank.add((msg.value).mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		
		User storage user = users[msg.sender];
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}
		if (user.referrer == address(0)) {
			user.referrer = projectAddress;
		}
		address upline = user.referrer;
		for (uint256 i = 0; i < 3; i++) {
			if (upline != address(0)) {
				uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
				users[upline].fromref[i] = users[upline].fromref[i].add(amount);
				users[upline].fromref_balance = users[upline].fromref_balance.add(amount);
				emit RefBonus(upline, msg.sender, i, amount);
				upline = users[upline].referrer;
			} else break;
		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.tw = block.timestamp;
			emit Newbie(msg.sender);
		}
		user.deposits.push(Deposit(msg.value,block.timestamp));
		totalInvested = totalInvested.add(msg.value);
		emit NewDeposit(msg.sender,msg.value);
	}

	function buyDelivery() public payable {
		uint256 invested = getUserTotalInvested(msg.sender);
		require(invested >= INVEST_MIN_AMOUNT,"You have no investment");
		uint256 delivery = getUserDelivery(msg.sender);
		require((block.timestamp).sub(delivery) > TIME_STEP,"You already have a delivery");
		uint256 cost = getCostDelivery(msg.sender);
		require(cost == msg.value,"Delivery payment amount error");
		User storage user = users[msg.sender];
		user.delivery = block.timestamp;
	}

	function withdraw() public {
		User storage user = users[msg.sender];
		uint256 dividends = getUserDividends(msg.sender);
		require(dividends > 0, "User has no dividends");
		uint256 contractBalance = getContractBalance();
		uint256 balance = contractBalance.sub(marketingBank).sub(projectBank);
		if (balance < dividends) {
			dividends = balance;
		}
		user.checkpoint = block.timestamp;
		uint256 delivery = getUserDelivery(msg.sender);
		if((block.timestamp).sub(delivery) > TIME_STEP){
			user.tw = block.timestamp;
		}
		user.withdrawn = user.withdrawn.add(dividends);
		msg.sender.transfer(dividends);
		totalWithdrawn = totalWithdrawn.add(dividends);
		emit Withdrawn(msg.sender,dividends);
	}

	function withdrawRef() public {
		User storage user = users[msg.sender];
		require(user.fromref_balance > 0);
		uint256 amount = user.fromref_balance;
		uint256 contractBalance = getContractBalance();
		uint256 balance = contractBalance.sub(marketingBank).sub(projectBank);
		if (balance < amount) {
			amount = balance;
		}
		msg.sender.transfer(amount);
		emit Withdrawn(msg.sender,amount);
		totalWithdrawn = totalWithdrawn.add(amount);
		user.fromref_balance = user.fromref_balance.sub(amount);
	}

	function withdrawMarketing() public {
		require(msg.sender == marketingAddress,"Only marketing address");
		uint256 contractBalance = getContractBalance();
		uint256 balance = contractBalance.sub(marketingBank).sub(projectBank);
		if (balance < marketingBank) {
			marketingBank = balance;
		}
		marketingAddress.transfer(marketingBank);
		marketingBank = 0;
	}

	function withdrawProject() public {
		require(msg.sender == projectAddress,"Only project address");
		uint256 contractBalance = getContractBalance();
		uint256 balance = contractBalance.sub(marketingBank).sub(projectBank);
		if (balance < projectBank) {
			projectBank = balance;
		}
		projectAddress.transfer(projectBank);
		projectBank = 0;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getUserDelivery(address userAddress) public view returns (uint256) {
		return users[userAddress].delivery;
	}

	function getCostDelivery(address userAddress) public view returns (uint256) {
		uint256 invested = getUserTotalInvested(userAddress);
		uint256 cost = invested.mul(COST_DELIVERY).div(PERCENTS_DIVIDER);
		return cost;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		uint256 invested = getUserTotalInvested(userAddress);
		uint256 percent = getUserPercentRate(userAddress);
		uint256 checkpoint = getUserCheckpoint(userAddress);
		return (invested.mul(percent).div(PERCENTS_DIVIDER)).mul(block.timestamp.sub(checkpoint)).div(TIME_STEP);
	}

	function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
		return amount;
	}
	
	function getUserPercentRate(address userAddress) public view returns (uint256) {
		return getUserPercent(userAddress).add(getUserPercentBonus(userAddress));
	}

	function getUserPercent(address userAddress) public view returns (uint256) {
		uint256 invested = getUserTotalInvested(userAddress);
		uint256 percent;
		if(invested >= INVEST_MIN_AMOUNT){
			if(invested <= 1200000000){
				percent = 10;
			}else if(invested <= 5000000000){
				percent = 11;
			}else if(invested <= 12000000000){
				percent = 13;
			}else if(invested <= 25000000000){
				percent = 17;
			}else if(invested <= 60000000000){
				percent = 23;
			}else if(invested <= 200000000000){
				percent = 33;
			}
		}
		return percent;
	}

	function getUserPercentBonus(address userAddress) public view returns (uint256) {
		uint256 percent;
		if(getUserTotalInvested(userAddress) > 0){
			if(users[userAddress].delivery + TIME_STEP > users[userAddress].checkpoint){
				percent = ((block.timestamp).sub(users[userAddress].tw)).div(TIME_STEP);
			}else{
				percent = ((block.timestamp).sub(users[userAddress].checkpoint)).div(TIME_STEP);
			}
			if(percent > MAX_HOLD_BONUS){
				percent = MAX_HOLD_BONUS;
			}
		}
		return percent;
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

	function getUserFromrefBalance(address userAddress) public view returns(uint256) {
		return users[userAddress].fromref_balance;
	}

	function getUserTw(address userAddress) public view returns(uint256) {
		return users[userAddress].tw;
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256) {
		return (users[userAddress].deposits[index].amount, users[userAddress].deposits[index].timestamp);
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].withdrawn;
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