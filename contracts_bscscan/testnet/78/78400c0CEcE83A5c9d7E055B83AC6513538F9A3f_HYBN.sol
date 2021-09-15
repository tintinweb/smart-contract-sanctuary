/**
 *Submitted for verification at BscScan.com on 2021-09-14
*/

// owner 0x6dA4867268c80BFcc1Fe4515A841eCa6299557Fb
// HYBN 0x1Ce91DdadFcEa8686eeFbDb5Dd922FFA59524732  token bnb
// busd 0xcf1aecc287027f797b99650b1e020ffa0fb0e248  busd  token
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
        uint256 investmentUsd;
        uint256 nextWithdrawalDate;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
        uint256 maxDailyInterest;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 referrerRoiEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 partners;
    }
}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract HBCICO
{
  function tokenPrice() public view returns (uint256);
}

contract HYBN is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 40; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 300;
    uint256[] public referralPercent = [50,20,10,10,10];
    uint256[] public referralPercent2 = [100,150,200];
    uint256[] public refRoiPercent = [200,100,50,50,50,50,50,50,50,50,20,20,20,20,20,10,10,10,10,10];

    

    uint256[] public MINIMUM = [500000000000000000000,1000000000000000000000];
    uint256 public constant REFERRER_CODE = 1; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private referenceAccount_;
    
    IBEP20 private hbcToken;
    HBCICO oldctr;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event Registration(address investor,uint256 investorId,address referrer,uint256 referrerId);
    event UserIncome(address user, address indexed _from, uint256 level, uint256 _type, uint256 income);
    event onInvest(address investor, uint256 amount, uint256 _type);
    event onWithdraw(address investor, uint256 amount);
    event test(uint256 check, uint256 check2);
    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor(IBEP20 _hbcToken, HBCICO _oldctr) public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        hbcToken=_hbcToken;
        oldctr=_oldctr;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0,0,0); //default to buy plan 0, no referrer
        }
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
        //first
        investmentPlans_.push(Objects.Plan(40,365*60*60*24,40)); 
        //second
        investmentPlans_.push(Objects.Plan(166,90*60*60*24,166));
        investmentPlans_.push(Objects.Plan(111,180*60*60*24,111));
        investmentPlans_.push(Objects.Plan(94,320*60*60*24,94));
    }

    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        uint256[] memory maxInterests = new uint256[](investmentPlans_.length);
        for(uint256 i = 0; i < investmentPlans_.length; i++) 
        {
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

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256,  uint256, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
         uint256[] memory usdInvestment = new uint256[](investor.planCount);
        uint256[] memory nextWithdrawalDate = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            usdInvestment[i] = investor.plans[i].investmentUsd;
            nextWithdrawalDate[i] = investor.plans[i].nextWithdrawalDate;
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
        investor.referrerRoiEarnings,
        investor.referrer,
        investor.planCount,
        currentDividends,
        newDividends,
        usdInvestment,
        nextWithdrawalDate
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
        
        require(uid2Investor[_referrerCode].addr != address(0), "Wrong referrer code");
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

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        uint256 tPrice=_tokenPrice();
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        uint256 tokenAmount;
        uint256 nextWithdrawal;
        if(_planId==0)
        {
            require(_amount%MINIMUM[0]==0,"Wrong Amount1.");
            tokenAmount=(_amount.div(tPrice)).mul(1e18);
            nextWithdrawal=block.timestamp+30 days;
        }
       
        else if(_planId>0)
        {
            require(_amount>=MINIMUM[1] && _amount%(1000*1e18)==0,"Wrong Amount1.");
            tokenAmount=(_amount.div(tPrice)).mul(1e18);
            nextWithdrawal=block.timestamp+investmentPlans_[_planId].term;
        }
        
        require(hbcToken.balanceOf(msg.sender)>=tokenAmount,"Low wallet balance");
        require(hbcToken.allowance(msg.sender,address(this))>=tokenAmount,"Allow token first");
        hbcToken.transferFrom(msg.sender,address(this),tokenAmount);
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {//old user
            //do nothing, referrer is permenant
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment =tokenAmount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
        investor.plans[planCount].investmentUsd =  _amount;
        investor.plans[planCount].nextWithdrawalDate = nextWithdrawal;

        investor.planCount = investor.planCount.add(1);
        Objects.Investor storage upline=uid2Investor[investor.referrer];
        
        if(_planId==0)
        {
          for(uint256 i=0; i<5; i++) 
          {
				if (upline.addr != address(0)) 
				{
				    if(upline.partners>i)
				    {
				        uint256 tokenIncome=(tokenAmount.mul(referralPercent[i])).div(1000);
				        hbcToken.transfer(upline.addr,tokenIncome);
				        upline.referrerEarnings=upline.referrerEarnings+tokenIncome;
				        emit UserIncome(upline.addr, _addr,i+1, 1,  tokenIncome);
				    }
				    upline = uid2Investor[upline.referrer];
				} 
				else break;
		   }
        }
        else
        {
            if (upline.addr!= address(0)) 
			{
                uint256 i=_planId-1;
                uint256 tokenIncome=(tokenAmount.mul(referralPercent2[i])).div(1000);
			    hbcToken.transfer(upline.addr,tokenIncome);
			    upline.referrerEarnings=upline.referrerEarnings+tokenIncome;
		    	emit UserIncome(upline.addr, _addr,i+1, 1,  tokenIncome);  
			}
        }
        totalInvestments_ = totalInvestments_.add(_amount);
        return true;
    }


    function invest(uint256 _referrerCode, uint256 _planId, uint256 usdValue) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, usdValue)) {
            emit onInvest(msg.sender, usdValue,(usdValue.div(_tokenPrice())).mul(1e18));
        }
    }
   
    function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        uint256 refRoi = 0;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) 
        {
            if (uid2Investor[uid].plans[i].isExpired || block.timestamp<uid2Investor[uid].plans[i].nextWithdrawalDate) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) 
            {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) 
                {
                    withdrawalDate = endTime;
                    isExpired = true;
                    withdrawalAmount=withdrawalAmount+uid2Investor[uid].plans[i].investment;
                }
            }
            uint256 usdAmt=uid2Investor[uid].plans[i].investment;
            uint256 amount = _calculateDividends(usdAmt , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate , plan.maxDailyInterest);
            if(uid2Investor[uid].plans[i].planId==0)
            refRoi=refRoi+amount;
            withdrawalAmount += amount;

            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
            if(isExpired && uid2Investor[uid].plans[i].planId>0)
            {
                Objects.Investor storage upline=uid2Investor[uid2Investor[uid].referrer];
                if(upline.addr!=address(0))
                {
                    uint256 j=uid2Investor[uid].plans[i].planId-1;
                    uint256 tokenIncome=(usdAmt.mul(referralPercent2[j])).div(1000);
			        hbcToken.transfer(upline.addr,tokenIncome);
			        upline.referrerEarnings=upline.referrerEarnings+tokenIncome;
		    	    emit UserIncome(upline.addr, msg.sender,j+1, 1,tokenIncome);  
                }
            }
        }
        
        
        hbcToken.transfer(msg.sender,withdrawalAmount);
        
        if(refRoi>0)
        {
            Objects.Investor storage upline=uid2Investor[uid2Investor[uid].referrer];
           for(uint256 i=0; i<20; i++) 
           {
				if (upline.addr != address(0)) 
				{
				   if(upline.partners>i)
				   {
    				   uint256 refRoiIncome=(refRoi.mul(refRoiPercent[i])).div(1000);
    				   hbcToken.transfer(upline.addr,refRoiIncome);
    				   upline.referrerEarnings=upline.referrerEarnings+refRoiIncome;
    				   emit UserIncome(upline.addr, msg.sender,i+1, 1,  refRoiIncome);
				   }
    			   upline = uid2Investor[upline.referrer];
				} 
				else break;
		    }
        }
        
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
                     result += (_amount * (_dailyInterestRate + index) / 10000 * INTEREST_CYCLE) / (60*60*24);
               }
               else
               {
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 10000 * secondsLeft) / (60*60*24);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 10000 * (_now - _start)) / (60*60*24);
        }

    }
    
    function _tokenPrice() public view returns(uint256) {
       return oldctr.tokenPrice();
    }

    function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(_amt*1e6);
    }
    
    function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        require(msg.sender == owner, "onlyOwner");
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }

}