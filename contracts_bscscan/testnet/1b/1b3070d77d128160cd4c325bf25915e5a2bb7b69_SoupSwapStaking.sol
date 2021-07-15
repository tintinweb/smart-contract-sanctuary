pragma solidity 0.8.0;

import "./IBEP20.sol";
import "./SafeMath.sol";
import "./DataStorage.sol";
import "./Access.sol";
import "./Events.sol";
import "./Manageable.sol";
import "./Utils.sol";

contract SoupSwapStaking is DataStorage, Access, Events, Manageable, Utils {
    using SafeMath for uint256;
    // Token used for staking
    IBEP20 stakingToken;

    /**
     * @dev Constructor function
     * @param _stakingToken ERC20/BEP20 The address of the token contract used for staking
     */
    constructor(
        IBEP20 _stakingToken,
        address payable wallet
    ) public {
        stakingToken = _stakingToken;
        commissionWallet = wallet;
        reentryStatus = ENTRY_ENABLED;

        plans.push(Plan(15, 100));
        plans.push(Plan(30, 116));
        plans.push(Plan(90, 150));
        plans.push(Plan(180, 200));
        plans.push(Plan(360, 240));
    }

    function invest(
        address payable referrer,
        uint8 plan,
        uint256 _amount
    ) external blockReEntry() {
        require(_amount >= INVEST_MIN_AMOUNT);
        require(plan < 5, "Invalid plan");
        require(
            stakingToken.allowance(msg.sender, address(this)) >= _amount,
            "Token allowance too low"
        );

        _safeTransferFrom(msg.sender, address(this), _amount);

        User storage user = users[msg.sender];
        uint256 fee = 0;
        if (PROJECT_FEE > 0) {
            fee = _amount.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
            commissionWallet.transfer(fee);
            emit FeePayed(msg.sender, fee);
        }

        if (user.referrer == address(0)) {
            if (
                (users[referrer].deposits.length > 0 &&
                    referrer != msg.sender) ||
                (users[referrer].isImport == true)
            ) {
                user.referrer = referrer;
            }

            address upline = user.referrer;
            for (uint256 i = 0; i < 3; i++) {
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

            for (uint256 i = 0; i < 3; i++) {
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
                    emit RefBonus(upline, msg.sender, i, amount);
                    upline = users[upline].referrer;
                } else break;
            }
        }

        if (user.deposits.length == 0) {
            user.checkpoint = block.timestamp;
            emit Newbie(msg.sender, referrer);
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
                msg.sender,
                fee,
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
                msg.sender,
                fee,
                false
            )
        );
        emit NewDeposit(
            msg.sender,
            plan,
            percent,
            _amount,
            block.timestamp,
            finish,
            fee
        );
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

                user.referrer = userNoFee[index].referrer;
                user.isImport = true;

                if (user.deposits.length == 0) {
                    user.checkpoint = block.timestamp;
                }

                totalUser.push(user);
            }
        }
    }

    function stakeNoFee(StakeNoFee memory stakes)
        external
        onlyAdmins
        blockReEntry()
    {
        _stakeNoFee(stakes);
    }

    function _stakeNoFee(StakeNoFee memory stakes) internal {
        User storage user = users[stakes.userAddress];
        for (uint256 index = 0; index < stakes.deposits.length; index++) {
            user.deposits.push(stakes.deposits[index]);
            totalDeposits.push(stakes.deposits[index]);
        }
    }

    function withdraw() public blockReEntry() {
        User storage user = users[msg.sender];

        uint256 totalAmount = getUserDividends(msg.sender);

        uint256 referralBonus = getUserReferralBonus(msg.sender);
        if (referralBonus > 0) {
            user.bonus = 0;
            totalAmount = totalAmount.add(referralBonus);
        }

        require(totalAmount > 5 ether, "Minimum withdraw is 5 SPW");

        user.checkpoint = block.timestamp;
        stakingToken.transfer(msg.sender, totalAmount);
        user.totalPayout = user.totalPayout.add(totalAmount);
        emit Withdrawn(msg.sender, totalAmount);
    }

    function unStake(uint256 start) public blockReEntry() {
        User storage user = users[msg.sender];
        uint256 totalAmount;

        for (uint256 i = 0; i < user.deposits.length; i++) {
            if (
                user.deposits[i].start == start &&
                user.deposits[i].isUnStake == false &&
                user.deposits[i].finish > user.checkpoint
            ) {
                user.deposits[i].isUnStake = true;
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

                if (
                    user.deposits[i].start == start &&
                    user.deposits[i].isUnStake == false &&
					block.timestamp >= user.deposits[i].finish
                ) {
                    totalAmount.add(user.deposits[i].amount);
                    stakingToken.transfer(msg.sender, totalAmount);
                    user.totalPayout = user.totalPayout.add(totalAmount);
                    emit UnStake(msg.sender, start, user.deposits[i].amount);
                }
            }
        }
    }

    function setOwner(address payable _addr) external onlyAdmins {
        owner = _addr;
    }

    function setFeeSystem(uint256 _fee) external onlyAdmins {
        PROJECT_FEE = _fee;
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

        stakingToken.transfer(_addr, _amount);
    }

    function _safeTransferFrom(
        address _sender,
        address _recipient,
        uint256 _amount
    ) private {
        bool sent = stakingToken.transferFrom(_sender, _recipient, _amount);
        require(sent, "Token transfer failed");
    }
}