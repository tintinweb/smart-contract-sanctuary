//SourceUnit: tronapex.sol

/*
 *  TronApex.com - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://tronapex.com                                       │
 *   │                                                                       │  
 *   │   Telegram Group: https://t.me/tronapex                             	 |
 *   │   Telegram Russian Group https://t.me/tronapex_ru                     |
 *   |   Telegram Chinese Group https://t.me/tronprom_ch                     |
 *   |   																     |
 *   |   E-mail: support@tronapex.com                                        |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +3% every 24 hours
 *   - Personal hold-bonus: +0.05% for every 24 hours without withdraw (Maximum 3%)
 *   - Contract total invested bonus: +0.1% for every 1,000,00 TRX on platform invested
 * 
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 170% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 7-level referral commission: 3% - 2% - 1% - 4th-7th 0.05%
 *	 - Extra daily precent for your deposits depending how mutch your first level referrals invested
 *	 - 50000 trx for 0.01%, 100000 trx for 0.1%, 250000 trx for 0.5%, 500000 trx for 0.75%, 1000000 trx for 1%
 *
 *	 [REFERRAL POOL]
 *
 *	 - From each deposit 1% go to referral pool
 *	 - When pool reach 100,000 TRX prizes are sent to top 10 referrers
 *   - Precentage 30%, 20%, 15%, 8%, 7%, 6%, 5%, 4%, 3%, 2% from referral pool
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 80% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 8% Affiliate program bonuses
 *	 - 3% Support work, technical functioning, administration fee
 *	 - 1% Referral Pool
 *
 *   ────────────────────────────────────────────────────────────────────────
 */
pragma solidity 0.5.9;

contract TronApex {
	using SafeMath for uint256;
	
	uint256 constant public MinimumInvest = 100 trx;
	uint256 constant public MarketingFee = 800;
	uint256 constant public ServiceFee = 300;
	uint256[] public ReferralCommissions = [300, 200, 100, 50, 50, 50, 50];
	uint256[] public ReferralBonusRewards = [50000 trx, 100000 trx, 250000 trx, 500000 trx, 1000000 trx];
	uint256[] public ReferralPoolPercents = [3000, 2000, 1500, 800, 700, 600, 500, 400, 300, 200];
	uint256 constant public Day = 1 days;
	uint256 constant public ROICap = 17000;
	uint256 constant public PercentDiv = 10000;
	uint256 constant public RefPoolBonus = 100;
	uint256 constant public ContractIncreaseEach = 1000000 trx;
	uint256 constant public StartBonus = 300;
	uint256 constant public ContractBonusCap = 300;
	uint256 constant public HoldBonusCap = 300;
	
	uint256 public TotalInvestors;
	uint256 public TotalInvested;
	uint256 public TotalWithdrawn;
	uint256 public TotalDepositCount;
	uint256 public CurrentBonus;
	uint256 public RefPool;
	uint256 public RefPoolID;
	uint256 public Locked;
	
	address payable public MarketingFeeAddress;
	address payable public ServiceFeeAddress;

    mapping(uint256 => mapping(address => uint256)) public	RefPoolSum;
    mapping(uint256 => address payable) public topRefPool;

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
		address payable upline;
		uint256 totalinvested;
		uint256 totalwithdrawn;
		uint256 RefPoolScore;
		uint256 RefPoolID;
		uint256 totalcommisions;
		uint256 lvlonecommisions;
		uint256 lvltwocommisions;
		uint256 lvlthreecommisions;
		uint256 lvlfourcommisions;
		uint256 lvlfivecommisions;
		uint256 lvlsixcommisions;
		uint256 lvlsevencommisions;
		uint256 availablecommisions;
	}
	
	mapping (address => User)   internal users;
	
	event ReferralBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawal(address indexed user, uint256 amount);
	event RefPoolPrize(address indexed user, uint256 amount, uint256 place);
	
	constructor(address payable MarketingAddress, address payable ServiceAddress) public {
		MarketingFeeAddress = MarketingAddress;
		ServiceFeeAddress = ServiceAddress;
		CurrentBonus = StartBonus;
		RefPool = 0;
		RefPoolID = 0;
		Locked = 0;
	}
	
	
	function Invest(address payable InvestorUpline) public payable {
		require(msg.value >= MinimumInvest);
		require(!isContract(msg.sender));
		MarketingFeeAddress.transfer(msg.value.mul(MarketingFee).div(PercentDiv));
		ServiceFeeAddress.transfer(msg.value.mul(ServiceFee).div(PercentDiv));
		
		User storage user = users[msg.sender];
		
		if (user.upline == address(0) && users[InvestorUpline].deposits.length > 0 && InvestorUpline != msg.sender) {
			user.upline = InvestorUpline;
		}
		if (user.upline != address(0)) {
			address upline = user.upline;
			for (uint256 i = 0; i < 7; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(ReferralCommissions[i]).div(PercentDiv);
					users[upline].totalcommisions = users[upline].totalcommisions.add(amount);
					users[upline].availablecommisions = users[upline].availablecommisions.add(amount);
					if(i == 0){
						users[upline].lvlonecommisions = users[upline].lvlonecommisions.add(amount);
						if(users[upline].RefPoolID == RefPoolID){
							users[upline].RefPoolScore = users[upline].RefPoolScore.add(msg.value);
						}else{
							users[upline].RefPoolScore = 0;
							users[upline].RefPoolID = RefPoolID;
							users[upline].RefPoolScore = users[upline].RefPoolScore.add(msg.value);
						}
						elaborateRefPool(user.upline, msg.value);
					}
					if(i == 1){
						users[upline].lvltwocommisions = users[upline].lvltwocommisions.add(amount);
					}
					if(i == 2){
						users[upline].lvlthreecommisions = users[upline].lvlthreecommisions.add(amount);
					}
					if(i == 3){
						users[upline].lvlfourcommisions = users[upline].lvlfourcommisions.add(amount);
					}
					if(i == 4){
						users[upline].lvlfivecommisions = users[upline].lvlfivecommisions.add(amount);
					}
					if(i == 5){
						users[upline].lvlsixcommisions = users[upline].lvlsixcommisions.add(amount);
					}
					if(i == 6){
						users[upline].lvlsevencommisions = users[upline].lvlsevencommisions.add(amount);
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
		RefPool = RefPool.add(msg.value.mul(RefPoolBonus).div(PercentDiv));
		if(RefPool >= ContractIncreaseEach.div(10) && Locked == 0){
			FinishRefPool();
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
		uint256 userPercentRate = CurrentBonus.add(GetHoldBonus(msg.sender)).add(GetRefBonus(msg.sender));
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
		uint256 userPercentRate = CurrentBonus.add(GetHoldBonus(msg.sender)).add(GetRefBonus(msg.sender));
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
		uint256 contractBalancePercent = (TotalInvested.div(ContractIncreaseEach)).mul(2);
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
	
    function GetRefBonus(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 bonus = 0;
		uint256 commissionsTotal = user.lvlonecommisions.mul(PercentDiv).div(ReferralCommissions[0]);
		if (commissionsTotal >= ReferralBonusRewards[0] && commissionsTotal <= ReferralBonusRewards[1]) {
            bonus = 5;
        } else if (commissionsTotal >= ReferralBonusRewards[1] && commissionsTotal <= ReferralBonusRewards[2]) {
            bonus = 10;
        } else if (commissionsTotal >= ReferralBonusRewards[2] && commissionsTotal <= ReferralBonusRewards[3]) {
            bonus = 50;
        } else if (commissionsTotal >= ReferralBonusRewards[3] && commissionsTotal <= ReferralBonusRewards[4]) {
            bonus = 75;
        } else if (commissionsTotal >= ReferralBonusRewards[4]) {
            bonus = 100;
        }
        return bonus;
    }
	
	function FinishRefPool() internal {
		Locked = 1;
		
        for(uint256 i = 0; i < ReferralPoolPercents.length; i++) {
            if(topRefPool[i] == address(0)) break;
			
			topRefPool[i].transfer(RefPool.mul(ReferralPoolPercents[i]).div(PercentDiv));
			emit RefPoolPrize(topRefPool[i], RefPool.mul(ReferralPoolPercents[i]).div(PercentDiv), i);
        }
        
        for(uint256 i = 0; i < ReferralPoolPercents.length; i++) {
            topRefPool[i] = address(0);
        }
		
		RefPool = 0;
		RefPoolID = RefPoolID.add(1);
		Locked = 0;
	}

	function elaborateRefPool(address payable addr, uint256 currentValue) private {
		
		RefPoolSum[RefPoolID][addr] += currentValue;
		
        for(uint256 i = 0; i < ReferralPoolPercents.length; i++) {
            if(topRefPool[i] == addr) break;

            if(topRefPool[i] == address(0)) {
                topRefPool[i] = addr;
                break;
            }

            if(RefPoolSum[RefPoolID][addr] > RefPoolSum[RefPoolID][topRefPool[i]]) {
                for(uint256 j = i + 1; j < ReferralPoolPercents.length; j++) {
                    if(topRefPool[j] == addr) {
                        for(uint256 k = j; k <= ReferralPoolPercents.length; k++) {
                            topRefPool[k] = topRefPool[k + 1];
                        }
                        break;
                    }
                }

                for(uint256 j = uint256(ReferralPoolPercents.length - 1); j > i; j--) {
                    topRefPool[j] = topRefPool[j - 1];
                }

                topRefPool[i] = addr;

                break;
            }
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
	
	function RefPoolTopAddr(uint256 index) public view returns (address) {
		return topRefPool[index];
	}

	function RefPoolTopValue(uint256 index) public view returns (uint256) {
		return RefPoolSum[RefPoolID][topRefPool[index]];
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