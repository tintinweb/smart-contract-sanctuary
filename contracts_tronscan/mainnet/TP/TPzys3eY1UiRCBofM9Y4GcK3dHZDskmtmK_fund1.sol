//SourceUnit: fund1.sol

/*
 * 
 *   Fund1 - investment platform based on TRX blockchain smart-contract technology. Safe and legit!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐  
 *   │   Website: https://fund1.etheron.club                                 │
 *   │                                                                       │  
 *   │   Telegram Support Group Eng: https://t.me/FundOfficial               │
 *   │   Telegram Support Group Rus: https://t.me/FundOfficialRu             │
 *   │                                                                       │
 *   │   Telegram info bot : https://t.me/fund_1_bot                         │
 *   │                                                                       │
 *   │   Telegram info channel: https://t.me/smartcontractsEtherOnClub       │
 *   └───────────────────────────────────────────────────────────────────────┘ 
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like Tronlink, Klever or TokenPocket.
 *   2) Send any TRX amount (300 TRX minimum) using our website "Invest" button.
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button.
 *
 *   [INVESTMENT CONDITIONS]
 * 
 *   - Basic interest rate: +1.5% every 24 hours
 *   - Minimal deposit: 300 TRX, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 * 
 *   [AFFILIATE PROGRAM]
 *
 *   Share your referral link with your partners and get additional bonuses.
 *   - Referral reward from 10% + 0.1% for every 10,000 TRX in the volume of your structure, but not more than 15%
 */

pragma solidity 0.5.10;

contract fund1 {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 300 trx;
    uint256 constant public DAILY_PERCENT = 15;
    uint256 constant public REF_BASE_PERCENT = 100;
    uint256 constant public REF_STEP = 10000 trx;
    uint256 constant public MARKETING_FEE = 50;
    uint256 constant public PROJECT_FEE = 50;
    uint256 constant public PERCENTS_DIVIDER = 1000;
    uint256 constant public TIME_STEP = 1 days;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;
    uint256 public maxDeposit;

    address payable public marketingAddress;
    address payable public projectAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        address[] referrals;
        uint256 checkpoint;
        address referrer;
        uint256 bonus;
        uint256 bonusPaid;
        uint256 involved;
    }

    mapping (address => User) internal users;

    event NewDeposit(address indexed user, uint256 amount, bool newbie);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
    }

    function invest(address referrer) public payable {
        require(msg.value >= INVEST_MIN_AMOUNT);
        marketingAddress.transfer(msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER));
        projectAddress.transfer(msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER));
        bool newbie;

        User storage user = users[msg.sender];

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
            users[referrer].referrals.push(msg.sender);
        }

        if (user.referrer != address(0)) {
            uint256 userBonusRate = getUserBonusRate(user.referrer);
            uint256 amount = msg.value.mul(userBonusRate).div(PERCENTS_DIVIDER);
            users[user.referrer].bonus = users[user.referrer].bonus.add(amount);
            emit RefBonus(user.referrer, msg.sender, amount);
            users[user.referrer].involved = users[user.referrer].involved.add(msg.value);
        }

        user.involved = user.involved.add(msg.value);

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            newbie = true;
        }

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);
        if (maxDeposit < msg.value) maxDeposit = msg.value;

        emit NewDeposit(msg.sender, msg.value, newbie);
    }

    function withdraw() public {
        User storage user = users[msg.sender];
        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (user.deposits[i].amount.mul(DAILY_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.deposits[i].amount.mul(DAILY_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            totalAmount = totalAmount.add(referralBonus);
            user.bonusPaid = user.bonusPaid.add(referralBonus);
            user.bonus = 0;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getUserBonusRate(address userAddress) public view returns (uint256) {
        uint256 percent = users[userAddress].involved.div(REF_STEP).add(REF_BASE_PERCENT);
        if (percent > 150) percent = 150;
        return percent;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (user.deposits[i].amount.mul(DAILY_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (user.deposits[i].amount.mul(DAILY_PERCENT).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                totalDividends = totalDividends.add(dividends);
            }

        }
        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns(uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns(address) {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns(uint256) {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) public view returns(uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            if (user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2)) {
                return true;
            }
        }
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint256, uint256, uint256) {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].withdrawn, user.deposits[index].start);
    }

    function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function getCommonStats() external view returns(uint256[6] memory) {
        return ([address(this).balance, totalUsers, totalInvested, totalWithdrawn, totalDeposits, maxDeposit]);
    }

    function getUserStats(address userAddress) external view returns(uint256[8] memory) {
        return ([
            getUserBonusRate(userAddress),
            getUserDividends(userAddress),
            users[userAddress].bonus,
            users[userAddress].deposits.length,
            getUserTotalDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            users[userAddress].bonusPaid,
            users[userAddress].referrals.length
        ]);
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