//SourceUnit: TWOxTron.sol

/* * * * * * * * * * * * * * * * * * * * * * * * ABOUT 2xTron * * *  * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *   2xTron — cryptocurrency-based investment platform that operates on TRON smart-contract
 *   Verified, audited, safe and authorized
 *   Developed with a support Troner.Space team
 *   All other platforms with the same contract code are FAKE!
 *
 * * * * * * * * * * * * * * * * * * * * * * * * * INFORMATION * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *  Website: https://www.2xtron.com/
 *  Telegram News and Support in English: @ https://t.me/en2xtron
 *  Telegram News and Support in Russian: @ https://t.me/ru2xtron
 *  E-mail: troner.project@gmail.com
 *
 * * * * * * * * * * * * * * * * * * * * * * * * USAGE INSTRUCTION * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet or Klever.
 *   2) Send any TRX amount using our website invest button or Tronscan "Write Contract" feature.
 *      Do not send coin directly on contract address!
 *   3) Wait for your earnings.
 *   4) Withdraw earnings any time using our website "Withdraw" button or Tronscan "Withdraw" feature.
 *
 *   For a complete tutorial you can watch instructional videos on the website: https://www.2xtron.com/how
 *
 * * * * * * * * * * * * * * * * * * * * * * * INVESTMENT CONDITIONS * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *   - Basic interest rate: +2.02% every 24 hours or +0.0842% an hour .
 *   - Minimal deposit: 100 TRX, no maximum limit.
 *   - Total income: 200% (deposit included).
 *   - Earn daily, withdraw any time.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * AFFILIATE PROGRAM * * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *   - 3-level referral commission: 5% - 3% - 2%
 *   - Auto-refback function.
 *
 * * * * * * * * * * * * * * * * * * * * * * * * FUNDS DISTRIBUTION * * * * * * * * * * * * * * * * * * * * * * * * * *
 *
 *   - 75% Platform main balance, participants payouts.
 *   - 10% Affiliate program bonuses.
 *   - 1%  Technical support, administrators, moderators and support team salary (PROJECT_FEE).
 *   - 4%  Development of future projects (PROJECT_FEE).
 *   - 10% Marketing expenses (MARKETING_FEE).
 *
 * * * * * * * * * * * * * * * * * * * *  * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 */

pragma solidity 0.5.10;

contract TWOxTron {
    using SafeMath for uint;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 100 trx;
    uint constant public USER_PERCENT_RATE = 202;
    uint[] public REFERRAL_PERCENTS = [500, 300, 200];
    uint constant public MARKETING_FEE = 1000;
    uint constant public PROJECT_FEE = 500;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public TIME_STEP = 1 days;

    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;

    address payable public marketingAddress;
    address payable public fundAddress;

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
        uint24[3] refs;
        uint16 rbackPercent;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address payable marketingAddr, address payable fundAddr) public {
        require(!isContract(marketingAddr) && !isContract(fundAddr));
        marketingAddress = marketingAddr;
        fundAddress = fundAddr;
        contractPercent = USER_PERCENT_RATE;
    }

    function invest(address referrer) public payable {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(msg.value >= INVEST_MIN_AMOUNT, "Minimum deposit amount 100 TRX");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        uint marketingFee = msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint projectFee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        marketingAddress.transfer(marketingFee);
        fundAddress.transfer(projectFee);

        emit FeePayed(msg.sender, marketingFee.add(projectFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        uint refbackAmount;
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

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

        user.deposits.push(Deposit(uint64(msg.value), 0, uint64(refbackAmount), uint32(block.timestamp)));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits++;

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint totalAmount;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(USER_PERCENT_RATE).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(USER_PERCENT_RATE).div(PERCENTS_DIVIDER))
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

    function getUserAvailable(address userAddress) public view returns (uint) {
        User storage user = users[userAddress];

        uint totalDividends;
        uint dividends;

        for (uint i = 0; i < user.deposits.length; i++) {

            if (uint(user.deposits[i].withdrawn) < uint(user.deposits[i].amount).mul(2)) {

                if (user.deposits[i].start > user.checkpoint) {

                    dividends = (uint(user.deposits[i].amount).mul(USER_PERCENT_RATE).div(PERCENTS_DIVIDER))
                        .mul(block.timestamp.sub(uint(user.deposits[i].start)))
                        .div(TIME_STEP);

                } else {

                    dividends = (uint(user.deposits[i].amount).mul(USER_PERCENT_RATE).div(PERCENTS_DIVIDER))
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
            amount = amount.add(uint(user.deposits[i].withdrawn)).add(uint(user.deposits[i].refback));
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

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = USER_PERCENT_RATE;
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint16, uint16, uint64, uint24[3] memory) {
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