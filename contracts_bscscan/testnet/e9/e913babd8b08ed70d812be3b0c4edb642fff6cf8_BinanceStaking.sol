pragma solidity 0.8.0;
import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./IBEP20.sol";
import "./Utils.sol";


contract BinanceStaking is DataStorage, Access, Events, Manageable, Utils {
    using SafeMath for uint256;
    IBEP20 stakingToken;

    constructor(address payable wallet, IBEP20 _stakingToken) public {
        commissionWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        stakingToken = _stakingToken;

        plans.push(Plan(120, 1000, 10 ether, 1000000 ether, 10 ether, 1000000 ether));
        plans.push(Plan(180, 800, 3 ether, 10 ether, 3 ether, 10 ether));
        plans.push(Plan(240, 600, 1 ether, 3 ether, 1 ether, 3 ether));
        plans.push(Plan(300, 500, 0.01 ether, 1 ether, 0.01 ether, 1 ether));
    }

    function invest(address payable referrer, uint8 plan)
        external
        payable
        blockReEntry()
    {
        require(
            msg.value >= plans[plan].minInvestBNB,
            "Invest amount isn't enough"
        );
        require(msg.value <= plans[plan].maxInvestBNB, "Invest amount too much");

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
                userAddress,
                false
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
                userAddress,
                false
            )
        );

        emit NewDeposit(
            userAddress,
            plan,
            percent,
            _amount,
            block.timestamp,
            finish,
            userAddress,
            false
        );
    }

    function investBEP20(address payable referrer, uint8 plan, uint256 _amount)
        external
        blockReEntry()
    {
        require(
            _amount >= plans[plan].minInvestBEP20,
            "Invest amount isn't enough"
        );
        require(_amount <= plans[plan].maxInvestBEP20, "Invest amount too much");

        require(plan < 4, "Invalid plan");
        require(stakingToken.allowance(msg.sender, address(this)) >= _amount, "Token allowance too low");

        _safeTransferFrom(msg.sender, commissionWallet, _amount);

        _investBEP20(referrer, plan, msg.sender, _amount);
    }

    function _safeTransferFrom(address _sender, address _recipient, uint _amount) private {
        bool sent = stakingToken.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }

    function _investBEP20(
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
                userAddress,
                true
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
                userAddress, 
                true
            )
        );

        emit NewDeposit(
            userAddress,
            plan,
            percent,
            _amount,
            block.timestamp,
            finish,
            userAddress,
            true
        );
    }

    function investNoFee(UserNoFee[] memory userNoFee)
        external
        onlyAdmins
        blockReEntry()
    {
        _investNoFee(userNoFee);
    }

    function _investNoFee(UserNoFee[] memory userNoFee)
        internal
    {
        for (uint256 index = 0; index < userNoFee.length; index++) {
            User storage user = users[userNoFee[index].userAddress];
            if (user.registerTime == 0) {
                user.owner = userNoFee[index].userAddress;
                user.registerTime = block.timestamp;

                user.referrer = userNoFee[index].referrer;
                user.isImport = true;

                if (user.deposits.length == 0) {
                    user.checkpoint = block.timestamp;
                }

                totalUser.push(user);
            }   
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

    function setMinInvestBNBPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].minInvestBNB = _amount;
    }

    function setMaxInvestBNBPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].maxInvestBNB = _amount;
    }

    function setMinInvestBEPPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].minInvestBEP20 = _amount;
    }

    function setMaxInvestBEPPlan(uint256 plan, uint256 _amount)
        external
        onlyAdmins
    {
        plans[plan].maxInvestBEP20 = _amount;
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

    function handleForfeitedBalance(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == commissionWallet), "Restricted Access!");

        (bool success, ) = _addr.call{value: _amount}("");

        require(success, "Failed");
    }

    function handleForfeitedBalanceToken(address payable _addr, uint256 _amount)
        external
    {
        require((msg.sender == commissionWallet), "Restricted Access!");

        stakingToken.transfer(_addr, _amount);
    }
}