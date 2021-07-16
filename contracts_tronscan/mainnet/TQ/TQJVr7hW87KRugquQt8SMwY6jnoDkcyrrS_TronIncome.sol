//SourceUnit: TronincomeFlat.sol

pragma solidity ^0.5.12;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership()
        public
        /*virtual*/
        onlyOwner
    {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner)
        public
        /*virtual*/
        onlyOwner
    {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

contract Investor is Ownable {
    using SafeMath for uint256;

    struct InvestorInfo {
        address referrer;
        uint256 totalInvestment;
        uint256 currentInvestedAmount;
        uint256 lastSettledTime;
        uint256 incomeLimitLeft;
        uint256 directReferralIncome;
        uint256 roiReferralIncome;
        uint256 investorPoolIncome;
        uint256 sponsorPoolIncome;
        uint256 whalePoolIncome;
        uint256 referralCount;
        uint256 totalVolumeTRX;
        uint256 cycle;
        bool isParticipateWhaleIncome;
    }

    struct InvestorDailyRounds {
        uint256 selfInvestment;
        uint256 trxVolume;
    }

    uint256[] public DIRECT_INCOME_REWARDS = [10];
    uint256[] public MATCHING_INCOME_REWARDS = [
        25,
        10,
        10,
        10,
        10,
        8,
        8,
        8,
        8,
        3,
        3,
        3,
        3,
        3,
        3,
        2,
        2,
        2,
        2,
        2,
        1,
        1,
        1,
        1,
        1
    ];
    uint256[] public DAILY_POOL_AWARD_PERCENTAGE = [50, 30, 20];

    mapping(address => InvestorInfo) public investors;
    mapping(address => uint256) public totalTeamPartners;
    mapping(address => mapping(uint256 => InvestorDailyRounds))
        public investorRounds;

    /****************************  EVENTS   *****************************************/

    event RegisterInvestor(
        address indexed investor,
        address indexed referrer
    );

    function registerInvestor(address _investor, address _referrer) internal {
        require(_investor != address(0x0), "Invalid investor address");
        require(_referrer != address(0x0), "Invalid referrer address");
        require(
            investors[_referrer].referrer != address(0x0),
            "Referrer does not exist"
        );

        investors[_investor].referrer = _referrer;

        _setTeamPartners(_investor);

        emit RegisterInvestor(_investor, _referrer);
    }

    function _setTeamPartners(address _investor) internal {
        address referrer = investors[_investor].referrer;
        uint256 totalLevels = MATCHING_INCOME_REWARDS.length;

        investors[referrer].referralCount = investors[referrer]
            .referralCount
            .add(1);

        for (uint256 i = 0; i < totalLevels; i++) {
            totalTeamPartners[referrer] = totalTeamPartners[referrer].add(1);

            if (referrer == owner()) break;

            referrer = investors[referrer].referrer;
        }
    }
}

contract Rating is Investor {
    using SafeMath for uint256;

    struct Leaderboard {
        uint256 amt;
        address addr;
    }

    Leaderboard[3] public topPromoters;
    Leaderboard[3] public topInvestors;
    Leaderboard[3] public lastTopInvestors;
    Leaderboard[3] public lastTopPromoters;

    uint256[3] public lastTopInvestorsWinningAmount;
    uint256[3] public lastTopPromotersWinningAmount;

    function _isInTop(address _investor, Leaderboard[3] memory _leaderboard)
        private
        pure
        returns (bool)
    {
        return (_leaderboard[0].addr == _investor ||
            _leaderboard[1].addr == _investor ||
            _leaderboard[2].addr == _investor);
    }

    function _placeInTop(Leaderboard[3] memory _leaderboard, uint256 _amt)
        private
        pure
        returns (uint256)
    {
        if (_amt < _leaderboard[2].amt) {
            return 0;
        }

        if (_amt > _leaderboard[0].amt) {
            return 1;
        }

        for (uint256 i = 2; i > 0; i--) {
            if (_leaderboard[i].amt < _amt && _amt <= _leaderboard[i - 1].amt)
                return i + 1;
        }
    }

    function addInTop(
        address _investor,
        Leaderboard[3] storage _leaderboard,
        uint256 _amt
    ) internal returns (bool) {
        if (_investor == address(0x0)) {
            return false;
        }

        uint256 place = _placeInTop(_leaderboard, _amt);
        uint256 currentPlace;

        if (place == 0) return false;

        if (_isInTop(_investor, _leaderboard)) {
            for (uint256 i = 0; i < 3; i++)
                if (_leaderboard[i].addr == _investor) currentPlace = i + 1;

            if (currentPlace - place == 1) {
                _leaderboard[currentPlace - 1].addr = _leaderboard[place - 1]
                    .addr;
                _leaderboard[currentPlace - 1].amt = _leaderboard[place - 1]
                    .amt;
            }

            if (currentPlace - place == 2) {
                _leaderboard[2].addr = _leaderboard[1].addr;
                _leaderboard[2].amt = _leaderboard[1].amt;
                _leaderboard[1].addr = _leaderboard[0].addr;
                _leaderboard[1].amt = _leaderboard[0].amt;
            }

            _leaderboard[place - 1].addr = _investor;
            _leaderboard[place - 1].amt = _amt;
            return true;
        }

        if (place == 1) {
            _leaderboard[2].addr = _leaderboard[1].addr;
            _leaderboard[2].amt = _leaderboard[1].amt;
            _leaderboard[1].addr = _leaderboard[0].addr;
            _leaderboard[1].amt = _leaderboard[0].amt;
        }

        if (place == 2) {
            _leaderboard[2].addr = _leaderboard[1].addr;
            _leaderboard[2].amt = _leaderboard[1].amt;
        }

        _leaderboard[place - 1].addr = _investor;
        _leaderboard[place - 1].amt = _amt;

        return true;
    }
}

contract Bonuses is Rating {
    using SafeMath for uint256;

    /****************************  EVENTS   *****************************************/

    event ReferralCommission(
        address indexed investor,
        address indexed referrer,
        uint256 amount
    );
    event RoundAwards(address indexed investor, uint256 indexed amount);

    function referralBonusTransferDirect(address _investor, uint256 _amount)
        internal
    {
        address referrer = investors[_investor].referrer;
        uint256 totalLevels = DIRECT_INCOME_REWARDS.length;
        InvestorInfo memory investor;

        for (uint256 i = 0; i < totalLevels; i++) {
            uint256 bonus = _amount.mul(DIRECT_INCOME_REWARDS[i]).div(100);
            investor = investors[referrer];

            if (investor.incomeLimitLeft >= bonus) {
                investors[referrer].incomeLimitLeft = investor
                    .incomeLimitLeft
                    .sub(bonus);
                investors[referrer].directReferralIncome = investor
                    .directReferralIncome
                    .add(bonus);

                emit ReferralCommission(_investor, referrer, bonus);
            } else if (investor.incomeLimitLeft != 0) {
                investors[referrer].directReferralIncome = investor
                    .directReferralIncome
                    .add(investor.incomeLimitLeft);
                investors[referrer].incomeLimitLeft = 0;

                emit ReferralCommission(
                    _investor,
                    referrer,
                    investor.incomeLimitLeft
                );
            }

            if (referrer == owner()) break;
        }
    }

    function referralBonusTransferDailyROI(address _investor, uint256 _amount)
        internal
    {
        address referrer = investors[_investor].referrer;
        uint256 totalLevels = MATCHING_INCOME_REWARDS.length;
        InvestorInfo memory investor;

        for (uint256 i = 0; i < totalLevels; i++) {
            uint256 bonus = _amount.mul(MATCHING_INCOME_REWARDS[i]).div(100);
            investor = investors[referrer];

            if (investor.incomeLimitLeft >= bonus) {
                investors[referrer].incomeLimitLeft = investor
                    .incomeLimitLeft
                    .sub(bonus);
                investors[referrer].roiReferralIncome = investor
                    .roiReferralIncome
                    .add(bonus);

                emit ReferralCommission(_investor, referrer, bonus);
            } else if (investor.incomeLimitLeft != 0) {
                investors[referrer].roiReferralIncome = investor
                    .roiReferralIncome
                    .add(investor.incomeLimitLeft);
                investors[referrer].incomeLimitLeft = 0;

                emit ReferralCommission(
                    _investor,
                    referrer,
                    investor.incomeLimitLeft
                );
            }

            if (referrer == owner()) break;

            referrer = investor.referrer;
        }
    }

    function distributeTopPromoters(uint256 _distributeAmount)
        internal
        returns (uint256)
    {
        uint256 distributedAmount;
        InvestorInfo memory investor;

        for (uint256 i = 0; i < 3; i++) {
            uint256 promoterPercentage = _distributeAmount
                .mul(DAILY_POOL_AWARD_PERCENTAGE[i])
                .div(100);

            if (topPromoters[i].addr != address(0x0)) {
                investor = investors[topPromoters[i].addr];

                if (investor.incomeLimitLeft >= promoterPercentage) {
                    investors[topPromoters[i].addr].incomeLimitLeft = investor
                        .incomeLimitLeft
                        .sub(promoterPercentage);
                    investors[topPromoters[i].addr].sponsorPoolIncome = investor
                        .sponsorPoolIncome
                        .add(promoterPercentage);

                    emit RoundAwards(topPromoters[i].addr, promoterPercentage);
                } else if (investor.incomeLimitLeft != 0) {
                    investors[topPromoters[i].addr].sponsorPoolIncome = investor
                        .sponsorPoolIncome
                        .add(investor.incomeLimitLeft);
                    investors[topPromoters[i].addr].incomeLimitLeft = 0;

                    emit RoundAwards(
                        topPromoters[i].addr,
                        investors[topPromoters[i].addr].incomeLimitLeft
                    );
                }

                distributedAmount = distributedAmount.add(promoterPercentage);
                lastTopPromoters[i].addr = topPromoters[i].addr;
                lastTopPromoters[i].amt = topPromoters[i].amt;
                lastTopPromotersWinningAmount[i] = promoterPercentage;
                topPromoters[i].addr = address(0x0);
                topPromoters[i].amt = 0;
            }
        }
        return distributedAmount;
    }

    function distributeTopInvestors(uint256 _distributeAmount)
        internal
        returns (uint256)
    {
        uint256 distributedAmount;
        InvestorInfo memory investor;

        for (uint256 i = 0; i < 3; i++) {
            uint256 investorPercentage = _distributeAmount
                .mul(DAILY_POOL_AWARD_PERCENTAGE[i])
                .div(100);

            if (topInvestors[i].addr != address(0x0)) {
                investor = investors[topPromoters[i].addr];

                if (investor.incomeLimitLeft >= investorPercentage) {
                    investors[topInvestors[i].addr].incomeLimitLeft = investor
                        .incomeLimitLeft
                        .sub(investorPercentage);
                    investors[topInvestors[i].addr]
                        .investorPoolIncome = investor.investorPoolIncome.add(
                        investorPercentage
                    );

                    emit RoundAwards(topInvestors[i].addr, investorPercentage);
                } else if (investor.incomeLimitLeft != 0) {
                    investors[topInvestors[i].addr]
                        .investorPoolIncome = investor.investorPoolIncome.add(
                        investor.incomeLimitLeft
                    );
                    investors[topInvestors[i].addr].incomeLimitLeft = 0;

                    emit RoundAwards(
                        topInvestors[i].addr,
                        investor.incomeLimitLeft
                    );
                }

                distributedAmount = distributedAmount.add(investorPercentage);
                lastTopInvestors[i].addr = topInvestors[i].addr;
                lastTopInvestors[i].amt = topInvestors[i].amt;
                lastTopInvestorsWinningAmount[i] = investorPercentage;
                topInvestors[i].addr = address(0x0);
                topInvestors[i].amt = 0;
            }
        }
        return distributedAmount;
    }
}

contract Round is Bonuses {
    struct DailyRound {
        uint256 startTime;
        uint256 endTime;
        bool ended; //has daily round ended
        uint256 pool; //amount in the pool;
    }

    uint256 constant POOL_TIME = 1 days;

    uint256 public roundID;

    mapping(uint256 => DailyRound) public round;

    //To start the new round for daily pool
    function startNewRound() public {
        require(
            now > round[roundID].endTime && round[roundID].ended == false,
            "Too early!"
        );
        uint256 _poolAmount = round[roundID].pool;

        if (
            _poolAmount >= 2000 trx
        ) {
            uint256 distributedSponsorAwards = distributeTopPromoters(
                round[roundID].pool.mul(10).div(100)
            );
            uint256 distributedInvestorAwards = distributeTopInvestors(
                round[roundID].pool.mul(10).div(100)
            );

            _poolAmount = _poolAmount.sub(
                distributedSponsorAwards.add(distributedInvestorAwards)
            );
        }

        round[roundID].ended = true;
        roundID++;
        round[roundID].startTime = now;
        round[roundID].endTime = now.add(POOL_TIME);
        round[roundID].pool = _poolAmount;
    }
}

contract Income is Round {
    uint256 public PASSIVE_ROI_PERCENT = 8;
    uint256 public PASSIVE_ROI_INTERVAL = 10 days;

    uint256 public totalWithdrawn = 11816325495;

    /****************************  EVENTS   *****************************************/

    event DailyPayout(
        address indexed investor,
        uint256 amount,
        uint256 timeStamp
    );
    event Withdraw(
        address indexed investor,
        uint256 amount,
        uint256 timeStamp
    );

    function currentDailyIncome(address _investor)
        public
        view
        returns (uint256)
    {
        uint256 _income = investors[_investor]
                .currentInvestedAmount
                .mul(PASSIVE_ROI_PERCENT)
                .div(100)
                .mul(now.sub(investors[_investor].lastSettledTime))
                .div(PASSIVE_ROI_INTERVAL);

        //check his income limit remaining
        if (investors[_investor].incomeLimitLeft >= _income) {
            return _income;
        }
        return investors[_investor].incomeLimitLeft;
    }

    //method to settle and withdraw the daily ROI
    function settleIncome(address _investor) private returns (uint256) {
        uint256 currInvestedAmount;

        uint256 _dailyIncome = currentDailyIncome(_investor);

        currInvestedAmount = investors[_investor].currentInvestedAmount;
        investors[_investor].incomeLimitLeft = investors[_investor]
            .incomeLimitLeft
            .sub(_dailyIncome);
        investors[_investor].lastSettledTime = now;

        emit DailyPayout(_investor, _dailyIncome, now);

        return _dailyIncome;
    }

    function claimIncome() public {
        address _investor = msg.sender;

        //settle the daily dividend
        uint256 _dailyIncome = settleIncome(_investor);

        referralBonusTransferDailyROI(_investor, _dailyIncome);

        uint256 _earnings = _dailyIncome +
            investors[_investor].directReferralIncome +
            investors[_investor].roiReferralIncome +
            investors[_investor].investorPoolIncome +
            investors[_investor].sponsorPoolIncome +
            investors[_investor].whalePoolIncome;

        //can only withdraw if they have some earnings.
        require(_earnings != 0, "Don't have earnings");

        if (address(this).balance < _earnings) {
            _earnings = address(this).balance;
        }

        totalWithdrawn = totalWithdrawn.add(_earnings);

        investors[_investor].directReferralIncome = 0;
        investors[_investor].roiReferralIncome = 0;
        investors[_investor].investorPoolIncome = 0;
        investors[_investor].sponsorPoolIncome = 0;
        investors[_investor].whalePoolIncome = 0;

        address(uint160(_investor)).transfer(_earnings);
        emit Withdraw(_investor, _earnings, now);
    }
}

contract TronIncomeInterface {
    function investors(address arg1)
        public
        returns (
            address referrer,
            uint256 totalInvestment,
            uint256 currentInvestedAmount,
            uint256 lastSettledTime,
            uint256 incomeLimitLeft,
            uint256 directReferralIncome,
            uint256 roiReferralIncome,
            uint256 investorPoolIncome,
            uint256 sponsorPoolIncome,
            uint256 whalePoolIncome,
            uint256 referralCount,
            uint256 totalVolumeTRX,
            uint256 cycle,
            bool isParticipateWhaleIncome
        );
}

contract TronIncome is Income {
    using SafeMath for uint256;

    uint256 constant HOUSE_FEE = 3; // Owner's comission
    uint256 constant WHALE_FEE = 3; // Whale's comission
    uint256 constant DAILY_WIN_POOL = 4;
    uint256 public MAX_ROI = 300; // Max ROI percent
    uint256 public WHALE_POOL = 2000000 trx; // If investment amount is higher then WHALE_POOL patricipate in whale pool

    address private unlimited;
    address private migrator;

    uint256 public totalInvested = 272463000000;
    address[] public whalePoolInvestors;

    uint256[] public CYCLES = [
        500000 trx,
        2000000 trx,
        4500000 trx,
        15000000 trx
    ];

    /****************************  EVENTS   *****************************************/

    event Investment(
        address indexed investor,
        address indexed referrer,
        uint256 amount
    );
    event WhaleIncome(
        address indexed whale,
        address investor,
        uint256 amount
    );

    constructor(
        address _unlimited,
        uint256 _initialFund
    ) public {
        roundID = 1;
        round[1].startTime = now;
        round[1].endTime = now.add(POOL_TIME);
        round[roundID].pool = 8586 trx;

        whalePoolInvestors.push(_unlimited);

        unlimited = _unlimited;
        migrator = msg.sender;
    }

    // If someone accidently sends trx to contract address
    function() external payable {
        if (msg.sender != owner()) {
            join(address(0x0));
        }
    }

    function join(address _referrer)
        public
        payable
    {
        InvestorInfo memory investor = investors[msg.sender];

        uint256 amount = msg.value;
        address referrer = _referrer != address(0x0) ? _referrer : unlimited;

        if (referrer == msg.sender) {
            referrer = unlimited;
        }

        require(
            investors[referrer].referrer != address(0x0),
            "Invalid referrer"
        );

        if (investor.referrer == address(0x0)) {
            registerInvestor(msg.sender, referrer);
        }

        _investment(msg.sender, amount);
    }

    function _investment(address _investor, uint256 _amount) private {
        InvestorInfo storage investor = investors[_investor];

        require(
            investor.incomeLimitLeft == 0,
            "Previous cycle is still active"
        );
        require(
            _amount % 1 trx == 0,
            "Amount must be in multiple of 1 TRX."
        );
        require(
            _amount >= 100 trx,
            "Minimum contribution amount is 100 TRX."
        );
        require(
            _amount >= investor.currentInvestedAmount.mul(150).div(100),
            "Cannot invest less than x1.5 amount"
        );

        if (investor.cycle < CYCLES.length) {
            require(
                _amount <= CYCLES[investor.cycle],
                "Too much for the next cycle"
            );
        }

        investor.cycle = investor.cycle.add(1);

        investor.lastSettledTime = now;
        investor.currentInvestedAmount = _amount;
        investor.incomeLimitLeft = _amount.mul(MAX_ROI).div(100);
        investor.totalInvestment = investor.totalInvestment.add(_amount);

        // update investor's investment in current round
        investorRounds[_investor][roundID]
            .selfInvestment = investorRounds[_investor][roundID]
            .selfInvestment
            .add(_amount);

        uint256 whalesCount = whalePoolInvestors.length;
        uint256 eachWhaleBonus = _amount.mul(WHALE_FEE).div(100).div(
            whalesCount
        );

        for (uint256 i = 0; i < whalesCount; i++) {
            investors[whalePoolInvestors[i]]
                .whalePoolIncome = investors[whalePoolInvestors[i]]
                .whalePoolIncome
                .add(eachWhaleBonus);

            emit WhaleIncome(whalePoolInvestors[i], _investor, eachWhaleBonus);
        }

        if (_amount >= WHALE_POOL && !investor.isParticipateWhaleIncome) {
            whalePoolInvestors.push(_investor);
            investor.isParticipateWhaleIncome = true;
        }

        investors[investor.referrer].totalVolumeTRX = investors[investor
            .referrer]
            .totalVolumeTRX
            .add(_amount);
        investorRounds[investor.referrer][roundID]
            .trxVolume = investorRounds[investor.referrer][roundID]
            .trxVolume
            .add(_amount);

        addInTop(
            _investor,
            topInvestors,
            investorRounds[_investor][roundID].selfInvestment
        );
        addInTop(
            investor.referrer,
            topPromoters,
            investorRounds[investor.referrer][roundID].trxVolume
        );
        referralBonusTransferDirect(_investor, _amount);

        totalInvested = totalInvested.add(_amount);
        round[roundID].pool = round[roundID].pool.add(
            _amount.mul(DAILY_WIN_POOL).div(100)
        );

        address(uint160(owner())).transfer(_amount.mul(HOUSE_FEE).div(100));

        emit Investment(_investor, investor.referrer, _amount);
    }

    // Migration function, to be disabled after 3 days

    modifier onlyTestPeriod() {
        require(
            round[1].startTime.add(3 days) > block.timestamp,
            "Test Days already passed!"
        );
        _;
    }

    function migrate(address _newContract) public onlyOwner onlyTestPeriod {
        address(uint160(_newContract)).transfer(address(this).balance);
    }

    mapping(address => bool) private isUserMigrated;
    mapping(address => bool) private isTeamPartnersSet;

    function addInvestor(address _investor, address _oldContract)
        external
        onlyTestPeriod
        returns (bool)
    {
        require(msg.sender == migrator, 'Only migrator');
        require(!isUserMigrated[_investor], 'Already migrated');

        TronIncomeInterface tronIncomeInterface = TronIncomeInterface(_oldContract);

        (
          investors[_investor].referrer,
          investors[_investor].totalInvestment,
          investors[_investor].currentInvestedAmount,
          investors[_investor].lastSettledTime,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
        ) = tronIncomeInterface.investors(_investor);

        (
          ,
          ,
          ,
          ,
          investors[_investor].incomeLimitLeft,
          investors[_investor].directReferralIncome,
          investors[_investor].roiReferralIncome,
          investors[_investor].investorPoolIncome,
          ,
          ,
          ,
          ,
          ,
        ) = tronIncomeInterface.investors(_investor);

        (
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          investors[_investor].sponsorPoolIncome,
          investors[_investor].whalePoolIncome,
          ,
          investors[_investor].totalVolumeTRX,
          ,
        ) = tronIncomeInterface.investors(_investor);

        (
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          ,
          investors[_investor].cycle,
          
        ) = tronIncomeInterface.investors(_investor);
        isUserMigrated[_investor] = true;
        return isUserMigrated[_investor];
    }

    function setTeamPartners(address _investor) external onlyTestPeriod returns (bool) {
        require(msg.sender == migrator, 'Only migrator');
        require(!isTeamPartnersSet[_investor], 'Already migrated');
        _setTeamPartners(_investor);
        isTeamPartnersSet[_investor] = true;
        return isTeamPartnersSet[_investor];
    }
}