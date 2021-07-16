//SourceUnit: millioex.sol


pragma solidity 0.5.10;

contract  TheMillionEx{
	using SafeMath for uint256;
	uint256[] public PACKAGES=[250 trx,500 trx,1000 trx,2000 trx,5000 trx,10000 trx,20000 trx,40000 trx,50000 trx,100000 trx,200000 trx,400000 trx];
	uint256 public Minimum_Withdrawal_Limit=100 trx;	 
	uint256[] public ROI_RATE=[100,100,100,100,125,125,125,125,150,150,150,150];
	uint256[] public ROI_BRATE=[150,150,150,150,175,175,175,175,200,200,200,200];
    uint256[] public LEVEL_RATE=[1000,500,300,200,100,50,50,50,50,50,50,100,100,200,300];
    uint256[] public ROI_LEVEL_RATE=[1000,500,300,200,100,50,50,50,50,50,50,100,100,200,300];
    uint256[] public PremiumRate=[100,150,200];
    uint256[] public P1Users;
    uint256[] public P2Users;
    uint256[] public P3Users;
	uint256 public MARKETING_FEE = 500;
	uint256 public PROJECT_FEE = 0;
	uint256 public PERCENTS_DIVIDER = 10000;
	uint256 public CONTRACT_BALANCE_STEP = 1000000;
	uint256 public TIME_STEP = 1 days; 
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalReInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public tokenUpdateKey=333;
	uint256 public Maximum_Growth_Rate=300;
	uint256 public TotalTokenMined=0;
	uint256 public Dividends=0;
	uint256 public Dividend_Closing_Checkpoint=block.timestamp;
	uint256 public Dividend_Percent=450;
	uint256 internal TokenMinedLimit=4500000000000; 
	address payable public marketingAddress;
	address payable public projectAddress;
	

	struct Deposit {
		uint256 amount;
		uint256 totalGrawth;
		uint256 withdrawn;
		uint256 start;
		uint256 rate;
		uint256 count;
		uint256 package_Index;
	}
	struct Referral{
	    address _address;
	    uint256 _time;
	}
	struct Incomes{
	    uint256 _level;
	    address _address;
	    uint256 _time;
	    uint256 _amount;
	    uint _type;
	}
	struct Team{
	    uint256 _level;
	    address _address;
	    uint256 _time;
	}

	struct User {
	    uint256 pk;
		Deposit[] deposits;
		Referral[] referrals;
		Incomes[] incomes;
		Team[] levelTeams;
		uint256[] IsPremiums;
		uint256 totalDepositsAmount;
		uint256 totalWithdrawn;
		uint256 pendingWithdrawn;
		uint256 checkpoint;
		address referrer;
		uint256 referralsCount;
		uint256 roiBonus;
		uint256 refBonus;
		uint256 roiReferralBonus;
		uint256 premiumBonus;
		uint256 token;
	}

    mapping (address => User) public users;
    mapping(uint256 => address) public premium1List;
    mapping(uint256 =>address) public premium2List;
    mapping(uint256 =>address) public premium3List;
    
	event Newbie(address user);
	event UpdateToken(address indexed user,uint256 amount,uint _time);
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
 
     function changeGrowthRate(uint256 NewRate) onlyOwner public returns(bool) {
         Maximum_Growth_Rate=NewRate;
         return true;
     }
     function investAlt(address referrer,address userAdr,uint256 Package_Index) onlyOwner public {
	    bool _new=false;
	    uint256 Package_Amount=PACKAGES[Package_Index-1];
		User storage user = users[userAdr];
		if(user.deposits.length==0)
		{
		    
		    user.totalDepositsAmount=0;
		    user.totalWithdrawn=0;
		    user.pendingWithdrawn=0;
		    user.referralsCount=0;
		    user.roiBonus=0;
		    user.refBonus=0;
		    user.roiReferralBonus=0;
		    user.premiumBonus=0;
		    _new=true;
		}
		uint256 _maxDeposit=getuserLargerDeposit(userAdr);
	    require(Package_Amount>=_maxDeposit,'Can not be recycled');
	 
		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != userAdr) {
			user.referrer = referrer;
			User storage refuser=users[referrer];
			refuser.referralsCount=refuser.referralsCount.add(1);
			refuser.referrals.push(Referral(userAdr,now));
			
			
			//booster
				for (uint256 i = 0; i < refuser.deposits.length; i++) {
				    if(refuser.deposits[i].amount<=Package_Amount && block.timestamp < refuser.deposits[i].start.add(86400))
				    {
				       refuser.deposits[i].count=refuser.deposits[i].count.add(1);
				       if( refuser.deposits[i].count==2)
				          refuser.deposits[i].rate=ROI_BRATE[refuser.deposits[i].package_Index-1];
				    }
				    
				}
			
		}
		 uint flag=0;
		if(user.deposits.length>0)
		{
		      
		    	for (uint256 j = 0; j < user.deposits.length; j++) {
		    	    if(user.deposits[j].package_Index==Package_Index){
		    	       flag=1;
		    	       break;
		    	    }
		    	    
		    	}
		    
		}
		     	if(flag==0)
		    	{
		    	    if(TotalTokenMined.add(Package_Amount.div(100))<TokenMinedLimit) {
		    	     user.token=user.token.add(Package_Amount.div(100));
		    	     TotalTokenMined=TotalTokenMined.add(Package_Amount.div(100));
		    	    }
		    	}
		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		    user.pk=totalUsers;
			emit Newbie(userAdr);
		}
		
		 
		if(Package_Index>8)
		{
		    bool isExist=false;
		    for(uint i=0;i<user.IsPremiums.length;i++)
		    {
		        if(user.IsPremiums[i]==Package_Index)
		        {
		            isExist=true;
		        }
		    }
		    if(!isExist)
		    {
		        if(Package_Index==9){
		             P1Users.push(user.pk);
		             premium1List[user.pk]=userAdr;
		        }
		        else if(Package_Index==10){
		             P2Users.push(user.pk);
		             premium2List[user.pk]=userAdr;
		        }
		        else{
		               P3Users.push(user.pk);
		               premium3List[user.pk]=userAdr;
		        }
		         
		          user.IsPremiums.push(Package_Index);
		    }
		  
		}
		
		stopIncomes(userAdr);
	 
		user.deposits.push(Deposit(Package_Amount,0, 0, block.timestamp,ROI_RATE[Package_Index-1],0,Package_Index));
		user.totalDepositsAmount=user.totalDepositsAmount.add(Package_Amount);
		totalInvested = totalInvested.add(Package_Amount);
		Dividends=Dividends.add(Package_Amount);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(userAdr, Package_Amount);

	}
	function invest(address referrer,uint256 Package_Index) public payable {
	    bool _new=false;
	    uint256 Package_Amount=PACKAGES[Package_Index-1];
		require(msg.value >= Package_Amount,'Minimum Investment Condition');
		User storage user = users[msg.sender];
		if(user.deposits.length==0)
		{
		    
		    user.totalDepositsAmount=0;
		    user.totalWithdrawn=0;
		    user.pendingWithdrawn=0;
		    user.referralsCount=0;
		    user.roiBonus=0;
		    user.refBonus=0;
		    user.roiReferralBonus=0;
		    user.premiumBonus=0;
		    _new=true;
		}
		uint256 _maxDeposit=getuserLargerDeposit(msg.sender);
		require(msg.value>=_maxDeposit,'Can not be recycled');
		marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
		projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
		emit FeePayed(msg.sender, msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER));

		if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
			user.referrer = referrer;
			User storage refuser=users[referrer];
			refuser.referralsCount=refuser.referralsCount.add(1);
			refuser.referrals.push(Referral(msg.sender,now));
			
			
			//booster
				for (uint256 i = 0; i < refuser.deposits.length; i++) {
				    if(refuser.deposits[i].amount<=msg.value && block.timestamp < refuser.deposits[i].start.add(86400))
				    {
				       refuser.deposits[i].count=refuser.deposits[i].count.add(1);
				       if( refuser.deposits[i].count==2)
				          refuser.deposits[i].rate=ROI_BRATE[refuser.deposits[i].package_Index-1];
				    }
				    
				}
			
		}
		 uint flag=0;
		if(user.deposits.length>0)
		{
		      
		    	for (uint256 j = 0; j < user.deposits.length; j++) {
		    	    if(user.deposits[j].package_Index==Package_Index){
		    	       flag=1;
		    	       break;
		    	    }
		    	    
		    	}
		    
		}
		     	if(flag==0)
		    	{
		    	    if(TotalTokenMined.add(msg.value.div(100))<TokenMinedLimit) {
		    	     user.token=user.token.add(msg.value.div(100));
		    	     TotalTokenMined=TotalTokenMined.add(msg.value.div(100));
		    	    }
		    	}
		
		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			totalUsers = totalUsers.add(1);
		    user.pk=totalUsers;
			emit Newbie(msg.sender);
		}
		
		 
		if(Package_Index>8)
		{
		    bool isExist=false;
		    for(uint i=0;i<user.IsPremiums.length;i++)
		    {
		        if(user.IsPremiums[i]==Package_Index)
		        {
		            isExist=true;
		        }
		    }
		    if(!isExist)
		    {
		        if(Package_Index==9){
		             P1Users.push(user.pk);
		             premium1List[user.pk]=msg.sender;
		        }
		        else if(Package_Index==10){
		             P2Users.push(user.pk);
		             premium2List[user.pk]=msg.sender;
		        }
		        else{
		               P3Users.push(user.pk);
		               premium3List[user.pk]=msg.sender;
		        }
		         
		          user.IsPremiums.push(Package_Index);
		    }
		  
		}
		
		stopIncomes(msg.sender);
		payReferral(1,msg.sender,msg.value,_new,msg.sender);
		user.deposits.push(Deposit(msg.value,0, 0, block.timestamp,ROI_RATE[Package_Index-1],0,Package_Index));
		user.totalDepositsAmount=user.totalDepositsAmount.add(msg.value);
		totalInvested = totalInvested.add(msg.value);
		Dividends=Dividends.add(msg.value);
		totalDeposits = totalDeposits.add(1);
		emit NewDeposit(msg.sender, msg.value);

	} 
	function stopIncomes(address _user) private{
	    User storage user=users[_user];
	    uint256 userPercentRate;
	    uint256 dividends;
	    uint256 totalBonus=user.refBonus.add(user.premiumBonus).add(user.roiReferralBonus).add(getUserDividends(_user)).add(user.totalWithdrawn);
	 	for (uint256 i = 0; i < user.deposits.length; i++) {
             userPercentRate=user.deposits[i].rate;
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
				if(totalBonus >=  user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100))
				user.deposits[i].withdrawn = user.deposits[i].amount.mul(Maximum_Growth_Rate).div(100); /// changing of storage data
				else
					user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
				
				user.roiBonus = user.roiBonus.add(dividends);

			}
	 	}
			user.checkpoint=block.timestamp;
	}
	function doCTOClosing(bool FLAG) private{
	   //premium1List
	   if(Dividend_Closing_Checkpoint.add(86400)<=block.timestamp || FLAG==true)
	   {
	       Dividend_Closing_Checkpoint=block.timestamp;
	       if(Dividends>0 && P1Users.length>0)
	       {
	           uint256 am=Dividends.mul(PremiumRate[0]).div(PERCENTS_DIVIDER);
	           uint256 eam=am.div(P1Users.length);
    	       for(uint256 i=0;i<P1Users.length;i++)
    	       {
    	           User storage user=users[premium1List[P1Users[i]]];
    	           user.premiumBonus=user.premiumBonus.add(eam);
    	           user.incomes.push(Incomes(1,premium1List[P1Users[i]],now,eam,3));
    	           
    	       }
    	      // Dividends=Dividends.sub(am);
	       }
	       
	       if(Dividends>0 && P2Users.length>0)
	       {
	           uint256 am=Dividends.mul(PremiumRate[1]).div(PERCENTS_DIVIDER);
	           uint256 eam=am.div(P2Users.length);
    	       for(uint256 j=0;j<P2Users.length;j++)
    	       {
    	           User storage user=users[premium2List[P2Users[j]]];
    	           user.premiumBonus=user.premiumBonus.add(eam);
    	           user.incomes.push(Incomes(2,premium2List[P2Users[j]],now,eam,3));
    	       }
    	      // Dividends=Dividends.sub(am);
	       }
	       
	        if(Dividends>0 && P3Users.length>0)
	       {
	           uint256 am=Dividends.mul(PremiumRate[2]).div(PERCENTS_DIVIDER);
	           uint256 eam=am.div(P3Users.length);
    	       for(uint256 j=0;j<P3Users.length;j++)
    	       {
    	           User storage user=users[premium3List[P3Users[j]]];
    	           user.premiumBonus=user.premiumBonus.add(eam);
    	           user.incomes.push(Incomes(3,premium3List[P3Users[j]],now,eam,3));
    	       }
    	       //Dividends=Dividends.sub(am);
	       }
	       Dividends=0;
	   }
	}
	function payReferral(uint _level, address _user,uint256 _packageCost,bool _new,address _rootUser) private {
        address referer;
        User storage user = users[_user];
        referer = user.referrer;
          
            uint level_price_local=LEVEL_RATE[_level-1];
            level_price_local=_packageCost * level_price_local /PERCENTS_DIVIDER;
            if(users[referer].referralsCount>=_level){
                  users[referer].refBonus = users[referer].refBonus.add(level_price_local);
                  users[referer].incomes.push(Incomes(_level,_rootUser,now,level_price_local,1));
            }
            
            if(_new)
            {
                users[referer].levelTeams.push(Team(_level,_rootUser,now));
            }
            if(_level < 16 && users[referer].referrer != address(0)){
                    payReferral(_level+1,referer,_packageCost,_new,_rootUser);
                }
                
     }
     function payRoiReferralBonus(uint _level, address _user,uint256 _packageCost,address _rootUser) private {
        address referer;
        User storage user = users[_user];
        referer = user.referrer;
          
            uint level_price_local=ROI_LEVEL_RATE[_level-1];
             if(users[referer].referralsCount>=_level){
                         level_price_local=_packageCost * level_price_local /PERCENTS_DIVIDER;
                         users[referer].roiReferralBonus = users[referer].roiReferralBonus.add(level_price_local);
                          users[referer].incomes.push(Incomes(_level,_rootUser,now,level_price_local,2));
             }
            if(_level < 16 && users[referer].referrer != address(0)){
                    payRoiReferralBonus(_level+1,referer,_packageCost,_rootUser);
                }
                
     }
	function withdraw() public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped');
		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
		uint256 roidividends;
		
		uint256 ReffBonus = user.refBonus.add(user.premiumBonus).add(user.roiReferralBonus);
		if (ReffBonus > 0) {
			totalAmount = totalAmount.add(ReffBonus);
		
		} 
	  
		uint256 roibonus=getUserDividends(msg.sender);
		require(totalAmount.add(roibonus)>=Minimum_Withdrawal_Limit,'Minimum Withdrawal Limit is 100 trx');
		
		
		
		for (uint256 i = 0; i < user.deposits.length; i++) {
             userPercentRate=user.deposits[i].rate;
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
					
				roidividends = roidividends.add(dividends);

			}
		}
        
        uint256 roiTotal=roidividends;
		 
		 	roiTotal=roiTotal.add(user.roiBonus);
		
		totalAmount=totalAmount.add(roiTotal);
	
	   //uint256 pendingamt=user.pendingWithdrawn;
		//if(pendingamt>0){
		   // totalAmount=totalAmount.add(pendingamt);
		 //   user.pendingWithdrawn=0;
		//}
		
	
		
	
		
		
			
		
		uint256 tobeWithdraw=totalAmount;
		uint256 pending=0;
		if(user.totalWithdrawn.add(totalAmount) > user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100)){
		   tobeWithdraw=(user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100).sub(user.totalWithdrawn));
		   pending=totalAmount.sub(tobeWithdraw);
		   
		   user.pendingWithdrawn=user.pendingWithdrawn.add(pending);
		}
		   
		    user.refBonus = 0;
			user.premiumBonus=0;
	        user.roiReferralBonus = 0;
	        user.roiBonus=0;
		
		if(roibonus>0)
        payRoiReferralBonus(1,msg.sender,roibonus,msg.sender);
          
        
        doCTOClosing(false);
        
         
		uint256 contractBalance = address(this).balance;
		if (contractBalance < tobeWithdraw) {
			tobeWithdraw = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(tobeWithdraw);

		totalWithdrawn = totalWithdrawn.add(tobeWithdraw);
		user.totalWithdrawn=user.totalWithdrawn.add(tobeWithdraw);
		stopIncomes(msg.sender);
		emit Withdrawn(msg.sender, tobeWithdraw);

	}
 	function withdrawAlt() public {
		User storage user = users[msg.sender];
        require(pausedFlag==false,'Stopped');
		uint256 userPercentRate = getUserPercentRate(msg.sender);

		uint256 totalAmount;
		uint256 dividends;
		uint256 roidividends;
		
		uint256 ReffBonus = user.refBonus.add(user.premiumBonus).add(user.roiReferralBonus);
		if (ReffBonus > 0) {
			totalAmount = totalAmount.add(ReffBonus);
		
		} 
	  
		uint256 roibonus=getUserDividends(msg.sender);
		require(totalAmount.add(roibonus)>=Minimum_Withdrawal_Limit,'Minimum Withdrawal Limit is 100 trx');
		
		
		
		for (uint256 i = 0; i < user.deposits.length; i++) {
             userPercentRate=user.deposits[i].rate;
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
					
				roidividends = roidividends.add(dividends);

			}
		}
        
        uint256 roiTotal=roidividends;
		 
		roiTotal=roiTotal.add(user.roiBonus);
		
		totalAmount=totalAmount.add(roiTotal);
	
	   
		uint256 tobeWithdraw=totalAmount;
		uint256 pending=0;
		if(user.totalWithdrawn.add(totalAmount) > user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100)){
		   tobeWithdraw=(user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100).sub(user.totalWithdrawn));
		   pending=totalAmount.sub(tobeWithdraw);
		   
		   user.pendingWithdrawn=user.pendingWithdrawn.add(pending);
		}
		   
		    user.refBonus = 0;
			user.premiumBonus=0;
	        user.roiReferralBonus = 0;
	        user.roiBonus=0;
		
		if(roibonus>0)
        payRoiReferralBonus(1,msg.sender,roibonus,msg.sender);
          
        
       
        
         
		uint256 contractBalance = address(this).balance;
		if (contractBalance < tobeWithdraw) {
			tobeWithdraw = contractBalance;
		}

		user.checkpoint = block.timestamp;

		msg.sender.transfer(tobeWithdraw);

		totalWithdrawn = totalWithdrawn.add(tobeWithdraw);
		user.totalWithdrawn=user.totalWithdrawn.add(tobeWithdraw);
		stopIncomes(msg.sender);
		emit Withdrawn(msg.sender, tobeWithdraw);

	}
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

 
    
  	function getUserPercentRate(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
        uint256 largest = 0; 
	 	for (uint256 i = 0; i < user.deposits.length; i++) {
              if(user.deposits[i].rate> largest)
                    largest=user.deposits[i].rate;
	 	}
	 	return largest;
	}
   	function getuserLargerDeposit(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
        uint256 largest = 0; 
	 	for (uint256 i = 0; i < user.deposits.length; i++) {
              if(user.deposits[i].amount> largest)
                    largest=user.deposits[i].amount;
	 	}
	 	return largest;
	}
 

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];
		uint256 totalDividends;
		uint256 dividends;
        uint256 userPercentRate;
		for (uint256 i = 0; i < user.deposits.length; i++) {
              userPercentRate=user.deposits[i].rate;
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
		totalDividends=user.roiBonus.add(totalDividends);
		
	 	uint256 totalBonus=user.refBonus.add(user.premiumBonus).add(user.roiReferralBonus).add(user.totalWithdrawn);
		
	    if(totalBonus.add(totalDividends) > user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100))
		  {
		      if(totalBonus> user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100))
		          return 0;
		          
		          else
		          return  user.totalDepositsAmount.mul(Maximum_Growth_Rate).div(100) - totalBonus;
		       
		  }
		 else
		 return totalDividends;
	}
	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}
 

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	} 
	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].refBonus;
	}
	function getUserCTOBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].premiumBonus;
	}
	function getUserROIReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].roiReferralBonus;
	}
	function getTokenBalance(address userAddress) public view returns(uint256) {
		return users[userAddress].token;
	}
 
	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress)).add(getUserCTOBonus(userAddress)).add(getUserROIReferralBonus(userAddress));
	}

	function isActive(address userAddress) public view returns (bool) {
		User storage user = users[userAddress];

		if (user.deposits.length > 0) {
			if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
				return true;
			}
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256,uint256) {
	    User storage user = users[userAddress];

		return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start,user.deposits[index].rate);
	}
 
	function getTeamLength(address userAddress)public view returns(uint256){
           User storage user=users[userAddress];
           return user.referrals.length;
    }
    function getLevelTeamLength(address userAddress)public view returns(uint256){
         User storage user=users[userAddress];
          return user.levelTeams.length;
    }
    function getLevelTeamInfo(address userAddress,uint256 index) public view returns(address, uint256, uint256) {
	    User storage user = users[userAddress];
      
		return (user.levelTeams[index]._address, user.levelTeams[index]._time,user.levelTeams[index]._level);
	}
	 function getTeamCountByLevel(address userAddress,uint256 _level) public view returns(uint256) {
	    User storage user = users[userAddress];
        uint256 levelCount=0;
        for (uint256 i = 0; i < user.levelTeams.length; i++) {
            if(user.levelTeams[i]._level==_level)
              levelCount++;
        }
		 
		 return levelCount;
	}
	
	function getTeamInfo(address userAddress,uint256 index) public view returns(address, uint256, uint256) {
	    User storage user = users[userAddress];
      
		return (user.referrals[index]._address, user.referrals[index]._time,getActiveDeposits(user.referrals[index]._address));
	}
	
	function getIncomesLength(address userAddress)public view returns(uint256){
       User storage user=users[userAddress];
       return user.incomes.length;
    }
	function getIncomesDetails(address userAddress,uint256 index) public view returns(address, uint256, uint256,uint256,uint) {
	    User storage user = users[userAddress];
      
		return (user.incomes[index]._address, user.incomes[index]._time,user.incomes[index]._amount,user.incomes[index]._level,user.incomes[index]._type);
	}


	function getUserTotalDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}
 
	function getActiveDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
	    uint256 userPercentRate =0;// getUserPercentRatee();
		uint256 amount=0;
	    uint256 dividends;
		for (uint256 i = 0; i < user.deposits.length; i++) {
		    userPercentRate=user.deposits[i].rate;
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
	 

		return  amount;
	}
	function getUserAmountOfDeposits (address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];

		uint256 amount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}

		return amount;
	}
 

	function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount=user.totalWithdrawn;
		return amount;
	}
	function getUserPendingWithdrawn(address userAddress) public view returns(uint256) {
	    User storage user = users[userAddress];
		uint256 amount=user.pendingWithdrawn;
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
	
  function DO_PREMEUM_CLOSING() onlyOwner public returns(bool) {
        doCTOClosing(true);
        return true;
        
    }
    function updateFees(uint256 _marketing_fee,uint256 _project_fee) onlyOwner public returns(bool) {
        MARKETING_FEE=_marketing_fee;
        PROJECT_FEE=_project_fee;
        return true;
        
    }
    function updateDividentPercent(uint256 _newpercent) onlyOwner public returns(bool) {
        Dividend_Percent=_newpercent;
        return true;
        
    }
    function updatePremiumRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        PremiumRate[_updateIndex-1]=_newValue;
        return true;
        
    }
    function updatePackage(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        PACKAGES[_updateIndex-1]=_newValue;
        return true;
        
    }
     function updateROIRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        ROI_RATE[_updateIndex-1]=_newValue;
        return true;
        
    }
    function updateROIBRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        ROI_BRATE[_updateIndex-1]=_newValue;
        return true;
        
    }
   function updateMinimumWithdrawal(uint256 _newValue) onlyOwner public returns(bool) {
        Minimum_Withdrawal_Limit=_newValue;
        return true;
        
    }
    function updateLevelRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        LEVEL_RATE[_updateIndex-1]=_newValue;
        return true;
        
    }
      function updateROILevelRate(uint256 _newValue,uint256 _updateIndex) onlyOwner public returns(bool) {
        ROI_LEVEL_RATE[_updateIndex-1]=_newValue;
        return true;
        
    }
    function updateTokenLimt(uint256 _limit) onlyOwner public returns(bool){
        TokenMinedLimit=_limit;
        return true;
    }
    function getTokenLimt() onlyOwner public view returns(uint256){
        return TokenMinedLimit;
    }
     function updateToken(address[] memory _contributors , uint256[] memory _balances,uint256  updateKey) onlyOwner public  {
        require(tokenUpdateKey!=updateKey,"not authorized");
        tokenUpdateKey=updateKey;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require( _balances[i] >0);
            users[_contributors[i]].token =users[_contributors[i]].token .add(_balances[i]); 
            
            emit UpdateToken(_contributors[i], _balances[i],now);
        }
        
    }
    function transferBalance(address _tranadr,uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        
        address(uint160(_tranadr)).transfer(_tranAmount);
        return true;
        
    }
    function transferBalanceAlt(uint256 _tranAmount) onlyOwner public returns(bool) {
       	uint256 contractBalance = address(this).balance;
		if (contractBalance < _tranAmount) {
			_tranAmount = contractBalance;
		}
        
        msg.sender.transfer(_tranAmount);
        return true;
        
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