//SourceUnit: TronConnect.sol

/*
 *
 *   TronConnect - Smart Investment Platform Based on TRX Blockchain Smart-Contract Technology. 
 *   100% Safe and Legit!
 *   S&S Dev
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronconnect.io                                    │
 *   │                                                                       │
 *   │   Telegram Public Group: @tronconnect_ENG                             |
 *   │   Telegram News Channel: @tronconnectofficial                            |
 *   |                                                                       |
 *   |   E-mail: support@tronconnect.io                                     |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (100 TRX minimum) using our website make deposit button
 *   3) Wait for your earnings
 *   4) Withdraw earnings once a day using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1.5% every 24 hours (+0.0625% hourly)
 *   - Personal hold-bonus: +0.05% for every 24 hours without withdraw. Max Limited to 2%
 *   - Contract total amount bonus: +0.1% for every 1,000,000 TRX on platform address balance. Max Limited to 3.5%
 *   - Referral Bonus upto +1.5% every 24 hours
 *   - Leader Deposit Bonus upto +1.5% every 24 hours and prize upto 130k TRX
 *
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 250% (deposit included)
 *   - Earnings every moment, withdraw once a day max 50% of deposit amount
 *
 *   - Custom Withdraw Option, here you can mention your amount of TRX to withdraw from your available TRX balance
 *
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 10% - 3% - 1% - 0.5% - 0.5%
 *   - Auto-refback function
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 71% Platform main balance, participants payouts
 *   - 12% Advertising and promotion expenses
 *   - 15% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TronConnect LTD (#12878147)
 *   - Company status: https://beta.companieshouse.gov.uk/company/12878147
 *   - Certificate of incorporation: https://tronconnect.io/certificate.pdf
 *
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company Haze Crypto: https://hazecrypto.net/tronconnect/
 *
 */

pragma solidity 0.5.10;

contract TronConnect {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 100e6;
	uint256 constant public BASE_PERCENT = 150;
	uint256[] public REFERRAL_PERCENTS = [1000,300,100,50,50];
	uint256 constant public MARKETING_FEE = 1200;
	uint256 constant public PROJECT_FEE = 200;
	uint256 constant public ROI = 25000;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public CONTRACT_BALANCE_STEP = 1e12;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalDeposits;

	address payable public marketingAddress;
	address payable public projectAddress;
	address public owner;
	uint256 internal lastMil;

	uint256 public startDate;

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	}

	struct User {
		uint256 id;
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 lastHoldPercent;
		address referrer;
		uint256[5] levels;
		uint256 directBusiness;
		uint256 totalRewards;
		uint256 bonus;
		uint256 reserved;
		uint256 refBackPercent;
	}

	mapping (address => User) internal users;
	mapping (uint256 => address) internal ids;
	mapping (address => uint256) internal contestRef;
	mapping (address => uint256) internal contestRew;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event RefBack(address indexed referrer, address indexed referral, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable marketingAddr, address payable projectAddr, uint256 start) public {
		require(marketingAddr != address(0) && projectAddr != address(0));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		startDate = start;
		owner = msg.sender;
	}

	function invest(uint256 referrerID) public payable {
		address referrer = ids[referrerID];

		require(msg.value >= INVEST_MIN_AMOUNT);

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		User storage user = users[msg.sender];

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					if(i==0){
						contestRef[upline] += 1 ;
					}
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.referrer != address(0)) {

			address upline = user.referrer;
			for (uint256 i = 0; i < 5; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(getUserReferralPercent(i)).div(PERCENTS_DIVIDER);
					if (i == 0) {
						uint256 preDirectBusiness = users[upline].directBusiness;
						users[upline].directBusiness = users[upline].directBusiness.add(msg.value);
						contestRew[upline] = contestRew[upline].add(msg.value);

						if (users[upline].refBackPercent > 0) {
							uint256 refback = amount.mul(users[upline].refBackPercent).div(PERCENTS_DIVIDER);
							user.bonus = user.bonus.add(refback);
							user.totalRewards = user.totalRewards.add(amount);
							amount = amount.sub(refback);
							emit RefBack(upline, msg.sender, refback);
						}

						//leader prize
						uint256 leaderPrize= getUserLeaderPrize(preDirectBusiness,users[upline].directBusiness);
						if(leaderPrize > 0){
							amount = amount.add(leaderPrize);
						}

					}
					if (amount > 0) {
						users[upline].bonus = users[upline].bonus.add(amount);
						users[upline].totalRewards = users[upline].totalRewards.add(amount);
						emit RefBonus(upline, msg.sender, i, amount);
					}
					upline = users[upline].referrer;
				} else break;
			}

		}

		if (user.deposits.length == 0) {
			if (block.timestamp < startDate) {
				user.checkpoint = startDate;
			} else {
				user.checkpoint = block.timestamp;
			}
			totalUsers = totalUsers.add(1);
			user.id = totalUsers;
			ids[totalUsers] = msg.sender;
			emit Newbie(msg.sender);
		}

		uint256 deposit = msg.value;
		if (block.timestamp < startDate) {
			deposit = deposit.add(getPrelaunchBonus(deposit));
		}
		user.deposits.push(Deposit(deposit, 0, block.timestamp));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);

		emit NewDeposit(msg.sender, msg.value);

		uint256 mils = address(this).balance.div(CONTRACT_BALANCE_STEP);
		if (mils > lastMil) { /// 1 per every 1 mil
			users[getUserById(1)].bonus = users[getUserById(1)].bonus.add((mils.sub(lastMil)).mul(CONTRACT_BALANCE_STEP.div(100)));
			lastMil = mils;
		}

	}

	function _reserve() internal {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		user.checkpoint = block.timestamp;
		user.reserved = user.reserved.add(totalAmount);
	}

	function withdraw(uint256 amount) public {
		require(block.timestamp >= startDate);
		User storage user = users[msg.sender];

		//only once a day
		require(now > user.checkpoint + 1 days , "Only once a day");

		//50% of total deposits
		uint256 uTotalInvest = getUserTotalDeposits(msg.sender);
		if(amount > uTotalInvest.div(2)){
			amount = uTotalInvest.div(2);
		}


		uint256 holdBonus = getUserHoldBonus(msg.sender);

		_reserve();

		uint256 reserved = user.reserved;

		uint256 referralBonus = getUserReferralBonus(msg.sender);

		uint256 contractBalance = address(this).balance;
		if (contractBalance < amount) {
			amount = contractBalance;
		}

		require(reserved.add(referralBonus) > amount, "User has no enough dividends");

		uint256 remaining = amount;

		if (referralBonus > 0) {
			if (referralBonus >= amount) {
				remaining = remaining.sub(amount);
				user.bonus = user.bonus.sub(amount);
			} else {
				remaining = remaining.sub(user.bonus);
				user.bonus = 0;
			}
		}

		if (remaining > 0) {
			user.reserved = user.reserved.sub(remaining);
		}

		user.lastHoldPercent = holdBonus.mul(user.reserved).div(reserved);

		msg.sender.transfer(amount);

		emit Withdrawn(msg.sender, amount);
	}

	function setRefBackPercent(uint256 newPercent) public {
		require(newPercent <= PERCENTS_DIVIDER);
		User storage user = users[msg.sender];
		user.refBackPercent = newPercent;
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function getContractBalanceRate() public view returns (uint256) {
		uint256 contractBalance = address(this).balance;
		uint256 contractBalancePercent = contractBalance.div(CONTRACT_BALANCE_STEP).mul(10);
		if (contractBalancePercent > 350) {
			contractBalancePercent = 350;
		}
		return BASE_PERCENT.add(contractBalancePercent);
	}

	function getUserHoldBonus(address userAddress) public view returns (uint256) {
		if (block.timestamp < startDate) return 0;
		User storage user = users[userAddress];

		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			uint256 holdBonus = (timeMultiplier.mul(5)).add(user.lastHoldPercent);
			if (holdBonus > 200) {
				holdBonus = 200;
			}
			return holdBonus;
		} else {
			return 0;
		}
	}

	function getUserDownlineBonus(address userAddress) public view returns(uint256) {
		uint256 refs = users[userAddress].levels[0];

		if (refs >= 1000) {
			return 150;
		} else if (refs >= 500) {
			return 100;
		} else if (refs >= 250) {
			return 75;
		} else if (refs >= 100) {
			return 50;
		} else if (refs >= 50) {
			return 25;
		} else if (refs >= 25) {
			return 10;
		} else {
			return 0;
		}
	}

	function getUserLeaderPrize(uint256 preDirectBusiness,uint256 directBusiness) internal pure returns(uint256) {
		
		uint256 leaderPrize=0;
		
		if (directBusiness >= 5e12 && preDirectBusiness < 5e12) {
			leaderPrize+= 130e9;
		}
		if (directBusiness >= 1e12 && preDirectBusiness < 1e12) {
			leaderPrize+= 35e9;
		}
		if (directBusiness >= 500e9 && preDirectBusiness < 500e9) {
			leaderPrize+= 10e9;
		}
		if (directBusiness >= 100e9 && preDirectBusiness < 100e9) {
			leaderPrize+= 2e9;
		}
		if (directBusiness >= 50e9 && preDirectBusiness < 50e9) {
			leaderPrize+= 1e9;
		}
		if (directBusiness >= 20e9 && preDirectBusiness < 20e9) {
			leaderPrize+= 4e8;
		}
		if (directBusiness >= 10e9 && preDirectBusiness < 10e9) {
			leaderPrize+= 2e8;
		}
		return leaderPrize;
	}
	function getUserLeaderBonus(address userAddress) public view returns(uint256) {
		uint256 directBusiness = getUserDirectBusiness(userAddress);

		if (directBusiness >= 5e12) {
			return 150;
		} else if (directBusiness >= 1e12) {
			return 130;
		} else if (directBusiness >= 500e9) {
			return 100;
		} else if (directBusiness >= 100e9) {
			return 70;
		} else if (directBusiness >= 50e9) {
			return 50;
		} else if (directBusiness >= 20e9) {
			return 30;
		} else if (directBusiness >= 10e9) {
			return 10;
		} else {
			return 0;
		}
	}

	function getPrelaunchBonus(uint256 deposit) public pure returns(uint256) {
		if (deposit >= 1e12) {
			return (deposit.mul(15).div(100));
		} else if (deposit >= 5e11) {
			return (deposit.mul(10).div(100));
		} else if (deposit >= 1e11) {
			return (deposit.mul(75).div(1000));
		} else {
			return (deposit.mul(5).div(100));
		}
	}

	function getUserPercentRate(address userAddress) public view returns (uint256) {
		return getContractBalanceRate().add(getUserHoldBonus(userAddress)).add(getUserDownlineBonus(userAddress)).add(getUserLeaderBonus(userAddress));
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		if (block.timestamp < startDate) return 0;

		User storage user = users[userAddress];

		uint256 userPercentRate = getUserPercentRate(userAddress);

		uint256 totalDividends = user.reserved;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)) {
					dividends = (user.deposits[i].amount.mul(ROI).div(PERCENTS_DIVIDER)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);

				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}

	function getUserReferralPercent(uint256 level) public view returns(uint256) {
		return REFERRAL_PERCENTS[level];
	}

	function getUserId(address userAddress) public view returns(uint256) {
		return users[userAddress].id;
	}

	function getUserById(uint256 id) public view returns(address) {
		return ids[id];
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDirectBusiness(address userAddress) public view returns(uint256) {
		return users[userAddress].directBusiness;
	}

	function getUserRefRewards(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRewards;
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserLastDepositDate(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits[users[userAddress].deposits.length-1].start;
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(ROI).div(PERCENTS_DIVIDER)) {
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

		uint256 amount = user.totalRewards.sub(user.bonus);

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].withdrawn);
		}

		return amount.sub(user.reserved);
	}

	function getUserWithdrawRef(address userAddress) public view returns(uint256) {
		return users[userAddress].totalRewards.sub(users[userAddress].bonus);
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserRefbackPercent(address userAddress) public view returns(uint256) {
		return users[userAddress].refBackPercent;
	}

	function getTop10Leader() public view returns(uint[] memory,uint[] memory){
		uint[10][2] memory top;

		uint cnt = totalUsers;

		uint total;
		uint tmpValue;
		uint tmpId;
		for (uint i = 1; i <= cnt; i++) {
			total = users[ids[i]].directBusiness;
			if(total > top[1][9]){
				top[0][9]=i;
				top[1][9]=total;
				for(uint j =9; j > 0; j--){
					if(top[1][j - 1] >= top[1][j]) break;
					tmpId = top[0][j - 1];
					tmpValue = top[1][j - 1];
					top[0][j - 1] = top[0][j];
					top[1][j - 1] = top[1][j];
					top[0][j] = tmpId;
					top[1][j] = tmpValue;
				}
			}
		}
		
		uint[] memory id = new uint[](10);
		uint[] memory val = new uint[](10);
		for (uint k = 0; k < 10; k++) {
			if(top[0][k]>0){
				id[k]=top[0][k];
				val[k]=top[1][k];
			}
		}

		return (id,val);
	}

	function getTop10Referral() public view returns(uint[] memory,uint[] memory){
		uint[10][2] memory top;

		uint cnt = totalUsers;

		uint total;
		uint tmpValue;
		uint tmpId;
		for (uint i = 1; i <= cnt; i++) {
			total = users[ids[i]].levels[0];
			if(total > top[1][9]){
				top[0][9]=i;
				top[1][9]=total;
				for(uint j =9; j > 0; j--){
					if(top[1][j - 1] >= top[1][j]) break;
					tmpId = top[0][j - 1];
					tmpValue = top[1][j - 1];
					top[0][j - 1] = top[0][j];
					top[1][j - 1] = top[1][j];
					top[0][j] = tmpId;
					top[1][j] = tmpValue;
				}
			}
		}
		
		uint[] memory id = new uint[](10);
		uint[] memory val = new uint[](10);
		for (uint k = 0; k < 10; k++) {
			if(top[0][k]>0){
				id[k]=top[0][k];
				val[k]=top[1][k];
			}
		}

		return (id,val);
	}

	function getTop10Investors() public view returns(uint[] memory,uint[] memory){
		uint[10][2] memory top;

		uint cnt = totalUsers;

		uint total;
		uint tmpValue;
		uint tmpId;
		for (uint i = 1; i <= cnt; i++) {
			total = getUserTotalDeposits(ids[i]);
			if(total > top[1][9]){
				top[0][9]=i;
				top[1][9]=total;
				for(uint j =9; j > 0; j--){
					if(top[1][j - 1] >= top[1][j]) break;
					tmpId = top[0][j - 1];
					tmpValue = top[1][j - 1];
					top[0][j - 1] = top[0][j];
					top[1][j - 1] = top[1][j];
					top[0][j] = tmpId;
					top[1][j] = tmpValue;
				}
			}
		}
		
		uint[] memory id = new uint[](10);
		uint[] memory val = new uint[](10);
		for (uint k = 0; k < 10; k++) {
			if(top[0][k]>0){
				id[k]=top[0][k];
				val[k]=top[1][k];
			}
		}

		return (id,val);
	}

	function resetContest() public returns(bool){
		require(msg.sender == owner , "only owners can call this function");
		uint cnt = totalUsers;
		for (uint i = 1; i <= cnt; i++) {
			if(contestRef[ids[i]]>0){
				contestRef[ids[i]]=0;
			}
			if(contestRew[ids[i]]>0){
				contestRew[ids[i]]=0;
			}
		}
		return true;
	}

	function getTop5contestRew() public view returns(uint[] memory,uint[] memory){
		uint[5][2] memory top;

		uint cnt = totalUsers;

		uint total;
		uint tmpValue;
		uint tmpId;
		for (uint i = 1; i <= cnt; i++) {
			total = contestRew[ids[i]];
			if(total > top[1][4]){
				top[0][4]=i;
				top[1][4]=total;
				for(uint j =4; j > 0; j--){
					if(top[1][j - 1] >= top[1][j]) break;
					tmpId = top[0][j - 1];
					tmpValue = top[1][j - 1];
					top[0][j - 1] = top[0][j];
					top[1][j - 1] = top[1][j];
					top[0][j] = tmpId;
					top[1][j] = tmpValue;
				}
			}
		}
		
		uint[] memory id = new uint[](5);
		uint[] memory val = new uint[](5);
		for (uint k = 0; k < 5; k++) {
			if(top[0][k]>0){
				id[k]=top[0][k];
				val[k]=top[1][k];
			}
		}

		return (id,val);
	}

	function getTop5contestRef() public view returns(uint[] memory,uint[] memory){
		uint[5][2] memory top;

		uint cnt = totalUsers;

		uint total;
		uint tmpValue;
		uint tmpId;
		for (uint i = 1; i <= cnt; i++) {
			total = contestRef[ids[i]];
			if(total > top[1][4]){
				top[0][4]=i;
				top[1][4]=total;
				for(uint j =4; j > 0; j--){
					if(top[1][j - 1] >= top[1][j]) break;
					tmpId = top[0][j - 1];
					tmpValue = top[1][j - 1];
					top[0][j - 1] = top[0][j];
					top[1][j - 1] = top[1][j];
					top[0][j] = tmpId;
					top[1][j] = tmpValue;
				}
			}
		}
		
		uint[] memory id = new uint[](5);
		uint[] memory val = new uint[](5);
		for (uint k = 0; k < 5; k++) {
			if(top[0][k]>0){
				id[k]=top[0][k];
				val[k]=top[1][k];
			}
		}

		return (id,val);
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