pragma solidity 0.5.10;
import "./IBEP20.sol";

//import "hardhat/console.sol";

contract Shibafarm {
    using SafeMath for uint256;

    uint128 public constant INVEST_MIN_AMOUNT = 1000000 * 1e18; //1 million shib
    uint64 public constant PROJECT_FEE = 100;
    // uint64 public constant PERCENT_STEP = 5;
    uint64 public constant PERCENTS_DIVIDER = 1000;
    uint64 public constant TIME_STEP = 600; //30 minute
    address public commissionWallet;
    bool public started;

    uint128 public totalInvested;
    uint128 public totalRefBonus;

    uint64[3] public REFERRAL_PERCENTS = [50, 30, 20];

    IBEP20 private token;

    struct Plan {
        uint128 time;
        uint128 percent;
    }

    Plan[3] internal plans;

    struct Deposit {
        uint8 plan;
        uint256 amount;
        uint256 start;
    }

    struct User {
        uint128 totalBonus;
        uint128 withdrawn;
        uint128 checkpoint;
        uint128 bonus;
        uint32[3] levels;
        address referrer;
        Deposit[] deposits;
    }

    mapping(address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor(address _tokenAddress) public {
        commissionWallet = msg.sender;
        token = IBEP20(_tokenAddress);

        plans[0].time = 40;
        plans[0].percent = 40;
        plans[1].time = 60;
        plans[1].percent = 35;
        plans[2].time = 90;
        plans[2].percent = 30;
    }

    function invest(
        address referrer,
        uint8 plan,
        uint256 investAmount
    ) public {
        uint256 _totalInvested = uint256(totalInvested);
        uint256 _totalRefBonus = uint256(totalRefBonus);

        require(investAmount >= INVEST_MIN_AMOUNT, "Min 1 Million SHIB");
        require(plan < 3, "Invalid plan");
        require(
            token.balanceOf(msg.sender) >= investAmount,
            "Insufficeint balance"
        );
        require(
            (users[referrer].deposits.length > 0 && referrer != msg.sender) ||
                (referrer == address(0) && msg.sender == commissionWallet),
            "Invalid Referrer"
        );

        uint256 fee = investAmount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER); //10% project fee
        //console.log("[Fee]", fee / 1e18);

        // console.log(token.balanceOf(commissionWallet) / 1e18);
        token.transferFrom(msg.sender, address(this), investAmount - fee);
        //console.log(token.balanceOf(commissionWallet) / 1e18);
        token.transferFrom(msg.sender, commissionWallet, fee);

        User storage user = users[msg.sender];

        if (user.referrer == address(0)) {
            // if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
            user.referrer = referrer;
            // }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i] + 1;
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
                if (upline != address(0)) {
                    uint256 amount = investAmount.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    uint256 _bonus = uint256(users[upline].bonus);
                    _bonus = _bonus.add(amount);
                    users[upline].bonus = uint128(_bonus);

                    uint256 _totalBonus = uint256(users[upline].totalBonus);
                    _totalBonus = _totalBonus.add(amount);
                    users[upline].totalBonus = uint128(_totalBonus);

                    _totalRefBonus += users[upline].totalBonus;
                    totalRefBonus = uint128(_totalRefBonus);
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = uint128(block.number);
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, investAmount, block.number));

        _totalInvested += investAmount;
        totalInvested = uint128(_totalInvested);

        emit NewDeposit(msg.sender, plan, investAmount);
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

        uint256 contractBalance = token.balanceOf(address(this));
        if (contractBalance < totalAmount) {
            uint256 _totalBonus = uint256(user.totalBonus);
            user.bonus = uint128(totalAmount.sub(contractBalance));
            _totalBonus = _totalBonus.add(user.bonus);
            user.totalBonus = uint128(_totalBonus);
            totalAmount = contractBalance;
        }

        user.checkpoint = uint128(block.number);

        uint256 _withdrawn = uint256(user.withdrawn);
        _withdrawn = _withdrawn.add(totalAmount);
        user.withdrawn = uint128(_withdrawn);

        //console.log("withdraw amount = %d", totalAmount / 1e18);

        token.transfer(msg.sender, totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
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
        uint256 _planTime;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            _planTime = uint256(plans[user.deposits[i].plan].time);

            uint256 finish = user.deposits[i].start.add(
                _planTime.mul(TIME_STEP)
            );
            if (user.checkpoint < finish) {
                uint256 share = user
                    .deposits[i]
                    .amount
                    .mul(plans[user.deposits[i].plan].percent)
                    .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.number ? finish : block.number;
                if (from < to) {
                    totalAmount = totalAmount.add(
                        share.mul(to.sub(from)).div(TIME_STEP)
                    );
                }
            }
        }

        return totalAmount;
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            uint256 _UserTotalWithdrawn,
            address _UserReferrer,
            uint32[3] memory _UserDownlineCount,
            uint256 _UserTotalReferrals,
            uint256 _UserReferralBonus,
            uint256 _UserReferralTotalBonus,
            uint256 _UserReferralWithdrawn,
            uint256 _UserAvailable,
            uint256 _UserAmountOfDeposits,
            uint256 _UserTotalDeposits
        )
    {
        _UserTotalWithdrawn = users[userAddress].withdrawn / 1e18;
        _UserReferrer = users[userAddress].referrer;
        _UserDownlineCount = users[userAddress].levels;
        _UserTotalReferrals =
            users[userAddress].levels[0] +
            users[userAddress].levels[1] +
            users[userAddress].levels[2];

        _UserReferralBonus = users[userAddress].bonus / 1e18;
        _UserReferralTotalBonus = users[userAddress].totalBonus / 1e18;
        uint256 userbonus = users[userAddress].bonus;

        _UserReferralWithdrawn = uint256(users[userAddress].totalBonus).sub(
            userbonus
        );
        _UserAvailable =
            _UserReferralBonus.add(getUserDividends(userAddress)) /
            1e18;
        _UserAmountOfDeposits = users[userAddress].deposits.length;

        for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            _UserTotalDeposits = _UserTotalDeposits.add(
                users[userAddress].deposits[i].amount
            );
        }
        _UserTotalDeposits = _UserTotalDeposits / 1e18;
    }

    function getUserCheckPoint(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].checkpoint;
    }

    function getUserReferralBonus(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].bonus;
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
        uint256 _planTime = uint256(plans[user.deposits[index].plan].time);

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(_planTime.mul(TIME_STEP));
    }

    function getSiteInfo()
        public
        view
        returns (uint256 _totalInvested, uint256 _totalBonus)
    {
        return (totalInvested, totalRefBonus);
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