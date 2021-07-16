//SourceUnit: TronStash.sol

pragma solidity 0.5.8;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract TronStash {
    using SafeMath for uint256;
    address public owner;

    struct UserPlan {
        uint256 planId;
        uint256 amount;
        uint256 expiredAt;
        uint256 lastPayout;
    }

    struct User {
        address inviter;
        uint256 investBalance;
        uint256 withdrawBalance;
        uint256 referralBonus;
        uint256 releasePercentage;
        uint256 lastWithdraw;
        uint256[3] structure;
        uint256[] plans;
    }

    struct Deposit {
        address user;
        uint256 time;
        uint256 amount;
    }

    uint256 public constant UPGRADE_COST = 600e6;
    uint256 public MINIMAL_INVEST = 10e6;

    uint256 public constant PLANS_AMOUNT = 6;
    uint256 public constant PLANS_DECIMALS = 1;
    uint256[PLANS_AMOUNT] public planProfitPerDay = [70, 65, 60, 55, 50, 45];
    uint256[PLANS_AMOUNT] public planLifespan = [20, 25, 30, 35, 40, 45];

    uint256 public lastPlan;
    uint256 public lastDeposit;

    uint256 public jackpot;

    uint8[] public refBonuses;
    mapping(uint256 => UserPlan) public planMapping;
    mapping(address => User) public users;
    mapping(uint256 => Deposit) public deposits;

    event onInvestPlan(address indexed user, uint256 planId, uint256 amount);
    event onDeposit(
        address indexed user,
        uint256 amount,
        address indexed inviter
    );
    event onReferralReward(
        address indexed inviter,
        address indexed user,
        uint256 amount,
        uint256 level
    );
    event onWithdraw(
        address indexed user,
        uint256 amount,
        address indexed receiver
    );
    event onNewUpline(
        address indexed user,
        address indexed inviter,
        uint256 amount
    );
    event onUpgradeRelease(address indexed user, uint256 newValue);
    event onJackpotWin(address indexed user, uint256 prize);

    constructor() public {
        owner = msg.sender;
        refBonuses.push(5);
        refBonuses.push(3);
        refBonuses.push(1);
    }

    function getBonus(uint256 time, uint256 amount)
        public
        view
        returns (uint256)
    {
        if (now <= time) {
            return amount;
        }
        if (now.sub(time) >= 21 days) {
            return amount.mul(115).div(100); // +15%
        }
        if (now.sub(time) >= 14 days) {
            return amount.mul(110).div(100); // +10%
        }
        if (now.sub(time) >= 7 days) {
            return amount.mul(105).div(100); // +5%
        }
        return amount;
    }

    function getJackpotStatus()
        public
        view
        returns (
            uint256 jackpotPrize,
            uint256 timeLast,
            uint256 currentPot,
            address[10] memory last
        )
    {
        timeLast = now.sub(deposits[lastDeposit].time);
        for (uint256 i = 0; i < 10; i++) {
            if (lastDeposit.sub(i) == 0) break;
            currentPot = currentPot.add(deposits[lastDeposit.sub(i)].amount);
            last[i] = deposits[lastDeposit.sub(i)].user;
        }
        return (jackpot, timeLast, currentPot, last);
    }

    function calculateProfit(uint256 pid, uint256 time)
        public
        view
        returns (uint256 profit)
    {
        UserPlan memory plan = planMapping[pid];
        uint256 from_ = plan.lastPayout;
        uint256 to = time > plan.expiredAt ? plan.expiredAt : time;

        if (from_ < to) {
            profit = to
                .sub(from_)
                .mul(plan.amount)
                .mul(planProfitPerDay[plan.planId])
                .div(10**PLANS_DECIMALS)
                .div(8640000);
        }
    }

    function getProfitOf(address user) public view returns (uint256 profit) {
        for (uint256 i = 0; i < users[user].plans.length; i++) {
            profit = profit.add(calculateProfit(users[user].plans[i], now));
        }
    }

    function getPlansOf(address user)
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256 userPlansCount = users[user].plans.length;

        uint256[] memory planId = new uint256[](userPlansCount);
        uint256[] memory amount = new uint256[](userPlansCount);
        uint256[] memory expiredAt = new uint256[](userPlansCount);

        for (uint256 i = 0; i < userPlansCount; i++) {
            UserPlan memory plan = planMapping[users[user].plans[i]];
            planId[i] = plan.planId;
            amount[i] = plan.amount;
            expiredAt[i] = plan.expiredAt;
        }
        return (planId, amount, expiredAt);
    }

    function getAccountOf(address user)
        public
        view
        returns (
            address inviter,
            uint256 investBalance,
            uint256 withdrawBalance,
            uint256 releasePercentage,
            uint256 referralBonus,
            uint256[3] memory structure
        )
    {
        uint256 profit = getProfitOf(user);

        uint256 unconfirmedInvestBalance = profit
            .mul(50 - users[user].releasePercentage)
            .div(100);
        uint256 unconfirmedWithdrawBalance = profit
            .mul(50 + users[user].releasePercentage)
            .div(100);

        investBalance = users[user].investBalance.add(unconfirmedInvestBalance);
        withdrawBalance = users[user].withdrawBalance.add(
            unconfirmedWithdrawBalance
        );
        inviter = users[user].inviter;
        releasePercentage = users[user].releasePercentage;
        referralBonus = users[user].referralBonus;
        structure = users[user].structure;
    }

    function _processPayment(address user, uint256 amount) internal {
        require(
            (users[user].investBalance.add(users[user].withdrawBalance)) >=
                amount,
            "Insufficient amount"
        );
        if (users[user].investBalance < amount) {
            uint256 investBalance = users[user].investBalance;
            users[user].investBalance = 0;
            users[user].withdrawBalance = users[user]
                .withdrawBalance
                .add(investBalance)
                .sub(amount);
        } else {
            users[user].investBalance = users[user].investBalance.sub(amount);
        }
    }

    function _upgradeReleasePercentage(address user)
        internal
        returns (uint256)
    {
        require(users[user].releasePercentage < 48, "Max release - 98%");
        _processPayment(
            user,
            UPGRADE_COST.add(
                UPGRADE_COST.mul(users[user].releasePercentage).div(2)
            )
        );
        users[user].releasePercentage = users[user].releasePercentage.add(2);
        return users[user].releasePercentage;
    }

    function _investPlan(
        address user,
        uint256 planId,
        uint256 amount
    ) internal {
        require(amount >= MINIMAL_INVEST, "Insufficient amount");
        require(planId < PLANS_AMOUNT, "This plan doesnt exists");
        if(users[user].plans.length == 0) {
            users[user].lastWithdraw = now;
        }
        planMapping[lastPlan] = UserPlan({
            planId: planId,
            amount: getBonus(
                users[user].lastWithdraw,
                amount
            ),
            lastPayout: now,
            expiredAt: now.add(planLifespan[planId].mul(86400))
        });
        users[user].plans.push(lastPlan);
        lastPlan++;
    }

    function _collectProfit(address user) internal {
        uint256 profit;
        for (uint256 i = 0; i < users[user].plans.length; i++) {
            profit = profit.add(calculateProfit(users[user].plans[i], now));
            planMapping[i].lastPayout = now;
        }
        uint256 unconfirmedInvestBalance = profit
            .mul(50 - users[user].releasePercentage)
            .div(100);
        uint256 unconfirmedWithdrawBalance = profit
            .mul(50 + users[user].releasePercentage)
            .div(100);

        users[user].investBalance = users[user].investBalance.add(
            unconfirmedInvestBalance
        );
        users[user].withdrawBalance = users[user].withdrawBalance.add(
            unconfirmedWithdrawBalance
        );
    }

    function _deposit(address user, uint256 amount) internal {
        users[user].investBalance = users[user].investBalance.add(amount);
        users[owner].withdrawBalance = users[owner].withdrawBalance.add(
            amount.div(20)
        ); // 5% dev commission
    }

    function _addInviter(
        address user,
        uint256 amount,
        address inviter
    ) internal {
        if (users[user].inviter == address(0) && user != owner) {
            if (users[inviter].plans.length == 0) {
                inviter = owner;
            } else {
                users[user].investBalance = users[user].investBalance.add(
                    amount.div(100)
                );
            }
            users[user].inviter = inviter;

            for (uint8 i = 0; i < refBonuses.length; i++) {
                users[inviter].structure[i]++;
                inviter = users[inviter].inviter;
                if (inviter == address(0)) break;
            }

            emit onNewUpline(user, inviter, amount.div(100));
        }
    }

    function _referralReward(address user, uint256 amount) internal {
        address inviter = users[user].inviter;

        for (uint8 i = 0; i < refBonuses.length; i++) {
            if (inviter == address(0)) break;
            uint256 bonus = amount.mul(refBonuses[i]).div(100);
            users[inviter].withdrawBalance = users[inviter].withdrawBalance.add(
                bonus
            );
            users[inviter].referralBonus = users[inviter].referralBonus.add(
                bonus
            );
            emit onReferralReward(inviter, user, bonus, i);
            inviter = users[inviter].inviter;
        }
    }

    function _jackpot(address user, uint256 amount) internal {
        lastDeposit++;
        deposits[lastDeposit] = Deposit({
            user: user,
            time: now,
            amount: amount
        });
        uint256 prize = amount.div(20); // 5%

        jackpot = jackpot.add(prize);

        uint256 currentPot;
        for (uint256 i = 0; i < 10; i++) {
            if (lastDeposit.sub(i) == 0) break;
            currentPot = currentPot.add(deposits[lastDeposit.sub(i)].amount);
        }

        for (uint256 i = 0; i < 10; i++) {
            if (lastDeposit.sub(i) == 0) break;
            uint256 distribution = prize
                .mul(deposits[lastDeposit.sub(i)].amount)
                .div(currentPot);
            users[deposits[lastDeposit.sub(i)].user]
                .withdrawBalance = users[deposits[lastDeposit.sub(i)].user]
                .withdrawBalance
                .add(distribution);
        }
    }

    function _withdraw(
        address user,
        uint256 amount,
        address receiver
    ) internal returns (uint) {
        require(amount <= users[user].withdrawBalance, "Insufficient amount");
        require(receiver != address(0), "Zero address");
        uint256 contractBalance = address(this).balance - jackpot;
        uint sum = contractBalance <= amount ? contractBalance : amount;
        users[user].withdrawBalance = users[user].withdrawBalance.sub(sum);
        users[user].lastWithdraw = now;
        address(uint160(receiver)).transfer(sum);
        return sum;
    }

    function deposit(address inviter) external payable {
        _deposit(msg.sender, msg.value);
        _addInviter(msg.sender, msg.value, inviter);
        _referralReward(msg.sender, msg.value);
        _jackpot(msg.sender, msg.value);
        emit onDeposit(msg.sender, msg.value, inviter);
    }

    function withdraw(uint256 amount, address receiver) external {
        _collectProfit(msg.sender);
        uint sum = _withdraw(msg.sender, amount, receiver);
        emit onWithdraw(msg.sender, sum, receiver);
    }

    function invest(uint256 planId, uint256 amount) external {
        _collectProfit(msg.sender);
        _processPayment(msg.sender, amount);
        _investPlan(msg.sender, planId, amount);
        emit onInvestPlan(msg.sender, planId, amount);
    }

    function upgradeRelease() external {
        uint256 newValue = _upgradeReleasePercentage(msg.sender);
        emit onUpgradeRelease(msg.sender, newValue.add(50));
    }

    function claimJackpot() external {
        if (
            deposits[lastDeposit].time > 0 ||
            now.sub(deposits[lastDeposit].time) >= 12 hours
        ) {
            address winner = deposits[lastDeposit].user;
            uint256 prize = jackpot;
            jackpot = 0;
            address(uint160(winner)).transfer(prize);
            emit onJackpotWin(winner, prize);
        }
    }

    function() external payable {
        revert();
    }
}