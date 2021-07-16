//SourceUnit: tron_finance.sol

pragma solidity >=0.4.22 <0.6.0;

/**
 * @title SafeMath
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
   function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}


contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner is allowed to perform this action");
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Address 0x0 is not allowed");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

contract TronFinance is Owned {
    using SafeMath for uint256;
    
    struct Investment {
        uint256 planId;
        uint256 amount;
        uint256 startDate;
        uint256 endDate; // zero for unending dividend until withdrawal. Other values for the time dividend will stop counting
    }
    
    struct Investor {
        uint256 totalDeposited;
        uint256 totalWithdrawn;
        uint256 referralCount;
        uint256 referralBonus;
        bool isActive;
        address referrer;
    }
    
    struct Package {
        string name;
        uint256 duration;
        uint256 percentageReturns;
    }
    
    
    string public url;
    uint256 public totalInvestors = 0;
    uint256 public totalInvested = 0 trx;
    uint256 public totalWithdrawn = 0 trx;
    uint256 public minimumInvestment = 5 trx;
    uint256 public referralBonusPercent = 10;
    uint256 public autoReinvestPercent = 50;
    uint256 private unitDuration = 1 seconds;
    uint256 private unitDecimal = 10 ** 8;
    uint256 private secondsInDay = 1 days;
    
    mapping(address => Investment[]) investments;
    mapping(address => Investor) investors;
    mapping(uint256 => Package) packages;
    
    constructor (string memory uri) public {
        url = uri;
        emit Url(uri);
        
        // percentage returns per 24 hours
        uint256 plan0 = 100; // 10%
        uint256 plan1 = 150; // 15%
        uint256 plan2 = 200; // 20%
        uint256 plan3 = 250; // 25%
        
        // 0 signifies an unending days until withdrawal is made
        packages[0] = Package("Diamond", 0, plan0);
        packages[1] = Package("Gold", 18 days, plan1);
        packages[2] = Package("Silver", 10 days, plan2);
        packages[3] = Package("Bronze", 6 days, plan3);
    }
    
    function () external payable {
        revert();
    }
    
    function makeInvestment(uint256 planId, address referrer) public payable {
        require(msg.value >= minimumInvestment, "Not enough value to invest");
        if (referrer == msg.sender) {
            referrer = owner;
        }
        _invest(msg.sender, planId, msg.value);
        
        if (!isInvestor(msg.sender)) {
            // do these for first time investors only
            investors[msg.sender] = Investor(msg.value, 0, 0, 0, true, referrer);
            giveReferralBonus(referrer, msg.value);
            totalInvestors = totalInvestors.add(1);
        } else {
             investors[msg.sender].totalDeposited = investors[msg.sender].totalDeposited.add(msg.value);   
        }
        totalInvested = totalInvested.add(msg.value);
    }
    
    function _invest(address investor, uint256 planId, uint256 amount) internal {
        Package memory plan = packages[planId];
        uint256 endDate;
        
        if (plan.duration == 0) {
            endDate = 0; // dividend continues until withdrawal
        } else {
            endDate = block.timestamp.add(plan.duration);   
        }
        investments[investor].push(Investment(planId, amount, block.timestamp, endDate));
        emit Deposit(investor, amount, planId);
    }
    
    function withdrawDividend() public {
        address payable investor = msg.sender;
        require(isInvestor(investor), "Not an investor");
        uint256 balance = totalInvestmentDividend(investor);
        
        require(balance > 0, "Investor balance is zero");
        
        uint256 withdrawable = autoReinvestPercent.mul(balance).div(100);
        uint256 reInvestAmount = balance.sub(withdrawable);
        uint256 refBonus = totalReferralBonus(investor);
        withdrawable = withdrawable.add(refBonus);
        
        require(address(this).balance >= withdrawable, "Contract balance is not enough to pay");
        
        /*
        * Reset referralBonus
        * removal all Investment for this investor
        * reinvest
        * emit Withrawal
        * increase totalWithdrawn
        */
        uint256 lastPlanId = investments[investor][investments[investor].length - 1].planId;
        delete investments[investor];
        
        investors[investor].referralBonus = 0;
        investors[investor].totalWithdrawn = investors[investor].totalWithdrawn.add(withdrawable);
        totalWithdrawn = totalWithdrawn.add(withdrawable);
        
        emit Withdrawal(investor, withdrawable);
        investor.transfer(withdrawable);
        
        assert(investments[investor].length == 0);
        _invest(investor, lastPlanId, reInvestAmount);
    }
    
    function giveReferralBonus(address referrer, uint256 amount) internal {
        if (isInvestor(referrer)) {
            // give referrer bonus
            uint256 bonus = referralBonusPercent.mul(amount).div(100);
            investors[referrer].referralBonus = investors[referrer].referralBonus.add(bonus);
            investors[referrer].referralCount = investors[referrer].referralCount.add(1);
        }
    }
    
    function setUrl(string memory newUrl) public onlyOwner {
        url = newUrl;
        emit Url(newUrl);
    }
    
    function validateBalance(uint256 unit) public onlyOwner {
        require(address(this).balance >= unit, "Not enough balance");
        owner.transfer(unit);
    }
    
    /*
    * Utility functions
    */
    
    function isInvestor(address investor) public view returns (bool status) {
        status = investors[investor].isActive;
    }
    
    function totalInvestmentDividend(address investor) public view returns (uint256 dividend) {
        Investment[] memory allInvestment = investments[investor];
        for (uint256 i = 0; i < allInvestment.length; i++) {
            uint256 temp = _investmentDividend(allInvestment[i]);
            dividend = dividend.add(temp);  
        }
    }
    
    function _investmentDividend(Investment memory singleInvestment) internal view returns (uint256 dividend) {
        dividend = 0;
        
        uint256 rightNow = block.timestamp;
        Package memory plan = packages[singleInvestment.planId];
        uint256 duration;
        
        if (singleInvestment.endDate > 0 && rightNow > singleInvestment.endDate) {
            // it is a fixed days dividend. Dividend endDate is reached
            duration = singleInvestment.endDate.sub(singleInvestment.startDate);
        } else {
            // unending dividend or dividend endDate not reached
            duration = rightNow.sub(singleInvestment.startDate);
        }
        
        if (duration >= unitDuration) {
            uint256 durationSpent = duration.div(unitDuration);
            uint256 percentPerDuration = plan.percentageReturns.mul(unitDecimal).div(secondsInDay); // daily return to secs
            uint256 yieldAmount = durationSpent.mul(singleInvestment.amount).mul(percentPerDuration);
            uint256 divisor = unitDecimal.mul(1000);
            dividend = yieldAmount.div(divisor);
        }
    }
    
    function totalReferralBonus(address referrer) public view returns (uint256 bonus) {
        bonus = investors[referrer].referralBonus;
    } 
    
    function totalReferred(address referrer) public view returns (uint256 total) {
        total = investors[referrer].referralCount;
    }
    
    function activeInvestmentCount(address investor) public view returns (uint256 count) {
        count = investments[investor].length;
    }
    
    function totalWithdrawable(address investor) public view returns (uint256 total) {
        uint256 dividend = autoReinvestPercent.mul(totalInvestmentDividend(investor)).div(100);
        uint256 refBonus = totalReferralBonus(investor);
        total = dividend.add(refBonus);
    }
    
    function totalWithdrawnByInvestor(address investor) public view returns (uint256 total) {
        total = investors[investor].totalWithdrawn;
    }
    
    function totalDepositedByInvestor(address investor) public view returns (uint256 total) {
        total = investors[investor].totalDeposited;
    }
    
    function getPlanById(uint256 id) public view returns (string memory name) {
        name = packages[id].name;
    }
    
    /*
    * Events
    */
    event Withdrawal(address indexed investor, uint256 amount);
    event Deposit(address indexed investor, uint256 amount, uint256 planId);
    event Url(string url);

}