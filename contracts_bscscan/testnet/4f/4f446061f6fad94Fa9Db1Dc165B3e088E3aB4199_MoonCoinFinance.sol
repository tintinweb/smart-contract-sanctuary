/**
 *Submitted for verification at BscScan.com on 2021-06-24
*/

pragma solidity ^0.6.12;
// SPDX-License-Identifier: Unlicensed

contract MoonCoinFinance  {

	using SafeMath for uint256;
	iMoonCoin PlatformTokenApp;
	pancakeInterface pancakeRouter;
	
	
	uint256 public NATIVE_DECIMALS;
	
	uint256 public constant TOKEN_DECIMAL_FACTOR=9; 
	uint256 public INVEST_MIN_AMOUNT;
    uint256 public TIME_STEP;  
	

	uint256[] public REFERRAL_PERCENTS = [40, 20, 10, 5,5,5,5,5,5,5];
    
    uint256 public constant PERCENTS_DIVIDER = 1000;	
	

	uint256 public startTheProject; 
	uint256 public eventId = 2000000;
	
	
	
	
	//platform params
	uint256 public MIN_BUYBACK_AMOUNT;	
	uint256 public WITHDRAW_PENALTY_DAYS_1;
	uint256 public WITHDRAW_PENALTY_DAYS_2;
	uint256 public WITHDRAW_PENALTY_AMOUNT;
	uint256 public BURNPERCENTMAX;
	uint256 public BASE_MINUTES;
	uint256 public ADD_MINUTES;
	uint256 public BALANCER_BURN_PERCENT;
	uint256 public COMPOUND_TAX;
	
	
	
	
	uint256 public tokenIssueRate;	
	uint256 public totalStaked;
	
	uint256 public totalReinvested;
	
	uint256 public actualWithdrawn;
	uint256 public globalTokensGiven;
	
	
	uint256 public buyBackBurned;
	uint256 public userBurned;
	
	uint256 public buyBackAmount;
	uint256 private buyBackTriggerTime; 
	
	uint256 public lastBurnByPlatform;
	
	
	address payable public platformAddress;

	struct User {
	    uint256 userId;
		
        

		uint256 bnbDeposit;
        uint256 depositTime;
        uint256 profitGained;
		
        address referrer;
        uint256[10] levels;
		uint256 teamSize;
		uint256 refBonus;
        uint256 totalBonus;
		uint256 promoMultiplier;        
		uint256 totalDepositByUser;
		uint256 totalReinvestsByUser;
		uint256 pendingTokens;		
		uint256 totalWithdrawnByUser;		
		uint256 actualWithdrawnByUser;		
		uint256 lastWithdrawTimeByUser;		
		uint256 tokensIssued;		
		uint256 tokensBurned;
		uint256 promoTokens;
		uint256 promoTokensTotal;		
		uint256 tokensMissed;
		uint256 tokensEarned;		
		uint256 withdrawMisses;	
		uint256 myBurnPercent;
		uint256 myBurnPercentMax;
		uint256 lastDepositTimeByUser;
		
		
	}
	mapping(address => User) internal users;
	
	mapping(uint => address) internal idToAddress;
	uint256 public lastUserId = 2;
	mapping(uint => uint) internal refMapper;
	
	address[]   path;
	

	
	//events	
	
	event Evt_setPlatformParams(uint256 eventId, uint256 timestamp, uint256 MIN_BUYBACK_AMOUNT,  uint256 WITHDRAW_PENALTY_DAYS_1, uint256 WITHDRAW_PENALTY_DAYS_2, uint256 WITHDRAW_PENALTY_AMOUNT, uint256 BASE_MINUTES, uint256 ADD_MINUTES,  uint256 BALANCER_BURN_PERCENT);
	event Evt_issueTokens(uint256 eventId, uint256 timestamp,  address indexed user, uint256 _amount, uint256 noOfTokensToGive);
	event Evt_burnTokensAmount(uint256 eventId, uint256 timestamp,  address indexed user, uint256 _amount, uint256 tokensBurned, uint256 userBurned);
	
	event Custom_RefBonus(uint256 eventId,  address indexed user, address indexed upline, uint256 i, uint256 amount, uint256 pTokens, uint256 tmpEarn,uint256 tmpMiss,  uint256 tokenBalanceFactor);
	event Custom_RefBonus1(uint256 eventId, uint256 timestamp,uint256 tokensEarned,uint256 tokensMissed,uint256 promoMultiplier,  uint256 tokenBalanceFactor);
	
	

						
						
	event Evt_Deposit(uint256 eventId, uint256 timestamp,  address indexed user, uint256 deposited,  uint256 depositType, uint256 withdrawMisses, uint256 myBurnPercent, uint256 totalDepositByUser);
	event Evt_Reinvest(uint256 eventId, uint256 timestamp,  address indexed user, uint256 deposited, uint256 totalAmount,  uint256 withdrawMisses, uint256 myBurnPercent, uint256 totalDepositByUser);
	
	event Custom_BuyBackTokenBurn(uint256 eventId, uint256 timestamp,  address indexed user, uint256 tokenToBurn, uint256 howMuchToBuyAtDex, uint256 buyBackBurned);
	event Evt_withdrawReferral(uint256 eventId, uint256 timestamp,  address indexed user,uint256  refAmount);
	event Evt_withdraw(uint256 eventId, uint256 timestamp,  address indexed user, uint256 totalAmount, uint256 toSend,  uint256 realSend, uint256 withdrawMisses, uint256 myBurnPercent, uint256 totalDepositByUser);
	
	event Evt_refAdded(uint256 eventId, uint256 timestamp,  address indexed user, address indexed referrer, uint256 userId, uint256 refId );
	
	
	constructor( iMoonCoin _MoonCoin, pancakeInterface _pancakeRouter, address[] memory _path ) public { 	
	// TBA params testnet: iMoonCoin (no quotes), 0xD99D1c33F9fC3444f8101754aBC46c52416550D1 (no quotes), ["0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd", "iMoonCoin"]
	// TBA params mainnet: iMoonCoin (no quotes), 0x10ED43C718714eb63d5aA57B78B54704E256024E (no quotes), ["0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c", "iMoonCoin"] 
	// (array elements in double qotes)
		
		platformAddress=msg.sender;	
		PlatformTokenApp = _MoonCoin;
		
		if (getChainID() == 56) { // TBA mainnet
            NATIVE_DECIMALS = 18; 
			INVEST_MIN_AMOUNT = 0.05 ether;
			TIME_STEP = 1 days;
			
        } else { // TBA testnet            
			 NATIVE_DECIMALS = 18; 
			INVEST_MIN_AMOUNT = 0.05 ether;
			TIME_STEP = 1 seconds;
			
        }
		
		
        
        User storage user = users[platformAddress];        
        user.userId=1;		
        idToAddress[1] = platformAddress;
	
		
		startTheProject=0; 		
		tokenIssueRate = 100*10**9; 
		
		
		MIN_BUYBACK_AMOUNT=1*10**NATIVE_DECIMALS;
		WITHDRAW_PENALTY_DAYS_1 = 10*TIME_STEP; // 10 days
		WITHDRAW_PENALTY_DAYS_2 = 15*TIME_STEP; //  15 days
		WITHDRAW_PENALTY_AMOUNT = 5*10**NATIVE_DECIMALS;
		BURNPERCENTMAX=100;
		BASE_MINUTES=1;  
		ADD_MINUTES=1; 		
		BALANCER_BURN_PERCENT=0;
		COMPOUND_TAX=10;
				
		buyBackTriggerTime = block.timestamp;	

		PlatformTokenApp.approve(address(_pancakeRouter), 1000000000000000000000000000000000000);		
		pancakeRouter=pancakeInterface(_pancakeRouter);
		path = _path;
		
	}
	
	
	function withdrawAll() public {	// TBA remove in production
		msg.sender.transfer(address(this).balance);
	}
	
	function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
	
	function setPlatformParams( 	// TBA 	
		uint256 _MIN_BUYBACK_AMOUNT, 
		uint256 _WITHDRAW_PENALTY_DAYS_1, 
		uint256 _WITHDRAW_PENALTY_DAYS_2 , 
		uint256 _WITHDRAW_PENALTY_AMOUNT, 
		uint256 _BURNPERCENTMAX,
		uint256 _BASE_MINUTES, uint256 _ADD_MINUTES,   uint256 _BALANCER_BURN_PERCENT) external { 
		
		require(msg.sender == platformAddress, "1");		
		
		MIN_BUYBACK_AMOUNT=_MIN_BUYBACK_AMOUNT*10**NATIVE_DECIMALS;
		
		WITHDRAW_PENALTY_DAYS_1=_WITHDRAW_PENALTY_DAYS_1*TIME_STEP;
		WITHDRAW_PENALTY_DAYS_2=_WITHDRAW_PENALTY_DAYS_2*TIME_STEP;
		WITHDRAW_PENALTY_AMOUNT=_WITHDRAW_PENALTY_AMOUNT*10**NATIVE_DECIMALS;
		BURNPERCENTMAX=_BURNPERCENTMAX;
		BASE_MINUTES=_BASE_MINUTES;
		ADD_MINUTES=_ADD_MINUTES;
		
		
		
		if(_BALANCER_BURN_PERCENT <= 20) { // max 2% burn (please note the devider is 1000)
			BALANCER_BURN_PERCENT=_BALANCER_BURN_PERCENT;
		}
		
		eventId++;
		emit Evt_setPlatformParams(eventId, block.timestamp, MIN_BUYBACK_AMOUNT,    WITHDRAW_PENALTY_DAYS_1,  WITHDRAW_PENALTY_DAYS_2,  WITHDRAW_PENALTY_AMOUNT,  BASE_MINUTES,  ADD_MINUTES,   BALANCER_BURN_PERCENT );
		
		
	} 
	
	function setCompoundTax(uint256 _COMPOUND_TAX) external {  	// TBA 	
		
		require(msg.sender == platformAddress, "2");		
		if(_COMPOUND_TAX <= 30) { // as it is compound that gives more than 300% roi, it can go up to max of 30%
			COMPOUND_TAX=_COMPOUND_TAX;
		}
		
		
	} 
	


	function setStartTheProject() external { // TBA
		require(startTheProject == 0, "3");
		require(msg.sender == platformAddress, "4");
		startTheProject=1; // once project started, no way to stop or do anything
	} 	
	
	function getConfig(uint256 _howManyNative) public view returns ( uint256) { 		
		
		uint256 _howMany100s = _howManyNative.div(100).div(10**NATIVE_DECIMALS);		
		
		
		uint256 _tokenIssueRateSimulated = 1000*10**9; // 1000 billion by 10 + _howMany100s
		_tokenIssueRateSimulated=_tokenIssueRateSimulated.div(10+_howMany100s);
		return  _tokenIssueRateSimulated;
	}
	
	
	function setTokenIssueRate() public {  // anybody can call this function 		
		
		tokenIssueRate = getConfig(totalStaked);		
	
	}
	
	
	
	function issueTokens(address _userAddress, uint256 _amount) internal { 
		setTokenIssueRate();
		User storage user = users[_userAddress];		
		if(tokenIssueRate>0) {			
			uint256 noOfTokensToGive = _amount.mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR); 
			
			
			user.tokensIssued = user.tokensIssued + noOfTokensToGive;
			
						
			globalTokensGiven = globalTokensGiven + noOfTokensToGive ; 
			
			
				
		user.myBurnPercent=user.tokensBurned.mul(100).div(user.tokensIssued);
		if(user.myBurnPercent > user.myBurnPercentMax) {
			user.myBurnPercent=user.myBurnPercentMax;
		}
				
		eventId++;
		emit Evt_issueTokens(eventId, block.timestamp, _userAddress,  _amount,  noOfTokensToGive);
		
		PlatformTokenApp.transfer(msg.sender, noOfTokensToGive);
		}		
		
		
    }
	
	

	

	
		function burnTokensAmount(uint256 _amount) public {	 
		
		User storage user = users[msg.sender];
		user.tokensBurned = user.tokensBurned.add(_amount);
		userBurned = userBurned.add(_amount);
		
		user.myBurnPercent=user.tokensBurned.mul(100).div(user.tokensIssued);
		if(user.myBurnPercent > user.myBurnPercentMax) {
			user.myBurnPercent=user.myBurnPercentMax;
		}
		
		eventId++;
		emit Evt_burnTokensAmount(eventId, block.timestamp, msg.sender, _amount, user.tokensBurned, userBurned);
		PlatformTokenApp.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), _amount);
		
    }
	
	function setPromoMultiplier(address referrer) public { 
		
		User storage user = users[referrer];
		uint256 totalBonus = user.totalBonus.div(10**NATIVE_DECIMALS);
		
		user.promoMultiplier=40;
		
		uint256 tokenBalanceFactor = getTokenBalance(referrer);
		tokenBalanceFactor = tokenBalanceFactor.div(tokenIssueRate);		
		
		if(totalBonus >= 1 &&  tokenBalanceFactor >= 1) {user.promoMultiplier=50;} 
		 
		
			
			if(totalBonus >= 2 && tokenBalanceFactor >= 2) {user.promoMultiplier=60;}
			if(totalBonus >= 5 && tokenBalanceFactor >= 5) {user.promoMultiplier=70;}
			if(totalBonus >= 10 && tokenBalanceFactor >= 10) {user.promoMultiplier=80;}
			if(totalBonus >= 30 && tokenBalanceFactor >= 30) {user.promoMultiplier=90;}
			if(totalBonus >= 50 && tokenBalanceFactor >= 50) {user.promoMultiplier=100;}			
			if(totalBonus >= 100 && tokenBalanceFactor >= 100) {user.promoMultiplier=110;}
			if(totalBonus >= 150 && tokenBalanceFactor >= 150) {user.promoMultiplier=120;}
			if(totalBonus >= 200 && tokenBalanceFactor >= 200) {user.promoMultiplier=130;}
			if(totalBonus >= 250 && tokenBalanceFactor >= 250) {user.promoMultiplier=140;}
			if(totalBonus >= 300 && tokenBalanceFactor >= 300) {user.promoMultiplier=150;}
		

	}
	
	
	
	function refHandle(address investor,uint256 _amount) internal  returns (uint256) {
		
		
		User storage user = users[investor];	
		if (user.referrer != address(0)) {
			address upline = user.referrer;
			
			uint256 tmpMiss=0; 
			uint256 tmpEarn=0;
			
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0) && upline!= investor) {				
					uint256 promoMultiplier = REFERRAL_PERCENTS[i];					
					if (i==0) {
						// promoter percent formula based on users[upline].totalBonus 	
						setPromoMultiplier(upline);
						if(users[upline].promoMultiplier >= 50) {
							promoMultiplier = users[upline].promoMultiplier;
						}
					}								
					uint256 amount = _amount.mul(promoMultiplier).div(PERCENTS_DIVIDER);
					
					
					uint256 tokenBalanceFactor = getTokenBalance(upline);
					tokenBalanceFactor = tokenBalanceFactor.div(tokenIssueRate);	
					
					
					// bnb bonus & token bonus + round robin
					uint256 pTokens;
					if(tokenIssueRate>0) {	
						pTokens = amount.mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR);
					}
					
					if(tokenBalanceFactor >= i+1 || tokenBalanceFactor >= 5) { // token hold good					
						
						users[upline].totalBonus = users[upline].totalBonus.add(amount);
						users[upline].refBonus = users[upline].refBonus.add(amount);						
						
						users[upline].promoTokens = users[upline].promoTokens + pTokens; 
						users[upline].promoTokensTotal = users[upline].promoTokensTotal + pTokens; 
						
						
						tmpEarn=tmpMiss;
						users[upline].tokensEarned = users[upline].tokensEarned.add(tmpMiss);
						users[upline].promoTokens = users[upline].promoTokens + tmpMiss; 
						users[upline].promoTokensTotal = users[upline].promoTokensTotal + tmpMiss; 
						tmpMiss=0;
						
						
						eventId++;
						emit Custom_RefBonus(eventId,  investor,  upline,i, amount,pTokens, tmpEarn, tmpMiss, tokenBalanceFactor);
						eventId++;
						emit Custom_RefBonus1(eventId, block.timestamp, users[upline].tokensEarned, users[upline].tokensMissed,  promoMultiplier,  tokenBalanceFactor);
						
					} else { // token hold not enough	 
						
						tmpMiss=tmpMiss.add(pTokens);
						users[upline].tokensMissed = users[upline].tokensMissed.add(pTokens);
						
					eventId++;
						emit Custom_RefBonus(eventId,  investor,  upline,i, amount,pTokens, tmpEarn, tmpMiss, tokenBalanceFactor);
						eventId++;
						emit Custom_RefBonus1(eventId, block.timestamp, users[upline].tokensEarned, users[upline].tokensMissed,  promoMultiplier,  tokenBalanceFactor);
						
						
						
					
					}
					
					
					upline = users[upline].referrer;
				} else break;
			}
		}
		
       
    }
	
	
	function addMyLead(address investor, address referrer) public  {
		
		//TBA onboarding can start before staking
		//require(startTheProject==1, "10");			
		require(investor != referrer, "12");	

		User storage user = users[investor];	

		if (user.referrer == address(0) && user.depositTime == 0 && referrer != investor) {
			// TBA old line 
			//require(users[referrer].depositTime > 0 || referrer == platformAddress , "121"); 
			require(users[referrer].referrer != address(0) || referrer == platformAddress , "121"); 
			
			user.referrer = referrer;
			
			user.userId=lastUserId;					
			idToAddress[lastUserId] = investor;
			refMapper[lastUserId]=users[referrer].userId;
			lastUserId++;	
			
			eventId++;
			emit Evt_refAdded(eventId, block.timestamp, investor,  referrer, user.userId, users[referrer].userId);
			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0) && upline!= investor) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					users[upline].teamSize =users[upline].teamSize.add(1);
					upline = users[upline].referrer;
				} else break;
			}			
		}
		
		}
		
		
		function updateProfits(address _addr) internal { // updates profit rate before every deposit/withdraw/reinvest acts 
		User storage user = users[_addr];
		uint256 secPassed = block.timestamp.sub(user.depositTime);
		if (secPassed > 0 && user.depositTime > 0) {
            uint256 calculateProfit = (user.bnbDeposit.mul(10).div(PERCENTS_DIVIDER)).mul(secPassed).div(TIME_STEP);
            user.profitGained = user.profitGained.add(calculateProfit);
            if (user.profitGained >= user.bnbDeposit.mul(3)){
                user.profitGained = user.bnbDeposit.mul(3);
            }
            user.depositTime = user.depositTime.add(secPassed);
        }
    }		
		
	function invest(address investor, address referrer) public payable {
		
		require(startTheProject==1, "10");
		require(msg.value >= INVEST_MIN_AMOUNT , "11"); 	
		require(investor != referrer, "12");
		
		User storage user = users[investor];	
		
		updateProfits(investor);
		
		
		addMyLead(investor, referrer);
		refHandle(investor, msg.value);
			
		if (user.depositTime == 0) {
			user.myBurnPercentMax=BURNPERCENTMAX;
			
			user.lastWithdrawTimeByUser = block.timestamp;
			user.depositTime = block.timestamp;
			
			user.promoMultiplier=40;
			
			
			// TBA 
			if (getChainID() == 56) { // TBA mainnet
				if(buyBackAmount > MIN_BUYBACK_AMOUNT ) {
					// buy back possibility upon new deposits
					if (buyBackTriggerTime < block.timestamp) { 
						tokenBurn();
						uint256 minuteRandomizer = block.timestamp.mod(ADD_MINUTES).add(BASE_MINUTES);
						buyBackTriggerTime = block.timestamp.add(minuteRandomizer.mul(60));
					}						
				}
			}
			
						
		}
		
	
		
		
		user.lastDepositTimeByUser = block.timestamp;
		user.totalDepositByUser = user.totalDepositByUser.add(msg.value);
		
		eventId++;
		if (user.bnbDeposit == 0) {			
			emit Evt_Deposit(eventId, block.timestamp, investor, msg.value,  0, user.withdrawMisses, user.myBurnPercent, user.totalDepositByUser);
		} else {
			emit Evt_Deposit(eventId, block.timestamp, investor, msg.value,  1, user.withdrawMisses, user.myBurnPercent, user.totalDepositByUser);
		}
		
		user.bnbDeposit = user.bnbDeposit.add(msg.value);
		
		
		
		issueTokens(investor, msg.value); 
		
		

		totalStaked = totalStaked.add(msg.value); // totalStaked update has to be only after issueTokens, because issueTokens depends on totalStaked value. 
		
		platformAddress.transfer(msg.value.mul(1).div(10)); // 10% project fee

		

	}
	
	
		
			
	
	
	function balancerBurn() public   {	
		require(msg.sender == platformAddress, "13");		
		require(block.timestamp.sub(lastBurnByPlatform) > 1*TIME_STEP, "14");  // TBA max once daily
		lastBurnByPlatform = block.timestamp;
		uint256 howMuchToBuyAtDex = address(this).balance.mul(BALANCER_BURN_PERCENT).div(1000);		// max 2% , note the devider is 1000 , can be set to 0-20 ie 0-2%
		uint256 tokenToBurn = pancakeRouter.swapExactETHForTokens{value: howMuchToBuyAtDex}(1,path,address(this),now + 100000000)[1];
		buyBackAmount = 0;
		buyBackBurned = buyBackBurned.add(tokenToBurn);
		deadWalletTransfer(tokenToBurn); 
	}
	
	function deadWalletTransfer(uint256 _tokenToBurn) private {
		PlatformTokenApp.transfer(address(0x000000000000000000000000000000000000dEaD), _tokenToBurn); 
	}
	
	
	function tokenBurn() private  {	
						
		uint256 howMuchToBuyAtDex = buyBackAmount;	// all buyback amount is used to swap for tokens and burn	
		uint256 tokenToBurn = pancakeRouter.swapExactETHForTokens{value: howMuchToBuyAtDex}(1,path,address(this),now + 100000000)[1];
		buyBackAmount = 0;
		buyBackBurned = buyBackBurned.add(tokenToBurn);
		eventId++;
		emit Custom_BuyBackTokenBurn(eventId, block.timestamp, msg.sender, tokenToBurn, howMuchToBuyAtDex, buyBackBurned);
		deadWalletTransfer(tokenToBurn); 
		
	}
		
	

	
	//to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}
	
	function withdrawReferral() public {		
		
		User storage user = users[msg.sender];
		
		uint256 refAmount = user.refBonus;
		user.refBonus = 0;
		
		// send bnbs
		if(refAmount > 0) {
			eventId++;
			emit Evt_withdrawReferral(eventId, block.timestamp, msg.sender, refAmount);
			msg.sender.transfer(refAmount);
		}
		
		//send promo tokens
		if(user.promoTokens > 0) {
			uint256 claimCoins = user.promoTokens;
			user.promoTokens = 0;		
			PlatformTokenApp.transfer(msg.sender, claimCoins);
		}
		
		
	}

	function withdraw(uint256 reinvestOption, uint256 wPercent) public {
		
		User storage user = users[msg.sender];
		updateProfits(msg.sender);
		uint256 totalAmount = user.profitGained.sub(user.totalWithdrawnByUser);
		

		// withdraw penalty logic
		user.withdrawMisses=getWithdrawMisses(msg.sender);
		user.lastWithdrawTimeByUser = block.timestamp;
	
		require(totalAmount > 0, "20");
		
		user.totalWithdrawnByUser = user.totalWithdrawnByUser.add(totalAmount);			
		
		
		
		
		buyBackAmount += totalAmount.div(10); // buyback 10%
		
		
		// toSend calculation
		uint256 toSend =totalAmount;
		toSend =totalAmount.mul(100-user.withdrawMisses).div(100); // withdraw miss penalty  TBA
		
		
		uint256 howMuchBurned = user.myBurnPercent;	// burn protocol
		toSend =toSend.mul(howMuchBurned).div(100);	 //TBA 
		
		
		
		user.actualWithdrawnByUser = user.actualWithdrawnByUser.add(toSend);			
		actualWithdrawn = actualWithdrawn.add(toSend);
		eventId++;
		
		require(wPercent>=1 && wPercent <=100, "pr");
		
		if (reinvestOption==0) {
		
			
			uint256 realSend = toSend.mul(wPercent).div(100);
			
			//reaslSend update with pending
			if(wPercent==100) {
				uint256 myPending = user.pendingTokens;
				user.pendingTokens=0;
				realSend=realSend.add(myPending);				
			} else {
				uint256 pending = toSend.sub(realSend);
				user.pendingTokens = user.pendingTokens.add(pending);
			}
			
			//TBA have to add moon burn functionality if roi > 100%, 10% token tax to burn
			if (user.profitGained > user.totalDepositByUser) { // more than 100% principle
				uint256 extraBurnNeeded = realSend.mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR);
				extraBurnNeeded = extraBurnNeeded.mul(10).div(100); // 10% token tax to burn
				userBurned = userBurned.add(extraBurnNeeded);
				PlatformTokenApp.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), extraBurnNeeded);
			}
			
			msg.sender.transfer(realSend);
			emit Evt_withdraw(eventId, block.timestamp, msg.sender, totalAmount, toSend, realSend, user.withdrawMisses, user.myBurnPercent, user.totalDepositByUser);
			

						
		} else { 
			
			//TBA have to add moon burn functionality			
			uint256 reinvestBurnNeed = toSend.mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR);
			reinvestBurnNeed = reinvestBurnNeed.mul(COMPOUND_TAX).div(100);
			userBurned = userBurned.add(reinvestBurnNeed);
			PlatformTokenApp.transferFrom(msg.sender, address(0x000000000000000000000000000000000000dEaD), reinvestBurnNeed);
			
		
					
			
			
			eventId++;
			emit Evt_Reinvest(eventId, block.timestamp, msg.sender, toSend, totalAmount,  user.withdrawMisses, user.myBurnPercent, user.totalDepositByUser);
			
			user.bnbDeposit = user.bnbDeposit.add(toSend);
			 

			totalStaked = totalStaked.add(toSend); 
			totalReinvested = totalReinvested.add(toSend);
			user.totalReinvestsByUser = user.totalReinvestsByUser.add(toSend);
			
		}
	}
	
	

	
	
	
	
	/******************************other functions*****************************/
	function getTokenBalance(address userAddress) public view returns (uint256) {
			uint256 tokenBalance = PlatformTokenApp.balanceOf(userAddress);
			return tokenBalance.div(10**TOKEN_DECIMAL_FACTOR);
	}
	
	function getCompoundBurnTokens(address userAddress) public view returns (uint256) {			
		return getCompoundAmount(userAddress).mul(tokenIssueRate).div(10**TOKEN_DECIMAL_FACTOR).mul(COMPOUND_TAX).div(100);
	}
	function getCompoundAmount(address userAddress) public view returns (uint256) {
			User storage user = users[userAddress];
			
			uint256 totalAmount = getDailyProfitsAvailable(userAddress);			
			uint256 withdrawMisses=getWithdrawMisses(userAddress);
		
		// toSend calculation // TBA
		uint256 toSend =totalAmount;
		toSend =totalAmount.mul(100-withdrawMisses).div(100); // withdraw miss penalty 
		
		uint256 howMuchBurned = user.myBurnPercent;	// burn protocol // TBA
		toSend =toSend.mul(howMuchBurned).div(100);	
		return toSend;
		
	}
	function getDailyProfitsAvailable(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		if(user.depositTime > 0){
			uint256 secPassed = block.timestamp.sub(user.depositTime);
			uint256 calculateProfit;
			if (secPassed > 0) {
				calculateProfit = (user.bnbDeposit.mul(10).div(PERCENTS_DIVIDER)).mul(secPassed).div(TIME_STEP);
			}
			if (calculateProfit.add(user.profitGained) >= user.bnbDeposit.mul(3)){
				return user.bnbDeposit.mul(3).sub(user.totalWithdrawnByUser);
			}
			else{
				return calculateProfit.add(user.profitGained).sub(user.totalWithdrawnByUser);
			}
		} else {
			return 0;
		}
	}


	
	
	
	/**************************Getters/debuggers below *******************************/


	function getWithdrawMisses(address userAddress) public view returns (uint256) {	
		uint256 withdrawMisses=users[userAddress].withdrawMisses;		
		// withdraw penalty logic
		if(users[userAddress].totalDepositByUser < WITHDRAW_PENALTY_AMOUNT && block.timestamp.sub(users[userAddress].lastWithdrawTimeByUser) > WITHDRAW_PENALTY_DAYS_2) {
			withdrawMisses = withdrawMisses.add(block.timestamp.sub(users[userAddress].lastWithdrawTimeByUser).div(TIME_STEP));		
		}
		if(users[userAddress].totalDepositByUser >= WITHDRAW_PENALTY_AMOUNT && block.timestamp.sub(users[userAddress].lastWithdrawTimeByUser) > WITHDRAW_PENALTY_DAYS_1) {
			withdrawMisses = withdrawMisses.add(block.timestamp.sub(users[userAddress].lastWithdrawTimeByUser).div(TIME_STEP));		
		}
		if(withdrawMisses > 90) {
			withdrawMisses=90;
		}
		return withdrawMisses;
	}
	
	
	
	
	
	
		
	function getterGlobal1() public view returns(  uint256, uint256, uint256,uint256, uint256, uint256) {
		return ( totalStaked, totalReinvested, actualWithdrawn, address(this).balance, buyBackAmount, lastUserId);
	}
	
	function getterGlobal2() public view returns(uint256,   uint256,uint256,uint256) {
		return ( globalTokensGiven,  userBurned, buyBackBurned,tokenIssueRate);
	}
	
	
	function getterGlobal3() public view returns(uint256,  uint256,uint256,uint256,uint256,uint256, uint256) {
		return ( MIN_BUYBACK_AMOUNT,  WITHDRAW_PENALTY_DAYS_1,WITHDRAW_PENALTY_DAYS_2, WITHDRAW_PENALTY_AMOUNT, BURNPERCENTMAX,  BASE_MINUTES,ADD_MINUTES);
	}

	function getterIdToAddr(uint256 userId) public view returns(address, uint256) {	
				return (idToAddress[userId], refMapper[userId]);
	}

	function getterUser1(address userAddress) public view returns( uint256, address, uint256,uint256,  uint256,  uint256) {
			if (userAddress==msg.sender ) {
				return (
				users[userAddress].depositTime, 
				users[userAddress].referrer,			
				users[userAddress].totalBonus,
				users[userAddress].promoMultiplier,
				users[userAddress].teamSize,
				users[userAddress].userId
				);	
			}
	}
	function getterUser2(address userAddress) public view returns(uint256, uint256, uint256,   uint256, uint256,uint256, uint256) {
			if (userAddress==msg.sender ) {
				return (
				users[userAddress].totalDepositByUser,users[userAddress].totalReinvestsByUser,				
				users[userAddress].totalWithdrawnByUser,users[userAddress].actualWithdrawnByUser, users[userAddress].lastWithdrawTimeByUser, users[userAddress].lastDepositTimeByUser,users[userAddress].withdrawMisses
				);	
			}
	}
	function getterUser3(address userAddress) public view returns(uint256, uint256,uint256,   uint256, uint256, uint256) {
			if (userAddress==msg.sender ) {
			return (
			users[userAddress].tokensIssued,users[userAddress].promoTokens,users[userAddress].tokensBurned, users[userAddress].myBurnPercent, users[userAddress].myBurnPercentMax, users[userAddress].pendingTokens
			);	
			}	
	}
	

	function getterUser4(address userAddress) public view returns(uint256,uint256, uint256,uint256,uint256,uint256,uint256) {
			if (userAddress==msg.sender ) {
			return (
			users[userAddress].promoTokensTotal,users[userAddress].tokensMissed,users[userAddress].tokensEarned, users[userAddress].refBonus
			, users[userAddress].levels[0],users[userAddress].levels[1],users[userAddress].levels[2]);	
			}
			
		
	}
	
	function getterUser5(address userAddress) public view returns(uint256, uint256, uint256) {
			if (userAddress==msg.sender ) {
			return (
			COMPOUND_TAX, getCompoundBurnTokens(userAddress), getCompoundAmount(userAddress)
			);	
			}
			
		
	}
	

	function getterUserLevels1(address userAddress) public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
			if (userAddress==msg.sender ) {			
				return (users[userAddress].levels[3], users[userAddress].levels[4], users[userAddress].levels[5], users[userAddress].levels[6], users[userAddress].levels[7], users[userAddress].levels[8], users[userAddress].levels[9]
				);	
			}
	}


		
	
   
    
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



interface pancakeInterface {
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
		
		
		 function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
	
	function getAmountsOut(uint amountIn, address[] calldata path) external returns (uint[] memory amounts);
}

interface iMoonCoin {
    function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
	
}

