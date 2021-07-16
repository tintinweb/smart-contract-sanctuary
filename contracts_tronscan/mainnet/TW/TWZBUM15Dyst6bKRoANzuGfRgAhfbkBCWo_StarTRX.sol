//SourceUnit: StarTRX.sol

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
	
	struct Nonworking {
        address addr;
        uint256 referrer;
        uint256 matchingIncome;
        uint256 availableMatchingIncome;
		uint256 referralMatchingIncome;
        uint256 availableReferralMatchingIncome;
		uint256 royaltyIncome;
        uint256 availableroyaltyIncome;
		uint256 performanceBonus;
		uint256 availablePerformanceBonus;
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

contract StarTRX is Ownable {
    using SafeMath for uint256;
    uint256 private constant INTEREST_CYCLE = 1 days;
    uint256 private constant DEVELOPER_ENTRY_RATE = 20; //per thousand
    uint256 private constant ADMIN_ENTRY_RATE = 100;
    uint256 private constant REFERENCE_RATE = 110;
    
	mapping(uint256 => uint256) public  REFERENCE_LEVEL_RATE;
	
	
    uint256 public constant MINIMUM = 10000000; //minimum investment needed
    uint256 public constant REFERRER_CODE = 1; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;
    uint256 private totalUser_;
	
	uint256 public withdrawalStatus;
    event UpdateWithdrawalStatus(uint256 indexed _withdrawalStatus, uint256 indexed newStatus);

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
	mapping(uint256 => Objects.Nonworking) public uid2nonWorkingIncome;    
    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
    event onWithdraw(address investor, uint256 amount);
	event Multisended(uint256 value , address indexed sender);
    event Airdropped(address indexed _userAddress, uint256 _amount);
    
    
    constructor() public {
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
	
	function setWithdrawalStatus(uint256 newStatus) public onlyOwner returns (bool success) {
        emit UpdateWithdrawalStatus(withdrawalStatus, newStatus);
        withdrawalStatus = newStatus;
        return true;
    }
    
    function getWithdrawalStatus() public view onlyOwner returns (uint256){
        return withdrawalStatus;
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
        
		investmentPlans_.push(Objects.Plan(15,200*60*60*24,15)); // 1.5% per day for 200 days
        investmentPlans_.push(Objects.Plan(20,150*60*60*24,20)); // 2% per day for 200 days
        investmentPlans_.push(Objects.Plan(25,100*60*60*24,25)); // 2.5% per day for 200 days
		
		REFERENCE_LEVEL_RATE[1]=50;
		
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
	
	function getNonworkingInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) 
	{        
		Objects.Nonworking storage nonworking = uid2nonWorkingIncome[_uid];
        return
        (
        nonworking.matchingIncome,
        nonworking.availableMatchingIncome,		
        nonworking.referralMatchingIncome,
        nonworking.availableReferralMatchingIncome,
        nonworking.royaltyIncome,
        nonworking.availableroyaltyIncome,
		nonworking.performanceBonus,
		nonworking.availablePerformanceBonus
        );
    }
	
    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256[] memory, uint256,  uint256[] memory, uint256[] memory) {
        
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
         uint256[] memory RefCount = new uint256[](1);
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
        for(uint256 j = 0; j < 1; j++)
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

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory,uint256[] memory, bool[] memory) 
	{
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
		
	    uid2nonWorkingIncome[latestReferrerCode].addr = addr;
        uid2nonWorkingIncome[latestReferrerCode].referrer = _referrerCode;
        
        uint256 ln =0;
		uint256 _ref1 = _referrerCode;
		while (_referrerCode >= REFERRER_CODE && ln<1) 
		{	
            uid2Investor[_ref1].levelRefCount[ln] = uid2Investor[_ref1].levelRefCount[ln].add(1);
            
			ln++;
			_ref1 = uid2Investor[_ref1].referrer;
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        //require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
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
		
        _calculateReferrerReward(_amount, investor.referrer);

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

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private 
	{
        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) 
		{
			uint256 _ref1 = _referrerCode;           
            uint256 _refAmount = 0;
			uint ln=0;            	
			_refAmount = (_investment.mul(REFERENCE_LEVEL_RATE[ln+1])).div(1000);	
			uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
        }
    }
	
	function SetNonworkingIncome(uint256 _uid, address _addr , uint256 _matchingAmount, uint256 _referralMatchingAmount, uint256 _reward, uint256 _performance) public onlyOwner returns (bool success)
    {
        require(_uid != 0, "Can not Update Non-working Income ");
        uint256 uid = address2UID[_addr];
		uint256 matchingAmount = _matchingAmount;
		uint256 rewards = _reward;
		uint256 referralMatchingAmount = _referralMatchingAmount;
		uint256 performance = _performance;
		
        if(matchingAmount > 0 && uid > 0)
        {
        	uid2nonWorkingIncome[uid].availableMatchingIncome = matchingAmount.add(uid2nonWorkingIncome[uid].availableMatchingIncome);
        }
		
		if(referralMatchingAmount > 0 && uid > 0 )
        {
        	uid2nonWorkingIncome[uid].availableReferralMatchingIncome = referralMatchingAmount.add(uid2nonWorkingIncome[uid].availableReferralMatchingIncome);
        }
		
		if(rewards > 0 && uid > 0)
        {
        	uid2nonWorkingIncome[uid].availableroyaltyIncome = rewards.add(uid2nonWorkingIncome[uid].availableroyaltyIncome);
        }
		if(performance > 0)
		{
			uid2nonWorkingIncome[uid].availablePerformanceBonus = performance.add(uid2nonWorkingIncome[uid].availablePerformanceBonus);
		}
    }
    
    function SetMultipleUsersIncome(uint256[] memory uid, address[] memory _userAddresses , uint256[] memory _matching, uint256[] memory _refmatching, uint256[] memory _rewards, uint256[] memory _performance) public onlyOwner returns (bool success)
    {
        for(uint256 i=0; i < _userAddresses.length; i++)
        {
            uint256 _uid = address2UID[_userAddresses[i]];
            uint256 matching = _matching[i];
			uint256 refmatching = _refmatching[i];
			uint256 rewards = _rewards[i];
			uint256 performance = _performance[i];
            if(matching > 0 && _uid >0)
            {
            	uid2nonWorkingIncome[_uid].availableMatchingIncome = matching.add(uid2nonWorkingIncome[_uid].availableMatchingIncome);
            }
			
			if(refmatching > 0 && _uid >0)
            {
            	uid2nonWorkingIncome[_uid].availableReferralMatchingIncome = refmatching.add(uid2nonWorkingIncome[_uid].availableReferralMatchingIncome);
            }
			
			if(rewards > 0 && _uid >0)
            {
            	uid2nonWorkingIncome[_uid].availableroyaltyIncome = rewards.add(uid2nonWorkingIncome[_uid].availableroyaltyIncome);
            }
			
			if(performance > 0)
			{
				uid2nonWorkingIncome[_uid].availablePerformanceBonus = performance.add(uid2nonWorkingIncome[_uid].availablePerformanceBonus);
			}
        }
    }

	function withdraw() public payable 
	{
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
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
        

        msg.sender.transfer(withdrawalAmount);
		
		if(withdrawalStatus==1)
		{
			if (uid2Investor[uid].availableReferrerEarnings>0) {
				msg.sender.transfer(uid2Investor[uid].availableReferrerEarnings);
				uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
				uid2Investor[uid].availableReferrerEarnings = 0;
			}
			if(uid2nonWorkingIncome[uid].availableMatchingIncome > 0)
			{
				msg.sender.transfer(uid2nonWorkingIncome[uid].availableMatchingIncome);
				uid2nonWorkingIncome[uid].matchingIncome = uid2nonWorkingIncome[uid].availableMatchingIncome.add(uid2nonWorkingIncome[uid].matchingIncome);
				uid2nonWorkingIncome[uid].availableMatchingIncome = 0;
			}
			if(uid2nonWorkingIncome[uid].availableReferralMatchingIncome > 0)
			{
				msg.sender.transfer(uid2nonWorkingIncome[uid].availableReferralMatchingIncome);
				uid2nonWorkingIncome[uid].referralMatchingIncome = uid2nonWorkingIncome[uid].availableReferralMatchingIncome.add(uid2nonWorkingIncome[uid].referralMatchingIncome);
				uid2nonWorkingIncome[uid].availableReferralMatchingIncome = 0;
			}
			if(uid2nonWorkingIncome[uid].availableroyaltyIncome > 0)
			{
				msg.sender.transfer(uid2nonWorkingIncome[uid].availableroyaltyIncome);
				uid2nonWorkingIncome[uid].royaltyIncome = uid2nonWorkingIncome[uid].availableroyaltyIncome.add(uid2nonWorkingIncome[uid].royaltyIncome);
				uid2nonWorkingIncome[uid].availableroyaltyIncome = 0;
			}
			if(uid2nonWorkingIncome[uid].availablePerformanceBonus > 0)
			{
				msg.sender.transfer(uid2nonWorkingIncome[uid].availablePerformanceBonus);
				uid2nonWorkingIncome[uid].performanceBonus = uid2nonWorkingIncome[uid].availablePerformanceBonus.add(uid2nonWorkingIncome[uid].performanceBonus);
				uid2nonWorkingIncome[uid].availablePerformanceBonus = 0;
			}
		}
		
        emit onWithdraw(msg.sender, withdrawalAmount);
    }
}