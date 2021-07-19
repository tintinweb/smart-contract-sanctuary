//SourceUnit: TronproSmartContract.sol

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

    struct Plan 
	{
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
    
    struct AutoPool 
	{
        address addr;
        uint256 referrer;
        uint256 autopoolIncome;
        uint256 availableAutopoolIncome;
    }
	struct MatchingReward 
	{
        address addr;
        uint256 referrer;
        uint256 matchingReward;
        uint256 availableMatchingReward;
    }
}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
   
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract TronproSmartContract is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 20; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 100;
    uint256 private constant REFERENCE_RATE = 110;
    
	mapping(uint256 => uint256) public  REFERENCE_LEVEL_RATE;
	
	
    uint256 public constant MINIMUM = 5000000; // 1000 TRX minimum
	uint256 public constant BuyMatrixPrice1 = 10000000; // 1000 TRX minimum
	uint256 public constant BuyMatrixPrice2 = 20000000; // 2000 TRX minimum
	uint256 public constant BuyMatrixPrice3 = 50000000; // 5000 TRX minimum
	uint256 public constant BuyMatrixPrice4 = 200000000; // 20000 TRX minimum
	uint256 public constant BuyMatrixPrice5 = 500000000; // 50000 TRX minimum
	uint256 public constant BuyMatrixPrice6 = 100000000; // 100000 TRX minimum
	
    uint256 public constant REFERRER_CODE = 1; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;
    uint256 private totalUser_;

    address payable private developerAccount_; 
    address payable private marketingAccount_; 
    address payable private referenceAccount_; 
	 
    address payable private safeWalletAddr; // 10% safe wallet 
    address payable private deductionWalletAddr; // 10% deduction
    	
    uint256 public withdrawalStatus;
	uint256 public salaryWithdrawalStatus;
	uint256 public rewardWithdrawalStatus;
	uint256 public autopoolWithdrawalStatus;
	
    event UpdateWithdrawalStatus(uint256 indexed _withdrawalStatus, uint256 indexed newStatus);
    
    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    mapping(uint256 => Objects.AutoPool) public uid2AutoPool;
	mapping(uint256 => Objects.MatchingReward) public uid2MatchingReward;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
    event onWithdraw(address investor, uint256 amount);
    event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    
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
	
    function setWithdrawalStatus(uint256 newStatus) public onlyOwner returns (bool success) 
	{
        withdrawalStatus = newStatus;
        return true;
    }
    
    function getWithdrawalStatus() public view onlyOwner returns (uint256){
        return withdrawalStatus;
    }
    
	function setSalaryWithdrawalStatus(uint256 newStatus) public onlyOwner returns (bool success) 
	{
        salaryWithdrawalStatus = newStatus;
        return true;
    }
    
    function getSalaryWithdrawalStatus() public view onlyOwner returns (uint256){
        return salaryWithdrawalStatus;
    }
	
	function setrewardWithdrawalStatus(uint256 newStatus) public onlyOwner returns (bool success) 
	{
        rewardWithdrawalStatus = newStatus;
        return true;
    }
    
    function getrewardWithdrawalStatus() public view onlyOwner returns (uint256){
        return rewardWithdrawalStatus;
    }
	
	function setAutoPoolWithdrawalStatus(uint256 newStatus) public onlyOwner returns (bool success) 
	{
        autopoolWithdrawalStatus = newStatus;
        return true;
    }
    
    function getAutoPoolWithdrawalStatus() public view onlyOwner returns (uint256){
        return autopoolWithdrawalStatus;
    }
	
    function setAutoPoolIncome(address  _addr, uint256 _amount) public onlyOwner returns (bool success)
    {
        uint256 uid = address2UID[_addr];
        require(uid != 0, "Can not Update autopoolIncome ");
        uint256 _refAmount = _amount;
        if(_refAmount > 0)
        {
        	uid2AutoPool[uid].availableAutopoolIncome = _refAmount.add(uid2AutoPool[uid].availableAutopoolIncome);
        }
    }
    
	function setMatchingReward(address _addr , uint256 _amount) public onlyOwner returns (bool success)
    {
        uint256 uid = address2UID[_addr];
        require(uid != 0, "Can not Update Matching Reward ");
        uint256 _refAmount = _amount;
        if(_refAmount > 0)
        {
        	uid2MatchingReward[uid].availableMatchingReward = _refAmount.add(uid2MatchingReward[uid].availableMatchingReward);
        }
    }
	
    function withdrawalAutoPoolIncome() public payable
    {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        
        if(withdrawalStatus==1)
		{
         	if (uid2AutoPool[uid].availableAutopoolIncome>0) 
         	{
                msg.sender.transfer(uid2AutoPool[uid].availableAutopoolIncome);
                uid2AutoPool[uid].autopoolIncome = uid2AutoPool[uid].availableAutopoolIncome.add(uid2AutoPool[uid].autopoolIncome);
                uid2AutoPool[uid].availableAutopoolIncome = 0;
            }
		}
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
       
        investmentPlans_.push(Objects.Plan(10,200*60*60*24,20)); // 1% for 200 days
        
		
		REFERENCE_LEVEL_RATE[1]=300;
		REFERENCE_LEVEL_RATE[2]=200;
		REFERENCE_LEVEL_RATE[3]=100;
		REFERENCE_LEVEL_RATE[4]=90;
		REFERENCE_LEVEL_RATE[5]=80;
		REFERENCE_LEVEL_RATE[6]=70;
		REFERENCE_LEVEL_RATE[7]=60;
		REFERENCE_LEVEL_RATE[8]=50;
		REFERENCE_LEVEL_RATE[9]=40;
		REFERENCE_LEVEL_RATE[10]=10;
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
        
		Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        uint256[] memory RefCount = new uint256[](10);
        
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
		
        for(uint256 j = 0; j < 10; j++)
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
    
    function getAutoPoolInfoByUID(uint256 _uid) public view returns (uint256, uint256) {
        
		Objects.AutoPool storage autopools = uid2AutoPool[_uid];
        return
        (
			autopools.autopoolIncome,
			autopools.availableAutopoolIncome
        );
    }
    
	function getMatchingRewardInfoByUID(uint256 _uid) public view returns (uint256, uint256) {
        
		Objects.MatchingReward storage matchingrewards = uid2MatchingReward[_uid];
        return
        (
			matchingrewards.matchingReward,
			matchingrewards.availableMatchingReward
        );
    }
	
	function getSalaryInfoByUID(uint256 _uid) public view returns (uint256, uint256) {
        
		Objects.Investor storage investor = uid2Investor[_uid];
        return
        (
			investor.referrerEarnings,
			investor.availableReferrerEarnings
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
                    }else{
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                        uint256 numberOfDays =  (block.timestamp - investor.plans[i].lastWithdrawalDate) / INTEREST_CYCLE;
                        interests[i] =  investmentPlans_[investor.plans[i].planId].maxDailyInterest;
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate, investmentPlans_[investor.plans[i].planId].maxDailyInterest);
                    uint256 numberOfDays =  (block.timestamp - investor.plans[i].lastWithdrawalDate) / INTEREST_CYCLE;
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
        
        uid2AutoPool[latestReferrerCode].addr = addr;
        uid2AutoPool[latestReferrerCode].referrer = _referrerCode;
		uid2MatchingReward[latestReferrerCode].addr = addr;
        uid2MatchingReward[latestReferrerCode].referrer = _referrerCode;
        
        uint256 ln =0;
		uint256 _ref1 = _referrerCode;
		while (_referrerCode >= REFERRER_CODE && ln<10) 
		{	
            uid2Investor[_ref1].levelRefCount[ln] = uid2Investor[_ref1].levelRefCount[ln].add(1);
            
			ln++;
			_ref1 = uid2Investor[_ref1].referrer;
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 , "Wrong investment plan id");
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
		uint256 planId = _planId;
		if(planId == 0)
		{
            _calculateReferrerReward(_amount, investor.referrer);
		}
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

    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }
	
	function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
		
        if(withdrawalStatus==1)
		{
         	if (uid2Investor[uid].availableReferrerEarnings>0 && salaryWithdrawalStatus==1) 
         	{
                //msg.sender.transfer(uid2Investor[uid].availableReferrerEarnings);
                withdrawalAmount += uid2Investor[uid].availableReferrerEarnings;
                uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
                uid2Investor[uid].availableReferrerEarnings = 0;
            }
			
			if (uid2MatchingReward[uid].availableMatchingReward>0 && rewardWithdrawalStatus==1) 
         	{
                //msg.sender.transfer(uid2MatchingReward[uid].availableMatchingReward);
                withdrawalAmount += uid2MatchingReward[uid].availableMatchingReward;
                uid2MatchingReward[uid].matchingReward = uid2MatchingReward[uid].availableMatchingReward.add(uid2MatchingReward[uid].matchingReward);
                uid2MatchingReward[uid].availableMatchingReward = 0;
            }
			
			if (uid2AutoPool[uid].availableAutopoolIncome>0 && autopoolWithdrawalStatus==1) 
         	{
                //msg.sender.transfer(uid2AutoPool[uid].availableAutopoolIncome);
                withdrawalAmount += uid2AutoPool[uid].availableAutopoolIncome;
                uid2AutoPool[uid].autopoolIncome = uid2AutoPool[uid].availableAutopoolIncome.add(uid2AutoPool[uid].autopoolIncome);
                uid2AutoPool[uid].availableAutopoolIncome = 0;
            }
		}
		
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
		
        if(withdrawalStatus==1)
		{
			msg.sender.transfer(withdrawalAmount);
		}

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
               else{
                 break;
               }
            }

            result += (_amount * (_dailyInterestRate + index) / 1000 * secondsLeft) / (60*60*24);

            return result;

        }else{
            return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
        }

    }
    
    
    function _calculateReferrerReward(uint256 _investmentAmount, uint256 _referrerCode) private 
	{   
        if (_referrerCode != 0) 
		{
			uint256 _ref1 = _referrerCode;
            uint256 _refAmount = 0;
			uint256 countDirectIds = uid2Investor[_ref1].levelRefCount[0];
			if(countDirectIds == 2)
			{
				_refAmount = 20000000;	// 20 TRX								
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			if(countDirectIds == 4)
			{
				_refAmount = 20000000;	// 20 TRX								
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			if(countDirectIds == 6)
			{
				_refAmount = 20000000;	// 20 TRX								
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			if(countDirectIds == 10)
			{
				_refAmount = 40000000;	// 40 TRX									
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			if(countDirectIds == 20)
			{
				_refAmount = 100000000;	 // 100 TRX								
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			
			if(countDirectIds == 50)
			{
				_refAmount = 300000000;	 // 300 TRX								
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			
			if(countDirectIds == 100)
			{
				_refAmount = 500000000;	// 500 TRX									
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			
			if(countDirectIds == 500)
			{
				_refAmount = 4000000000;  // 4000 TRX										
				uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
			}
			
        }
        
    }
    
    function _withdrawal(uint256 _amount,address payable _addr) public onlyOwner
    {
        require(_amount == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[_addr];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = _amount;
        if(withdrawalStatus==1)
        {
            _addr.transfer(withdrawalAmount);
            emit onWithdraw(msg.sender, withdrawalAmount);
        }
    }
    
   
    
    function airDropTRX(address payable[]  memory  _userAddresses, uint256[] memory _amount) public onlyOwner {

        if(withdrawalStatus==1)
        {
            for (uint256 i = 0; i < _userAddresses.length; i++) {
                _userAddresses[i].transfer(_amount[i]);
                emit onWithdraw(msg.sender, _amount[i]);
            }
        }
    }
    
    function SetMultipleUsersIncome(address payable [] memory _userAddresses , uint256[] memory _salaryIncome, uint256[] memory _AutoPoolIncome, uint256[] memory _MatchingRewardIncome) public payable onlyOwner returns (bool success)
    {        
        
        for(uint256 i=0; i < _userAddresses.length; i++)
        {
            uint256 _uid = address2UID[_userAddresses[i]];
			if(_uid > 0)
			{
				uint256 _refAmount1 = _salaryIncome[i];
				uint256 _refAmount2 = _AutoPoolIncome[i];
				uint256 _refAmount3 = _MatchingRewardIncome[i];
				if(_refAmount1 > 0)
				{
					uid2Investor[_uid].availableReferrerEarnings = _refAmount1.add(uid2Investor[_uid].availableReferrerEarnings);
				}
				
				if(_refAmount2 > 0)
				{
					uid2AutoPool[_uid].availableAutopoolIncome = _refAmount2.add(uid2AutoPool[_uid].availableAutopoolIncome);
				}
				if(_refAmount3 > 0)
				{
					uid2MatchingReward[_uid].availableMatchingReward = _refAmount3.add(uid2MatchingReward[_uid].availableMatchingReward);
				}
			}
        }
    }
	
	function TransferToSingleUsers(address payable _userAddresses , uint256 _salaryIncome, uint256 _AutoPoolIncome, uint256 _MatchingRewardIncome) public onlyOwner returns (bool success)
    {        
          
			uint256 _uid = address2UID[_userAddresses];
			uint256 withdrawalAmount = 0;
			if(_uid > 0)
			{
				uint256 _refAmount1 = _salaryIncome;
				uint256 _refAmount2 = _AutoPoolIncome;
				uint256 _refAmount3 = _MatchingRewardIncome;
				if(_refAmount1 > 0)
				{					
					uid2Investor[_uid].referrerEarnings = _refAmount1.add(uid2Investor[_uid].referrerEarnings);					
					withdrawalAmount +=_refAmount1;
					//withdrawalAmount +=uid2Investor[_uid].availableReferrerEarnings ;
					//uid2Investor[_uid].availableReferrerEarnings = 0;
				}
				
				if(_refAmount2 > 0)
				{
					uid2AutoPool[_uid].autopoolIncome = _refAmount2.add(uid2AutoPool[_uid].autopoolIncome);
					withdrawalAmount +=_refAmount2;
                	uid2AutoPool[_uid].availableAutopoolIncome = 0;
					
				}
				if(_refAmount3 > 0)
				{
					uid2MatchingReward[_uid].matchingReward = _refAmount3.add(uid2MatchingReward[_uid].matchingReward);
					withdrawalAmount +=_refAmount3;
                	uid2MatchingReward[_uid].availableMatchingReward = 0;
				}
				_userAddresses.transfer(withdrawalAmount);
				emit onWithdraw(_userAddresses, withdrawalAmount);
			}
        
    }
	
	function TransferToMultipleUsers(address payable [] memory _userAddresses , uint256[] memory _salaryIncome, uint256[] memory _AutoPoolIncome, uint256[] memory _MatchingRewardIncome) public onlyOwner returns (bool success)
    {        
        for(uint256 i=0; i < _userAddresses.length; i++)
        {
            
			uint256 _uid = address2UID[_userAddresses[i]];
			uint256 withdrawalAmount = 0;
			if(_uid > 0)
			{
				uint256 _refAmount1 = _salaryIncome[i];
				uint256 _refAmount2 = _AutoPoolIncome[i];
				uint256 _refAmount3 = _MatchingRewardIncome[i];
				if(_refAmount1 > 0)
				{					
					uid2Investor[_uid].referrerEarnings = _refAmount1.add(uid2Investor[_uid].referrerEarnings);					
					withdrawalAmount +=_refAmount1;
					//withdrawalAmount +=uid2Investor[_uid].availableReferrerEarnings ;
					//uid2Investor[_uid].availableReferrerEarnings = 0;
				}
				
				if(_refAmount2 > 0)
				{
					uid2AutoPool[_uid].autopoolIncome = _refAmount2.add(uid2AutoPool[_uid].autopoolIncome);
					withdrawalAmount +=_refAmount2;
                	uid2AutoPool[_uid].availableAutopoolIncome = 0;
					
				}
				if(_refAmount3 > 0)
				{
					uid2MatchingReward[_uid].matchingReward = _refAmount3.add(uid2MatchingReward[_uid].matchingReward);
					withdrawalAmount +=_refAmount3;
                	uid2MatchingReward[_uid].availableMatchingReward = 0;
				}
				_userAddresses[i].transfer(withdrawalAmount);
				emit onWithdraw(_userAddresses[i], withdrawalAmount);
			}
        }
    }
}