/**
 *Submitted for verification at BscScan.com on 2021-10-05
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.7.6;

contract BNBNXT {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 0.025 ether;
    uint256 public constant BASE_PERCENT = 500; // 5% per day
    uint256[] public REFERRAL_PERCENTS = [600, 200, 150, 100, 50];
    uint256 public constant MARKETING_FEE = 400;
    uint256 public constant PROJECT_FEE = 600;
    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant MAX_USERS_BONUS = 500; //5%
    uint256 public constant MAX_HOLD_BONUS = 200; // 2%
    uint256 public constant TIME_STEP = 1 days;
    uint256 public LAUNCH_TIME;

    uint256 public constant LIMIT1 = 2.5 ether;
    uint256 public constant LIMIT2 = 6.25 ether;
    uint256 public constant LIMIT3 = 12.5 ether;
    uint256 public constant LIMIT4 = 25 ether;
    uint256 public constant LIMIT5 = 50 ether;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public marketingAddress;
    address payable public projectAddress;
    address payable public wfeeAddress;
    

    struct Deposit {
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address payable referrer;
        uint256 bonus;
        uint256 ref_avaliable;
        uint256 id;
        uint256 returnedDividends;
        uint256 available;
        uint256 withdrawn;
        uint256 ref_1;
        uint256 ref_2;
        uint256 ref_3;
        uint256 ref_4;
        uint256 ref_5;
        bool hasUsersBonus;
    }

    mapping(address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    modifier beforeStarted() {
        require(block.timestamp >= LAUNCH_TIME, "!beforeStarted");
        _;
    }

    constructor(address payable marketingAddr, address payable projectAddr,address payable wfeeAddr) {
        require(!isContract(marketingAddr), "!marketingAddr");
        require(!isContract(projectAddr), "!projectAddr");
        require(!isContract(wfeeAddr), "!wfeeAddr");

        marketingAddress = marketingAddr;
        projectAddress = projectAddr;
        wfeeAddress = wfeeAddr;
        LAUNCH_TIME = 1633407802;
    }

    function invest(address payable referrer) public payable beforeStarted() {
        require(msg.value >= INVEST_MIN_AMOUNT, "!INVEST_MIN_AMOUNT");

        marketingAddress.transfer(
            msg.value.mul(MARKETING_FEE).div(PERCENTS_DIVIDER)
        );
        projectAddress.transfer(
            msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER)
        );
        emit FeePayed(
            msg.sender,
            msg.value.mul(MARKETING_FEE.add(PROJECT_FEE)).div(PERCENTS_DIVIDER)
        );

        User storage user = users[msg.sender];

        if (
            user.referrer == address(0) &&
            referrer != msg.sender
        ) {
            user.referrer = referrer;
        }

        if (user.referrer != address(0)) {
            address payable upline = user.referrer;
            for (uint256 i = 0; i < 5; i++) {
                if (upline != address(0)) {
                    uint256 amount =
                        msg.value.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );

                    users[upline].ref_avaliable = users[upline].ref_avaliable.add(amount);
                    users[upline].bonus = users[upline].bonus.add(amount);

                    if (i == 0) {
                        users[upline].ref_1 = users[upline].ref_1.add(1);
                    }
                    if (i == 1) {
                        users[upline].ref_2 = users[upline].ref_2.add(1);
                    }
                    if (i == 2) {
                        users[upline].ref_3 = users[upline].ref_3.add(1);
                    }
                    if (i == 3) {
                        users[upline].ref_4 = users[upline].ref_4.add(1);
                    }
                    if (i == 4) {
                        users[upline].ref_5 = users[upline].ref_5.add(1);
                    }

                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            totalUsers = totalUsers.add(1);
            user.id = totalUsers;
            user.hasUsersBonus = true;
            user.returnedDividends = 0;
            user.withdrawn = 0;
            user.ref_1 = 0;
            user.ref_2 = 0;
            user.ref_3 = 0;
            user.ref_4 = 0;
            user.ref_5 = 0;
            emit Newbie(msg.sender);
        }

        user.available = user.available.add(msg.value.mul(25).div(10));

        user.deposits.push(Deposit(msg.value, block.timestamp));

        totalInvested = totalInvested.add(msg.value);
        totalDeposits = totalDeposits.add(1);

        emit NewDeposit(msg.sender, msg.value);
    }

    function withdraw() public beforeStarted() {
        require(
            getTimer(msg.sender) < block.timestamp,
            "withdrawal is available only once every 24 hours"
        );

        User storage user = users[msg.sender];

        uint256 userPercentRate = getUserPercentRate(msg.sender);

        uint256 totalAmount;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalAmount = totalAmount.add(dividends);
            }
        }

        totalAmount = totalAmount.add(user.returnedDividends);
        totalAmount = totalAmount.add(user.ref_avaliable);

        if (user.available < totalAmount) {
            totalAmount = user.available;
        }

        uint256 limit = getUserLimit(msg.sender);

        if (totalAmount > limit) {
            uint256 dif = totalAmount.sub(limit);

            user.returnedDividends = dif;
            totalAmount = limit;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 wfee = totalAmount.mul(5).div(100); //5% withdraw fee;
        totalAmount = totalAmount.sub(wfee);

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        wfeeAddress.transfer(wfee);
        msg.sender.transfer(totalAmount);

        user.available = user.available.sub(totalAmount);
        user.withdrawn = user.withdrawn.add(totalAmount);
        user.ref_avaliable = 0;
        totalWithdrawn = totalWithdrawn.add(totalAmount);

        if (isActive(msg.sender)) {
            user.hasUsersBonus = false;
        } else {
            user.id = totalUsers;
        }

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getContractUsersRate(address userAddress) public view returns (uint256)
    {
        // +0.1% per 100 users
        User storage user = users[userAddress];

        uint256 userID = user.id;

        uint256 contractUsersPercent = totalUsers.sub(userID).div(10); // +0.1% per day

        if (contractUsersPercent > MAX_USERS_BONUS) {
            contractUsersPercent = MAX_USERS_BONUS;
        }

        if (user.hasUsersBonus) {
            return BASE_PERCENT.add(contractUsersPercent);
        } else {
            return BASE_PERCENT;
        }
    }

    function getUserPercentRate(address userAddress) public view returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 contractUsersRate = getContractUsersRate(userAddress);
        if (isActive(userAddress)) {
            uint256 timeMultiplier =
                (block.timestamp.sub(user.checkpoint)).div(TIME_STEP).mul(10); // +0.1% per day

            if (timeMultiplier > MAX_HOLD_BONUS) {
                timeMultiplier = MAX_HOLD_BONUS;
            }

            return contractUsersRate.add(timeMultiplier);
        } else {
            return contractUsersRate;
        }
    }

    function getUserDividends(address userAddress) public view returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 userPercentRate = getUserPercentRate(userAddress);

        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (user.available > 0) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(TIME_STEP);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PERCENTS_DIVIDER
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(TIME_STEP);
                }

                totalDividends = totalDividends.add(dividends);

                /// no update of withdrawn because that is view function
            }
        }
        totalDividends = totalDividends.add(user.returnedDividends);

        if (totalDividends > user.available) {
            totalDividends = user.available;
        }

        return totalDividends;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress) public view returns (uint256)
    {
        return getUserDividends(userAddress);
    }

    function getAvailable(address userAddress) public view returns (uint256) {
        return users[userAddress].available;
    }

    function getUserLimit(address userAddress) public view returns (uint256) {
        uint256 totalUserDeposits = getUserTotalDeposits(userAddress);

        if (
            (totalUserDeposits >= 0.05 ether) &&
            (totalUserDeposits <= 12.4999 ether)
        ) {
            return LIMIT1;
        }

        if (
            (totalUserDeposits >= 12.5 ether) &&
            (totalUserDeposits <= 24.9999 ether)
        ) {
            return LIMIT2;
        }

        if (
            (totalUserDeposits >= 25 ether) &&
            (totalUserDeposits <= 99.99 ether)
        ) {
            return LIMIT3;
        }

        if (
            (totalUserDeposits >= 100 ether) &&
            (totalUserDeposits <= 149.999 ether)
        ) {
            return LIMIT4;
        }

        if (totalUserDeposits >= 150 ether) {
            return LIMIT5;
        }

        return 0;
    }

    function getUserAmountOfReferrals(address userAddress) public view returns (uint256,uint256,uint256,uint256,uint256)
    {
        return (
            users[userAddress].ref_1,
            users[userAddress].ref_2,
            users[userAddress].ref_3,
            users[userAddress].ref_4,
            users[userAddress].ref_5
        );
    }

    function getTimer(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpoint.add(24 hours);
    }

    function getChainID() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function isActive(address userAddress) public view returns (bool) {
        User memory user = users[userAddress];

        if (user.available > 0) {
            return true;
        }

        return false;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (uint256, uint256)
    {
        User storage user = users[userAddress];

        return (user.deposits[index].amount, user.deposits[index].start);
    }

    function userHasBonus(address userAddress) public view returns (bool) {
        return users[userAddress].hasUsersBonus;
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256)
    {
        User storage user = users[userAddress];
        return user.withdrawn;
    }

    function isContract(address addr) internal view returns (bool) { uint256 size;
        assembly {
            size := extcodesize(addr)
        }
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