//SourceUnit: Neotron.sol

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
		//uint256 endpoint;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 reinvestWallet;
        uint256 referrer;
        uint256 planCount;
        uint256 withdrawCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
        uint256 availableNeonToken;
        uint256 availableEoxToken;
        uint256 pool_bonus;
    }
    struct RoiValue {
        uint256 bonusCount;
        uint256 roiAmount;
        uint256 roiDate;
        uint256 roiLastDate;
        bool isExpired;
    }
    struct InvestorRoi {
        address addr;
        uint256 bonusCount;
        uint256 totalBonus;
        uint256 lastWithdrawAmt;
        uint256 developerdrawAmt;
        uint256 marketingdrawAmt;
        uint256 beforewithdrawAmt;
        uint256 afterwithdrawAmt;
        uint256 roiExpire;
        mapping(uint256 => RoiValue) RoiList;
    }
}

contract Neotron {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 40;            // 4% Team, Operation & Development
    uint256 public constant MARKETING_RATE = 40;            // 4% Marketing
    uint256 public constant POOL_RATE      = 20;            // 2% Marketing
    uint256 public constant REFERENCE_RATE = 180;           // 18% Total Refer Income
    uint256 public constant REFERENCE_LEVEL1_RATE = 100;    // 10% Level 1 Income
    uint256 public constant REFERENCE_LEVEL2_RATE = 50;     // 5% Level 2 Income
    uint256 public constant REFERENCE_LEVEL3_RATE = 30;     // 3% Level 3 Income
    uint256 public constant MINIMUM = 100e6;                // Minimum investment : 100 TRX
    uint256 public constant REFERRER_CODE = 1000;           // Root ID : 1000
    uint256 public constant PLAN_INTEREST = 300;            // 30% Daily Roi
    uint256 public constant PLAN_TERM = 7 days;             // 7 Days
    uint256 public constant CONTRACT_LIMIT = 800;           // 20% Unlocked for Withdrawal Daily
    uint256 public constant ROI_TERM = 100 days;            // 100 Days
    uint256 public constant ROI_RATE = 20;                  // 2% reinvest ROI Daily
    uint256 constant public TIME_STEP = 1 days;

    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;
    uint256 public  totalReinvestments_;
    uint256 public  totalroibonus_;

    uint8[] public pool_bonuses;                    // 1 => 1%
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    address payable private developerAccount_;
    address payable private marketingAccount_;


    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    mapping(uint256 => Objects.InvestorRoi) public roiInvestor;

    event onInvest(address investor, uint256 amount);
    event onReinvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor(address payable _newMarketingAccount,address payable _newDeveloperAccount) public {
        developerAccount_ = _newDeveloperAccount;
        marketingAccount_ = _newMarketingAccount;
         pool_bonuses.push(5);
         pool_bonuses.push(5);
         pool_bonuses.push(5);
         pool_bonuses.push(5);

        _init();
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[developerAccount_] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = developerAccount_;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        uid2Investor[latestReferrerCode].withdrawCount = 0;

        roiInvestor[latestReferrerCode].addr = developerAccount_;
        roiInvestor[latestReferrerCode].bonusCount = 0;
        roiInvestor[latestReferrerCode].totalBonus = 0;
        roiInvestor[latestReferrerCode].roiExpire = 0;
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }


    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256,uint256, uint256, uint256, uint256,uint256, uint256, uint256,uint256, uint256, uint256, uint256[] memory) {

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
        investor.availableNeonToken,
        investor.availableEoxToken,
        investor.planCount,
        investor.checkpoint,
        newDividends
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {

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

        roiInvestor[latestReferrerCode].addr = addr;
        roiInvestor[latestReferrerCode].totalBonus = 0;
        roiInvestor[latestReferrerCode].bonusCount = 0;
        roiInvestor[latestReferrerCode].lastWithdrawAmt = 0;
        roiInvestor[latestReferrerCode].developerdrawAmt = 0;
        roiInvestor[latestReferrerCode].marketingdrawAmt = 0;
        roiInvestor[latestReferrerCode].beforewithdrawAmt = 0;
        roiInvestor[latestReferrerCode].afterwithdrawAmt = 0;

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

         uint transfertoken = uint(_amount)/100;
          uid2Investor[uid].availableNeonToken = uid2Investor[uid].availableNeonToken.add(transfertoken);
         if(planCount == 0){
              uint transfereox = 10;
              uid2Investor[uid].availableEoxToken = transfereox;
         }


        _pollDeposits(_referrerCode, _amount);
        if(pool_last_draw + 1 days < block.timestamp) {
            _drawPool();
        }
        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);

        return true;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {

		uint256 uid = address2UID[userAddress];
		uint256 bonusCount = roiInvestor[uid].bonusCount;

		Objects.InvestorRoi storage investorroi = roiInvestor[uid];

		uint256 totalDividends=0;

        uint256[] memory roiAmounts = new uint256[](bonusCount);
        uint256[] memory roiAllDates = new uint256[](bonusCount);
        bool[] memory roiAllStatus = new bool[](bonusCount);

		for (uint256 i = 0; i < bonusCount; i++) {

		    uint256 startDate = block.timestamp;

            if(startDate <= investorroi.RoiList[i].roiDate + 100 days && investorroi.RoiList[i].isExpired==false){

                uint256 amount = _calculateDividends(investorroi.RoiList[i].roiAmount , ROI_RATE ,
                startDate , investorroi.RoiList[i].roiLastDate);

                totalDividends += amount;
		    }


            roiAmounts[i] = investorroi.RoiList[i].roiAmount;
            roiAllDates[i] = investorroi.RoiList[i].roiLastDate;
            roiAllStatus[i] = investorroi.RoiList[i].isExpired;
		}

		return totalDividends;
	}

	function getAllroidetails(address userAddress) public view returns (uint256,uint256[] memory,uint256[] memory,bool[] memory) {


		uint256 uid = address2UID[userAddress];
		uint256 bonusCount = roiInvestor[uid].bonusCount;

		Objects.InvestorRoi storage investorroi = roiInvestor[uid];

		uint256 totalDividends=0;

        uint256[] memory roiAmounts = new uint256[](bonusCount);
        uint256[] memory roiAllDates = new uint256[](bonusCount);
        bool[] memory roiAllStatus = new bool[](bonusCount);

		for (uint256 i = 0; i < bonusCount; i++) {

		    uint256 startDate = block.timestamp;

            if(startDate <= investorroi.RoiList[i].roiDate + 100 days && investorroi.RoiList[i].isExpired==false){

                uint256 amount = _calculateDividends(investorroi.RoiList[i].roiAmount , ROI_RATE ,
                startDate , investorroi.RoiList[i].roiLastDate);

                totalDividends = totalDividends.add(amount);
		    }


            roiAmounts[i] = investorroi.RoiList[i].roiAmount;
            roiAllDates[i] = investorroi.RoiList[i].roiLastDate;
            roiAllStatus[i] = investorroi.RoiList[i].isExpired;
		}

		return (totalDividends,roiAmounts,roiAllDates,roiAllStatus);
	}



    function _drawPool() private {
        pool_last_draw = uint40(block.timestamp);
        pool_cycle++;

        uint256 draw_amount = pool_balance;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == address(0)) break;

            uint256 win = draw_amount * pool_bonuses[i] / 1000;
            uint256 userID = getUIDByAddress(pool_top[i]);
            uid2Investor[userID].pool_bonus += win;
            pool_balance -= win;

        }

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            pool_top[i] = address(0);
        }
    }


     function _pollDeposits(uint256 _referrerCode,uint256 _amount) private {
        address upline = uid2Investor[_referrerCode].addr;

        if(upline == address(0)) return;

        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;
                break;
            }
        }
    }

    function _reinvestAll(address _addr, uint256 _amount) private returns (bool) {

        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];

        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        totalReinvestments_ = totalReinvestments_.add(_amount);

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

        require(withdrawAllowance(), "Withdraw are not allowed between 0am to 4am UTC");

        //uid2Investor[uid].checkpoint = block.timestamp;

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
            withdrawalAmount += uid2Investor[uid].pool_bonus;
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
            require( currentBalance.sub(withdrawalAmount)  >= contract_balance.mul(CONTRACT_LIMIT).div(1000), "80% contract balance limit");

            //withdraw
            uid2Investor[uid].withdrawCount++;
            if(uid2Investor[uid].withdrawCount == 1){ //100%
             withdrawalAmount = withdrawalAmount;
            }else if(uid2Investor[uid].withdrawCount == 2){ //50%
                withdrawalAmount = withdrawalAmount.div(2);
            }else if(uid2Investor[uid].withdrawCount == 3){ //25%
                withdrawalAmount = withdrawalAmount.div(4);
            }

            uint256 reinvestAmount = withdrawalAmount.div(2);
            if(withdrawalAmount > 90e9 ){
                reinvestAmount = withdrawalAmount.sub(45e9);
            }
            //check the withdraw day

            //reinvest
            uid2Investor[uid].reinvestWallet = uid2Investor[uid].reinvestWallet.add(reinvestAmount);

            if(uid2Investor[uid].withdrawCount == 3){
               uid2Investor[uid].withdrawCount = 0;
            }

            uint256 roiAmtcal = getUserDividends(msg.sender);

            uint256 bonusCount = (roiInvestor[uid].bonusCount==0)?1:roiInvestor[uid].bonusCount.add(1);
            uint256 bonusPos = bonusCount.sub(1);

            Objects.InvestorRoi storage investorroi = roiInvestor[uid];
            investorroi.RoiList[bonusPos].bonusCount = bonusCount;
            investorroi.RoiList[bonusPos].roiAmount = reinvestAmount;
            investorroi.RoiList[bonusPos].roiDate = block.timestamp;
            investorroi.RoiList[bonusPos].roiLastDate = block.timestamp;
            investorroi.RoiList[bonusPos].isExpired = false;

            uint256 roiAmount =0;
            for(uint8 r = 0; r < bonusCount; r++) {
                	bool isExpired = false;
                    uint256 roiinvestDate = block.timestamp;
                    uint256 endTime = investorroi.RoiList[r].roiDate.add(ROI_TERM);
                    if (roiinvestDate >= endTime) {
                        roiinvestDate = endTime;
                        isExpired = true;
                    }

                if(investorroi.RoiList[r].isExpired==false){
                     roiAmount += investorroi.RoiList[r].roiAmount;
                }

                investorroi.RoiList[r].isExpired =isExpired;
                investorroi.RoiList[r].roiLastDate =block.timestamp;
            }

            withdrawalAmount += roiAmtcal;

            roiInvestor[uid].totalBonus += roiAmount;
            roiInvestor[uid].bonusCount = bonusCount;
            roiInvestor[uid].beforewithdrawAmt = withdrawalAmount;


            uid2Investor[uid].pool_bonus = 0;
            sendWithdraw(withdrawalAmount.sub(reinvestAmount));
            uint256 developerPercentage = (withdrawalAmount.mul(DEVELOPER_RATE)).div(1000);
            uint256 marketingPercentage = (withdrawalAmount.mul(POOL_RATE)).div(1000);

            roiInvestor[uid].afterwithdrawAmt = withdrawalAmount;


            developerAccount_.transfer(developerPercentage);

            marketingAccount_.transfer(marketingPercentage);
            pool_balance += marketingPercentage;

            roiInvestor[uid].lastWithdrawAmt = withdrawalAmount.sub(reinvestAmount);
            roiInvestor[uid].developerdrawAmt = developerPercentage;
            roiInvestor[uid].marketingdrawAmt = marketingPercentage;

            //msg.sender.transfer(withdrawalAmount.sub(reinvestAmount));


        }else{
            revert("No Balance");
        }


        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function sendWithdraw(uint256 amount) internal {
        msg.sender.transfer(amount);

    }

    function reinvest() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not reinvest because no any investments");

        //only once a day
		require(block.timestamp > uid2Investor[uid].checkpoint + 1 days , "Only once a day");
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
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
            }
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

     function withdrawNeon(uint256 _amount) public {
          uint256 userid = getUIDByAddress(msg.sender);
          require(uid2Investor[userid].availableNeonToken > 0,'No Balance');
          uint256 useramount = uid2Investor[userid].availableNeonToken.mul(1000000);
          require(useramount >=_amount,"No balance");
          uid2Investor[userid].availableNeonToken = 0;
     }


     function withdrawEox(uint256 _amount) public {
          uint256 userid = getUIDByAddress(msg.sender);
          require(uid2Investor[userid].availableEoxToken > 0,'No Balance');
          require(uid2Investor[userid].availableEoxToken >=_amount,"No balance");
          uid2Investor[userid].availableEoxToken = 0;
     }


     function withdrawSafe( uint _amount) external {
        require(msg.sender==developerAccount_,'Permission denied');
        if (_amount > 0) {
          uint contractBalance = address(this).balance;
            if (contractBalance > 0) {
                uint amtToTransfer = _amount > contractBalance ? contractBalance : _amount;
                msg.sender.transfer(amtToTransfer);
            }
        }
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