//SourceUnit: mlm.sol

/*
 *
 *   TronSmart - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *   The only official platform of original TronSmart team! All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronsmart.live                                     │
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any TRX amount (100 TRX minimum) using our website invest button
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.05% for every 12 hours without withdraw
 *   - Contract total amount bonus: +0.05% for every 1,000,00 TRX on platform address balance
 *
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 *
 *   - Total deposits daily limits: every 12 hours contract upgrade its total limit
 *   - Total limit grow every 24 hours. The more days contract works, the more total limit
 *   - When total limit filled, nobody can make a new deposit, you should wait for limit update
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 10-level referral commission: 4% - 2% - 1% - 0.5% - 0.5% - 0.5% - 0.5% - 0.5% - 0.5% - 0.5%
 *   - Auto-refback function
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 79.5% Platform main balance, participants payouts
 *   - 8% Advertising and promotion expenses
 *   - 10.5% Affiliate program bonuses
 *   - 2% Support work, technical functioning, administration fee
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TronSmart Ltd (#13059361)
 *   - Company status: https://find-and-update.company-information.service.gov.uk/company/13059361
 *   - Certificate of incorporation: https://tronsmart.live/assets/files/tronsmartcert.pdf
 *
 *
 */

pragma solidity 0.5.10;

contract TronSmart {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [400, 200, 100, 50, 50, 50, 50, 50, 50, 50];
    uint constant public MARKETING_FEE = 800;
    uint constant public PROJECT_FEE = 200;
    uint constant public MAX_CONTRACT_PERCENT = 1000;
    uint constant public MAX_HOLD_PERCENT = 500;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 1000000 trx;
    uint constant public TIME_STEP = 1 days;
    uint[] public DAY_LIMIT_STEPS = [100000 trx, 200000 trx, 500000 trx, 1000000 trx, 2000000 trx];

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

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint availableLimit = getCurrentHalfDayAvailable();
        require(availableLimit > 0, "Deposit limit exceed");

        uint msgValue = msg.value;

        if (msgValue > availableLimit) {
            msg.sender.transfer(msgValue.sub(availableLimit));
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

        marketingAddress.transfer(marketingFee);
        projectAddress.transfer(projectFee);

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
                        msg.sender.transfer(refbackAmount);

                        emit RefBack(upline, msg.sender, refbackAmount);

                        amount = amount.sub(refbackAmount);
                    }

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

        user.deposits.push(Deposit(uint64(msgValue), 0, uint64(refbackAmount), uint32(block.timestamp)));

        totalInvested = totalInvested.add(msgValue);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, msgValue);
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

                user.deposits[i].withdrawn = uint64(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
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

    function setRefback(uint16 rbackPercent) public {
        require(rbackPercent <= 10000);

        User storage user = users[msg.sender];

        if (user.deposits.length > 0) {
            user.rbackPercent = rbackPercent;
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = address(this).balance;
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

                /// no update of withdrawn because that is view function

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
        } else if (currentDay >= 2 && currentDay <= 5) {
            limit = DAY_LIMIT_STEPS[1].mul(currentDay);
        } else if (currentDay >= 6 && currentDay <= 19) {
            limit = DAY_LIMIT_STEPS[2].mul(currentDay.sub(3));
        } else if (currentDay >= 20 && currentDay <= 49) {
            limit = DAY_LIMIT_STEPS[3].mul(currentDay.sub(11));
        } else if (currentDay >= 50) {
            limit = DAY_LIMIT_STEPS[4].mul(currentDay.sub(30));
        }

        return limit;
    }

    function getCurrentHalfDayTurnover() public view returns (uint) {
        return turnover[getCurrentHalfDay()];
    }

    function getCurrentHalfDayAvailable() public view returns (uint) {
        return getCurrentDayLimit().sub(getCurrentHalfDayTurnover());
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

    function getSiteStats() public view returns (uint, uint, uint, uint, uint) {
        return (totalInvested, totalDeposits, address(this).balance, contractPercent, getCurrentHalfDayAvailable());
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
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