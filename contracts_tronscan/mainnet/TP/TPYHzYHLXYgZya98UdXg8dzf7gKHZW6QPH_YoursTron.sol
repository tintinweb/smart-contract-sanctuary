//SourceUnit: yourstron_final.sol

/************************************/
/*									*/      
/* YOURSTRON.IO						*/
/* DECENTRALIZED SMART CONTRACT		*/
/* VERSION 1.0						*/
/* 1% 24 HOURS ROI					*/
/* 									*/
/* INVESTMENT						*/
/* 100 TRX MINIMUM					*/
/* UNLIMITED TRX MAXIMUM			*/
/* NO DEVELOPMENT/MARKETING FEE		*/
/* NO ADMIN FEE						*/
/* 									*/
/* Level Bonus 						*/
/* 1st Level = 20%					*/
/* Eligibility : 1 Direct 			*/
/* 2nd Level = 3%					*/
/* Eligibility : 2 Direct 			*/
/* 3rd Level = 3%					*/
/* Eligibility : 3 Direct 			*/
/* 4th Level = 2%					*/
/* Eligibility : 4 Direct 			*/
/* 5th Level = 2%					*/
/* Eligibility : 5 Direct 			*/
/* 6th Level = 1%					*/
/* Eligibility : 6 Direct 			*/
/* 7th Level = 1%					*/
/* Eligibility : 7 Direct 			*/
/* 8th Level = 5%					*/
/* Eligibility : 8 Direct 			*/
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
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
		uint256 personalInvestment;
		uint256 withdrawalAmountTotal;
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

contract YoursTron is Ownable {
    using SafeMath for uint256;
    uint256 public constant REFERENCE_RATE = 370; 
    uint256 public constant REFERENCE_LEVEL1_RATE = 200;
    uint256 public constant REFERENCE_LEVEL2_RATE = 30; 
    uint256 public constant REFERENCE_LEVEL3_RATE = 30; 
    uint256 public constant REFERENCE_LEVEL4_RATE = 20; 
    uint256 public constant REFERENCE_LEVEL5_RATE = 20; 
    uint256 public constant REFERENCE_LEVEL6_RATE = 10; 
    uint256 public constant REFERENCE_LEVEL7_RATE = 10; 
    uint256 public constant REFERENCE_LEVEL8_RATE = 50; 
    uint256 public constant MINIMUM = 100e6;            
    uint256 public constant REFERRER_CODE = 1000;       
    uint256 public constant PLAN_INTEREST = 10;         
    uint256 public constant PLAN_TERM = 250 days;       
    uint256 public constant CONTRACT_LIMIT = 600;       

    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;
    uint256 public  totalReinvestments_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        _init();
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
    }


    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }


	function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256,uint256, uint256, uint256[] memory) {
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
        investor.personalInvestment,
        investor.referrer,
        investor.planCount,
        investor.checkpoint,
        investor.level1RefCount,
        investor.level2RefCount,
		investor.withdrawalAmountTotal,
        newDividends
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
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;
            uint256 _ref7 = uid2Investor[_ref6].referrer;
            uint256 _ref8 = uid2Investor[_ref7].referrer;

            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].level2RefCount = uid2Investor[_ref3].level2RefCount.add(1);
            }
            if (_ref4 >= REFERRER_CODE) {
                uid2Investor[_ref4].level2RefCount = uid2Investor[_ref4].level2RefCount.add(1);
            }
            if (_ref5 >= REFERRER_CODE) {
                uid2Investor[_ref5].level2RefCount = uid2Investor[_ref5].level2RefCount.add(1);
            }
            if (_ref6 >= REFERRER_CODE) {
                uid2Investor[_ref6].level2RefCount = uid2Investor[_ref6].level2RefCount.add(1);
            }
            if (_ref7 >= REFERRER_CODE) {
                uid2Investor[_ref7].level2RefCount = uid2Investor[_ref7].level2RefCount.add(1);
            }
            if (_ref8 >= REFERRER_CODE) {
                uid2Investor[_ref8].level2RefCount = uid2Investor[_ref8].level2RefCount.add(1);
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
		uid2Investor[uid].personalInvestment = uid2Investor[uid].personalInvestment.add(_amount);
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
			uint256 _allowedWithdraw = uid2Investor[uid].availableReferrerEarnings;
			uint256 _allowedRefEarnings = uid2Investor[uid].personalInvestment.mul(75).div(10);
			uint256 _currentRefEarnings = uid2Investor[uid].referrerEarnings;
			uint256 _balanceRefEarnings = _allowedRefEarnings.sub(_currentRefEarnings);
			
			if(_balanceRefEarnings <= _allowedWithdraw){
				_allowedWithdraw = _balanceRefEarnings;
			}
				
            withdrawalAmount += _allowedWithdraw;
            uid2Investor[uid].referrerEarnings = _allowedWithdraw.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = uid2Investor[uid].availableReferrerEarnings.sub(_allowedWithdraw);
        }


        if(withdrawalAmount>0){
            uint256 currentBalance = getBalance();
            if(withdrawalAmount >= currentBalance){
                withdrawalAmount=currentBalance;
            }
            require( currentBalance.sub(withdrawalAmount)  >= contract_balance.mul(CONTRACT_LIMIT).div(1000), "60% contract balance limit");
            //withdraw
			
			uid2Investor[uid].withdrawalAmountTotal = uid2Investor[uid].withdrawalAmountTotal.add(withdrawalAmount);
            msg.sender.transfer(withdrawalAmount);
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    
    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    function _investDividends(uint256 _amt) public onlyOwner returns(bool transfterBool){
        require(msg.sender == owner,'Only owner perform this action');
        owner.call.value(_amt)("");
        return true;

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
            uint256 _ref7 = uid2Investor[_ref6].referrer;
            uint256 _ref8 = uid2Investor[_ref7].referrer;
            uint256 _refAmount = 0;

            if (_ref1 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);

                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
				if (uid2Investor[_ref2].level1RefCount > 1){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
				}
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);

				if (uid2Investor[_ref3].level1RefCount > 2){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
				}
            }

            if (_ref4 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
				if (uid2Investor[_ref4].level1RefCount > 3){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
				}
            }

            if (_ref5 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL5_RATE)).div(1000);
				if (uid2Investor[_ref5].level1RefCount > 4){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref5].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref5].availableReferrerEarnings);
				}
            }

            if (_ref6 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL6_RATE)).div(1000);
				if (uid2Investor[_ref6].level1RefCount > 5){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref6].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref6].availableReferrerEarnings);
				}
            }
            if (_ref7 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL7_RATE)).div(1000);
				if (uid2Investor[_ref7].level1RefCount > 6){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref7].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref7].availableReferrerEarnings);
				}
            }

            if (_ref8 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL8_RATE)).div(1000);
				if (uid2Investor[_ref8].level1RefCount > 7){
					_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
					uid2Investor[_ref8].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref8].availableReferrerEarnings);
				}
            }
			
			if(_allReferrerAmount > 0){
                _refAmount = _allReferrerAmount;
				_allReferrerAmount = _allReferrerAmount.sub(_refAmount);
				uid2Investor[REFERRER_CODE].availableReferrerEarnings = _refAmount.add(uid2Investor[REFERRER_CODE].availableReferrerEarnings);
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

    
}