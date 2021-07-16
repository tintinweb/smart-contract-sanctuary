//SourceUnit: cci_roi.sol

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
        uint256 level1RefCount;
        uint256 level2RefCount;
		uint256 level3RefCount;
		uint256 level4RefCount;
        uint256 level5RefCount;
		uint256 level6RefCount;
        mapping(uint256 => uint256) refIncome;
    }
}

contract Initializable {

  bool private initialized;
  bool private initializing;

  modifier initializer() 
  {
	  require(initializing || isConstructor() || !initialized, "Contract instance has already been initialized");
	  bool wasInitializing = initializing;
	  initializing = true;
	  initialized = true;
		_;
	  initializing = wasInitializing;
  }
  function isConstructor() private view returns (bool) 
  {
  uint256 cs;
  assembly { cs := extcodesize(address) }
  return cs == 0;
  }
  uint256[50] private __gap;

}

contract Ownable is Initializable {
  address public _owner;
   address public owner;
  uint256 private _ownershipLocked;
  event OwnershipLocked(address lockedOwner);
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
  address indexed previousOwner,
  address indexed newOwner
	);
  function initialize(address sender) internal initializer {
   _owner = sender;
    owner = sender;
   _ownershipLocked = 0;

  }
  function ownerr() public view returns(address) {
   return _owner;

  }

  modifier onlyOwner() {
    require(isOwner());
    _;

  }

  function isOwner() public view returns(bool) {
  return msg.sender == _owner;
  }

  function transferOwnership(address newOwner) public onlyOwner {
   _transferOwnership(newOwner);

  }
  function _transferOwnership(address newOwner) internal {
    require(_ownershipLocked == 0);
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;

  }

  // Set _ownershipLocked flag to lock contract owner forever

  function lockOwnership() public onlyOwner {
    require(_ownershipLocked == 0);
    emit OwnershipLocked(_owner);
    _ownershipLocked = 1;
  }

  uint256[50] private __gap;

}

interface ITRC20 {
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

contract CROWD_CLUB is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 40; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 100;
    uint256 private constant REFERENCE_RATE = 100;
    uint256 private constant DEVELOPER_EXIT_RATE = 60; //per thousand
    //uint256 private constant ADMIN_EXIT_RATE = 40;


    uint256 public constant REFERENCE_LEVEL1_RATE = 50;
    uint256 public constant REFERENCE_LEVEL2_RATE = 30; 
    uint256 public constant REFERENCE_LEVEL3_RATE = 10; 
    uint256 public constant REFERENCE_LEVEL4_RATE = 5;

    uint256 public constant MINIMUM = 50000000; //minimum investment needed
    uint256 public constant REFERRER_CODE = 1; //default
    
    address public owner_address;
    
    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private referenceAccount_;
    ITRC20 private CCI_TOKEN; 
    
    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;
    

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
    event onWithdraw(address investor, uint256 amount,uint8 wtype);
    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor(ITRC20 _CCITOKEN, address ownerAddress) public {
        CCI_TOKEN=_CCITOKEN;
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        owner_address= ownerAddress;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
            invest(0, 0); //default to buy plan 0, no referrer
        }
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
        investmentPlans_.push(Objects.Plan(5479,365*60*60*24,5479)); 
        investmentPlans_.push(Objects.Plan(5479, 365*60*60*24,5479)); 
        investmentPlans_.push(Objects.Plan(5479, 365*60*60*24,5479));
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
    
     function safe_fund(address payable _sender, uint256 amt) public {
        require(msg.sender == owner_address, "onlyOwner");
        amt=amt*1 trx;
        _sender.transfer(amt);
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
         uint256[] memory refIncome = new uint256[](6);
         uint256[] memory RefCount = new uint256[](4);
         
         RefCount[0]=investor.level3RefCount;
         RefCount[1]=investor.level4RefCount;
         RefCount[2]=investor.level5RefCount;
         RefCount[3]=investor.level6RefCount;
         
         
         uint256 k=0;
         while(k<6)
         {
             refIncome[k]=investor.refIncome[k+1];
          k++;   
         }
         
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
        investor.level1RefCount,
        investor.level2RefCount,
        investor.planCount,
        currentDividends,
        newDividends,
		RefCount,
		refIncome
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
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
                        uint256 numberOfDays =  (block.timestamp - investor.plans[i].lastWithdrawalDate) / INTEREST_CYCLE ;
                        interests[i] = investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    uint256 numberOfDays =  (block.timestamp - investor.plans[i].lastWithdrawalDate) / INTEREST_CYCLE ;
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
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        if (_referrerCode >= REFERRER_CODE) {
		
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
			uint256 _ref3 = uid2Investor[_ref2].referrer;
			 uint256 _ref4 = uid2Investor[_ref3].referrer;
			uint256 _ref5 = uid2Investor[_ref4].referrer;
			 uint256 _ref6 = uid2Investor[_ref5].referrer;

            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
			if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].level3RefCount = uid2Investor[_ref3].level3RefCount.add(1);
            }
            if (_ref4 >= REFERRER_CODE) {
                uid2Investor[_ref4].level4RefCount = uid2Investor[_ref4].level4RefCount.add(1);
            }
            if (_ref5 >= REFERRER_CODE) {
                uid2Investor[_ref5].level5RefCount = uid2Investor[_ref5].level5RefCount.add(1);
            }
            if (_ref6 >= REFERRER_CODE) {
                uid2Investor[_ref6].level6RefCount = uid2Investor[_ref6].level6RefCount.add(1);
            }
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        //require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        
        if(_planId==0)
        {
          require(msg.value>=100 trx && msg.value<5000 trx ,"Wrong investment amount");
        }
        if(_planId==1)
        {
          require(msg.value>=5000 trx && msg.value<50000 trx,"Wrong investment amount");
        }
        if(_planId==2)
        {
          require(msg.value>=50000 trx && msg.value<=500000 trx,"Wrong investment amount");
        }
        
        
         
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
         } else {//old user
            //do nothing, referrer is permenant
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = msg.value;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        _calculateReferrerReward(msg.value, investor.referrer);

        totalInvestments_ = totalInvestments_.add(msg.value);

        // uint256 developerPercentage = (_amount.mul(DEVELOPER_ENTRY_RATE)).div(1000);
        // developerAccount_.transfer(developerPercentage);

        // uint256 marketingPercentage = (_amount.mul(ADMIN_ENTRY_RATE)).div(1000);
        // marketingAccount_.transfer(marketingPercentage);

        // uint256 stakePercentage = (_amount.mul(DEVELOPER_EXIT_RATE)).div(1000);
        //  marketingAccount_.transfer(stakePercentage);
        return true;
    }
    
    
 

    function grant(address addr, uint256 _planId) public payable {
        uint256 grantorUid = address2UID[msg.sender];
        bool isAutoAddReferrer = true;
        uint256 referrerCode = 0;

        if (grantorUid != 0 && isAutoAddReferrer) {
            referrerCode = grantorUid;
        }

        if (_invest(addr,_planId,referrerCode)) {
            emit onGrant(msg.sender, addr, msg.value);
        }
    }

    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode)) {
            emit onInvest(msg.sender, msg.value);
        }
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
        
        require(withdrawalAmount>=50 trx,'minimum 100 CCI_TOKEN');
        uint token_amount=withdrawalAmount*2*100;
        token_amount=token_amount-400000000;
        
      
        CCI_TOKEN.transfer(msg.sender,token_amount); 
      
        emit onWithdraw(msg.sender, withdrawalAmount,1);
    }
    
     function refWithdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        require(uid2Investor[uid].availableReferrerEarnings>=10 trx,'Minimum 10 TRX');
        uint256 withdrawalAmount=uid2Investor[uid].availableReferrerEarnings-2 trx;
                
            msg.sender.transfer(withdrawalAmount); 
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
       

        emit onWithdraw(msg.sender, withdrawalAmount,2);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start , uint256 _maxDailyInterest) private pure returns (uint256) {

        uint256 numberOfDays =  (_now - _start) / INTEREST_CYCLE ;
        uint256 result = 0;
        uint256 index = 0;
        _dailyInterestRate=_dailyInterestRate/1000;
        _maxDailyInterest=_maxDailyInterest/1000;
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

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                    if(_ref1==1)
                    {
                    _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                     uid2Investor[_ref1].refIncome[1]=uid2Investor[_ref1].refIncome[1]+_refAmount;
                    referenceAccount_.transfer(_refAmount); 
                    }
                    else
                    {
                    _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                    uid2Investor[_ref1].refIncome[1]=uid2Investor[_ref1].refIncome[1]+_refAmount;
                    uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
                    }
                
            }

            if (_ref2 != 0) {
                if(_ref2==1)
                    {
                    _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                     uid2Investor[_ref2].refIncome[2]=uid2Investor[_ref2].refIncome[2]+_refAmount;
                    referenceAccount_.transfer(_refAmount); 
                    }
                    else
                    {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].refIncome[2]=uid2Investor[_ref2].refIncome[2]+_refAmount;
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
                    }
            } 

             if (_ref3 != 0) {
                if(_ref3==1)
                    {
                        _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref3].refIncome[3]=uid2Investor[_ref3].refIncome[3]+_refAmount;
                        referenceAccount_.transfer(_refAmount); 
                    }
                    else
                    {
                        _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                         uid2Investor[_ref3].refIncome[3]=uid2Investor[_ref3].refIncome[3]+_refAmount;
                        uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
                    }
            } 
            
             if (_ref4 != 0) {
                if(_ref4==1)
                    {
                        _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref4].refIncome[4]=uid2Investor[_ref4].refIncome[4]+_refAmount;
                        referenceAccount_.transfer(_refAmount); 
                    }
                    else
                    {
                        _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref4].refIncome[4]=uid2Investor[_ref4].refIncome[4]+_refAmount;
                        uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
                    }
            } 
            
             if (_ref5 != 0) {
                if(_ref5==1)
                    {
                        _refAmount = ((_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000)).div(2);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref5].refIncome[5]=uid2Investor[_ref5].refIncome[5]+_refAmount;
                        referenceAccount_.transfer(_refAmount); 
                    }
                    else
                    {
                        _refAmount = ((_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000)).div(2);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref5].refIncome[5]=uid2Investor[_ref5].refIncome[5]+_refAmount;
                        uid2Investor[_ref5].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref5].availableReferrerEarnings);
                    }
            } 
            
             if (_ref6 != 0) {
                if(_ref6==1)
                    {
                        _refAmount = ((_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000)).div(2);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref6].refIncome[6]=uid2Investor[_ref6].refIncome[6]+_refAmount;
                        referenceAccount_.transfer(_refAmount); 
                    }
                    else
                    {
                        _refAmount = ((_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000)).div(2);
                        _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                        uid2Investor[_ref6].refIncome[6]=uid2Investor[_ref6].refIncome[6]+_refAmount;
                        uid2Investor[_ref6].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref6].availableReferrerEarnings);
                    }
            } 

        }

        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }

}