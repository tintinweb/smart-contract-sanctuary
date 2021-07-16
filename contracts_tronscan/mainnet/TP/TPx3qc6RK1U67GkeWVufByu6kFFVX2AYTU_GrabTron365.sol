//SourceUnit: GrabTron365.sol

/*
 *  
 *   GRABTRON365
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +0.2% to 1% every 24 hours
 *   [-200,001 to 300,000 daily 0.4%
 *    -300,001 to 400,000 daily 0.6%
 *    -400,001 to 500,000 daily 0.8%
 *    - 500,000 and above daily 1.0%]
 *   
 * 
 *   - Minimal deposit: 500 TRX, no maximal limit
 *   - Total Max income: 365% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *    Share your referral link with your partners and get additional bonuses.
 *   - 6-level referral commission: 15% (2 direct) - 5% (4 direct) - 3% (6 direct) - 3% (8 direct) - 2% (10 direct) - 2% (12% direct)
 *   
 *   Matching bonus 10% 1st-level
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 50% Platform main balance, participants payouts
 *	 - 30% Affiliate program bonuses
 *   - 10%  Direct Sponsor (First Level) matching bonus 
 *   - 10% Advertising and promotion expenses
 *
 *
 *   ────────────────────────────────────────────────────────────────────────
 */

pragma solidity ^0.5.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


contract GrabTron365 {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
	uint256 constant REFERRAL_PERCENTS = 1000; // 10%
	uint256 constant DEFAULT_ROI = 20; // 0.2 %
	uint256 constant public PROJECT_FEE = 1000; // 10%;
	uint256 constant public MIN_WITHDRAW = 100 trx;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP =  1 days; // 1 days

	uint256 public base_percent;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[] public ref_bonuses = [15,5,3,3,2,2]; 


	address payable public admin;

	

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		bool end;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 match_bonus;
		uint256 totalWithdrawn;
		uint256 remainingWithdrawn;
		uint256 totalReferrer;
		uint[25] refs;
	}

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event MatchPayout(address indexed addr, address indexed from, uint256 amount);
	event RefDirectBonus(address indexed referrer, address indexed referral, uint256 amount);
	event RefMatchPayout(address indexed referrer, address indexed referral, uint256 amount);

	constructor(address payable _admin) public {
		require(!isContract(_admin));
		admin = _admin;

		base_percent = (getContractBalanceRate() > 0) ? getContractBalanceRate() : DEFAULT_ROI;
	}


	function _refPayout(address _addr, uint256 _amount) private {
		 address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].refs[0] >= ((i+1)*2)){

					(uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
					
					uint256 bonus = _amount * ref_bonuses[i] / 100;
					uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

					bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

                users[up].bonus = users[up].bonus.add(bonus);
                emit MatchPayout(up, _addr, bonus);
			}
            up = users[up].referrer;
        }
    }


	function _refMatchPayout(address _addr, uint256 _amount) private {
		 address up = users[_addr].referrer;

		 (uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
		 uint256 bonus = _amount.mul(10).div(100);
		 uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

		 bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

		 if (bonus > 0) {
				users[up].match_bonus = users[up].match_bonus.add(bonus);
				emit RefMatchPayout(up, msg.sender, bonus);
			}

	}

	function invest(address referrer) public payable {

		
		require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment 500TRX');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].deposits.length > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");

		if(user.deposits.length > 0){
		 uint previousDeposit = user.deposits[user.deposits.length-1].amount;
		 require(msg.value > previousDeposit , "Invalid Deposit!");
		}

		admin.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));

		// setup upline

		if (user.referrer != address(0) && user.deposits.length == 0) {

            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refs[i]++;
					users[upline].totalReferrer++;
                    upline = users[upline].referrer;
                } else break;
            }
			downline[referrer][users[referrer].refs[0] - 1]= msg.sender;

        }
	
		uint msgValue = msg.value;
		
		// 6 Level Referral
		_refPayout(msg.sender,msgValue.mul(30).div(100));


		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,false));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);


		base_percent = (getContractBalanceRate() > 0) ? getContractBalanceRate() : DEFAULT_ROI;
		
		
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {

		User storage user = users[msg.sender];
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
		require(to_payout > 0, "User has no dividends");
		require(to_payout >= MIN_WITHDRAW, "Minimum withdraw 100 trx!");


		uint256 userPercentRate = base_percent;

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(365).div(100)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(365).div(100)) {     // Deposited Amount × 365 ÷ 100    // = Deposited Amount × 3.65
						dividends = (user.deposits[i].amount.mul(365).div(100)).sub(user.deposits[i].withdrawn);     // Deposited Amount × 3.65 Times Return
					}                                                                                                // Total Return = 365%

					user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);    // changing of storage data after withdrawal
					totalAmount = totalAmount.add(dividends);

					if(user.totalWithdrawn.add(to_payout) >= max_payout){
						user.deposits[i].withdrawn = user.deposits[i].amount.mul(365).div(100);
					}

				}
			
		}


        if(totalAmount > 0){
		 _refMatchPayout(msg.sender,totalAmount);
		}


		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
		}

		uint256 referralMatchingBonus = getUserReferralMatchingBonus(msg.sender);
		if (referralMatchingBonus > 0) {
			user.match_bonus = 0;
		}

		


		user.checkpoint = block.timestamp;

		msg.sender.transfer(to_payout);

		user.totalWithdrawn = user.totalWithdrawn.add(to_payout);
		totalWithdrawn = totalWithdrawn.add(to_payout);

		emit Withdrawn(msg.sender, to_payout);

	}



	

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw,  uint _contractPercent) {
        return (totalUsers, totalInvested, totalWithdrawn, base_percent);
    }


	function getContractBalanceRate() public view returns (uint256) {

        uint contractBalance = address(this).balance;
		uint _rate = 0;
        if(contractBalance > 100000 trx && contractBalance <= 300000 trx){
			_rate = 40;
		}
		if(contractBalance > 300000 trx && contractBalance <= 400000 trx){
			_rate = 60;
		}
		if(contractBalance > 400000 trx && contractBalance <= 500000 trx){
			_rate = 80;
		}

		if(contractBalance > 500000 trx){
			_rate = 100;
		}

		return _rate;

    }

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = base_percent;

		uint256 totalDividends;
		uint256 dividends;



		for (uint256 i = 0; i < user.deposits.length; i++) {

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(365).div(100)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(365).div(100)) {
						dividends = (user.deposits[i].amount.mul(365).div(100)).sub(user.deposits[i].withdrawn);
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

	function getUserDownlineInfo(address userAddress, uint index) public view returns(uint256) {
		return users[userAddress].refs[index];
	}

	
    function maxPayoutOf(address userAddress) view external returns(uint256) {
		User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}
        return amount * 365 / 100;
    }

	function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
		User storage user = users[_addr];
        max_payout = this.maxPayoutOf(_addr);


		if(user.totalWithdrawn < max_payout){
			payout = getUserDividends(_addr).add(getUserReferralBonus(_addr)).add(getUserReferralMatchingBonus(_addr)).add(user.remainingWithdrawn);

			if(user.totalWithdrawn.add(payout) > max_payout){
				payout = max_payout.sub(user.totalWithdrawn);
			}
		}

    }

	

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralMatchingBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].match_bonus;
	}

	


	function getUserAvailableBalanceForWithdrawal(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
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