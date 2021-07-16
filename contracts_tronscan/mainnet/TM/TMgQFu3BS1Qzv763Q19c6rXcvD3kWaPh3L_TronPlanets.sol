//SourceUnit: CompanyGame.sol

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

contract TronPlanets {
    using SafeMath for uint256;
    address public owner;

    struct UserPlan {
        uint256 planId;
        uint256 amount;
        uint256 expiredAt;
        uint256 createdAt;
    }

    struct User {
        address inviter;
        uint256 investBalance;
        uint256 withdrawBalance;
        uint256 releasePercentage;

        uint256 totalDividends;
        uint256 totalInvestments;
        uint256 referralBonus;

        uint256 lastPayout;
        uint256 lastWithdraw;
        uint256[3] structure;
        uint256[] plans;
    }

    struct Deposit {
        address user;
        uint256 time;
        uint256 amount;
    }

    uint256 public constant UPGRADE_COST = 1000e6;
    uint256 public minimalDeposit = 100e6;
    uint256 public maxTime = 12 hours;
    uint256 public addOffset = 30 minutes;

    uint256 public constant PLANS_AMOUNT = 6;
    uint256 public constant PLANS_DECIMALS = 2;
    uint256[PLANS_AMOUNT] public planProfitPerDay = [700, 650, 600, 570, 560, 555];
    uint256[PLANS_AMOUNT] public planLifespan = [20, 25, 30, 35, 40, 45];

    uint256 public lastPlan;
    uint256 public lastDeposit;


    uint256 public jackpot;
    uint256 public timer;

    uint256 public totalInvested;
    uint256 public totalReferralBonus;

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

    function updateSettings(uint256 _addOffset, uint256 _minimalDeposit) external {
        require(msg.sender == owner, "Owner method only");
        require(_minimalDeposit <= 200e6, "minimal invest Sanity Check");
        require(_addOffset <= maxTime && _addOffset >= 10 minutes, "Timer offset Sanity Check");
        addOffset = _addOffset;
        minimalDeposit = _minimalDeposit;
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
            return amount.mul(115).div(100);
        }
        if (now.sub(time) >= 14 days) {
            return amount.mul(110).div(100);
        }
        if (now.sub(time) >= 7 days) {
            return amount.mul(105).div(100);
        }
        return amount;
    }

    function getPlatformStatus()
    public
    view
    returns (
        address[10] memory last,
        uint256 jackpotPrize,
        uint256 timeLast,
        uint256 currentPot,
        uint256 totalInvesting,
        uint256 totalReferralReward,
        uint256[10] memory amounts
    )
    {
        for (uint256 i = 0; i < 10; i++) {
            if (lastDeposit.sub(i) == 0) break;
            currentPot = currentPot.add(deposits[lastDeposit.sub(i)].amount);
            last[i] = deposits[lastDeposit.sub(i)].user;
            amounts[i] = deposits[lastDeposit.sub(i)].amount;
        }
        return (last, jackpot, now.sub(timer), currentPot, totalInvested, totalReferralBonus, amounts);
    }

    function calculateProfit(uint256 pid, uint256 from, uint256 time)
    public
    view
    returns (uint256 profit)
    {
        UserPlan memory plan = planMapping[pid];
        uint256 to = time > plan.expiredAt ? plan.expiredAt : time;

        if (from < to) {
            profit = to
            .sub(from)
            .mul(plan.amount)
            .mul(planProfitPerDay[plan.planId])
            .div(10 ** PLANS_DECIMALS)
            .div(8640000);
        }
    }

    function getProfitOf(address userAddress) public view returns (uint256 profit) {
        User memory user = users[userAddress];
        for (uint256 i = 0; i < user.plans.length; i++) {
            profit = profit.add(calculateProfit(user.plans[i], user.lastPayout, now));
        }
    }

    function getPendingBalanceOf(address userAddress) public view returns (uint256 withdraw, uint256 invest) {
        uint256 profit = getProfitOf(userAddress);

        invest = profit
        .mul(50 - users[userAddress].releasePercentage)
        .div(100);
        withdraw = profit
        .mul(50 + users[userAddress].releasePercentage)
        .div(100);
    }

    function getPlansOf(address user)
    public
    view
    returns (
        uint256[] memory,
        uint256[] memory,
        uint256[] memory,
        uint256[] memory
    )
    {
        uint256 userPlansCount = users[user].plans.length;

        uint256[] memory planId = new uint256[](userPlansCount);
        uint256[] memory amount = new uint256[](userPlansCount);
        uint256[] memory expiredAt = new uint256[](userPlansCount);
        uint256[] memory createdAt = new uint256[](userPlansCount);

        for (uint256 i = 0; i < userPlansCount; i++) {
            UserPlan memory plan = planMapping[users[user].plans[i]];
            planId[i] = plan.planId;
            amount[i] = plan.amount;
            expiredAt[i] = plan.expiredAt;
            createdAt[i] = plan.createdAt;
        }
        return (planId, amount, expiredAt, createdAt);
    }

    function getAccountOf(address userAddress)
    public
    view
    returns (
        address inviter,
        uint256 withdrawBalance,
        uint256 investBalance,
        uint256 releasePercentage,
        uint256 referralBonus,
        uint256 totalInvestments,
        uint256 totalDividends,
        uint256 lastPayout,
        uint256 depositBonus,
        uint256[3] memory structure
    )
    {
        User memory user = users[userAddress];
        (uint256 pendingWithdraw, uint256 pendingInvest) = getPendingBalanceOf(userAddress);

        withdrawBalance = user.withdrawBalance.add(pendingWithdraw);
        investBalance = user.investBalance.add(pendingInvest);
        inviter = user.inviter;
        releasePercentage = user.releasePercentage;
        referralBonus = user.referralBonus;
        totalInvestments = user.totalInvestments;
        totalDividends = user.totalDividends;
        lastPayout = user.lastPayout;
        depositBonus = getBonus(user.lastWithdraw, 100);
        structure = user.structure;
    }

    function _processPayment(address userAddress, uint256 amount) internal {
        User storage user = users[userAddress];
        require(
            (user.investBalance.add(user.withdrawBalance)) >=
            amount,
            "Insufficient amount"
        );
        if (user.investBalance < amount) {
            uint256 investBalance = user.investBalance;
            user.investBalance = 0;
            user.withdrawBalance = user
            .withdrawBalance
            .add(investBalance)
            .sub(amount);
        } else {
            user.investBalance = user.investBalance.sub(amount);
        }
    }

    function _upgradeReleasePercentage(address userAddress)
    internal
    returns (uint256)
    {
        User storage user = users[userAddress];
        require(user.releasePercentage < 10, "Max release - 60%");
        _processPayment(
            userAddress,
            UPGRADE_COST.add(
                UPGRADE_COST.mul(user.releasePercentage)
            )
        );
        user.releasePercentage = user.releasePercentage.add(1);
        return user.releasePercentage;
    }

    function _investPlan(
        address userAddress,
        uint256 planId,
        uint256 amount
    ) internal returns (uint256) {
        require(planId < PLANS_AMOUNT, "This plan doesnt exists");
        require(amount >= 10e6, "Minimal Invest = 10 TRX");
        User storage user = users[userAddress];
        require(user.plans.length < 100, "Max plans per address - 100");


        if (user.plans.length == 0) {
            user.lastPayout = now;
            user.lastWithdraw = now;
        }

        amount = getBonus(user.lastWithdraw, amount);

        planMapping[lastPlan] = UserPlan({
        planId : planId,
        amount : amount,
        createdAt : now,
        expiredAt : now.add(planLifespan[planId].mul(86400))
        });
        user.plans.push(lastPlan);
        lastPlan++;

        address(uint160(owner)).transfer(amount.div(20));
        return amount;
    }

    function _collectProfit(address userAddress) internal {
        User storage user = users[userAddress];
        (uint256 pendingWithdraw, uint256 pendingInvest) = getPendingBalanceOf(userAddress);

        user.withdrawBalance = users[userAddress].withdrawBalance.add(
            pendingWithdraw
        );

        user.investBalance = users[userAddress].investBalance.add(
            pendingInvest
        );

        user.lastPayout = now;
    }

    function _deposit(address userAddress, uint256 amount) internal {
        require(amount >= minimalDeposit, "Insufficient amount");
        users[userAddress].investBalance = users[userAddress].investBalance.add(amount);


        users[userAddress].totalInvestments = users[userAddress].totalInvestments.add(amount);
        totalInvested = totalInvested.add(amount);
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
            totalReferralBonus = totalReferralBonus.add(bonus);
            emit onReferralReward(inviter, user, bonus, i);
            inviter = users[inviter].inviter;
        }
    }

    function _jackpot(address user, uint256 amount) internal {
        if (lastDeposit == 0) {
            timer = now;
        }
        lastDeposit++;
        deposits[lastDeposit] = Deposit({
        user : user,
        time : now,
        amount : amount
        });

        if (now <= timer.add(addOffset)) {
            timer = now;
        } else {
            timer = timer.add(addOffset);
        }

        uint256 prize = amount.div(20);
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
        address userAddress,
        uint256 amount,
        address receiver
    ) internal returns (uint256) {
        User storage user = users[userAddress];
        require(amount <= user.withdrawBalance, "Insufficient amount");
        require(receiver != address(0), "Zero address");
        uint256 contractBalance = address(this).balance - jackpot;
        uint256 sum = contractBalance <= amount ? contractBalance : amount;

        user.lastWithdraw = now;
        user.withdrawBalance = user.withdrawBalance.sub(sum);
        user.totalDividends = user.totalDividends.add(sum);
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
        uint256 sum = _withdraw(msg.sender, amount, receiver);
        emit onWithdraw(msg.sender, sum, receiver);
    }

    function invest(uint256 planId, uint256 amount) external {
        _collectProfit(msg.sender);
        _processPayment(msg.sender, amount);
        uint256 amount = _investPlan(msg.sender, planId, amount);
        emit onInvestPlan(msg.sender, planId, amount);
    }

    function upgradeRelease() external {
        uint256 newValue = _upgradeReleasePercentage(msg.sender);
        emit onUpgradeRelease(msg.sender, newValue.add(50));
    }

    function claimJackpot() external {
        require(now.sub(timer) >= maxTime && jackpot > 0, "Jackpot is not finished");
        address winner = deposits[lastDeposit].user;
        uint256 prize = jackpot;
        jackpot = 0;
        timer = now;
        address(uint160(winner)).transfer(prize);
        emit onJackpotWin(winner, prize);
    }
}