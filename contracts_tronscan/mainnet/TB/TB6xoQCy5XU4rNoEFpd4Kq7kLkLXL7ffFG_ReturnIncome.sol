//SourceUnit: ReturnIncome.sol

/**
*
* Return Income - The best Investment plateform based on TRON trx contract
*
* https://returnincome.com
* (only for returnincome.co Community)
* Crowdfunding And Investment Program: 10% Daily ROI.
* Referral Program
*
* Always use https://returnincome.com
* 10% Daily Income
* returnincome also has referral program check the website for more details
*
* 
* returnincome - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
*
*   ┌───────────────────────────────────────────────────────────────────────┐  
*   │   Website: https://www.returnincome.com                               │
*   └───────────────────────────────────────────────────────────────────────┘ 
*
*   [USAGE INSTRUCTION]
*
*   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronLink, TronWallet or Banko.
*   2) Send any TRX amount (100 TRX minimum) using our website invest button.
*   3) Wait for your earnings.
*   4) Withdraw earnings any time using our website "Withdraw" button.
*
*   [INVESTMENT CONDITIONS]
* 
*   - Basic interest rate: +10% every 24 hours (+0.416% hourly) 
*   - Contract total amount bonus: +0.1% for every 1,000,00 TRX on platform address balance 
* 
*   - Minimal deposit: 100 TRX, no maximal limit
*   - Total income: 200% (deposit included)
*   - Earnings every moment, withdraw any time
* 
*   [AFFILIATE PROGRAM]
*
*   Share your referral link with your partners and get additional bonuses.
*   - 10-level referral commission: 5% - 1% - 0.5% - 0.5% - ...
*
*
**/

pragma solidity 0.5.10;

contract ReturnIncome {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 50 trx;
	uint256 constant public BASE_PERCENT = 10;
	uint256[] public REFERRAL_PERCENTS = [5, 3, 2,1,1,1,1,1,1,1];
	uint256 constant public MARKETING_FEE = 14;
	uint256 constant public PROJECT_FEE = 13;
	uint256 constant public APP_FEE = 13;
	uint256 constant public PERCENTS_DIVIDER = 100;
	uint256 constant public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 constant public TIME_STEP = 1 days;
	uint256 constant public  INTENVAL = 7 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;
	address payable public appfeeaddress;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 updateTime;
		mapping(uint256 => uint256) referralReward;
	}

	mapping (address => User) public users;
	
	mapping (address => uint256) public userWithdrawn;
	
	mapping (address => uint256) public userReferralBonus;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event Reinvest(address sender,uint256 amount);
	
	constructor(address payable marketingAddr, address payable projectAddr, address payable appfeeAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr) && !isContract(appfeeAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		appfeeaddress = appfeeAddr;
	}
	
	function getLevalReward(address _address,uint256 _level) public view returns(uint256){
	    return users[_address].referralReward[_level];
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		appfeeaddress.transfer(msg.value.mul(APP_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].referralReward[i] = users[upline].referralReward[i].add(1);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {

			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

	}
	
	
	function reinvest(address sender,uint256 amount) internal{
		marketingAddress.transfer(amount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		appfeeaddress.transfer(amount.mul(APP_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(sender, amount.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[sender];
		
		if (user.deposits.length == 0) {

			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}
       
		user.deposits.push(Deposit(amount, 0, block.timestamp));
	

		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(sender, amount);
	
	}

	function withdraw() public {
	
		User storage user = users[msg.sender];
				
		require( block.timestamp > user.updateTime.add(INTENVAL),'Try again after 7 days');

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		
		userReferralBonus[msg.sender] = userReferralBonus[msg.sender].add(referralBonus);
		
		if (referralBonus > 0) {
			totalAmount = totalAmount.add(referralBonus);
			user.bonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		

		reinvest(msg.sender,totalAmount.mul(50).div(100));
		
		userWithdrawn[msg.sender] = userWithdrawn[msg.sender].add(totalAmount.mul(50).div(100));
		
		msg.sender.transfer(totalAmount.mul(50).div(100));

		totalWithdrawn = totalWithdrawn.add(totalAmount.mul(50).div(100));
		
		user.updateTime = block.timestamp;

		emit Withdrawn(msg.sender, totalAmount.mul(50).div(100));

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		if(contractBalancePercent > 190){
			contractBalancePercent = 190;
		}
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP).mul(0);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}
				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
					dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
				}
				totalDividends = totalDividends.add(dividends);
			}

		}

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
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