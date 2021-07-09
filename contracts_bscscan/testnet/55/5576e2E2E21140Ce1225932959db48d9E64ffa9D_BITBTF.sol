/**
 *Submitted for verification at BscScan.com on 2021-07-09
*/

pragma solidity 0.5.4;
//  busd token == 0xCF1AeCc287027f797b99650B1E020fFa0fb0e248
//  btf token == 0xcD3D2E9f6cab548D277A1DC0F63fA845A7f6436B

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
   
contract BITBTF  {
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
        uint partnersCount;
        uint256 refIncome;
        uint256 levelIncome;
        uint256 selfBuy;
        uint256 selfSell;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
    }
    	bool public saleOpen=true;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    Plan[] private investmentPlans_;
    
    uint256 private constant INTEREST_CYCLE = 30 days;

    uint public lastUserId = 2;
    uint256[] public refPercent=[50,25,15,10];

    
    
    
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
    event TokenPriceHistory(uint  previous, uint indexed inc_desc, uint new_price, uint8 type_of);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount);
    event onWithdraw(address  _user, uint256 withdrawalAmount);
   
    
   //For Token Transfer
   
   IBEP20 private btfToken; 
   IBEP20 private busdToken; 
   event onBuy(address buyer , uint256 amount);
   mapping(address => uint256) public boughtOf;

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _btfToken) public 
    {
        owner = ownerAddress;
        
        btfToken = _btfToken;
        busdToken = _busdToken;
        investmentPlans_.push(Plan(50,540*60*60*24,50)); //540 days and 5%
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            partnersCount: uint(0),
            refIncome: uint(0),
            levelIncome: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            planCount: uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
        
        for(uint64 i=1;i<=10;i++)
        {
            buyLevel[i]=100000*1e18;
            if(i==1)
            priceLevel[i]=125*1e14;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=11;i<=20;i++)
        {
            buyLevel[i]=150000*1e18;
            if(i==11)
            priceLevel[i]=135*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
         for(uint64 i=21;i<=30;i++)
        {
            buyLevel[i]=200000*1e18;
            if(i==21)
            priceLevel[i]=235*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=31;i<=40;i++)
        {
            buyLevel[i]=250000*1e18;
            if(i==31)
            priceLevel[i]=335*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=41;i<=50;i++)
        {
            buyLevel[i]=300000*1e18;
            if(i==41)
            priceLevel[i]=425*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        for(uint64 i=51;i<=99;i++)
        {
            buyLevel[i]=200000*1e18;
            if(i==51)
            priceLevel[i]=535*1e15;
            else
            priceLevel[i]=priceLevel[i-1]+10*1e15;
        }
        
        
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
        else
        btfToken.transfer(msg.sender,amt);
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
            partnersCount: 0,
            refIncome: 0,
            levelIncome: 0,
            selfBuy: 0,
            selfSell: 0,
            planCount: 0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        users[referrerAddress].partnersCount++;
        

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id);
    }
    
    
    function _invest(address _addr,uint256 _amount,uint256 _planId) private 
    {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        uint256 uid = users[_addr].id;
        require(uid>0,"Regster First.");
        uint256 planCount = users[_addr].planCount;
        
        users[_addr].plans[planCount].planId = _planId;
        users[_addr].plans[planCount].investmentDate = block.timestamp;
        users[_addr].plans[planCount].lastWithdrawalDate = block.timestamp;
        users[_addr].plans[planCount].investment = _amount;
        users[_addr].plans[planCount].currentDividends = 0;
        users[_addr].plans[planCount].isExpired = false;

        users[_addr].planCount = users[_addr].planCount.add(1);
    }

    function buyToken(uint tokenQty,address referrer) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     (uint256 buy_amt,uint256 newpriceGap, uint64 newpriceIndex)=calcBuyAmt(tokenQty);
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     
	     if(!isUserExists(msg.sender))
	     {
	       registration(msg.sender, referrer);   
	     }
	     require(isUserExists(msg.sender), "user not exists");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	     priceGap=newpriceGap;
	     priceIndex=newpriceIndex;
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     btfToken.transfer(msg.sender , tokenQty);
	     
	     _invest(msg.sender,tokenQty,0);
	     
	     if(msg.sender!=owner)
	     _calculateReferrerReward(tokenQty,users[msg.sender].referrer);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, priceLevel[priceIndex],buy_amt);					
	 }
	 
	function sellToken(uint tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(saleOpen,"Sale Stopped.");
	    require(btfToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(btfToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
        require(isUserExists(userAddress), "user is not exists. Register first.");
	   
	    
	    uint256 bnb_amt=0;
	     
		 btfToken.transferFrom(userAddress ,address(this), (tokenQty));
		 address(uint160(msg.sender)).transfer((bnb_amt));
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],bnb_amt);
		total_token_sale=total_token_sale+tokenQty;
	 }
	 
	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	     for(uint8 i=0;i<4;i++)
	     {
	         if(i==0)
	         users[_referrer].refIncome=users[_referrer].refIncome+(_investment*refPercent[i])/1000;
	         else
	         users[_referrer].levelIncome=users[_referrer].levelIncome+(_investment*refPercent[i])/1000;
            btfToken.transfer(_referrer,(_investment*refPercent[i])/1000); 
            if(users[_referrer].referrer!=address(0))
            _referrer=users[_referrer].referrer;
            else
            break;
	     }
     }
	
	function calcBuyAmt(uint tokenQty) public view returns(uint256,uint256,uint64)
	{
	    uint256 amt;
	    uint256 total_buy=priceGap+tokenQty;
	    uint256 newPriceGap=priceGap;
	    uint64 newPriceIndex=priceIndex;
	    if(total_buy<buyLevel[1] && priceIndex==1)
	    {
	        amt=(tokenQty/1e18)*priceLevel[1];
	        newPriceGap=newPriceGap+tokenQty;
	    }
	    else
	    {
	        uint64 i=newPriceIndex;
	        while(i<101 && tokenQty>0)
	        {
	            if((newPriceGap+tokenQty)>=buyLevel[i])
	            {
	               uint256 _left=((buyLevel[i]-newPriceGap));
	               if(_left>0)
	               {
	                   amt=amt+((_left/1e18)*priceLevel[i]);  
	                   tokenQty=tokenQty-_left;
	                   newPriceGap=0;
	                   newPriceIndex++;
	               }
	            }
	            else
	            {
	               amt=amt+((tokenQty/1e18)*priceLevel[i]);  
	               newPriceGap=newPriceGap+tokenQty;
	               tokenQty=0;
	            }
	            i++;
	        }
	    }
	    
	    return (amt,newPriceGap,newPriceIndex);
	}
	
	function calcBuyToken(uint256 amount) public view returns(uint256,uint256,uint64)
	{
	    uint256 quatity;
	    uint256 newPriceGap=priceGap;
	    uint64 newPriceIndex=priceIndex;  
	    uint64 i=newPriceIndex; 
	    while(amount>0 && i<101)
	    {
	        if(i==100)
	        {
	            quatity=quatity+(amount/priceLevel[priceIndex]);
	            amount=0;
	        }
	        else
	        {
	            uint256 left=(buyLevel[priceIndex]-newPriceGap)/1e18;
	            
	            uint256 LeftValue=(left*priceLevel[newPriceIndex]);
	            
	            if(LeftValue>=amount)
	            {
	                left=(amount/priceLevel[newPriceIndex]);
	                 quatity=quatity+(left*1e18);
	                 amount=0;
	                 newPriceGap=newPriceGap+(left*1e18);
	            }
	            else
	            {
	                 quatity=quatity+(left*1e18);
	                 amount=amount-LeftValue;  
	                 newPriceGap=0;
	            }
	        }
	        newPriceIndex++;
	        i++;
	    }
	    if(newPriceIndex>1)
	    newPriceIndex=newPriceIndex-1;
	     return (quatity,newPriceGap,newPriceIndex);
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
        
        btfToken.transfer(address(this),(withdrawalAmount/priceLevel[priceIndex]));

        emit onWithdraw(msg.sender, withdrawalAmount/priceLevel[priceIndex]);
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