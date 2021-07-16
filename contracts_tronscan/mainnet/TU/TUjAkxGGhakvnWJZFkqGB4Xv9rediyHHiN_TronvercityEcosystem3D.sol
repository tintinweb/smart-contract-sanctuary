//SourceUnit: Tronvercity3d.sol

/*
*
* TRONVERCITY - investment ecosystem based on TRX verified and audited smart-contracts!
*
* ┌───────────────────────────────────────────────────────────────────────┐
* │ Website: https://tronvercity3d.com                                    │
* │                                                                       │
* │ Support: via Contact Form on website                                  |
* │ Telegram Public Group: https://t.me/tronvercity                       |
* │ Telegram News Channel: https://t.me/tronvercitynews                   |
* |                                                                       |
* |                                                                       |
* | Audit Conclusion (ENG): https://tronvercity3d.com/audit_eng.pdf       |
* └───────────────────────────────────────────────────────────────────────┘
*
* [USAGE INSTRUCTION]
*
* 1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like Banko or TronWallet.
* 2) Send any TRX amount (100 TRX minimum) using our website Invest button.
* 3) Wait for your earnings.
* 4) Withdraw earnings any time using our website "Withdraw" button (in accordance with the AntiPanic mode operating procedure).
*
* [INVESTMENT CONDITIONS]
*
* - Basic interest rate: +3% every 24 hours (+0.125% hourly)
* - Personal hold-bonus: +0.2% for every 24 hours without withdrawal
* - Contract turnover bonus: +0.2% for every 1,000,000 TRX of Total Turnover (deposited + withdrawn) of smart-contract
*  (Contract Bonus not decreasing, but growing up (!) even if contract balance goes down)
*
* - Minimal deposit: 100 TRX, no maximal limit
* - Total income: 200% (deposit included)
* - Earnings every moment
* - Anti-Panic Protection Algorithm
*
* [AFFILIATE PROGRAM]
*
* Share your referral link with your partners and get additional bonuses (you need at least minimal deposit to get this bonuses).
* 3-level referral commission: 5% - 2% - 1%
*
* [FUNDS DISTRIBUTION]
*
* - 82% Platform main balance, participants payouts
* - 8% Advertising and promotion expenses
* - 8% Affiliate program bonuses
* - 2% Administration fee, Support work, technical functioning
*
* ────────────────────────────────────────────────────────────────────────
*
* [LEGAL COMPANY INFORMATION]
*
* - Officially registered company name: TRONVERCITY LIMITED (#13101401)
* - Company status: https://beta.companieshouse.gov.uk/company/13101401
* - Certificate of incorporation: https://tronvercity3d.com/img/cert.pdf
*
* [SMART-CONTRACT AUDITION AND SAFETY]
*
* - Audited by independent company Telescr.in (https://telescr.in)
* - Audition certificate: https://tronvercity3d.com/audit.pdf & on Auditor Website
*
*/

pragma solidity 0.5.10;

contract TronvercityEcosystem3D {
    using SafeMath for uint256;

    uint256 constant public INVEST_MIN_AMOUNT = 100 trx;
    uint256 constant public DEPOSITS_MAX = 100;
    uint256 constant public BASE_PERCENT = 300;
    uint256[] public REFERRAL_PERCENTS = [500, 200, 100];
    uint256 constant public MARKETING_PERCENT = 800;
    uint256 constant public PROJECT_PERCENT = 200;
    uint256 constant public PERCENTS_DIVIDER = 10000;
    uint256 constant public CONTRACT_STEP = 1000000 trx;
    uint256 constant public TIME_STEP = 1 days;
    uint256 constant public MAX_BLOCK_TIME = 2 days;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public marketingAddress;
    address payable public projectAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        uint256 blockremoval;
        uint256 bonus;
        address referrer;
        uint32 refs1;
        uint32 refs2;
        uint32 refs3;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address payable marketingAddr, address payable projectAddr) public {
        require(!isContract(marketingAddr) && !isContract(projectAddr));
        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
    }

    function invest(address referrer) public payable {
        User storage user = users[msg.sender];

        require(!isContract(msg.sender) && msg.sender == tx.origin);
        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit 100 TRX");
        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits per address");

        uint256 marketingFee = msg.value.mul(MARKETING_PERCENT).div(PERCENTS_DIVIDER);
        marketingAddress.transfer(marketingFee);

        uint256 projectFee = msg.value.mul(PROJECT_PERCENT).div(PERCENTS_DIVIDER);
        projectAddress.transfer(projectFee);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
                    address(uint160(upline)).transfer(amount);

                    if (i == 0) {
                        users[upline].refs1++;
                    } else if (i == 1) {
                        users[upline].refs2++;
                    } else if (i == 2) {
                        users[upline].refs3++;
                    }

                    users[upline].bonus = users[upline].bonus.add(amount);

                    emit RefBonus(upline, msg.sender, i, amount);

                    upline = users[upline].referrer;
                } else break;
            }

        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers++;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(msg.value, 0, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits++;

        emit NewDeposit(msg.sender, msg.value);

    }

    function withdraw() public {
        User storage user = users[msg.sender];

        if (user.blockremoval != 0) {
            require(now > user.blockremoval, "Wait till withdrawal block end");
        }

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);

                }

                if (user.deposits[i].withdrawn.add(dividends) > user.deposits[i].amount.mul(2)) {
                    dividends = (user.deposits[i].amount.mul(2)).sub(user.deposits[i].withdrawn);
                }

                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(dividends);
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        uint256 nextBlockRemovalTime = now.sub(user.checkpoint);
        if (nextBlockRemovalTime > MAX_BLOCK_TIME) {
            nextBlockRemovalTime = MAX_BLOCK_TIME;
        }
        user.blockremoval = now.add(nextBlockRemovalTime);

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);

        totalWithdrawn = totalWithdrawn.add(totalAmount);

        emit Withdrawn(msg.sender, totalAmount);

    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractRate() public view returns (uint256) {
        uint256 contractPercent = (totalInvested.add(totalWithdrawn)).div(CONTRACT_STEP);
        return BASE_PERCENT.add(contractPercent.mul(20));
    }

    function getUserPercentRate(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 contractRate = getContractRate();
        if (isActive(userAddress)) {
            uint256 timeMultiplier = (now.sub(user.checkpoint)).div(TIME_STEP).mul(20);
            return contractRate.add(timeMultiplier);
        } else {
            return contractRate;
        }
    }

    function getUserAvailable(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {

            if (user.deposits[i].withdrawn < user.deposits[i].amount.mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);

                } else {

                    dividends = (user.deposits[i].amount.mul(userPercentRate).div(PERCENTS_DIVIDER))
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

    function isActive(address userAddress) public view returns (bool) {
        User storage user = users[userAddress];

        return (user.deposits.length > 0) && user.deposits[user.deposits.length-1].withdrawn < user.deposits[user.deposits.length-1].amount.mul(2);
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

        uint256 amount = user.bonus;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].withdrawn);
        }

        return amount;
    }

    function getUserBlockRemovalTime(address userAddress) public view returns(uint256) {
        return users[userAddress].blockremoval;
    }

    function getUserLastDepositDate(address userAddress) public view returns(uint256) {
        User storage user = users[userAddress];

        if (user.deposits.length > 0) {
            return user.deposits[user.deposits.length-1].start;
        }
    }

    function getSiteStats() public view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        return (totalUsers, totalInvested, totalWithdrawn, totalDeposits, getContractBalance(), getContractRate());
    }

    function getUserStats(address userAddress) public view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 percent = getUserPercentRate(userAddress);
        uint256 available = getUserAvailable(userAddress);
        uint256 blockRemoval = getUserBlockRemovalTime(userAddress);
        uint256 withdrawn = getUserTotalWithdrawn(userAddress);
        uint256 checkpoint = getUserCheckpoint(userAddress);

        return (percent, available, blockRemoval, withdrawn, checkpoint);
    }

    function getUserDepStats(address userAddress) public view returns (uint256, uint256, uint256) {
        uint256 depositsAmount = getUserAmountOfDeposits(userAddress);
        uint256 depositsTotal = getUserTotalDeposits(userAddress);
        uint256 lastDeposit = getUserLastDepositDate(userAddress);

        return (depositsAmount, depositsTotal, lastDeposit);
    }

    function getUserRefStats(address userAddress) public view returns (address, uint32, uint32, uint32) {
        User storage user = users[userAddress];

        return (user.referrer, user.refs1, user.refs2, user.refs3);
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