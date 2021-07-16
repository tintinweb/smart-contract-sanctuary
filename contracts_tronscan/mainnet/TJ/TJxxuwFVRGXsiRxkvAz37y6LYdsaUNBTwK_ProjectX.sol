//SourceUnit: ProjectX.sol

/*
 * 
 *   TRONex - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://xxxxx.fund                                         │
 *   │                                                                       │  
 *   │   Telegram Live Support: https://t.me/Projectxadminxxxxx              |
 *   │   Telegram Public Group: https://t.me/projectxinternationalgroup      |
 *   |                                                                       |
 *   |   Twitter: https://twitter.com/investment_x                           |
 *   |   Instagram: https://www.instagram.com/projectxinternational?r=nametag|
 *   |   E-mail: fundprojectx@gmail.com                                      |
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko.
 *   2) Send any TRX amount (100 TRX / 1 TRC20 USDT minimum) using our website invest button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw 
 *   - Contract total amount bonus: +0.1% for every 1,000,00 TRX/250,00 USDT on platform address balance 
 * 
 *   - Minimal deposit: 100 TRX/1 USDT, no maximal limit
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
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audition result with En: https://xxxxx.fund/files/ProjectX-En.pdf
 *   - Audition result with Zh: https://xxxxx.fund/files/ProjectX-Zh.pdf
 *
 */

pragma solidity 0.5.10;

interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ProjectX {
	using SafeMath for uint256;

	uint256[2] public INVEST_MIN_AMOUNT = [100 trx, 1 trx]; // 100 trx, 1 usdt
	uint256[2] public CONTRACT_BALANCE_STEP = [1000000 trx, 25000 trx]; // 1000000 trx, 25000 usdt
	uint256[3] public REFERRAL_PERCENTS = [50, 20, 5];

	uint256 constant public BASE_PERCENT = 10;
	uint256 constant public PROJECT_FEE = 100;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256[2] public totalInvested; // 0-->TRX, 1-->USDT
	uint256[2] public totalWithdrawn;
	uint256[2] public totalDeposits;

	address payable public projectAddress;
	address public owner;
	ITRC20 public usdt;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		mapping(uint8 => Deposit[]) deposits;
		uint256[2] checkpoint;
		address referrer;
		uint256[2] bonus;
	}

	mapping (address => User) internal users;
	mapping (address => mapping(uint8 => mapping(uint8 => uint256))) internal referLevelBonus;

	event NewGuy(uint8 tokenType, address user);
	event NewDeposit(uint8 tokenType, address indexed user, uint256 amount);
	event Withdrawn(uint8 tokenType, address indexed user, uint256 amount);
	event RefBonus(uint8 tokenType, address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(uint8 tokenType, address indexed user, uint256 totalAmount);

	constructor(ITRC20 _usdt, address payable _projectAddress) public {
		require(!isContract(_projectAddress));
		usdt = _usdt;
		projectAddress = _projectAddress;
		owner = msg.sender;
	}

	function invest(uint8 tokenType, uint256 amountIn, address referrer) public payable {
		require(( tokenType == 0 && msg.value >= INVEST_MIN_AMOUNT[0] && amountIn == 0) || (tokenType == 1 && amountIn >= INVEST_MIN_AMOUNT[1] && msg.value == 0));
		uint256 val = msg.value;
		if(tokenType == 1){
			val = amountIn;
		}
		uint256 fee = val.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		if(tokenType == 1){
			usdt.transferFrom(msg.sender, projectAddress, fee);
			usdt.transferFrom(msg.sender, address(this), val.sub(fee));
		}else{
			projectAddress.transfer(fee);
		}
		emit FeePayed(tokenType, msg.sender, fee);

		User storage user = users[msg.sender];
		if (user.referrer == address(0) && (users[referrer].deposits[0].length > 0 || users[referrer].deposits[1].length > 0) && referrer != msg.sender) {
			user.referrer = referrer;
		}
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint8 i = 0; i < 3; i++) {
				if (upline != address(0)) {
					uint256 amount = val.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					referLevelBonus[upline][tokenType][i] = referLevelBonus[upline][tokenType][i].add(amount);
					users[upline].bonus[tokenType] = users[upline].bonus[tokenType].add(amount);
					emit RefBonus(tokenType, upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}
		if (user.deposits[tokenType].length == 0) {
			user.checkpoint[tokenType] = block.timestamp;
			if(tokenType == 0 && user.deposits[1].length == 0){
				totalUsers = totalUsers.add(1);
			}else if(tokenType == 1 && user.deposits[0].length == 0){
				totalUsers = totalUsers.add(1);
			}
			emit NewGuy(tokenType, msg.sender);
		}
		user.deposits[tokenType].push(Deposit(val, 0, block.timestamp));
		totalInvested[tokenType] = totalInvested[tokenType].add(val);
		totalDeposits[tokenType] = totalDeposits[tokenType].add(1);
		emit NewDeposit(tokenType, msg.sender, val);
	}

	function withdraw(uint8 tokenType) public {
		User storage user = users[msg.sender];
		uint256 totalAmount = _dividends(tokenType, msg.sender);

		if (user.bonus[tokenType] > 0) {
			totalAmount = totalAmount.add(user.bonus[tokenType]);
			user.bonus[tokenType] = 0;
		}

		require(totalAmount > 0, "withdraw: User has no dividends");

		uint256 contractBalance = address(this).balance;
		if(tokenType == 1){
			contractBalance = usdt.balanceOf(address(this));
		}
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint[tokenType] = block.timestamp;
		totalWithdrawn[tokenType] = totalWithdrawn[tokenType].add(totalAmount);
		if(tokenType == 1){
			usdt.transfer(msg.sender, totalAmount);
		}else{
			msg.sender.transfer(totalAmount);
		}
		emit Withdrawn(tokenType, msg.sender, totalAmount);
	}

	function _dividends(uint8 tokenType, address userAddress) internal returns(uint256) {
		User storage user = users[userAddress];
		Deposit[] storage deposits = user.deposits[tokenType];
		uint256 userPercentRate = getUserPercentRate(tokenType, userAddress);

		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < deposits.length; i++) {
			if (deposits[i].withdrawn < deposits[i].amount.mul(2)) {
				if (deposits[i].start > user.checkpoint[tokenType]) {
					dividends = (deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(deposits[i].start))
						.div(TIME_STEP);

				} else {
					dividends = (deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint[tokenType]))
						.div(TIME_STEP);
				}
				if (deposits[i].withdrawn.add(dividends) > deposits[i].amount.mul(2)) {
					dividends = (deposits[i].amount.mul(2)).sub(deposits[i].withdrawn);
				}
				deposits[i].withdrawn = deposits[i].withdrawn.add(dividends);  // update withdrawn
				totalDividends = totalDividends.add(dividends);
			}
		}
		return totalDividends;
	}

	function getContractBalance(uint8 tokenType) public view returns (uint256) {
		if(tokenType == 1){
			return usdt.balanceOf(address(this));
		} 
		return address(this).balance;
	}

	function getContractBalanceRate(uint8 tokenType) public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		if(tokenType == 1){
			contractBalance = usdt.balanceOf(address(this));
		}
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP[tokenType]);
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserPercentRate(uint8 tokenType, address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 contractBalanceRate = getContractBalanceRate(tokenType);
		if (isActive(tokenType, userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint[tokenType])).div(TIME_STEP);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}

	function getUserDividends(uint8 tokenType, address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		Deposit[] storage deposits = user.deposits[tokenType];
		uint256 userPercentRate = getUserPercentRate(tokenType, userAddress);

		uint256 totalDividends;
		uint256 dividends;
		for (uint256 i = 0; i < deposits.length; i++) {
			if (deposits[i].withdrawn < deposits[i].amount.mul(2)) {
				if (deposits[i].start > user.checkpoint[tokenType]) {
					dividends = (deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(deposits[i].start))
						.div(TIME_STEP);

				} else {
					dividends = (deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint[tokenType]))
						.div(TIME_STEP);
				}
				if (deposits[i].withdrawn.add(dividends) > deposits[i].amount.mul(2)) {
					dividends = (deposits[i].amount.mul(2)).sub(deposits[i].withdrawn);
				}
				totalDividends = totalDividends.add(dividends);
			}
		}
		return totalDividends;
	}

	function getUserCheckpoint(uint8 tokenType, address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint[tokenType];
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserReferralBonus(uint8 tokenType, address userAddress) public view returns(uint256) {
		return users[userAddress].bonus[tokenType];
	}

	function getUserReferLevelBonus(uint8 tokenType, address userAddress) public view returns(uint256,uint256,uint256) {
		return (referLevelBonus[userAddress][tokenType][0], referLevelBonus[userAddress][tokenType][1], referLevelBonus[userAddress][tokenType][2]);
	}

	function getUserAvailable(uint8 tokenType, address userAddress) public view returns(uint256) {
		return getUserReferralBonus(tokenType, userAddress).add(getUserDividends(tokenType, userAddress));
	}

	function getUserDepositInfo(uint8 tokenType, address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];
		return (user.deposits[tokenType][index].amount, user.deposits[tokenType][index].withdrawn, user.deposits[tokenType][index].start);
	}

	function getUserLengthOfDeposits(uint8 tokenType, address userAddress) public view returns(uint256) {
		return users[userAddress].deposits[tokenType].length;
	}

	function getUserTotalDeposits(uint8 tokenType, address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount;
		for (uint256 i = 0; i < user.deposits[tokenType].length; i++) {
			amount = amount.add(user.deposits[tokenType][i].amount);
		}
		return amount;
	}

	function getUserTotalWithdrawn(uint8 tokenType, address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount;
		for (uint256 i = 0; i < user.deposits[tokenType].length; i++) {
			amount = amount.add(user.deposits[tokenType][i].withdrawn);
		}
		return amount;
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function isActive(uint8 tokenType, address userAddress) public view returns (bool) {
		User storage user = users[userAddress];
		if (user.deposits[tokenType].length > 0) {
			if (user.deposits[tokenType][user.deposits[tokenType].length-1].withdrawn < user.deposits[tokenType][user.deposits[tokenType].length-1].amount.mul(2)) {
				return true;
			}
		}else{
			return false;
		}
	}

	function setProject(address payable addr) public {
		require(msg.sender == owner);
		projectAddress = addr;
	}

	function setOwner(address addr) public {
		require(msg.sender == owner);
		owner = addr;
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