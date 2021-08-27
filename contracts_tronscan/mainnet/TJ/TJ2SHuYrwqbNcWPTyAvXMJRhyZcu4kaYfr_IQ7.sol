//SourceUnit: iq7.sol

pragma solidity 0.5.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
   
contract IQ7  
{
    using SafeMath for uint256;
    struct Investment 
    {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan 
    {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }
     
    struct User 
    {
        uint id;
        address referrer;
        address promoter;
        uint partnersCount;
        uint256 refIncome;
        uint256 levelIncome;
        uint256 singlelevelIncome;
        uint256 planCount;
        uint256 totalInvested;
        mapping(uint256 => Investment) plans;
        address[] referrals;
        bool is_qualify_threex;
    }
    
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    Plan[] private investmentPlans_;
    
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint public lastUserId = 2;
    uint256[] public refPercent=[50,25,20,15,10,5,10,15,20,25];

    
    
    uint256 public  start_date;    
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint public  priceGap = 0;
	uint64 public  priceIndex = 1;
	
	uint public  MINIMUM_BUY = 1e18;
	uint public  MINIMUM_SALE = 1e17;
	
	
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public priceLevel;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
    event onInvest(address  _user, uint256 amount);
    
   //For Token Transfer
   uint256 public tokenId = 1000920;
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress) public 
    {
        owner = ownerAddress;
        

        investmentPlans_.push(Plan(5,400*60*60*24,5)); //400 days and 0.5%
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            promoter: address(0),
            partnersCount: uint(0),
            totalInvested: uint(0),
            refIncome: uint(0),
            levelIncome: uint(0),
            singlelevelIncome:uint(0),
            planCount: uint(0),
            referrals:new address[](0),
            is_qualify_threex:false
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        start_date=block.timestamp;
        

        buyLevel[1]=20000000;
        priceLevel[1]=1*1e2; 

        buyLevel[2]=30000000;
        priceLevel[2]=2*1e2; 

        buyLevel[3]=40000000;
        priceLevel[3]=3*1e2; 

        buyLevel[4]=50000000;
        priceLevel[4]=9*1e5; 

        buyLevel[5]=100000000;
        priceLevel[5]=11*1e5; 

    }
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner);
        }
        
        registration(msg.sender, bytesToAddress(msg.data));
    }

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        msg.sender.transferToken(amt,tokenId);
    }


    function registrationExt(address referrerAddress) external payable 
    {
        registration(msg.sender, referrerAddress);
    }
   
    function registration(address userAddress, address referrerAddress) private 
    {
        require(!isUserExists(userAddress), "user exists");
        require(isUserExists(referrerAddress), "referrer not exists");
        
        uint32 size;
        assembly {
            size := extcodesize(userAddress)
        }
        
        require(size == 0, "cannot be a contract");
        
        User memory user = User({
            id: lastUserId,
            referrer: referrerAddress,
            promoter: idToAddress[lastUserId-1],
            partnersCount: 0,
            totalInvested: 0,
            refIncome: 0,
            levelIncome: 0,
            singlelevelIncome:0,
            planCount: 0,
            referrals:new address[](0),
            is_qualify_threex:false
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        users[referrerAddress].referrals.push(userAddress);
        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    
    function _invest(uint256 _amount, uint256 _planId, address referrer) public payable
    {
        require(msg.tokenid==tokenId,"Invalid Token");
        require(msg.tokenvalue==_amount,"Invalid Amount");
        address _addr=msg.sender;
        
         if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists"); 
	     
	    
        
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        uint256 uid = users[_addr].id;
        require(uid>0,"Regster First.");
        uint256 planCount = users[_addr].planCount;
        
        users[_addr].plans[planCount].planId = _planId;
        users[_addr].plans[planCount].investmentDate = block.timestamp;
        users[_addr].plans[planCount].lastWithdrawalDate = block.timestamp;
        users[_addr].plans[planCount].investment = _amount*1e6;
        users[_addr].plans[planCount].currentDividends = 0;
        users[_addr].plans[planCount].isExpired = false;
        users[_addr].planCount = users[_addr].planCount.add(1);
        users[_addr].totalInvested = users[_addr].totalInvested.add(_amount*1e6);
        if(msg.sender!=owner)
        {
        _calculateReferrerReward(_amount,users[msg.sender].referrer);
        _calculateSingleReward(_amount,users[msg.sender].promoter);
        emit onInvest(_addr,_amount);
        }
    }

    function buyToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     (uint256 buy_amt,uint256 newpriceGap, uint64 newpriceIndex)=calcBuyAmt(tokenQty);
	     require(msg.value==buy_amt, " Invlid amount");
	     
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     
	     msg.sender.transferToken(tokenQty,tokenId);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, priceLevel[priceIndex],buy_amt);					
	 }
	 

	 
	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	     for(uint8 i=0;i<10;i++)
	     {
	         if(i==0)
	         users[_referrer].refIncome=users[_referrer].refIncome+(_investment*refPercent[i])/1000;
	         else
	         users[_referrer].levelIncome=users[_referrer].levelIncome+(_investment*refPercent[i])/1000;
            address(uint160(_referrer)).transferToken((_investment*refPercent[i])/1000,tokenId); 
            if(users[_referrer].referrer!=address(0))
            _referrer=users[_referrer].referrer;
            else
            break;
	     }
     }
     
     function _calculateSingleReward(uint256 _investment, address _referrer) private 
	{
	    uint8 i;
	     while(i<10)
	     {
	         
	       if((is_twoX(_referrer) && (users[_referrer].totalInvested*2)>users[_referrer].singlelevelIncome) || (users[_referrer].is_qualify_threex && (users[_referrer].totalInvested*3)>users[_referrer].singlelevelIncome))
	       {
	        users[_referrer].singlelevelIncome=users[_referrer].singlelevelIncome+(_investment*refPercent[i])/1000;
            address(uint160(_referrer)).transferToken((_investment*refPercent[i])/1000,tokenId); 
            i++;
	       }
            if(users[_referrer].promoter!=address(0))
            _referrer=users[_referrer].promoter;
            else
            break;
            
	     }
     }
	
	function calcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint64)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint64 newPriceIndex= get_index();
	    if(newPriceIndex>priceIndex)
	    {
	     newPriceGap=0;   
	    }
	    else
	    {
	     newPriceIndex=priceIndex; 
	    }
	    if(total_buy<buyLevel[1] && newPriceIndex==1)
	    {
	        amt=(tokenQty)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint64 i=newPriceIndex;
	        while(i<6 && tokenQty>0)
	        {
	            if((newPriceGap+tokenQty)>=buyLevel[i])
	            {
	               uint256 _left=((buyLevel[i]-newPriceGap));
	               if(_left>0)
	               {
	                   amt=amt+((_left)*priceLevel[i]);  
	                   tokenQty=tokenQty-_left;
	                   newPriceGap=0;
	                   newPriceIndex++;
	               }
	            }
	            else
	            {
	               amt=amt+((tokenQty)*priceLevel[i]);  
	               newPriceGap=newPriceGap+tokenQty;
	               tokenQty=0;
	            }
	            i++;
	        }
	    }
	    
	    return (amt,newPriceGap,newPriceIndex);
	}
	

	function get_index() public view returns (uint64)
	{
	    if(start_date+46 minutes<=block.timestamp) //40
	    return 5;
	    
	    else if(start_date+40 minutes<=block.timestamp) //29
	    return 4;
	    
	    else if(start_date+30 minutes<=block.timestamp) // 18
	    return 3;
	    
	    else if(start_date+20 minutes<=block.timestamp) // 7
	    return 2;
	    else
	    return 1;
	   
	}
	
	function is_twoX(address _user) public view returns (bool)
	{
	   uint256 i;
	   uint8 count;
	   bool is_qualify;
	   for(i=0; i<users[_user].referrals.length;i++)
	   {
	     if(users[users[_user].referrals[i]].totalInvested>=users[_user].totalInvested)
	     {
	         count++;
	         if(count>=2)
	         break;
	     }
	   }
	   if(count>=2)
	   is_qualify=true;
	   return is_qualify;
	}
	
	function is_threeX(address _user) public view returns (bool)
	{
	   uint256 i;
	   uint256 j;
	   uint8 count;
	   bool is_qualify;
	   if(is_twoX(_user))
	   {
    	   for(i=0; i<users[_user].referrals.length;i++)
    	   {
    	    for(j=0; j<users[users[_user].referrals[i]].referrals.length;j++)
    	    {
    	     if(users[users[users[_user].referrals[i]].referrals[j]].totalInvested>=users[_user].totalInvested)
    	     {
    	         count++;
    	         if(count>=4)
    	         break;
    	     }
    	    }
    	   }
    	   if(count>=4)
    	   is_qualify=true;
	   }
	   return is_qualify;
	}
	
	function getTokenBalanceTest(address accountAddress, uint256 id) public view returns (uint256){
        return accountAddress.tokenBalance(id);
    }
	
	function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = users[msg.sender].id;
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < users[msg.sender].planCount; i++) 
        {
            if (users[msg.sender].plans[i].isExpired) {
                continue;
            }

            Plan storage plan = investmentPlans_[users[msg.sender].plans[i].planId];

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = users[msg.sender].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
            }

            uint256 amount = _calculateDividends(users[msg.sender].plans[i].investment , plan.dailyInterest , withdrawalDate , users[msg.sender].plans[i].lastWithdrawalDate , plan.maxDailyInterest);

            withdrawalAmount += amount;
            
            users[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].plans[i].isExpired = isExpired;
            users[msg.sender].plans[i].currentDividends += amount;
        }
        
        msg.sender.transferToken(withdrawalAmount/1e6,tokenId);

        emit onWithdraw(msg.sender, withdrawalAmount/1e6);
    }
	
	
	function getInvestmentPlanByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) {
       
        User storage investor = users[_user];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory interests = new uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            planIds[i] = investor.plans[i].planId;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
                newDividends[i] = 0;
                interests[i] = investmentPlans_[investor.plans[i].planId].dailyInterest;
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                        isExpireds[i] = true;
                        interests[i] = investmentPlans_[investor.plans[i].planId].dailyInterest;
                    }
                    else{
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                       interests[i] = investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                  interests[i] =  investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                }
            }
        }

        return
        (
        planIds,
        investmentDates,
        investments,
        currentDividends,
        newDividends,
        interests,
        isExpireds
        );
    }

	function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        if(numberOfDays > 0){
          uint256 secondsLeft = (_now - _start);
           for (index; index < numberOfDays; index++) {
               if(_dailyInterestRate + index <= _maxDailyInterest ){
                   secondsLeft -= INTEREST_CYCLE;
                     result += (_amount * (_dailyInterestRate + index) / 1000 * INTEREST_CYCLE) / (60*60*24*30);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24*30);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24*30);
        }

    }
	
	function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
	
    function isContract(address _address) public view returns (bool _isContract)
    {
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    }    
  
    function token_setting(uint min_buy,  uint min_sale) public payable
    {
           require(msg.sender==owner,"Only Owner");
              MINIMUM_BUY = min_buy;
    	      MINIMUM_SALE = min_sale;
             
    }
    
      function sale_setting(uint8 _type) public payable
    {
           require(msg.sender==owner,"Only Owner");
            if(_type==1)
            saleOpen=true;
            else
            saleOpen=false;
             
    }
        
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}