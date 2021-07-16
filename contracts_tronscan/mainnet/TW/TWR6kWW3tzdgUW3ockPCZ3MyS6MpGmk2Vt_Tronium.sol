//SourceUnit: Tronium.sol

/*
 *   TRONIUM - https://Tronium.io
 *   Verified, audited, safe and legitimate!
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronWallet
 *   2) Send any TRX amount using our website invest button. Dont send coin directly on contract address!
 *   3) Wait for your earnings
 *   4) Withdraw earnings every 24 hours using the "Withdraw" button
 *
 *
 */
 
pragma solidity 0.5.10;

contract Tronium {
    using SafeMath for uint256;

    uint256 public constant INVEST_MIN_AMOUNT = 250000000;
    uint256 public constant BASE_PERCENT = 140; // 1.4% per day
    uint256[] public REFERRAL_PERCENTS = [
        50,
        40,
        30,
        20,
        20,
        10,
        10,
        10,
        10,
        10
    ];
    uint256 public constant MARKETING_FEE = 500;
    uint256 public constant PROJECT_FEE = 1000;
    uint256 public constant PERCENTS_DIVIDER = 10000;
    uint256 public constant MAX_HOLD_BONUS = 10; // 0.1%
    uint256 public constant TIME_STEP = 1 days;
    uint256 public LAUNCH_TIME;

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    address payable public BackupAddress;
    address payable public projectAddress;
    address payable public withdraw_Address;

    struct Deposit {
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address payable referrer;
        uint256 bonus;
        uint256 id;
        uint256 returnedDividends;
        uint256 available;
        uint256 withdrawn;
        uint256 ref_1;
        uint256 ref_2;
        uint256 ref_3;
        uint256 ref_4;
        uint256 ref_5;
        uint256 ref_6;
        uint256 ref_7;
        uint256 ref_8;
        uint256 ref_9;
        uint256 ref_10;
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

    constructor(address payable marketingAddr, address payable projectAddr,address payable withdraw_add)
        public
    {
        require(!isContract(marketingAddr), "!marketingAddr");
        require(!isContract(projectAddr), "!projectAddr");

        BackupAddress = marketingAddr;
        projectAddress = projectAddr;
        withdraw_Address = withdraw_add;
        LAUNCH_TIME = 1615744800;
    }

    function invest(address payable referrer) public payable beforeStarted() {
        require(msg.value >= INVEST_MIN_AMOUNT, "!INVEST_MIN_AMOUNT");

        BackupAddress.transfer(
            msg.value.mul(40).div(100) 
        );
       

        User storage user = users[msg.sender];

        if (
            user.referrer == address(0) &&
            users[referrer].deposits.length > 0 &&
            referrer != msg.sender
        ) {
            user.referrer = referrer;
        }
        user.available = user.available.add(msg.value.mul(3));
        if (user.referrer != address(0)) {
            address payable upline = user.referrer;
            for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint256 amount =
                        msg.value.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );

                    if(isActive(upline))
                    {
                        upline.transfer(amount);
                        users[upline].bonus = users[upline].bonus.add(amount);
                        users[upline].available = users[upline].available.sub(amount);
                    }

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
                    if (i == 5) {
                        users[upline].ref_6 = users[upline].ref_6.add(1);
                    }
                    if (i == 6) {
                        users[upline].ref_7 = users[upline].ref_7.add(1);
                    }
                    if (i == 7) {
                        users[upline].ref_8 = users[upline].ref_8.add(1);
                    }
                    if (i == 8) {
                        users[upline].ref_9 = users[upline].ref_9.add(1);
                    }
                    if (i == 9) {
                        users[upline].ref_10 = users[upline].ref_10.add(1);
                    }

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
            user.ref_6 = 0;
            user.ref_7 = 0;
            user.ref_8 = 0;
            user.ref_9 = 0;
            user.ref_10 = 0;
            emit Newbie(msg.sender);
        }

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
        require(totalAmount > 99000000,'Minimum 100 Trons');
        totalAmount = totalAmount.add(user.returnedDividends);
        uint256 withdraw_fees = totalAmount.mul(20).div(100);
        totalAmount = totalAmount.sub(withdraw_fees);

        uint256 total_dep_withdrawer = getUserTotalDeposits(msg.sender);
        if (user.referrer != address(0)) {
            address payable upline = user.referrer;
            for (uint256 i = 0; i < 10; i++) {
                if (upline != address(0)) {
                    uint256 amount =
                        total_dep_withdrawer.mul(REFERRAL_PERCENTS[i]).div(
                            PERCENTS_DIVIDER
                        );

                    if (isActive(upline)) {
                        upline.transfer(amount);
                        withdraw_fees = withdraw_fees.add(amount.mul(20).div(100)); // 20% of upline referral to backUp
                        users[upline].bonus = users[upline].bonus.add(amount);
                        users[upline].available = users[upline].available.sub(
                            amount
                        );
                    }
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.available < totalAmount) {
            totalAmount = user.available;
        }

        require(totalAmount > 0, "User has no dividends");

        uint256 contractBalance = address(this).balance;
        if (contractBalance < totalAmount) {
            totalAmount = contractBalance;
        }

        user.checkpoint = block.timestamp;

        msg.sender.transfer(totalAmount);
        projectAddress.transfer(withdraw_fees.div(2));
        withdraw_Address.transfer(withdraw_fees.div(2));

        user.available = user.available.sub(totalAmount);
        user.withdrawn = user.withdrawn.add(totalAmount);

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

   

    function getUserPercentRate(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 contractUsersRate = BASE_PERCENT;
        if (isActive(userAddress)) {
            uint256 timeMultiplier =
                (block.timestamp.sub(user.checkpoint)).div(TIME_STEP).mul(1); // +0.01% per day holding bonus

            if (timeMultiplier > MAX_HOLD_BONUS) {
                timeMultiplier = MAX_HOLD_BONUS;
            }

            return contractUsersRate.add(timeMultiplier);
        } else {
            return contractUsersRate;
        }
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
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

    function getUserCheckpoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress)
        public
        view
        returns (address)
    {
        return users[userAddress].referrer;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return getUserDividends(userAddress);
    }

    function getAvailable(address userAddress) public view returns (uint256) {
        return users[userAddress].available;
    }

    function getUserAmountOfReferrals_ff(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].ref_1,
            users[userAddress].ref_2,
            users[userAddress].ref_3,
            users[userAddress].ref_4,
            users[userAddress].ref_5,
            users[userAddress].checkpoint,
            users[userAddress].available
        );
    }

    function getUserAmountOfReferrals_lf(address userAddress)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            users[userAddress].ref_6,
            users[userAddress].ref_7,
            users[userAddress].ref_8,
            users[userAddress].ref_9,
            users[userAddress].ref_10
        );
    }

    function getTimer(address userAddress) public view returns (uint256) {
         return users[userAddress].checkpoint.add(24 hours);
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

    function getUserAmountOfDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 amount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            amount = amount.add(user.deposits[i].amount);
        }

        return amount;
    }


    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        return user.withdrawn;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
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