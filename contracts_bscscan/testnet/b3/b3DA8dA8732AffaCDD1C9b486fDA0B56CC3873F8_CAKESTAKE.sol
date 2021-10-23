/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

pragma solidity 0.5.8;

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

 
  function name() external view returns (string memory);


  function getOwner() external view returns (address);

 
  function balanceOf(address account) external view returns (uint256);

  
  function transfer(address recipient, uint256 amount) external returns (bool);

  
  function allowance(address _owner, address spender) external view returns (uint256);


  function approve(address spender, uint256 amount) external returns (bool);


  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

 
  event Transfer(address indexed from, address indexed to, uint256 value);


  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract CAKESTAKE {
	using SafeMath for uint256;
	
	 IBEP20 public CAKE;

	uint256 constant public INVEST_MIN_AMOUNT = 1e17; //0.1 Cake
	uint256 constant public PROJECT_FEE = 45;
	uint256 constant public DEVELOPER_FEE = 20;
	uint256 constant public MARKETING_FEE = 35;
	uint256 constant public PERCENT_STEP = 8; // 0.8%
	uint256 constant public PERCENTS_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;
	
	uint256 constant public WITHDRAWAL_LOTTERY_FEE = 25;
	uint256 constant public STAKE_LOTTERY_FEE = 10;
	
	
	uint256[] public REFERRAL_PERCENTS = [30, 20, 10, 10, 10, 8, 5, 2];
	
	uint256 public constant CAKE_PER_TICKET = 1e17; // 0.1 CAKE
    uint256 public lotteryRound = 0;
    uint256 public currentPot = 0;
    uint256 public participants = 0;
    uint256 public totalTickets = 0;
    uint256 public LOTTERY_STEP = 6 hours; 
    uint256 public LOTTERY_START_TIME;
    
    uint256 public constant STAKE_MIN_AMOUNT = 0.05 ether;
    uint256 public constant FINE_TIME = 3 days;
	
	
	
    uint256 public totalStaked;
    uint256 public totalBnbStaked;
	uint256 public totalDeposits;
	uint256 public totalReferralEarned;
    
    uint256 public cakeFee;

    uint256 FEE_HISTORY_UPDATE_TIME;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
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
		address payable referrer;
		uint256 referrals;
		uint256 totalBonus;
		uint256 refRewards;
		uint256 lotteryRewards;
		uint256 bnbStaked;
		uint256 feeCheckpoint;
		uint256 bnbStakeCheckpoint;
	}

	mapping (address => User) internal users;
	
	uint256[] public projectFeeHistory;
	
    mapping(uint256 => mapping(address => uint256)) public ticketOwners; // round => address => amount of owned tickets
    mapping(uint256 => mapping(uint256 => address)) public participantAdresses; // round => id => address

	uint256 public startUNIX;
	address payable private commissionWallet;
	address payable private developerWallet;
	address payable public marketingWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event onLotteryWinner(address indexed investor, uint256 pot, uint256 indexed round);
	event onBnbStaked(address indexed user, uint256 amount);
	event onCakeFeeClaimed(address indexed user, uint256 amount);
	event onUnstake(address indexed user, uint256 amount, bool indexed fine);
	event onLotteryRewardsClaimed(address investor, uint256 rewards);

	constructor(address payable wallet, address payable _developer, address payable _marketing,  IBEP20 CAKE_ADDRESS) public {
		require(!isContract(wallet));
		commissionWallet = wallet;
		developerWallet = _developer;
		marketingWallet = _marketing;
		
		CAKE = CAKE_ADDRESS;
		FEE_HISTORY_UPDATE_TIME = block.timestamp.add(115 hours);
		startUNIX = block.timestamp.add(115 hours);
		LOTTERY_START_TIME = block.timestamp.add(115 hours);

        plans.push(Plan(365, 60)); // 6% per day for 365 days
        plans.push(Plan(15, 90)); // 9% per day for 15 days
        plans.push(Plan(13, 70)); // 7% per day for 13 days (auto-compound)
        plans.push(Plan(13, 130)); // 13% per day for 13 days (payment at the end)
        plans.push(Plan(15, 70)); // 7-11% per day for 15 days (random)
        plans.push(Plan(15, 30)); // 3-15% per day for 15 days (random)
	}


function invest(address payable referrer,uint8 plan, uint256 amount) public payable {
        _invest(referrer, plan, msg.sender, amount);
           
    }


	function _invest(address payable referrer, uint8 plan, address payable sender, uint256 value) private {
		require(value >= INVEST_MIN_AMOUNT);
        require(plan < 6, "Invalid plan");
        require(startUNIX < block.timestamp, "contract hasn`t started yet");
        require(value <= CAKE.balanceOf(sender), "insufficient amount");
        
        CAKE.transferFrom(sender, address(this), value);
        
		uint256 fee = value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		CAKE.transfer(commissionWallet,fee);
		uint256 developerFee = value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		CAKE.transfer(developerWallet,developerFee);
		uint256 marketingFee = value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		CAKE.transfer(marketingWallet,marketingFee);
		
		
		User storage user = users[sender];

		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) { 
				if (upline != address(0)) {
					users[upline].referrals = users[upline].referrals.add(1);
					upline = users[upline].referrer;
				} else break;
			}
		}

            _countRefRewards(sender, value);
	

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			
			
			emit Newbie(sender);
		}

		(uint256 percent, uint256 profit, uint256 finish) = getResult(plan, value);
		
		
		user.deposits.push(Deposit(plan, percent, value, profit, block.timestamp, finish));

		totalStaked = totalStaked.add(value);
		totalDeposits = totalDeposits.add(1);
		
		uint256 amountForLottery = value.mul(STAKE_LOTTERY_FEE).div(PERCENTS_DIVIDER);
 		
 		_buyTickets(sender, amountForLottery);
 		
 		cakeFee = cakeFee.add(value.mul(10).div(1000)); // 1%
 		
 		checkFeeHistoryUpdate();
		
		emit NewDeposit(sender, plan, percent, value, profit, block.timestamp, finish);
	}
	
	function stake() public payable {
	    require(startUNIX < block.timestamp, "contract hasn`t started yet");
	    require(msg.value >= STAKE_MIN_AMOUNT, "Min. amount is 0.05 BNB");
	    require(getUserTotalDeposits(msg.sender) > 0, "must be an active deposit");
	    
	    uint256 totalCakeDeposits = getUserTotalDeposits(msg.sender);
	    uint256 availableBnbStake = totalCakeDeposits.div(20).sub(users[msg.sender].bnbStaked);
	    
	    require(msg.value <= availableBnbStake, "BNB limit is exceeded");
	    
	    uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		uint256 developerFee = msg.value.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		developerWallet.transfer(developerFee);
		uint256 marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		marketingWallet.transfer(marketingFee);
	    
	    User storage user = users[msg.sender];
	    
	    if(user.bnbStaked > 0) { // already have deposit
	        uint256 rewards = getCakeDividends(msg.sender);
	        CAKE.transfer(msg.sender, rewards);
	    } 
	    
	    user.feeCheckpoint = cakeFee;
	    user.bnbStaked = user.bnbStaked.add(msg.value);
	    user.bnbStakeCheckpoint = block.timestamp;
	    
	    totalBnbStaked = totalBnbStaked.add(msg.value);
	    
	    emit onBnbStaked(msg.sender, msg.value);
	    
	}
	
	function claimCakeFee() public payable {
	    User storage user = users[msg.sender];
	    
	    uint256 rewards = getCakeDividends(msg.sender);
	    
	    require(rewards > 0, "nothing to claim");
	    
	    user.feeCheckpoint = cakeFee;
	    
	    CAKE.transfer(msg.sender, rewards);
	    
	    emit onCakeFeeClaimed(msg.sender, rewards);
	}
	
	
	function unstake() public payable {
	   User storage user = users[msg.sender];
	   
	   uint256 rewards = getCakeDividends(msg.sender);
	   
	   bool flag;
	   
	   if(rewards > 0){
	       if(CAKE.balanceOf(address(this)) >= rewards) {
	           CAKE.transfer(msg.sender, rewards);
	       }
	       
	   }
	   
	   if(block.timestamp.sub(user.bnbStakeCheckpoint) < FINE_TIME){
	       uint256 amount = user.bnbStaked.mul(95).div(100);
	       if(amount > address(this).balance){
	           amount = address(this).balance;
	       }
	       msg.sender.transfer(amount);
	       flag = true;
	   } else {
	       uint256 amount = user.bnbStaked;
	       if(amount > address(this).balance){
	           amount = address(this).balance;
	       }
	       msg.sender.transfer(amount);
	       flag = false;
	   }
	   
	   totalBnbStaked = totalBnbStaked.sub(user.bnbStaked);
	   
	   emit onUnstake(msg.sender, user.bnbStaked, flag);
	   
	   user.bnbStaked = 0;
	    
	   
	}
	
	function getCakeDividends(address userAddress) public view returns(uint256){
	    User storage user = users[userAddress];
	    
	    uint256 availableFee = cakeFee.sub(user.feeCheckpoint);
	    
	    return user.bnbStaked.mul(availableFee).div(totalBnbStaked);
	}
	
	function _countRefRewards(address userAddress, uint256 value) private {
	        User storage user = users[userAddress];
	        
	        uint256 total = 0;
	        
	    	if (user.referrer != address(0)) {
			address payable upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {  
				if (upline != address(0)) {
				
    					uint256 amount = value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
    					total = total.add(amount);
    					
    					users[upline].refRewards = users[upline].refRewards.add(amount);
				    
					
					upline = users[upline].referrer;
				} else break;
			}

		}
		
		totalReferralEarned = totalReferralEarned.add(total);
	}
	
		function _countLotteryRefRewards(address userAddress, uint256 value) private {
	        User storage user = users[userAddress];

	        uint256 total = 0;

	    	if (user.referrer != address(0)) {
			address payable upline = user.referrer;
			for (uint256 i = 0; i < REFERRAL_PERCENTS.length; i++) {  
				if (upline != address(0)) {
				
    					uint256 amount = value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER).div(2); // 2 times less
    					total = total.add(amount);
    					users[upline].refRewards = users[upline].refRewards.add(amount);
				    
					
					upline = users[upline].referrer;
				} else break;
			}

			totalReferralEarned = totalReferralEarned.add(total);

		}
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);

		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = CAKE.balanceOf(address(this));
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		
 		uint256 amountForLottery = totalAmount.mul(WITHDRAWAL_LOTTERY_FEE).div(PERCENTS_DIVIDER);
 		
 		
 		_buyTickets(msg.sender, amountForLottery);
 		
 		uint256 commission = totalAmount.mul(25).div(1000); // 2.5%
 		
 		cakeFee = cakeFee.add(commission); // 2.5%
 		
 		totalAmount = totalAmount.sub(amountForLottery).sub(commission);
	

		CAKE.transfer(msg.sender, totalAmount);
	
		
		
		checkFeeHistoryUpdate();
		

		emit Withdrawn(msg.sender, totalAmount);

	}
	
	
	function withdrawRef() public {
	    User storage user = users[msg.sender];
	    require(user.refRewards > 0 , 'user doesnt have referral rewards');
	    
	    uint256 value = user.refRewards;
	    user.refRewards = 0;
	    
	    uint256 amountForLottery = value.mul(WITHDRAWAL_LOTTERY_FEE).div(PERCENTS_DIVIDER);
	    
	    uint256 commission = value.mul(25).div(1000); // 2.5%
	    
	    cakeFee = cakeFee.add(commission);
 		
 		value = value.sub(amountForLottery).sub(commission);
 		
 		_buyTickets(msg.sender, amountForLottery);
	    
	    
	    CAKE.transfer(msg.sender, value);
	    
	    user.totalBonus = user.totalBonus.add(value);
	    
	    
	    emit Withdrawn(msg.sender, user.refRewards);
	    
	   checkFeeHistoryUpdate();
	    
	}
	
	function claimLotteryReward() public {
        User storage user = users[msg.sender];
        require(user.lotteryRewards !=0, "Nothing to claim");
        
        uint256 amount = user.lotteryRewards;
        
        CAKE.transfer(msg.sender, amount);
        
        user.lotteryRewards = 0;
        
        emit onLotteryRewardsClaimed(msg.sender, amount);
    }
	
	  function buyTickets(uint256 cakeAmount) public {
	    require(startUNIX < block.timestamp, "contract hasn`t started yet");
	    require(CAKE.balanceOf(msg.sender) >= cakeAmount, "insufficient balance");
	    require(cakeAmount != 0, "zero purchase amount.");
	      
	    CAKE.transferFrom(msg.sender, address(this), cakeAmount);
	      
	    uint256 fee = cakeAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		CAKE.transfer(commissionWallet,fee);
		uint256 developerFee = cakeAmount.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER);
		CAKE.transfer(developerWallet,developerFee);
		uint256 marketingFee = cakeAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		CAKE.transfer(marketingWallet,marketingFee);
		
		
		_countRefRewards(msg.sender, cakeAmount);
		
		_buyTickets(msg.sender, cakeAmount);
	      
	  }


      function _buyTickets(address userAddress, uint256 amount) private { // amount - CAKE for purchase
    
        require(amount != 0, "zero purchase amount");
        
        uint256 tickets = amount.mul(1e18).div(CAKE_PER_TICKET);
        
        if(ticketOwners[lotteryRound][userAddress] == 0) {
            participantAdresses[lotteryRound][participants] = userAddress;
            participants = participants.add(1);
        }
        
        ticketOwners[lotteryRound][userAddress] = ticketOwners[lotteryRound][userAddress].add(tickets);
        currentPot = currentPot.add(amount);
        totalTickets = totalTickets.add(tickets);
        
        if(block.timestamp.sub(LOTTERY_START_TIME) >= LOTTERY_STEP || participants == 200){
            _chooseWinner();
        }
    }
    
    function _chooseWinner() private {
        
       uint256[] memory init_range = new uint256[](participants);
       uint256[] memory end_range = new uint256[](participants);
       
       uint256 last_range = 0;
       
       for(uint256 i = 0; i < participants; i++){
           uint256 range0 = last_range.add(1);
           uint256 range1 = range0.add(ticketOwners[lotteryRound][participantAdresses[lotteryRound][i]].div(1e18)); 
           
           init_range[i] = range0;
           end_range[i] = range1;
           
           last_range = range1;
       }
        
       uint256 random = _getRandom().mod(last_range).add(1); 
       
       for(uint256 i = 0; i < participants; i++){
           if((random >= init_range[i]) && (random <= end_range[i])){
               // winner found
               
               address winnerAddress = participantAdresses[lotteryRound][i];
               
               users[winnerAddress].lotteryRewards = users[winnerAddress].lotteryRewards.add(currentPot.mul(8).div(10));
               
               //fees and rewards
               
               uint256 fee = currentPot.mul(PROJECT_FEE).div(PERCENTS_DIVIDER); 
     		   CAKE.transfer(commissionWallet,fee);
    		   uint256 developerFee = currentPot.mul(DEVELOPER_FEE).div(PERCENTS_DIVIDER); 
    		   CAKE.transfer(developerWallet,developerFee);
    		   uint256 marketingFee = currentPot.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
		       CAKE.transfer(marketingWallet,marketingFee);
    		   
    		   _countLotteryRefRewards(winnerAddress, currentPot);
    		   
    		   cakeFee = cakeFee.add(currentPot.mul(10).div(100));
              
               // reset lotteryRound
               
                emit onLotteryWinner(winnerAddress, currentPot, lotteryRound);
               
               currentPot = 0;
               lotteryRound = lotteryRound.add(1);
               participants = 0;
               totalTickets = 0;
               LOTTERY_START_TIME = block.timestamp;
               
              

               break;
           }
       }
    }
    
    function checkFeeHistoryUpdate() public {
        if(block.timestamp.sub(FEE_HISTORY_UPDATE_TIME) >= 24 hours) {
            projectFeeHistory.push(cakeFee);
            FEE_HISTORY_UPDATE_TIME = block.timestamp;
        }
    }
    
    function _getRandom() private view returns(uint256){
        
        bytes32 _blockhash = blockhash(block.number-1);
        
        
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,currentPot,block.difficulty)));
    }
	

	function getContractBalance() public view returns (uint256) {
		return CAKE.balanceOf(address(this));
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getPercent(uint8 plan) public view returns (uint256) {
	    
		if(plan < 4 ){
			 return plans[plan].percent.add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		} 
		
		if(plan >= 4){
		    uint256 random = getRandomPercent(plan);
		    return plans[plan].percent.add(random).add(PERCENT_STEP.mul(block.timestamp.sub(startUNIX)).div(TIME_STEP));
		}
    }
    
    function getRandomPercent(uint8 plan) private view returns(uint256) {
        uint256 mod;
        
        if(plan == 4){
            mod = 40; // (11% - 7%) * 10
        }
        if(plan == 5){
            mod = 120; // (15% - 3%) * 10
        }
        
        
        bytes32 _blockhash = blockhash(block.number-1);
        
        
        uint256 random =  uint256(keccak256(abi.encode(_blockhash,block.timestamp,block.difficulty))); 
        uint256 rand = random.mod(mod); // random number
        
        
        return rand;
    }

	function getResult(uint8 plan, uint256 deposit) public view returns (uint256 percent, uint256 profit, uint256 finish) {
		percent = getPercent(plan);

	
		profit = deposit.mul(percent).div(PERCENTS_DIVIDER).mul(plans[plan].time);
	

		finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
	}
	
    
	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;
		

		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.checkpoint < user.deposits[i].finish) {
				if (user.deposits[i].plan == 3) {
				    if (block.timestamp > user.deposits[i].finish){
				        totalAmount = totalAmount.add(user.deposits[i].profit);
				    }
				    
				} else  {
					if(user.deposits[i].plan == 2) {
					    
					    uint256 passedDays = block.timestamp.sub(user.checkpoint).div(TIME_STEP);
					    uint256 payout = 0;
					    uint256 percent = user.deposits[i].percent;
					    
					    for(uint256 k = 0; k<passedDays;k++){
					            payout = payout.add(user.deposits[i].amount.add(payout).mul(percent).div(PERCENTS_DIVIDER));
					    }
					    
					    totalAmount = totalAmount.add(payout);
					    
					} else {
					    	uint256 share = user.deposits[i].amount.mul(user.deposits[i].percent).div(PERCENTS_DIVIDER);
        					uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
        					uint256 to = user.deposits[i].finish < block.timestamp ? user.deposits[i].finish : block.timestamp;
        					if (from < to) {
        						totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
        					}
					}
				
				}
			}
		}

		return totalAmount;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
    
	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}
	

	function getUserDownlineCount(address userAddress) public view returns(uint256) {
		return (users[userAddress].referrals);
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}
	
	function getUserRefRewards(address userAddress) public view returns(uint256) {
	    return users[userAddress].refRewards;
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserDividends(userAddress);
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	
	function getUserBnbStaked(address userAddress) public view returns(uint256) {
	    return users[userAddress].bnbStaked;
	}
	
	function getAvailableBnb(address userAddress) public view returns(uint256){
	    return getUserTotalDeposits(userAddress).div(20).sub(users[userAddress].bnbStaked);
	}
	
	function getAvailableLotteryRewards(address userAddress) public view returns(uint256) {
	    return users[userAddress].lotteryRewards;
	}
	
	function getUserBnbTimer(address userAddress) public view returns(uint256) {
	    
	    return block.timestamp.sub(users[userAddress].bnbStakeCheckpoint);
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}
    
    function getFeeHistory() public view returns(uint256[] memory) {
        
        
        return projectFeeHistory;
    }
    
	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 profit, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = user.deposits[index].percent;
		amount = user.deposits[index].amount;
		profit = user.deposits[index].profit;
		start = user.deposits[index].start;
		finish = user.deposits[index].finish;
	}
	
	 function getUserTickets(address _userAddress) public view returns(uint256) {
         
         return ticketOwners[lotteryRound][_userAddress];
    }
    
    function getLotteryTimer() public view returns(uint256) {
        return LOTTERY_START_TIME.add(LOTTERY_STEP);
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
    
     function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}