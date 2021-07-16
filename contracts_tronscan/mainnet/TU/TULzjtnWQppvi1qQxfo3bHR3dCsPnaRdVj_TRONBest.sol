//SourceUnit: TronBest.sol

pragma solidity 0.5.12;

contract TRONBest {
	using SafeMath for uint256;
	
	uint256 constant public MinimumInvest = 100 trx;
	uint256 constant public MinimumWithdrawal = 50 trx;
	uint256 constant public MarketingFee = 500;
	uint256 constant public ServiceFee = 500;
	uint256[] public ReferralCommissions = [500, 200, 50];
	uint256 constant public Day = 1 days;
	uint256 constant public ROICap = 18000;
	uint256 constant public PercentDiv = 10000;
	uint256 constant public ContractIncreaseEach = 1000000 trx;
	uint256 constant public StartBonus = 100;
	uint256 constant public ContractBonusCap = 300;
	uint256 constant public HoldBonusCap = 300;
	
	uint256 public TotalInvestors;
	uint256 public TotalInvested;
	uint256 public TotalWithdrawn;
	uint256 public TotalDepositCount;
	uint256 public CurrentBonus;
	
	address payable public MarketingFeeAddress;
	address payable public ServiceFeeAddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}
	
	struct Commissions {
		address Downline;
		uint256 Earned;
		uint256 Invested;
		uint256 Level;
		uint256 DepositTime;
	}
	
	struct User {
		Deposit[] deposits;
		Commissions[] commissions;
		uint256 checkpoint;
		address upline;
		uint256 totalinvested;
		uint256 totalwithdrawn;
		uint256 totalcommisions;
		uint256 lvlonecommisions;
		uint256 lvltwocommisions;
		uint256 lvlthreecommisions;
		uint256 availablecommisions;
	}
	
	mapping (address => User)   internal users;
	
	event ReferralBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawal(address indexed user, uint256 amount);
	
	constructor(address payable MarketingAddress, address payable ServiceAddress) public {
		require(!isContract(MarketingAddress) && !isContract(ServiceAddress));
		MarketingFeeAddress = MarketingAddress;
		ServiceFeeAddress = ServiceAddress;
		CurrentBonus = StartBonus;
	}
	
function Invest(address InvestorUpline) public payable {
		require(msg.value >= MinimumInvest);
		MarketingFeeAddress.transfer(msg.value.mul(MarketingFee).div(PercentDiv));
		ServiceFeeAddress.transfer(msg.value.mul(ServiceFee).div(PercentDiv));
		
		User storage user = users[msg.sender];
		
		if (user.upline == address(0) && users[InvestorUpline].deposits.length > 0 && InvestorUpline != msg.sender) {
			user.upline = InvestorUpline;
		}
		
		if (user.upline != address(0)) {
			address upline = user.upline;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(ReferralCommissions[i]).div(PercentDiv);
					users[upline].totalcommisions = users[upline].totalcommisions.add(amount);
					users[upline].availablecommisions = users[upline].availablecommisions.add(amount);
					
					if(i == 0){
						users[upline].lvlonecommisions = users[upline].lvlonecommisions.add(amount);
					}
					if(i == 1){
						users[upline].lvltwocommisions = users[upline].lvltwocommisions.add(amount);
					}
					if(i == 2){
						users[upline].lvlthreecommisions = users[upline].lvlthreecommisions.add(amount);
					}
					users[upline].commissions.push(Commissions(msg.sender, amount, msg.value, i, block.timestamp));
					emit ReferralBonus(upline, msg.sender, i, amount);
					upline = users[upline].upline;
				} else break;
			}
		}
		if (user.upline == address(0)) {
			uint256 advertise = 750;
			ServiceFeeAddress.transfer(msg.value.mul(advertise).div(PercentDiv));
		}
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			TotalInvestors = TotalInvestors.add(1);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));
		user.totalinvested = user.totalinvested.add(msg.value);
		TotalDepositCount = TotalDepositCount.add(1);
		TotalInvested = TotalInvested.add(msg.value);
		UpdateContractBonus();
		emit NewDeposit(msg.sender, msg.value);
	}
	
	function WithdrawCommissions() public {
		User storage user = users[msg.sender];
		uint256 contractBalance = address(this).balance;
		uint256 toSend;
		require(user.availablecommisions > 0, "No commissions available");

		if (contractBalance < user.availablecommisions) {
			toSend = contractBalance;
			user.availablecommisions = user.availablecommisions.sub(toSend);
		}else{
			toSend = user.availablecommisions;
			user.availablecommisions = 0;
		}
		
		msg.sender.transfer(toSend);
		TotalWithdrawn = TotalWithdrawn.add(toSend);
		
		emit Withdrawal(msg.sender, toSend);
	}
	
	function WithdrawDividends() public {
		User storage user = users[msg.sender];
		uint256 userPercentRate = CurrentBonus.add(GetHoldBonus(msg.sender));
		uint256 toSend;
		uint256 dividends;
		uint256 ResetHoldBonus;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PercentDiv))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(Day);
					ResetHoldBonus = ResetHoldBonus.add(1);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PercentDiv))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(Day);
					ResetHoldBonus = ResetHoldBonus.add(1);
				}
				if (user.deposits[i].withdrawn.add(dividends) >= ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))) {
					dividends = (((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))).sub(user.deposits[i].withdrawn);
					ResetHoldBonus = 0;
				}
				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
				toSend = toSend.add(dividends);
			}
		}

		require((toSend >= MinimumWithdrawal), "No dividends available");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < toSend) {
			toSend = contractBalance;
		}
		
		MarketingFeeAddress.transfer((toSend.mul(2).div(10)).mul(MarketingFee).div(PercentDiv));
		ServiceFeeAddress.transfer((toSend.mul(2).div(10)).mul(ServiceFee).div(PercentDiv));
		
		msg.sender.transfer(toSend.mul(8).div(10));
		TotalWithdrawn = TotalWithdrawn.add(toSend.mul(8).div(10));
		user.totalwithdrawn = user.totalwithdrawn.add(toSend.mul(8).div(10));
		
		user.deposits.push(Deposit(toSend.mul(2).div(10), 0, block.timestamp));
		user.totalinvested = user.totalinvested.add(toSend.mul(2).div(10));
		TotalDepositCount = TotalDepositCount.add(1);
		TotalInvested = TotalInvested.add(toSend.mul(2).div(10));
		UpdateContractBonus();
		
		user.checkpoint = block.timestamp;
		
		emit NewDeposit(msg.sender, toSend.mul(2).div(10));
		emit Withdrawal(msg.sender, toSend.mul(8).div(10));
	}
	
	function GetUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 userPercentRate = CurrentBonus.add(GetHoldBonus(msg.sender));
		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PercentDiv))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(Day);
				} else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PercentDiv))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(Day);
				}
				if (user.deposits[i].withdrawn.add(dividends) > ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))) {
					dividends = ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv)).sub(user.deposits[i].withdrawn);
				}
				totalDividends = totalDividends.add(dividends);
			}
		}
		return totalDividends;
	}
	
	function ActiveClient(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];
		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < ((user.deposits[user.deposits.length-1].amount.mul(ROICap)).div(PercentDiv))) {
				return true;
			}
		}
	}
	
	function UpdateContractBonus() internal {
		uint256 contractBalancePercent = TotalInvested.div(ContractIncreaseEach);
		if(contractBalancePercent > ContractBonusCap){
			contractBalancePercent = ContractBonusCap;
		}
		CurrentBonus = StartBonus.add(contractBalancePercent);
	}
	
    function GetHoldBonus(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        if (user.checkpoint > 0) {
            uint256 timeMultiplier = ((now.sub(user.checkpoint)).div(Day)).mul(5);
            if(timeMultiplier > HoldBonusCap){
                timeMultiplier = HoldBonusCap;
            }
            return timeMultiplier;
        }else{
            return 0;
        }
    }
	
	function GetTotalCommission(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		return (user.commissions.length);
	}

	function GetUserCommission(address userAddress, uint256 index) public view returns(address, uint256, uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.commissions[index].Downline, user.commissions[index].Earned, user.commissions[index].Invested, user.commissions[index].Level, user.commissions[index].DepositTime);
	}

	function GetUserData(address userAddress) public view returns(address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.upline, user.totalinvested, user.totalwithdrawn, user.totalcommisions, user.lvlonecommisions, user.lvltwocommisions, user.lvlthreecommisions, user.availablecommisions, user.checkpoint);
	}
	
	function GetUserTotalDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	
	function GetUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}
	
	function GetContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

library SafeMath {
	
	function fxpMul(uint256 a, uint256 b, uint256 base) internal pure returns (uint256) {
		return div(mul(a, b), base);
	}
		
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