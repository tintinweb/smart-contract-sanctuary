//SourceUnit: TronPlace.sol

pragma solidity 0.5.12;


/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library DateTime {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;


    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }
    
    function check(uint sec) public view returns (uint _days) {
        _days = diffDays(block.timestamp , block.timestamp + sec);
    }

}

contract TronPlace {
    using SafeMath for uint256;
    
    struct Deposit {
        uint256 amount;
        uint256 startDate;
        uint256 endDate;
    }
    
    struct Tier {
        string name;
        uint256 price;
        uint8[5] rafPercent;
        uint8 tierPercent;
    }
    
    struct TeamStat {
        uint256 count;
        uint256 invested;
        uint256 withdrawn;
        uint256 withdrawnBonus;
        uint256 tierPurchased;
        uint256 tierPurchasedBonus;
    }
    
    struct Account {
        address referrer;
        address addr;
        Deposit[] deposits;
        string tier;
        uint256 totalInvested;
        uint256 rafBonus;
        uint256 rafTierBonus;
        uint256 totalWithdrawn;
        uint256 lastWithdrawDividendsDate;
        TeamStat[5] teamStat;
    }
    
    address payable appAddress;
    
    mapping(address => Account) public accounts;
    mapping(string => Tier) public tiers;
    uint256 public totalInvested;
    
    
    uint constant START_TS = 1603994400;
    uint constant MIN_DEPOSIT = 500 trx;
    uint constant DEPOSIT_LIFE = 260;
    uint constant PERCENT_PER_DAY = 1;
    uint constant FEE = 10;
    
    event RegistrationEvent(address accountAddr, address referrerAddr);
    event DepositEvent(address accountAddr, uint256 amount, uint startDate, uint endDate);
    event PurchaseTierEvent(address accountAddr, string tierName);
    event WidthdrawEvent(address accountAddr, uint256 amount);
    event RafBonus(address upliner, address referral, uint8 level, uint256 bonus);
    
    constructor () public {
        appAddress = msg.sender;
        tiers['Basic'] = Tier('Basic', 0 trx, [10,8,0,0,0], 15);
        tiers['Entrepreneur'] = Tier('Entrepreneur', 2000 trx, [12,10,5,0,0], 20);
        tiers['Partner'] = Tier('Partner', 5000 trx, [14,12,7,3,0], 25);
        tiers['Boss'] = Tier('Boss', 12000 trx, [16,14,9,5,2], 30);
    }
    
    
    function deposit(address referrerAddress) public payable{
        require(block.timestamp >= START_TS, 'Contract is not launched yet');
        require(msg.value >= MIN_DEPOSIT, 'Less than minimum deposit');
        require(msg.sender != referrerAddress, 'Referrer address should not be the same as deposit address');
        
        Account storage acc = accounts[msg.sender];
        
        acc.referrer = referrerAddress;
        acc.addr = msg.sender;
        
        if(bytes(acc.tier).length == 0) {
            acc.tier = 'Basic';
            emit RegistrationEvent(msg.sender, referrerAddress); 
        }
        
        uint startDate = block.timestamp;
        uint endDate = DateTime.addDays( startDate, DEPOSIT_LIFE);
        acc.deposits.push(Deposit(msg.value,  startDate, endDate));
        acc.totalInvested += msg.value;
        totalInvested += msg.value;
        emit DepositEvent(msg.sender, msg.value, startDate, endDate);
        appAddress.transfer(msg.value.div(100).mul(FEE));
        
        _iterateRaf(acc.referrer, msg.sender, msg.value, _rafInvestedStat);
    }
    
    function purchaseTier(string memory tierName) public payable {
        Tier storage tier = tiers[tierName];
        Tier storage currentTier = tiers[accounts[msg.sender].tier];
        
        uint256 shouldPay = tier.price - currentTier.price;
        
        require(msg.value == shouldPay, 'Invalid send amount for this tier');
        require(hasActiveDeposit(msg.sender), 'You need active deposit');
        
        accounts[msg.sender].tier = tier.name;
        
        totalInvested + msg.value;
        
        
        appAddress.transfer(msg.value.div(100).mul(FEE));
        emit PurchaseTierEvent(msg.sender, tierName);
        
        Account storage acc = accounts[msg.sender];
        if(hasActiveDeposit(acc.referrer)){
            Account storage upliner = accounts[acc.referrer];
            Tier storage referrerTier = tiers[upliner.tier];
            uint256 bonus = msg.value.div(100).mul(referrerTier.tierPercent);
            upliner.rafTierBonus += bonus;
            upliner.teamStat[0].tierPurchased += msg.value;
            upliner.teamStat[0].tierPurchasedBonus += bonus;
            emit RafBonus(upliner.addr, msg.sender, uint8(999), bonus);
        }
        
    }
    
    function withdraw() public {
        Account storage acc = accounts[msg.sender];
        uint256 amount = availableWithdrawAmount(msg.sender);
        
        require(amount > 0, 'Insufficient funds');
        
        msg.sender.transfer(amount);

        acc.totalWithdrawn += amount;
        if(availableDividends(msg.sender) > 0) {
            acc.lastWithdrawDividendsDate = block.timestamp;
        }
        acc.rafBonus = 0;
        acc.rafTierBonus = 0;
        
        emit WidthdrawEvent(msg.sender, amount);
        
        _iterateRaf(acc.referrer, msg.sender, amount, _rafWithdrawBonus);
    }
    
    function getTs() public view returns (uint256){
        return block.timestamp;
    }
    
    function teamStat (address addr) public view returns (uint256[30] memory stats) {
        Account storage acc = accounts[addr];
        
        for(uint8 i = 0; i < acc.teamStat.length; i++) {
            uint8 startIndex = i * 5;
            stats[startIndex] = acc.teamStat[i].count;
            stats[startIndex + 1] = acc.teamStat[i].invested;
            stats[startIndex + 2] = acc.teamStat[i].withdrawn;
            stats[startIndex + 3] = acc.teamStat[i].withdrawnBonus;
            stats[startIndex + 4] = acc.teamStat[i].tierPurchased;
            stats[startIndex + 5] = acc.teamStat[i].tierPurchasedBonus;
        }
    }
    
    function hasActiveDeposit(address addr) public view returns(bool has){
        Account storage acc = accounts[addr];
        for(uint8 i = 0; i < acc.deposits.length; i++){
            if(DateTime.diffDays(block.timestamp, acc.deposits[i].endDate) > 0){
                has = true;
                break;
            }
        }
    }
    
    function availableWithdrawAmount(address addr) public view returns (uint amount) {
        Account storage acc = accounts[addr];
        amount += availableDividends(addr) + acc.rafBonus + acc.rafTierBonus;
        return amount;
    }
    
    function availableDividends(address addr) public view returns (uint amount) {
        Account storage acc = accounts[addr];
    
        
        for(uint8 i = 0; i < acc.deposits.length; i++){
            Deposit storage dep = acc.deposits[i];
            uint start = acc.lastWithdrawDividendsDate > dep.startDate ? acc.lastWithdrawDividendsDate : dep.startDate;
            uint daysDiff = DateTime.diffDays(start, block.timestamp);
            uint dividendsDays = daysDiff > DEPOSIT_LIFE ? DEPOSIT_LIFE : daysDiff;
            
            if(dividendsDays > 0) {
                amount += dep.amount.div(100).mul(dividendsDays * PERCENT_PER_DAY);
            }
        }
    
        
        return amount;
    }

    
    function _iterateRaf(address upLinerAddress, address referralAddress, uint256 value, function (Account storage, uint8, address, uint256, uint8) forEachActiveUpliner) private {
        uint8 level = 0;
        while(upLinerAddress != address(0) && level < 5) {
            Account storage upliner = accounts[upLinerAddress];
            Tier storage tier = tiers[upliner.tier];
            forEachActiveUpliner(upliner, tier.rafPercent[level], referralAddress, value, level);
            upLinerAddress = upliner.referrer;
            level += 1;
        }
    }
    
    function _rafWithdrawBonus(Account storage upliner, uint8 rafPercent, address referralAddress, uint256 value, uint8 level) private {
            uint256 bonus = value.div(100).mul(rafPercent);
            upliner.teamStat[level].withdrawn += value;
            
            
            if(bonus > 0 && hasActiveDeposit(upliner.addr)) {
                upliner.rafBonus += bonus;
                upliner.teamStat[level].withdrawnBonus += bonus;
                emit RafBonus(upliner.addr, referralAddress, level, bonus);
            }
    }
    
    function _rafInvestedStat(Account storage upliner, uint8, address referralAddress, uint256 value, uint8 level) private {
        upliner.teamStat[level].invested += value;
        if(accounts[referralAddress].deposits.length == 1) {
            upliner.teamStat[level].count += 1;
        }
    }
}