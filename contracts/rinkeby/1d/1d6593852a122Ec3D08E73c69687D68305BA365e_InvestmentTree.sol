//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

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

contract InvestmentTree {
    using SafeMath for uint256;
    address public Owner;
    uint256 public constant Owner_PERCENT = 10;
    uint256 public constant DEPOSITS_MAX = 300;
    uint256 public constant INVEST_MIN_AMOUNT = 0.0310 ether;
    uint256 public constant INVEST_MAX_AMOUNT = 1.35 ether;
    uint256 public constant INVEST_MAX_MONTH_AMOUNT = 1.33 ether;
    uint256 public totalBalance;
    uint256 public totalDepositAmount;
    uint256 public totalDepositsCount;
    uint256 public totalWithdrawnsAmount;
    uint256 public totalWithdrawnsCount;
    uint256 public contractCreationTime;
    uint256 public totalRefBonus;
    uint256 public totalUsers;
    uint256 public totalOwnerFees;

    uint256[] public REFERRAL_PERCENTS = [5, 3, 2, 1];

    struct Deposit {
        uint256 amount;
        uint256 timestamp;
    }

    struct Withdrawn {
        uint256 amount;
        uint256 timestamp;
    }

    struct Lock {
        uint256 amount;
        uint256 timestamp;
        bool status;
    }

    struct User {
        address self;
        address referrer;
        Deposit[] deposits;
        uint256 perMonthDeposit;
        uint256 depositTimestamp;
        Withdrawn[] withdrawns;
        uint256 withdrawTimestamp;
        Lock[] locks;
        uint256 lockedAmount;
        uint256 bonus;
        uint256[4] refs;
    }

    mapping(address => User) public users;

    event NewDeposit(address indexed user, uint256 amount);
    event NewWithdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );

    event FeePayed(address indexed user, uint256 totalAmount);

    modifier onlyOwner() {
        if (msg.sender != Owner)
            revert("InvestmentTree: Only owner can perform this transaction.");
        _;
    }

    constructor() {
        Owner = msg.sender;
        contractCreationTime = block.timestamp;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function invest(address referrer) public payable {
        require(msg.sender == tx.origin);

        require(
            msg.value >= INVEST_MIN_AMOUNT && msg.value <= INVEST_MAX_AMOUNT,
            "InvestmentTree: Deposit amount should be between mix and max amount."
        );

        if (users[msg.sender].self == address(0)) {
            User storage u = users[msg.sender];
            u.self = msg.sender;
            u.referrer = referrer;

            totalUsers++;
        }

        User storage user = users[msg.sender];

        require(
            user.deposits.length < DEPOSITS_MAX,
            "InvestmentTree: Maximum 300 deposits from address"
        );

        uint256 msgValue = msg.value;

        if (
            user.deposits.length == 0 || block.timestamp > user.depositTimestamp
        ) {
            user.depositTimestamp = block.timestamp.add(30 days);
            user.perMonthDeposit = 0;
        }

        require(
            msgValue.add(user.perMonthDeposit) <= INVEST_MAX_MONTH_AMOUNT,
            "InvestmentTree: Maximum deposit of 1.33 eth per month limit is reached."
        );

        uint256 ownerFee = msgValue.mul(Owner_PERCENT).div(100);
        payable(Owner).transfer(ownerFee);
        totalOwnerFees = totalOwnerFees.add(ownerFee);
        emit FeePayed(msg.sender, ownerFee);

        msgValue = msgValue.sub(ownerFee);

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 4; i++) {
                if (upline != address(0)) {
                    uint256 amount = msgValue.mul(REFERRAL_PERCENTS[i]).div(
                        100
                    );

                    if (amount > 0) {
                        //payable(upline).transfer(amount);
                        users[upline].bonus = uint256(
                            users[upline].bonus.add(amount)
                        );

                        totalRefBonus = totalRefBonus.add(amount);
                        emit RefBonus(upline, msg.sender, i, amount);
                    }

                    users[upline].refs[i]++;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        user.deposits.push(Deposit(msg.value, uint256(block.timestamp)));
        user.perMonthDeposit = user.perMonthDeposit.add(msg.value);

        totalBalance = totalBalance.add(msgValue);
        totalDepositAmount = totalDepositAmount.add(msg.value);
        totalDepositsCount++;

        emit NewDeposit(msg.sender, msg.value);
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDepositsAmount(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(uint256(user.deposits[i].amount));
        }

        return amount;
    }

    function getUserFirstDeposit(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        if (user.deposits.length > 0) {
            return user.deposits[0].timestamp;
        }
        return 0;
    }

    function getUserLastDeposit(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        if (user.deposits.length > 0) {
            return user.deposits[user.deposits.length.sub(1)].timestamp;
        }
        return 0;
    }

    function withdraw(address userAddress, uint256 amount) public {
        User storage user = users[userAddress];

        require(
            user.withdrawns.length == 0 ||
                block.timestamp > user.withdrawTimestamp,
            "InvestmentTree: 1 withdrawal in a 24 hours period"
        );

        require(
            user.bonus > 0,
            "InvestmentTree: You have insufficient balance to make withdrawal request."
        );

        require(
            amount <= user.bonus,
            "InvestmentTree: Withdrawal amount should be less than total bonus"
        );

        user.withdrawTimestamp = block.timestamp.add(1 days); // Add 1 day
        user.bonus = user.bonus.sub(amount);

        uint256 _withdraw = amount.mul(70).div(100);
        uint256 lock = amount.mul(30).div(100);

        user.withdrawns.push(Withdrawn(amount, uint256(block.timestamp)));
        totalWithdrawnsAmount = totalWithdrawnsAmount.add(amount);
        totalWithdrawnsCount++;

        payable(userAddress).transfer(_withdraw);

        user.locks.push(Lock(amount, block.timestamp.add(30 days), false));
        user.lockedAmount = user.lockedAmount.add(lock);

        emit NewWithdrawn(msg.sender, amount);
    }

    function getUserTotalWithdrawns(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].withdrawns.length;
    }

    function getUserTotalWithdrawnsAmount(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.withdrawns.length; i++) {
            amount = amount.add(uint256(user.withdrawns[i].amount));
        }

        return amount;
    }

    function getUserFirstWithdraw(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        if (user.withdrawns.length > 0) {
            return user.withdrawns[0].timestamp;
        }
        return 0;
    }

    function getUserLastWithdraw(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        if (user.withdrawns.length > 0) {
            return user.withdrawns[user.withdrawns.length.sub(1)].timestamp;
        }
        return 0;
    }

    function release(address userAddress, uint256 index) public {
        User storage user = users[userAddress];

        payable(userAddress).transfer(user.locks[index].amount);
        user.locks[index].status = true;
    }

    function getSiteStats()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            totalDepositAmount,
            totalDepositsCount,
            totalWithdrawnsAmount,
            totalWithdrawnsCount,
            totalUsers,
            address(this).balance
        );
    }

    function getUserStats(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 userDepositsCount = getUserTotalDeposits(userAddress);
        uint256 userDepositsAmount = getUserTotalDepositsAmount(userAddress);
        uint256 userWithdrawnsCount = getUserTotalWithdrawns(userAddress);
        uint256 userWithdrawnsAmount = getUserTotalWithdrawnsAmount(
            userAddress
        );

        return (
            userDepositsCount,
            userDepositsAmount,
            userWithdrawnsCount,
            userWithdrawnsAmount
        );
    }

    function getUserReferralsStats(address userAddress)
        public
        view
        returns (
            address,
            uint256,
            uint256[4] memory
        )
    {
        User storage user = users[userAddress];

        return (user.referrer, user.bonus, user.refs);
    }

    function userDeposits(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        User storage user = users[userAddress];
        return user.deposits;
    }

    function userWithdrawns(address userAddress)
        public
        view
        returns (Withdrawn[] memory)
    {
        User storage user = users[userAddress];
        return user.withdrawns;
    }

    function userLockedAmounts(address userAddress)
        public
        view
        returns (Lock[] memory)
    {
        User storage user = users[userAddress];
        return user.locks;
    }
}

