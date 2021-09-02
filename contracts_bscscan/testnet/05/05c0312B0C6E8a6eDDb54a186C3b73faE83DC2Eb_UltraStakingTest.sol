/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract UltraStakingTest {
    using SafeMath for uint256;

    struct User {
        address referrer;
        uint256 cycle;
        uint256 rewards;
        uint256 deposit_amount;
        uint256 deposit_time;
        uint256 claim_time;
        uint256 total_deposits;
        uint256 total_withdraws;
        uint256 last_distPoints;
        uint256 num_tickets_roll;
        uint256 num_tickets_deposit;
        uint256 winnings;
        bool auto_roll;
    }

    address payable public glass;
    address payable private dev;
    
    mapping(uint256 => uint256[]) public lotteryInfo;
    mapping(uint256 => mapping(uint256 => address)) public lotteryContestants;
    mapping(address => User) public users;
    address[] public userIndices;

    uint256 public total_users;
    uint256 public total_deposited;
    uint256 public total_withdrawn;
    uint256 public total_rewards;
    uint256 public rewardTime;
    uint256 public lastDripTime;
    uint256 public ticketPrice;
    uint256 public maxTickets;
    uint256 public minReferrer;
    uint256 public dripRate;
    uint256 public largestRewardBP;
    uint256 public randomRewardBP;
    uint256 public largestDayDeposit;
    address public largestDayDepositer;
    uint256 public totalDistributeRewards;
    address public pastLargestWinner;
    address[] public pastRandomWinners;
    uint256 public totalDistributePoints;
    uint256 public rolloverDistributePoints;
    uint256 public unclaimedDistributeRewards;
    uint256 public compoundFeePercent;
    uint256 public depositFeePercent;
    uint256 public claimFeePercent;
    uint256 public lotteryId;
    uint256 public ticketId;
    uint256 public reductionWeigthPercent;
    uint256 public weekDay;
    uint256 public numRandomWinners;
    uint256 public winningsClaimFeePercent;
    uint256 public lotteryTime;
    bool public depositEnabled;
    uint256 public constant MULTIPLIER = 1e12;

    event NewDeposit(address indexed addr, address indexed ref, uint256 amount);
    event DirectPayout(
        address indexed addr,
        address indexed from,
        uint256 amount
    );
    event Withdraw(address indexed addr, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    constructor() public {
        ticketPrice = SafeMath.mul(3e9, 1 gwei);
        maxTickets = 50;
        minReferrer = SafeMath.mul(27e8, 1 gwei);
        rewardTime = 1629583200;
        lotteryTime = rewardTime.add(70 minutes);
        largestRewardBP = 24; // 0.24%
        randomRewardBP = 250; // 2.5%
        dripRate = 4320000; // 2% daily
        lastDripTime = now;
        compoundFeePercent = 18;
        depositFeePercent = 10;
        claimFeePercent = 10;
        ticketId = 0;
        lotteryId = 0;
        reductionWeigthPercent = 40;
        numRandomWinners = 10;
        winningsClaimFeePercent = 33;

        dev = msg.sender;
        glass = 0x9c9d4302A1A550b446401e56000F76Bc761C3A33;
        depositEnabled = true;
    }

    receive() external payable {
        revert("Do not send BNB.");
    }

    modifier onlyDev() {
        require(msg.sender == dev, "Caller is not the dev!");
        _;
    }

    function changeDev(address payable newDev) external onlyDev {
        require(newDev != address(0), "Zero address");
        dev = newDev;
    }
    
    function migrateGlobals(
        uint256 _rewardTime,
        uint256 _total_users,
        uint256 _total_deposited,
        uint256 _total_withdrawn,
        uint256 _total_rewards,
        uint256 _lastDripTime,
        uint256 _largestDayDeposit,
        address _largestDayDepositer,
        uint256 _totalDistributeRewards,
        uint256 _totalDistributePoints,
        uint256 _rolloverDistributePoints,
        uint256 _unclaimedDistributeRewards
    ) external onlyDev {
        rewardTime = _rewardTime;
        total_users = _total_users;
        total_deposited = _total_deposited;
        total_withdrawn = _total_withdrawn;
        total_rewards = _total_rewards;
        lastDripTime = _lastDripTime;
        largestDayDeposit = _largestDayDeposit;
        largestDayDepositer = _largestDayDepositer;
        totalDistributeRewards = _totalDistributeRewards;
        totalDistributePoints = _totalDistributePoints;
        rolloverDistributePoints = _rolloverDistributePoints;
        unclaimedDistributeRewards = _unclaimedDistributeRewards;
    }
    
    function migrateUsers(address[] memory _addr, User[] memory _user) external onlyDev {        
        for (uint256 i = 0; i < _addr.length; i++) {            
            if (users[_addr[i]].deposit_time == 0) {
                if (_user[i].num_tickets_deposit > 0)
                    _buyTickets(_addr[i], _user[i].num_tickets_deposit);
                if (_user[i].num_tickets_roll > 0)
                    _buyTickets(_addr[i], _user[i].num_tickets_roll);

                userIndices.push(_addr[i]);
                users[_addr[i]] = _user[i];
            }      
        }
    }

    function setUser(address _addr, User memory _user) external onlyDev {
        require(users[_addr].deposit_time > 0, "User does not exist");        
        users[_addr] = _user;
    }

    function setDepositEnabled(bool enabled) external onlyDev {
        depositEnabled = enabled;
    }

    function setRewardTime(uint256 time) external onlyDev {
        rewardTime = time;
        lotteryTime = time.add(70 minutes);
    }

    function setLargestRewardBP(uint256 bp) external onlyDev {
        largestRewardBP = bp;
    }
    
    function setRandomRewardBP(uint256 bp) external onlyDev {
        randomRewardBP = bp;
    }

    function setTicketPrice(uint256 amnt) external onlyDev {
        ticketPrice = amnt;
    }
    
    function setMaxTickets(uint256 amnt) external onlyDev {
        maxTickets = amnt;
    }
    
    function setMinReferrer(uint256 amnt) external onlyDev {
        minReferrer = amnt;
    }
    
    function setDripRate(uint256 rate) external onlyDev {
        dripRate = rate;
    }
    
    function setCompoundFeePercent(uint256 percent) external onlyDev {
        compoundFeePercent = percent;
    }
    
    function setDepositFeePercent(uint256 percent) external onlyDev {
        depositFeePercent = percent;
    }
    
    function setClaimFeePercent(uint256 percent) external onlyDev {
        claimFeePercent = percent;
    }
    
    function setReductionWeigthPercent(uint256 percent) external onlyDev {
        reductionWeigthPercent = percent;
    }
    
    function setWeekDay(uint256 day) external onlyDev {
        weekDay = day;
    }
    
    function setNumRandomWinners(uint256 numWinners) external onlyDev {
        numRandomWinners = numWinners;
    }

    function setWinningsClaimFeePercent(uint256 percent) external onlyDev {
        winningsClaimFeePercent = percent;
    }
    
    function setLotteryTime(uint256 time) external onlyDev {
        lotteryTime = time;
    }

    function setAutoRoll(address user, bool canAuto) external onlyDev {
        users[user].auto_roll = canAuto;
    }

    function emergencyWithdraw(uint256 amnt) external onlyDev {
        IBEP20(glass).transfer(dev, amnt);
    }

    function timeToReward() external view returns (uint256) {
        return now < rewardTime ? rewardTime - now : 0;
    }

    function random(uint256 _exlcusiveMax, uint256 _randInt) external view returns (uint256) {
        return _random(_exlcusiveMax, _randInt);
    }

    function listPastRandomWinners() external view returns (address[] memory) {
        return pastRandomWinners;
    }

    function _random(uint256 _exlcusiveMax, uint256 _randInt) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        block.timestamp,
                        block.difficulty,
                        _randInt
                    )
                )
            ) % _exlcusiveMax;
    }

    function trySendReward() external {
        return _trySendReward();
    }

    function _trySendReward() internal {
        if (now >= rewardTime) {
            weekDay ++;
            delete pastRandomWinners;

            uint256 reward1 = _getGlassBalancePool().mul(largestRewardBP).div(10000);
            uint256 reward2 = _getGlassBalancePool().mul(randomRewardBP).div(10000);
            address receiver1 = largestDayDepositer;

            if (receiver1 != address(0) && reward1 > 0) {
                if (reward1 > _getGlassBalancePool()) {
                    reward1 = _getGlassBalancePool();
                }

                users[receiver1].rewards = users[receiver1].rewards.add(reward1);
                total_rewards = total_rewards.add(reward1);
            }

            if (weekDay >= 7) {
                if (reward2 > _getGlassBalancePool()) {
                    reward2 = _getGlassBalancePool();
                }
                
                uint256 singleReward2 = reward2.div(numRandomWinners);
                uint256 randInt = _random(numRandomWinners, ticketId);
                
                for (uint256 i = 0; i < numRandomWinners; i++) {
                    address receiver2 = ticketId > 0 ? lotteryContestants[lotteryId][_random(ticketId, randInt++)] : address(0);

                    if (receiver2 != address(0) && singleReward2 > 0) {
                        
                        bool duplicate = false;
                        
                        for (uint256 j = 0; j < i; j++) {
                            if (pastRandomWinners[j] == receiver2) {
                                duplicate = true;
                                break;
                            }
                        }

                        if (duplicate) {
                            i--;
                            continue;
                        }

                        users[receiver2].winnings = users[receiver2].winnings.add(singleReward2);
                        total_rewards = total_rewards.add(singleReward2);
                        pastRandomWinners[i] = receiver2;
                    }
                }

                rolloverDistributePoints = totalDistributePoints;
                total_rewards = total_rewards.sub(unclaimedDistributeRewards);
                unclaimedDistributeRewards = 0;

                lotteryTime = lotteryTime.add(70 minutes);
                weekDay = 0;
            }

            pastLargestWinner = receiver1;

            lastDripTime = now;
            largestDayDeposit = 0;
            largestDayDepositer = address(0);
            
            ticketId = 0;
            lotteryId++;

            rewardTime = rewardTime.add(10 minutes);
        }
    }

    function _buyTickets(address to, uint256 numTix) internal {
        for (uint256 i = 0; i < numTix; i++) {
            lotteryContestants[lotteryId][ticketId++] = to;
        }
    }

    function _deposit(
        address _addr,
        uint256 _amount,
        address _referrer
    ) internal {
        require(depositEnabled, "Disabled.");
        if (_referrer != address(0)) {
            require(_referrer != _addr, "Cannot refer self.");
            require(
                users[_referrer].total_deposits > minReferrer,
                "Referrer has not depositted enough GLASS."
            );
        }
        require(_amount >= 1 gwei, "You must deposit a minimum of 1 GLASS.");
        require(
            IBEP20(glass).balanceOf(_addr) >= _amount,
            "Insufficient GLASS balance."
        );
        require(
            IBEP20(glass).allowance(_addr, address(this)) >= _amount,
            "Insufficient GLASS allowance."
        );

        // if (getTotalRewards(_addr) > 0) {
        //     claim();
        // }
        /////////////////
        _trySendReward();
        /////////////////

        if (users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
            
            if (users[_addr].deposit_time < SafeMath.sub(lotteryTime, 70 minutes)) {
                users[_addr].num_tickets_deposit = 0;
                users[_addr].num_tickets_roll = 0;
            }
        } else {
            userIndices.push(_addr); // New user
            users[_addr].last_distPoints = totalDistributePoints;
            total_users++;
        }

        uint256 largestReward = _getGlassBalancePool().mul(largestRewardBP).div(10000);
        uint256 balanceBefore = _getGlassBalance();
        IBEP20(glass).transferFrom(_addr, address(this), _amount);

        uint256 amountWithFee = _getGlassBalance().sub(balanceBefore);
        amountWithFee = amountWithFee.mul(SafeMath.sub(100, depositFeePercent)).div(100);

        users[_addr].referrer = _referrer;
        users[_addr].deposit_amount = amountWithFee;
        users[_addr].deposit_time = now;
        users[_addr].total_deposits = users[_addr].total_deposits.add(amountWithFee);

        total_deposited = total_deposited.add(amountWithFee);

        if (_referrer != address(0)) {
            users[_referrer].rewards = users[_referrer].rewards.add( // 3% (ref)
                amountWithFee.mul(3).div(100)
            );

            total_rewards = total_rewards.add(amountWithFee.mul(3).div(100));
        }

        IBEP20(glass).transfer(dev, amountWithFee.mul(2).div(100)); // 2% (dev)
        _disperse(amountWithFee.mul(8).div(100)); // 8% (users)

        if (
            amountWithFee > largestDayDeposit &&
            amountWithFee > largestReward.mul(SafeMath.sub(100, depositFeePercent)).div(100)
        ) {
            largestDayDeposit = amountWithFee;
            largestDayDepositer = _addr;
        }
        if (_amount >= ticketPrice) {
            uint256 numTix = (_amount.add(1)).div(ticketPrice);
            if (numTix > maxTickets)
                numTix = maxTickets;
            if (numTix.add(users[_addr].num_tickets_deposit) > maxTickets.mul(weekDay.add(1)))
                numTix = maxTickets.mul(weekDay.add(1)).sub(users[_addr].num_tickets_deposit);

            _buyTickets(_addr, numTix);
            users[_addr].num_tickets_deposit = users[_addr].num_tickets_deposit.add(numTix);
        }

        emit NewDeposit(_addr, _referrer, amountWithFee);
    }

    function deposit(uint256 amount) external {
        _deposit(msg.sender, amount, address(0));
    }

    function deposit(uint256 amount, address referrer) external {
        _deposit(msg.sender, amount, referrer);
    }

    function roll(address user) external {
        require(users[user].auto_roll, "User cannot auto-roll.");
        _roll(user);
    }

    function roll() public {
        _roll(msg.sender);
    }

    function _roll(address _sender) internal {
        require(depositEnabled, "Disabled.");

        _dripRewards();

        uint256 _rewards = getRewards(_sender);
        require(_rewards > 0, "No rewards.");

        unclaimedDistributeRewards = unclaimedDistributeRewards.sub(getDistributionRewards(_sender));

        users[_sender].claim_time = now;
        users[_sender].total_withdraws = users[_sender].total_withdraws.add(_rewards.sub(users[_sender].rewards).sub(users[_sender].winnings));
        total_withdrawn = total_withdrawn.add(_rewards);

        total_rewards = total_rewards.sub(_rewards);
        users[_sender].rewards = 0;
        users[_sender].winnings = 0;

        users[_sender].last_distPoints = totalDistributePoints;

        emit Withdraw(_sender, _rewards);

        /////////////////
        _trySendReward();
        /////////////////

        users[_sender].cycle++;
            
        if (users[_sender].deposit_time < SafeMath.sub(lotteryTime, 70 minutes)) {
            users[_sender].num_tickets_deposit = 0;
            users[_sender].num_tickets_roll = 0;
        }

        uint256 largestReward = _getGlassBalancePool().mul(largestRewardBP).div(10000);
        uint256 rewardsPostClaim = _rewards.mul(SafeMath.sub(100, claimFeePercent)).div(100);
        _rewards = _rewards.mul(SafeMath.sub(100, compoundFeePercent)).div(100);

        users[_sender].deposit_amount = _rewards;
        users[_sender].deposit_time = now;
        users[_sender].total_deposits = users[_sender].total_deposits.add(_rewards);

        total_deposited = total_deposited.add(_rewards);

        address referrer = users[_sender].referrer;
        if (referrer != address(0)) {
            users[referrer].rewards = users[referrer].rewards.add( // 3% (ref)
                _rewards.mul(3).div(100)
            );

            total_rewards = total_rewards.add(_rewards.mul(3).div(100));
        }

        IBEP20(glass).transfer(dev, _rewards.mul(2).div(100)); // 2% (dev)
        _disperse(_rewards.mul(8).div(100)); // 8% (users)

        if (
            _rewards > largestDayDeposit &&
            _rewards > largestReward.mul(SafeMath.sub(100, depositFeePercent)).div(100)
        ) {
            largestDayDeposit = _rewards;
            largestDayDepositer = _sender;
        }
        if (rewardsPostClaim >= ticketPrice) {
                uint256 numTix = (rewardsPostClaim.add(1)).div(ticketPrice);
            if (numTix > maxTickets)
                numTix = maxTickets;
            if (numTix.add(users[_sender].num_tickets_roll) > maxTickets.mul(weekDay.add(1)))
                numTix = maxTickets.mul(weekDay.add(1)).sub(users[_sender].num_tickets_roll);

            _buyTickets(_sender, numTix);
            users[_sender].num_tickets_roll = users[_sender].num_tickets_roll.add(numTix);
        }

        emit NewDeposit(_sender, referrer, _rewards);
    }
    
    function _disperse(uint256 amount) internal {
        if (amount > 0 && total_deposited > 0) {
            totalDistributePoints = totalDistributePoints.add(amount.mul(MULTIPLIER).div(total_deposited));
            totalDistributeRewards = totalDistributeRewards.add(amount);
            total_rewards = total_rewards.add(amount);
            unclaimedDistributeRewards = unclaimedDistributeRewards.add(amount);
        }
    }

    function getDistributionRewards(address account) public view returns (uint256) {
        uint256 newDividendPoints;
        if (users[account].last_distPoints >= rolloverDistributePoints) { // last_DistPoints updated today
            newDividendPoints = totalDistributePoints.sub(users[account].last_distPoints);
        } else {
            newDividendPoints = totalDistributePoints.sub(rolloverDistributePoints);
        }

        return users[account].total_deposits.mul(newDividendPoints).mul(poolShareReductionFactor(account)).div(MULTIPLIER).div(MULTIPLIER);
    }

    function poolShareReductionFactor(address account) public view returns (uint256) {
        uint256 dcRatio = SafeMath.sub(MULTIPLIER, (users[account].total_withdraws.mul(SafeMath.sub(100, claimFeePercent)).div(100)).mul(MULTIPLIER).div(users[account].total_deposits));
        return ((((SafeMath.sub(MULTIPLIER, dcRatio)).mul(reductionWeigthPercent)).div(100)).add(dcRatio));
    }

    function getRewards(address _user) public view returns (uint256) {
        return users[_user].rewards.add(users[_user].winnings).add(getDistributionRewards(_user));
    }
    
    function getTotalRewards(address _user) public view returns (uint256) {
        return
            users[_user].total_deposits > 0
                ? getRewards(_user).add(
                    _getRewardDrip()
                        .mul(users[_user].total_deposits)
                        .mul(poolShareReductionFactor(_user))
                        .div(total_deposited)
                        .div(MULTIPLIER)
                )
                : 0;
    }

    function claim() public {
        _dripRewards();

        address _sender = msg.sender;
        uint256 _rewards = getRewards(_sender);
        require(_rewards > 0, "No rewards.");

        uint256 winnings = users[_sender].winnings;
        
        if (winnings > 0) {
            _rewards = _rewards.sub(winnings);
            _rewards = _rewards.add(winnings.mul(SafeMath.sub(100, winningsClaimFeePercent)).div(100));
        }

        unclaimedDistributeRewards = unclaimedDistributeRewards.sub(getDistributionRewards(_sender));

        users[_sender].claim_time = now;
        users[_sender].total_withdraws = users[_sender].total_withdraws.add(_rewards.sub(users[_sender].rewards).sub(users[_sender].winnings));
        total_withdrawn = total_withdrawn.add(_rewards);

        IBEP20(glass).transfer(_sender, _rewards.mul(SafeMath.sub(100, claimFeePercent)).div(100));
        total_rewards = total_rewards.sub(_rewards);
        users[_sender].rewards = 0;
        users[_sender].winnings = 0;

        users[_sender].last_distPoints = totalDistributePoints;

        if (users[_sender].deposit_time < SafeMath.sub(lotteryTime, 70 minutes)) {
            users[_sender].num_tickets_deposit = 0;
            users[_sender].num_tickets_roll = 0;
        }

        emit Withdraw(_sender, _rewards);
    }

    function dripRewards() external {
        _dripRewards();
    }

    function _dripRewards() internal {
        uint256 drip = _getRewardDrip();

        if (drip > 0) {
            _disperse(drip);
            lastDripTime = now;
        }
    }

    function _getRewardDrip() internal view returns (uint256) {
        if (lastDripTime < now) {
            uint256 poolBalance = _getGlassBalancePool();
            uint256 secondsPassed = now.sub(lastDripTime);
            uint256 drip = secondsPassed.mul(poolBalance).div(dripRate);

            if (drip > poolBalance) {
                drip = poolBalance;
            }

            return drip;
        }
        return 0;
    }

    function getRewardDrip() external view returns (uint256) {
        return _getRewardDrip();
    }

    function getDayDripEstimate(address _user) external view returns (uint256) {
        return
            users[_user].total_deposits > 0
                ? _getGlassBalancePool()
                    .mul(86400)
                    .mul(users[_user].total_deposits)
                    .mul(poolShareReductionFactor(_user))
                    .div(total_deposited)
                    .div(dripRate)
                    .div(MULTIPLIER)
                : 0;
    }

    function userInfo(address _addr)
        external
        view
        returns (
            uint256 deposit_time,
            uint256 deposit_amount,
            uint256 rewards,
            address referrer
        )
    {
        return (
            users[_addr].deposit_time,
            users[_addr].deposit_amount,
            users[_addr].rewards,
            users[_addr].referrer
        );
    }

    function userInfoTotals(address _addr)
        external
        view
        returns (
            uint256 total_withdraws,
            uint256 total_deposits,
            uint256 last_distPoints
        )
    {
        return (
            users[_addr].total_withdraws,
            users[_addr].total_deposits,
            users[_addr].last_distPoints
        );
    }

    function contractInfo()
        external
        view
        returns (
            uint256 _total_users,
            uint256 _total_deposited,
            uint256 _total_withdrawn,
            uint256 _total_rewards,
            uint256 _totalDistributeRewards
        )
    {
        return (total_users, total_deposited, total_withdrawn, total_rewards, totalDistributeRewards);
    }

    function getGlassBalancePool() external view returns (uint256) {
        return _getGlassBalancePool();
    }

    function _getGlassBalancePool() internal view returns (uint256) {
        return _getGlassBalance().sub(total_rewards);
    }

    function _getGlassBalance() internal view returns (uint256) {
        return IBEP20(glass).balanceOf(address(this));
    }

    function getGlassBalance() external view returns (uint256) {
        return _getGlassBalance();
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}