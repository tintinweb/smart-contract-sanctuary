/*
 * 
 *   Bank Of Ethereum - investment platform based on ETH blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://bankofethereum.org                                 │
 *   │                                                                       │  
 *   │   Telegram Support Account: https://t.me/bankofethereum_support       |
 *   │   Telegram Public Group: https://t.me/bankofethereum_group            |
 *   │   Telegram News Channel: https://t.me/bankofethereum_news             |
 *   |                                                                       |
 *   |   Twitter: https://twitter.com/BankEthereum                           |
 *   |   E-mail: support@bankofethereum.org                                  |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect using ETH browser extension MetaMask or the MetaMask/Coinbase wallet mobile app .
 *   2) Send any ETH amount (0.05 minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw 
 *   - Contract total amount bonus: +0.1% for every 100 ETH on platform address balance 
 * 
 *   - Minimal deposit: 0.05 ETH, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 3-level referral commission: 5% - 2% - 0.5%
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 82.5% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 7.5% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 * 
 *
 *
 */

pragma solidity 0.5.10;

contract BankOfEthereum {
	using SafeMath for uint256;
	uint256 constant public INVEST_MIN_AMOUNT = 0.05 ether;
	uint256 constant public BASE_PERCENT = 10;
	uint256[] public REFERRAL_PERCENTS = [50, 20, 5];
	uint256 constant public MARKETING_FEE = 80;
	uint256 constant public PROJECT_FEE = 20;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public CONTRACT_BALANCE_STEP = 100 ether;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public adminAddress;

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
		uint256 level1;
		uint256 level2;
		uint256 level3;
	}

	mapping (address => User) internal users;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable adminAddr) public {
		require(!isContract(marketingAddr) && !isContract(adminAddr));
		marketingAddress = marketingAddr;
		adminAddress = adminAddr;
	}

	function invest(address referrer) public payable {
		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		adminAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];
		
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					if(i == 0){
						users[upline].level1 = users[upline].level1.add(1);	
					} else if(i == 1){
						users[upline].level2 = users[upline].level2.add(1);	
					} else if(i == 2){
						users[upline].level3 = users[upline].level3.add(1);	
					}
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

	function withdraw() public {
		User storage user = users[msg.sender];

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

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);

	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP);
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 contractBalanceRate = getContractBalanceRate();
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
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

				/// no update of withdrawn because that is view function

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

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].level1, users[userAddress].level2, users[userAddress].level3);
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

    modifier onlyAdmin() {
		require(msg.sender == adminAddress);
		_;
    }

	modifier onlyProjectLevel() {
        require(
			msg.sender == marketingAddress ||
			msg.sender == adminAddress
			);
		_;
    }

	function setMarketingAddress( address payable _newMarketingAddress) public onlyProjectLevel {
		require(_newMarketingAddress != address(0));
		marketingAddress = _newMarketingAddress;
    }

	function setAdminAddress( address payable _newAdminAddress) public onlyAdmin {
		require(_newAdminAddress != address(0));
		adminAddress = _newAdminAddress;
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