/**
 *Submitted for verification at BscScan.com on 2021-11-12
*/

// SPDX-License-Identifier: None

pragma solidity 0.6.12;

contract SafemoonFarmer {
	using SafeMath for uint256;

	IBEP20 public token;
	uint256 public INVEST_MAX_AMOUNT = 13000000000 * (10 ** 9); // ~50k

    address safemoon = 0xDAcbdeCc2992a63390d108e8507B98c7E2B5584a; // testnet safemoon
    // mainnet: 0x8076C74C5e3F5852037F31Ff0093Eeb8c8ADd8D3;

    uint256 public constant REFERRAL_PERCENT = 30;
    uint256 public constant PROJECT_FEE = 100;
    uint256 public constant PERCENTS_DIVIDER = 1000;
    uint256 public constant TIME_STEP = 1 days;


    bool public started;
    uint256 public totalInvested;
    uint256 public totalRefBonus;

    address payable public contractOwner;
    address payable public partner1;
    address payable public partner2;

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
        uint256 referral_count;
        uint256 bonus;
        uint256 totalBonus;
        uint256 withdrawn;
    }

    mapping(address => User) internal users;

    event Newbie(address user);
    event NewDeposit(address indexed user, uint8 plan, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RefBonus(address indexed referrer, address indexed referral, uint256 amount);
    event FeePayed(address indexed user, uint256 totalAmount);

    constructor() public {
        token = IBEP20(safemoon);
        contractOwner = msg.sender;
        partner1 = 0x384E771e8e4d5cAcA87533d491C317Bae1e2318f; // J
        partner2 = 0xE5ec80188bD20bb2b93E98c23c429E25e713c0e9; // A
        plans.push(Plan(10000, 20));
        plans.push(Plan(40, 40));
        plans.push(Plan(60, 35));
        plans.push(Plan(90, 30));
    }

    function updateInvestMaxAmount(uint256 amount) public {
        require(msg.sender == contractOwner, "Admin use only");
        INVEST_MAX_AMOUNT = amount * (10 ** 9);
    }

    function startContract() public {
        require(msg.sender == contractOwner, "Admin use only");
        require(started == false, "Contract already started");
        started = true;
    }

    function invest(address referrer, uint8 plan, uint256 _amount) public payable {
        require(started, "Contract not yet started");
        require(getUserTotalDeposits(msg.sender).add(_amount) <= INVEST_MAX_AMOUNT, 'Total investment is over the limit');
        require(plan < 4, "Invalid plan");

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 commission = _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
        token.transfer(contractOwner, commission.div(3));
        token.transfer(partner1, commission.div(3));
        token.transfer(partner2, commission.div(3));
        emit FeePayed(msg.sender, commission);

        User storage user = users[msg.sender];
        if (user.referrer == address(0)) {
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            if (upline != address(0)) {
                users[upline].referral_count = users[upline].referral_count.add(1);
            }
        }

        if (user.referrer != address(0)) {
            address upline = user.referrer;
            uint256 amount = _amount.mul(REFERRAL_PERCENT).div(PERCENTS_DIVIDER);
            users[upline].bonus = users[upline].bonus.add(amount);
            users[upline].totalBonus = users[upline].totalBonus.add(amount);
            totalRefBonus = totalRefBonus.add(amount);
            emit RefBonus(upline, msg.sender, amount);
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender);
        }

        user.deposits.push(Deposit(plan, _amount, block.timestamp));
        totalInvested = totalInvested.add(_amount);
        emit NewDeposit(msg.sender, plan, _amount);
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
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

        user.checkpoint = block.timestamp;
        user.withdrawn = user.withdrawn.add(totalAmount);

        token.transfer(msg.sender, totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function getContractBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getPlanInfo(uint8 plan) public view returns (uint256 time, uint256 percent) {
        time = plans[plan].time;
        percent = plans[plan].percent;
    }

    function getUserDividends(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];

        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            uint256 finish = user.deposits[i].start.add(
                plans[user.deposits[i].plan].time.mul(1 days)
            );
            if (user.checkpoint < finish) {
                uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = finish < block.timestamp
                    ? finish
                    : block.timestamp;
                if (from < to) {
                    totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
                }
            }
        }

        return totalAmount;
    }

    function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].withdrawn;
    }

    function getUserCheckpoint(address userAddress) public view returns (uint256) {
        return users[userAddress].checkpoint;
    }

    function getUserReferrer(address userAddress) public view returns (address) {
        return users[userAddress].referrer;
    }

    function getUserTotalReferrals(address userAddress) public view returns (uint256) {
        return users[userAddress].referral_count;
    }

    function getUserReferralBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].bonus;
    }

    function getUserReferralTotalBonus(address userAddress) public view returns (uint256) {
        return users[userAddress].totalBonus;
    }

    function getUserReferralWithdrawn(address userAddress) public view returns (uint256) {
        return users[userAddress].totalBonus.sub(users[userAddress].bonus);
    }

    function getUserAvailable(address userAddress) public view returns (uint256) {
        return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
    }

    function getUserAmountOfDeposits(address userAddress) public view returns (uint256) {
        return users[userAddress].deposits.length;
    }

    function getUserTotalDeposits(address userAddress) public view returns (uint256 amount) {
        User storage user = users[userAddress];
		for (uint256 i = 0; i < user.deposits.length; i++) {
			amount = amount.add(user.deposits[i].amount);
		}
    }

    function getUserDepositInfo(address userAddress, uint256 index) public view returns (uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
        User storage user = users[userAddress];

        plan = user.deposits[index].plan;
        percent = plans[plan].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
    }

    function getSiteInfo() public view returns (uint256 _totalInvested, uint256 _totalBonus) {
        return (totalInvested, totalRefBonus);
    }

    function getUserInfo(address userAddress) public view returns (uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
        return (
            getUserTotalDeposits(userAddress),
            getUserTotalWithdrawn(userAddress),
            getUserTotalReferrals(userAddress)
        );
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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