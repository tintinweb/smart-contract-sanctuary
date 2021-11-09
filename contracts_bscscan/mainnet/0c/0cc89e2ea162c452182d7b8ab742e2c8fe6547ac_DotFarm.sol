/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract DotFarm {
    IERC20 public token_DOT;
    using SafeMath for uint256;
    address erctoken = address(0x7083609fCE4d1d8Dc0C979AAb8c869Ea2C873402); //DOT
    uint256 public constant INVEST_MIN_AMOUNT = 1 ether;
    uint256 public REFERRAL_PERCENT = 70;
    uint256 public constant PROJECT_FEE = 33; // each
    uint256 public constant PERCENT_STEP = 5;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;
    
    uint256 public ADDITIONAL_PERCENT_PLAN_1 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_2 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_3 = 0;
    uint256 public ADDITIONAL_PERCENT_PLAN_4 = 0;
    

    uint256 public totalInvested;
    uint256 public totalRefBonus;

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        Deposit[] deposits;
        uint256 checkpoint;
        address referrer;
        uint256 levels;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
    }

    mapping(address => User) internal users;

    bool public started;

    address public ceoAddress;
    address public ceoAddress2;
    address public ceoAddress3;
    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor() {
        ceoAddress = msg.sender;
        ceoAddress2=address(0xb5A61db0eb8235E45AB24c98E59D91BE5E4D9853); 
        ceoAddress3=address(0xd16E218DAE84283cA0f5eCcca84906b1F9595cF4); 

        token_DOT = IERC20(erctoken);

        plans.push(Plan(10000, 50));
        plans.push(Plan(40, 70));
        plans.push(Plan(60, 65));
        plans.push(Plan(90, 60));
    }
    
    function invest(
        address referrer,
        uint8 plan,
        uint256 amounterc
    ) public {
        if (!started) {
            if (msg.sender == ceoAddress) {
                started = true;
            } else revert("Not started yet");
        }

        require(amounterc >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

        token_DOT.transferFrom(address(msg.sender), address(this), amounterc);

        // dev fee
        uint256 fee = amounterc.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);

        token_DOT.transfer(ceoAddress, fee);
        token_DOT.transfer(ceoAddress2, fee);
        token_DOT.transfer(ceoAddress3, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline1 = user.referrer;
            if (upline1 != address(0)) {
                users[upline1].levels = users[upline1].levels.add(1);
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            if (upline != address(0)) {
                uint256 amount = amounterc.mul(REFERRAL_PERCENT).div(
                    PERCENTS_DIVIDER
                );
                users[upline].bonus = users[upline].bonus.add(amount);
                users[upline].totalBonus = users[upline].totalBonus.add(amount);
                emit RefBonus(upline, msg.sender, amount);
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, amounterc, block.timestamp));

        totalInvested = totalInvested.add(amounterc);

        emit NewDeposit(msg.sender, plan, amounterc);
        emit FeePayed(msg.sender, fee);
    }

    function withdraw() public {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 0, "User has no dividends");

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);

        token_DOT.transfer(msg.sender, totalAmount);

        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getPlanInfo(uint8 plan)
        public
        view
        returns (uint256 time, uint256 percent)
    {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (user.checkpoint < finish) {
                uint256 share = user
                    .deposits[i]
                    .amount;
                
                uint256 percent = plans[user.deposits[i].plan].percent;
                if(user.deposits[i].plan == 0){
                    percent = percent.add(ADDITIONAL_PERCENT_PLAN_1);                }
                else if(user.deposits[i].plan == 1){
                    percent = percent.add(ADDITIONAL_PERCENT_PLAN_2);
                }else if(user.deposits[i].plan == 2){
                    percent = percent.add(ADDITIONAL_PERCENT_PLAN_3);
                }else if(user.deposits[i].plan == 3){
                    percent = percent.add(ADDITIONAL_PERCENT_PLAN_4);
                }

                share = share.mul(percent).div(PERCENTS_DIVIDER);
                    
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.timestamp
                    ? finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
        }

        return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].withdrawn;
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

    function getUserTotalReferrals(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].levels;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserReferralBonus(userAddress).add(
                getUserDividends(userAddress)
            );
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
        returns (uint256 amount)
    {
        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            amount = amount.add(users[userAddress].deposits[i].amount);
        }
    }
    
    function getUserPlanTotalAmount(address userAddress, uint8 plan)
        public
        view
        returns (
            uint256 totalAmount
        )
    {
        User storage user = users[userAddress];
        uint256 amount = 0;

        for( uint256 i = 0; i < user.deposits.length; i++){
            if(user.deposits[i].plan == plan){
                // check if Plan is still active
                uint256 finish = user.deposits[i].start.add(
                    plans[user.deposits[i].plan].time.mul(1 days)
                );                
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.timestamp
                    ? finish
                    : block.timestamp;
                if (from < to) {
                    amount = user.deposits[i].amount;
                }
            }
        }
        
        totalAmount = amount;
    }

    function getUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint8 plan,
            uint256 percent,
            uint256 amount,
            uint256 start,
            uint256 finish
        )
    {
        User storage user = users[userAddress];

        if( index < user.deposits.length )
        {
            plan = user.deposits[index].plan;
            percent = plans[plan].percent;
            amount = user.deposits[index].amount;
            start = user.deposits[index].start;
            finish = user.deposits[index].start.add(
                plans[user.deposits[index].plan].time.mul(1 days)
            );
        }else{
            plan = 0;
            percent = 0;
            amount = 0;
            start = 0;
            finish = 0;
        }
    }
    
    function getUserDepositsCount(address userAddress)
        public
        view
        returns (uint256 length)
    {
        User storage user = users[userAddress];

        return user.deposits.length;
    }

    function getSiteInfo()
        public
        view
        returns (uint256 _totalInvested, uint256 _totalBonus)
    {
        return (totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 totalDeposit,
            uint256 totalWithdrawn,
            uint256 totalReferrals
        )
    {
        return (
            getUserTotalDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            getUserTotalReferrals(userAddress)
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
    
    function setAdditionalPercent_Plan1(uint256 value) external {
        require(msg.sender == ceoAddress);
        require(value > 0 && value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_1 = value;
    }
    function setAdditionalPercent_Plan2(uint256 value) external {
        require(msg.sender == ceoAddress);
        require(value > 0 && value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_2 = value;
    }
    function setAdditionalPercent_Plan3(uint256 value) external {
        require(msg.sender == ceoAddress);
        require(value > 0 && value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_3 = value;
    }
    function setAdditionalPercent_Plan4(uint256 value) external {
        require(msg.sender == ceoAddress);
        require(value > 0 && value < 100); // 100 = 10%
        ADDITIONAL_PERCENT_PLAN_4 = value;
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