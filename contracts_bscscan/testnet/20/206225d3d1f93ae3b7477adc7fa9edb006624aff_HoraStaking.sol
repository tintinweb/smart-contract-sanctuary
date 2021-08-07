pragma solidity 0.8.0;

import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./Utils.sol";
import "./IBEP20.sol";

contract HoraStaking is DataStorage, Events, Manageable, Utils {
    using SafeMath for uint256;

    /**
     * @dev Constructor function
     */
    constructor(address payable wallet, IBEP20 _bep20) public {
        commissionWallet = wallet;
        reentryStatus = ENTRY_ENABLED;
        stakingToken = _bep20;
        plans.push(Plan(0, 16, 0 ether, 90000000 ether));
        plans.push(Plan(30, 33, 0 ether, 90000000 ether));
        plans.push(Plan(90, 50, 0 ether, 90000000 ether));
        plans.push(Plan(180, 66, 0 ether, 90000000 ether));
        plans.push(Plan(365, 116, 0 ether, 90000000 ether));
    }

    function invest(uint8 plan, uint256 _amount)
        external
        payable
        blockReEntry()
    {
        require(_amount > plans[plan].minInvest, "Invest amount isn't enough");
        require(_amount <= plans[plan].maxInvest, "Invest amount too much");

        require(plan < 6, "Invalid plan");
        require(
            stakingToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );
        _invest(plan, msg.sender, _amount);
        if (PROJECT_FEE > 0) {
            commissionWallet.transfer(PROJECT_FEE);
            emit FeePayed(msg.sender, PROJECT_FEE);
        }
    }

    function _invest(
        uint8 plan,
        address userAddress,
        uint256 _amount
    ) internal {
        User storage user = users[userAddress];
        uint256 currentTime = block.timestamp;
        require(
            user.lastStake.add(TIME_STAKE) <= currentTime,
            "Required: Must be take time to stake"
        );
        _safeTransferFrom(userAddress, address(this), _amount);
        user.lastStake = currentTime;
        user.owner = userAddress;
        user.registerTime = currentTime;
        user.isImport = false;

        if (user.deposits.length == 0 && !user.isImport) {
            user.checkpoint = currentTime;
            emit Newbie(userAddress, currentTime);
            totalUser.push(user);
        }

        (uint256 percent, uint256 finish) = getResult(plan);
        user.deposits.push(
            Deposit(
                plan,
                percent,
                _amount,
                currentTime,
                finish,
                userAddress,
                PROJECT_FEE,
                false
            )
        );
        totalStakedAmount = totalStakedAmount.add(_amount);
        totalDeposits.push(
            Deposit(
                plan,
                percent,
                _amount,
                currentTime,
                finish,
                userAddress,
                PROJECT_FEE,
                false
            )
        );

        emit NewDeposit(
            userAddress,
            plan,
            percent,
            _amount,
            currentTime,
            finish,
            PROJECT_FEE
        );
    }

    function _safeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        bool sent = stakingToken.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }

    function investNoFee(UserNoFee[] memory userNoFee)
        external
        onlyAdmins
        blockReEntry()
    {
        _investNoFee(userNoFee);
    }

    function _investNoFee(UserNoFee[] memory userNoFee) internal {
        for (uint256 index = 0; index < userNoFee.length; index++) {
            User storage user = users[userNoFee[index].userAddress];
            if (user.registerTime == 0) {
                user.owner = userNoFee[index].userAddress;
                user.registerTime = block.timestamp;

                user.isImport = true;

                if (user.deposits.length == 0) {
                    user.checkpoint = block.timestamp;
                }

                totalUser.push(user);
            }
        }
    }

    function withdraw() external blockReEntry() {
        User storage user = users[msg.sender];
        uint256 totalAmount = getUserDividends(msg.sender);

        require(
            user.checkpoint.add(TIME_WITHDRAWN) <= block.timestamp,
            "Required: Withdrawn one time every day"
        );

        user.checkpoint = block.timestamp;
        stakingToken.transfer(user.owner, totalAmount);
        user.totalPayout = user.totalPayout.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function unStake(uint256 start) external payable blockReEntry() {
        require(msg.value == UNLOCK_FEE, "Required: Pay fee for unlock stake");
        User storage user = users[msg.sender];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].start == start &&
                user.deposits[i].isUnStake == false &&
                (user.deposits[i].finish > user.checkpoint ||
                    user.deposits[i].plan == 0)
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

                if (user.deposits[i].plan == 0) {
                    to = block.timestamp;
                }
                totalAmount = totalAmount.add(
                    share.mul(to.sub(from)).div(TIME_STEP)
                );
            }

            if (
                user.deposits[i].start == start &&
                user.deposits[i].isUnStake == false &&
                (block.timestamp >= user.deposits[i].finish ||
                    user.deposits[i].plan == 0)
            ) {
                user.deposits[i].isUnStake = true;
                totalAmount = totalAmount.add(user.deposits[i].amount);
                stakingToken.transfer(user.owner, totalAmount);
                user.totalPayout = user.totalPayout.add(totalAmount);
                emit UnStake(msg.sender, start, user.deposits[i].amount);
                commissionWallet.transfer(UNLOCK_FEE);
                emit FeePayed(msg.sender, UNLOCK_FEE);
            }
        }
    }

    function setOwner(address payable _addr) external onlyAdmins {
        owner = _addr;
    }

    function setFeeSystem(uint256 _fee) external onlyAdmins {
        PROJECT_FEE = _fee;
    }

    function setUnlockFeeSystem(uint256 _fee) external onlyAdmins {
        UNLOCK_FEE = _fee;
    }

    function setTime_Step(uint256 _timeStep) external onlyAdmins {
        TIME_STEP = _timeStep;
    }

    function setTime_Stake(uint256 _timeStake) external onlyAdmins {
        TIME_STAKE = _timeStake;
    }

    function setWithdrawn(uint256 _timeWithdrawn) external onlyAdmins {
        TIME_WITHDRAWN = _timeWithdrawn;
    }

    function setCommissionsWallet(address payable _addr) external onlyAdmins {
        commissionWallet = _addr;
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