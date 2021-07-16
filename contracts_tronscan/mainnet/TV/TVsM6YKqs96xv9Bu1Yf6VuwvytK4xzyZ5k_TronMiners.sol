//SourceUnit: contract.sol

pragma solidity >=0.5.4;

contract TronMiners {
    using SafeMath for uint256;
    using SafeMath for uint24;

    //Data Types
    //-------------------------------------------------------------

    event onDeposit(address investor, uint256 amount);
    event onWithdraw(address investor, uint256 amount);

    struct ContractStats {
        uint totalInvested;
        uint totalWithdrawn;
        uint totalInvestors;
        uint totalReferrals;
    }

    struct Deposit {
        uint time;
        uint amount;
    }

    struct Investor {
        bool registered;
        uint totalInvested;
        uint totalWithdrawn;
        uint referral;
        Deposit[] deposits;
    }

    //Variables
    //-------------------------------------------------------------
    uint24[70] coEff = [1021000, 1042441, 1064332, 1086683, 1109504, 1132803, 1156592, 1180880, 1205679, 1230998, 1256849, 1283243, 1310191, 1337705, 1365797, 1394479, 1423763, 1453662, 1484189, 1515357, 1547179, 1579670, 1612843, 1646713, 1681294, 1716601, 1752649, 1789455, 1827034, 1865401, 1904575, 1944571, 1985407, 2027100, 2069669, 2113132, 2157508, 2202816, 2249075, 2296306, 2344528, 2393763, 2444032, 2495357, 2547759, 2601262, 2655889, 2711662, 2768607, 2826748, 2886110, 2946718, 3008599, 3071780, 3136287, 3202149, 3269394, 3338052, 3408151, 3479722, 3552796, 3627405, 3703580, 3781355, 3860764, 3941840, 4024619, 4109135, 4195427, 4283531];
    uint public constant TAXES = 76;
    uint public constant DAY = 86400;
    uint8 public constant DEP_LIMIT = 50;
    uint public rootRefLimit = 100;
    uint public minimumRootDeposit = 1000000000;
    address payable lotteryWallet;
    bool private paying = true;
    bool private bonusRefs = false;
    address[] rootReferrals;
    uint referralTurn;
    ContractStats public stats;

    mapping(address => Investor) private investors;

    modifier onlyOwner {
        require(
            msg.sender == lotteryWallet,
            "Only owner can call this function."
        );
        _;
    }

    //Functions
    //-------------------------------------------------------------

    function() external payable {}

    constructor() public {lotteryWallet = msg.sender;}

    function getInvestor() public view returns (bool, uint, uint, uint, uint[] memory, uint[] memory){
        Investor storage investor = investors[msg.sender];
        uint[] memory amounts = new uint[](investor.deposits.length);
        uint[] memory times = new uint[](investor.deposits.length);
        for (uint i = 0; i < amounts.length; i++) {
            amounts[i] = investor.deposits[i].amount;
            times[i] = investor.deposits[i].time;
        }
        return (investor.registered, investor.totalInvested, investor.totalWithdrawn, investor.referral, amounts, times);
    }

    function getStats() public view returns (uint, uint, uint, uint, uint, bool){
        return (stats.totalInvested, stats.totalInvestors,
        stats.totalWithdrawn, stats.totalReferrals, address(this).balance, paying);
    }

    function getPaying() public view returns (bool){
        return paying;
    }

    function getBonus() public view returns (bool){
        return bonusRefs;
    }

    function getBonusRefsCount() public view returns (uint){
        return rootReferrals.length;
    }

    function deposit(address _referer) public payable {
        require(msg.sender != 0x0000000000000000000000000000000000000000);
        require(investors[msg.sender].deposits.length <= DEP_LIMIT, "Maximum number of deposits exceeded");
        uint amount = msg.value;
        require(amount >= 50000000 && amount <= 1000000000000, "Wrong amount");
        Investor storage investor = investors[msg.sender];
        investor.deposits.push(Deposit(now, amount));
        if (!investor.registered) {
            address actualReferral = _referer;
            if (!investors[actualReferral].registered) {
                if (!bonusRefs && rootReferrals.length > 0) {
                    actualReferral = rootReferrals[referralTurn];
                    referralTurn++;
                    if (referralTurn == rootReferrals.length) {
                        referralTurn = 0;
                    }
                }
            }
            if (investors[actualReferral].registered) {
                uint referral = (amount * 4) / 100;
                investors[actualReferral].referral += referral;
                stats.totalReferrals += referral;
            }
            investor.registered = true;
            stats.totalInvestors += 1;
            if (bonusRefs) {
                if (rootReferrals.length <= rootRefLimit && amount >= minimumRootDeposit) {
                    rootReferrals.push(msg.sender);
                }
            }
        }

        investor.totalInvested += amount;
        stats.totalInvested += amount;

        emit onDeposit(msg.sender, amount);
    }

    function withdraw(uint _depIndex) public payable {
        Investor storage investor = investors[msg.sender];
        require(_depIndex < investor.deposits.length, "Invalid index");
        Deposit storage _deposit = investor.deposits[_depIndex];
        require(_deposit.amount > 0, "No deposit");
        uint netAmount;
        if (!paying) {
            netAmount = _deposit.amount;
        } else {
            uint ticks = now.sub(_deposit.time);
            uint fullDays = ticks.div(DAY);
            fullDays = fullDays > 70 ? 70 : fullDays;
            if (fullDays == 70) {
                netAmount = _deposit.amount.mul(coEff[fullDays - 1]);
            } else {
                if (fullDays > 0) {
                    uint fullDaysProfit = _deposit.amount.mul(coEff[fullDays - 1]);
                    uint currentDayProfit = _deposit.amount.mul((coEff[fullDays].sub(coEff[fullDays - 1])));
                    netAmount = fullDaysProfit + ((ticks % DAY) * currentDayProfit) / DAY;
                }
                else {
                    netAmount = ((ticks % DAY) * coEff[0] * _deposit.amount) / DAY;
                }
            }
            netAmount = netAmount / 1000000;
        }

        uint balance = address(this).balance;
        uint netTax;
        uint netPayment;

        if (netAmount > balance) {
            netTax = (balance * TAXES) / 1000;
            netPayment = balance.sub(netTax);
            _deposit.amount = (_deposit.amount * (netAmount.sub(balance))).div(netAmount);
        } else {
            netTax = (netAmount * TAXES) / 1000;
            netPayment = netAmount.sub(netTax);
            _deposit.amount = 0;
        }

        stats.totalWithdrawn += netPayment;
        lotteryWallet.transfer(netTax);
        msg.sender.transfer(netPayment);

        emit onWithdraw(msg.sender, netPayment);
    }

    function withdrawReferral() public payable {
        Investor storage referrer = investors[msg.sender];
        require(referrer.referral > 0 && paying, "No referrals");
        uint netAmount = referrer.referral;
        uint balance = address(this).balance;
        if (netAmount > balance) {
            netAmount = balance;
        }
        uint tax = (netAmount * TAXES) / 1000;
        netAmount = netAmount.sub(tax);
        referrer.referral = 0;
        stats.totalWithdrawn+=netAmount;
        lotteryWallet.transfer(tax);
        msg.sender.transfer(netAmount);

        emit onWithdraw(msg.sender, netAmount);
    }

    function setPaying(bool _paying) public onlyOwner {
        paying = _paying;
    }

    function setBonus(bool _bonusRefs) public onlyOwner {
        bonusRefs = _bonusRefs;
    }

    function setRootRefLimit(uint _limit) public onlyOwner {
        rootRefLimit = _limit;
    }

    function setMinimumRootDeposit(uint _limit) public onlyOwner {
        minimumRootDeposit = _limit;
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