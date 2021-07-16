//SourceUnit: CyberTron.sol

pragma solidity ^0.5.10;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library DataStructs {
    struct DailyRound {
        uint256 startTime;
        uint256 endTime;
        bool ended; //has daily round ended
        uint256 pool; //amount in the pool;
    }

    struct Player {
        uint256 totalInvestment;
        uint256 totalVolumeTRX;
        uint256 eventVariable;
        uint256 directReferralIncome;
        uint256 roiReferralIncome;
        uint256 currentInvestedAmount;
        uint256 dailyIncome;
        uint256 lastSettledTime;
        uint256 incomeLimitLeft;
        uint256 investorPoolIncome;
        uint256 sponsorPoolIncome;
        uint256 superIncome;
        uint256 referralCount;
        address referrer;
    }

    struct PlayerDailyRounds {
        uint256 selfInvestment;
        uint256 trxVolume;
    }

    struct Investment {
        uint256 amount;
        uint256 time;
    }
}

contract CyberTron is Context {
    using SafeMath for *;

    address public owner;
    uint256 private houseFee = 5; // Owner's comission
    uint256 private poolTime = 24 hours;
    uint256 private payoutPeriod = 24 hours;
    uint256 private dailyWinPool = 10;
    uint256 public maxRoi = 300; // Max ROI percent
    uint256 public roundID;
    uint256 public r1 = 0;
    uint256 public r2 = 0;
    uint256 public r3 = 0;
    uint256 public eventStep = 2000000 trx;
    uint256[3] private awardPercentage;

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

    mapping(address => bool) public playerExist;
    mapping(uint256 => DataStructs.DailyRound) public round;
    mapping(address => DataStructs.Player) public player;
    mapping(address => mapping(uint256 => DataStructs.PlayerDailyRounds)) public plyrRnds_;
    mapping(address => DataStructs.Investment[]) private _investments;
    mapping(address => address[]) private _partners;

    /****************************  EVENTS   *****************************************/

    event RegisterUserEvent(
        address indexed _playerAddress,
        address indexed _referrer
    );
    event InvestmentEvent(
        address indexed _playerAddress,
        uint256 indexed _amount
    );
    event ReferralCommissionEvent(
        address indexed _playerAddress,
        address indexed _referrer,
        uint256 indexed amount,
        uint256 timeStamp
    );
    event DailyPayoutEvent(
        address indexed _playerAddress,
        uint256 indexed amount,
        uint256 indexed timeStamp
    );
    event WithdrawEvent(
        address indexed _playerAddress,
        uint256 indexed amount,
        uint256 indexed timeStamp
    );
    event SuperBonusEvent(
        address indexed _playerAddress,
        uint256 indexed _amount
    );
    event SuperBonusAwardEvent(
        address indexed _playerAddress,
        uint256 indexed _amount
    );
    event RoundAwardsEvent(
        address indexed _playerAddress,
        uint256 indexed _amount
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);

        roundID = 1;
        round[1].startTime = now;
        round[1].endTime = now + poolTime;
        awardPercentage[0] = 50;
        awardPercentage[1] = 30;
        awardPercentage[2] = 20;

        _addOwner(msgSender);
    }

    /****************************  MODIFIERS    *****************************************/

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev sets boundaries for incoming tx
     */
    modifier isWithinLimits(uint256 _trx) {
        require(
            _trx >= 2000 trx,
            'Minimum contribution amount is 2000 TRX.'
        );
        _;
    }

    /**
     * @dev sets permissible values for incoming tx
     */
    modifier isAllowedValue(uint256 _trx) {
        require(
            _trx % 1 trx == 0,
            'Amount should be in multiple of 10 TRX.'
        );
        _;
    }

    /****************************  CORE LOGIC    *****************************************/

    //if someone accidently sends trx to contract address
    function() external payable {
        playGame(address(0x0));
    }

    function playGame(address _referrer)
        public
        payable
        isWithinLimits(msg.value)
        isAllowedValue(msg.value)
    {
        uint256 amount = msg.value;
        if (playerExist[msg.sender] == false) {
            player[msg.sender].lastSettledTime = now;
            player[msg.sender].currentInvestedAmount = amount;
            player[msg.sender].incomeLimitLeft = amount.mul(maxRoi).div(
                100
            );
            player[msg.sender].totalInvestment = amount;
            player[msg.sender].eventVariable = eventStep;
            playerExist[msg.sender] = true;

            // update player's investment in current round
            plyrRnds_[msg.sender][roundID].selfInvestment = plyrRnds_[msg
                .sender][roundID]
                .selfInvestment
                .add(amount);
            addInvestor(msg.sender);

            if (
                // is this a referred purchase?
                _referrer != address(0x0) &&
                // self referrer not allowed
                _referrer != msg.sender &&
                // referrer exists?
                playerExist[_referrer] == true
            ) {
                player[msg.sender].referrer = _referrer;
                player[_referrer].referralCount = player[_referrer]
                    .referralCount
                    .add(1);
                player[_referrer].totalVolumeTRX = player[_referrer]
                    .totalVolumeTRX
                    .add(amount);
                plyrRnds_[_referrer][roundID]
                    .trxVolume = plyrRnds_[_referrer][roundID].trxVolume.add(
                    amount
                );

                addPromoter(_referrer);
                checkSuperBonus(_referrer);
                referralBonusTransferDirect(
                    msg.sender,
                    amount.mul(20).div(100)
                );
            } else {
                r1 = r1.add(amount.mul(20).div(100));
                _referrer = address(0x0);
            }
            emit RegisterUserEvent(msg.sender, _referrer);

        // if the player has already joined earlier
        } else {
            require(
                player[msg.sender].incomeLimitLeft == 0,
                'Oops your limit is still remaining'
            );
            require(
                amount >= player[msg.sender].currentInvestedAmount,
                'Cannot invest less amount'
            );

            player[msg.sender].lastSettledTime = now;
            player[msg.sender].currentInvestedAmount = player[msg.sender].currentInvestedAmount.add(amount);
            player[msg.sender].incomeLimitLeft = player[msg.sender].incomeLimitLeft
                .add(amount.mul(maxRoi).div(100));
            player[msg.sender].totalInvestment = player[msg.sender]
                .totalInvestment
                .add(amount);

            // update player's investment in current round
            plyrRnds_[msg.sender][roundID].selfInvestment = plyrRnds_[msg
                .sender][roundID]
                .selfInvestment
                .add(amount);
            addInvestor(msg.sender);

            if (
                // is this a referred purchase?
                _referrer != address(0x0) &&
                // self referrer not allowed
                _referrer != msg.sender &&
                // does the referrer exist?
                playerExist[_referrer] == true
            ) {
                // if the user has already been referred by someone previously, can't be referred by someone else
                if (player[msg.sender].referrer != address(0x0))
                    _referrer = player[msg.sender].referrer;
                else {
                    player[msg.sender].referrer = _referrer;
                    player[_referrer].referralCount = player[_referrer]
                        .referralCount
                        .add(1);
                }

                player[_referrer].totalVolumeTRX = player[_referrer]
                    .totalVolumeTRX
                    .add(amount);
                plyrRnds_[_referrer][roundID]
                    .trxVolume = plyrRnds_[_referrer][roundID].trxVolume.add(
                    amount
                );
                addPromoter(_referrer);
                checkSuperBonus(_referrer);
                // assign the referral commission to all.
                referralBonusTransferDirect(
                    msg.sender,
                    amount.mul(20).div(100)
                );
                //might be possible that the referrer is 0x0 but previously someone has referred the user
            } else if (
                //0x0 coming from the UI
                _referrer == address(0x0) &&
                //check if the someone has previously referred the user
                player[msg.sender].referrer != address(0x0)
            ) {
                _referrer = player[msg.sender].referrer;
                plyrRnds_[_referrer][roundID]
                    .trxVolume = plyrRnds_[_referrer][roundID].trxVolume.add(
                    amount
                );
                player[_referrer].totalVolumeTRX = player[_referrer]
                    .totalVolumeTRX
                    .add(amount);

                addPromoter(_referrer);
                checkSuperBonus(_referrer);
                //assign the referral commission to all.
                referralBonusTransferDirect(
                    msg.sender,
                    amount.mul(20).div(100)
                );
            } else {
                //no referrer, neither was previously used, nor has used now.
                r1 = r1.add(amount.mul(20).div(100));
            }
        }
        DataStructs.Investment memory investment = DataStructs.Investment({
            amount: msg.value,
            time: block.timestamp
        });
        _investments[msg.sender].push(investment);
        _partners[_referrer].push(msg.sender);
        round[roundID].pool = round[roundID].pool.add(
            amount.mul(dailyWinPool).div(100)
        );
        player[owner].dailyIncome = player[owner].dailyIncome.add(
            amount.mul(houseFee).div(100)
        );
        r3 = r3.add(amount.mul(5).div(100));
        emit InvestmentEvent(msg.sender, amount);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        _addOwner(newOwner);
    }

    //to check the super bonus eligibilty
    function checkSuperBonus(address _playerAddress) private {
        if (
            player[_playerAddress].totalVolumeTRX >=
            player[_playerAddress].eventVariable
        ) {
            player[_playerAddress].eventVariable = player[_playerAddress]
                .eventVariable
                .add(eventStep);
            emit SuperBonusEvent(
                _playerAddress,
                player[_playerAddress].totalVolumeTRX
            );
        }
    }

    function referralBonusTransferDirect(address _playerAddress, uint256 amount)
        private
    {
        address _nextReferrer = player[_playerAddress].referrer;
        uint256 _amountLeft = amount.mul(60).div(100);
        uint256 i;

        for (i = 0; i < 10; i++) {
            if (_nextReferrer != address(0x0)) {
                //referral commission to level 1
                if (i == 0) {
                    if (
                        player[_nextReferrer].incomeLimitLeft >= amount.div(2)
                    ) {
                        player[_nextReferrer]
                            .incomeLimitLeft = player[_nextReferrer]
                            .incomeLimitLeft
                            .sub(amount.div(2));
                        player[_nextReferrer]
                            .directReferralIncome = player[_nextReferrer]
                            .directReferralIncome
                            .add(amount.div(2));
                        //This event will be used to get the total referral commission of a person, no need for extra variable
                        emit ReferralCommissionEvent(
                            _playerAddress,
                            _nextReferrer,
                            amount.div(2),
                            now
                        );
                    } else if (player[_nextReferrer].incomeLimitLeft != 0) {
                        player[_nextReferrer]
                            .directReferralIncome = player[_nextReferrer]
                            .directReferralIncome
                            .add(player[_nextReferrer].incomeLimitLeft);
                        r1 = r1.add(
                            amount.div(2).sub(
                                player[_nextReferrer].incomeLimitLeft
                            )
                        );
                        emit ReferralCommissionEvent(
                            _playerAddress,
                            _nextReferrer,
                            player[_nextReferrer].incomeLimitLeft,
                            now
                        );
                        player[_nextReferrer].incomeLimitLeft = 0;
                    } else {
                        r1 = r1.add(amount.div(2));
                    }
                    _amountLeft = _amountLeft.sub(amount.div(2));
                } else if (i == 1) {
                    if (player[_nextReferrer].referralCount >= 2) {
                        if (
                            player[_nextReferrer].incomeLimitLeft >=
                            amount.div(10)
                        ) {
                            player[_nextReferrer]
                                .incomeLimitLeft = player[_nextReferrer]
                                .incomeLimitLeft
                                .sub(amount.div(10));
                            player[_nextReferrer]
                                .directReferralIncome = player[_nextReferrer]
                                .directReferralIncome
                                .add(amount.div(10));

                            emit ReferralCommissionEvent(
                                _playerAddress,
                                _nextReferrer,
                                amount.div(10),
                                now
                            );
                        } else if (player[_nextReferrer].incomeLimitLeft != 0) {
                            player[_nextReferrer]
                                .directReferralIncome = player[_nextReferrer]
                                .directReferralIncome
                                .add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(
                                amount.div(10).sub(
                                    player[_nextReferrer].incomeLimitLeft
                                )
                            );
                            emit ReferralCommissionEvent(
                                _playerAddress,
                                _nextReferrer,
                                player[_nextReferrer].incomeLimitLeft,
                                now
                            );
                            player[_nextReferrer].incomeLimitLeft = 0;
                        } else {
                            r1 = r1.add(amount.div(10));
                        }
                    } else {
                        r1 = r1.add(amount.div(10));
                    }
                    _amountLeft = _amountLeft.sub(amount.div(10));
                    //referral commission from level 3-10
                } else {
                    if (player[_nextReferrer].referralCount >= i + 1) {
                        if (
                            player[_nextReferrer].incomeLimitLeft >=
                            amount.div(20)
                        ) {
                            player[_nextReferrer]
                                .incomeLimitLeft = player[_nextReferrer]
                                .incomeLimitLeft
                                .sub(amount.div(20));
                            player[_nextReferrer]
                                .directReferralIncome = player[_nextReferrer]
                                .directReferralIncome
                                .add(amount.div(20));

                            emit ReferralCommissionEvent(
                                _playerAddress,
                                _nextReferrer,
                                amount.div(20),
                                now
                            );
                        } else if (player[_nextReferrer].incomeLimitLeft != 0) {
                            player[_nextReferrer]
                                .directReferralIncome = player[_nextReferrer]
                                .directReferralIncome
                                .add(player[_nextReferrer].incomeLimitLeft);
                            r1 = r1.add(
                                amount.div(20).sub(
                                    player[_nextReferrer].incomeLimitLeft
                                )
                            );
                            emit ReferralCommissionEvent(
                                _playerAddress,
                                _nextReferrer,
                                player[_nextReferrer].incomeLimitLeft,
                                now
                            );
                            player[_nextReferrer].incomeLimitLeft = 0;
                        } else {
                            r1 = r1.add(amount.div(20));
                        }
                    } else {
                        r1 = r1.add(amount.div(20));
                    }
                }
            } else {
                r1 = r1.add(
                    (uint256(10).sub(i)).mul(amount.div(20)).add(_amountLeft)
                );
                break;
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }

    function referralBonusTransferDailyROI(
        address _playerAddress,
        uint256 amount
    ) private {
        address _nextReferrer = player[_playerAddress].referrer;
        uint256 _amountLeft = amount.div(2);
        uint256 i;

        for (i = 0; i < 20; i++) {
            if (_nextReferrer != address(0x0)) {
                if (i == 0) {
                    if (
                        player[_nextReferrer].incomeLimitLeft >= amount.div(2)
                    ) {
                        player[_nextReferrer]
                            .incomeLimitLeft = player[_nextReferrer]
                            .incomeLimitLeft
                            .sub(amount.div(2));
                        player[_nextReferrer]
                            .roiReferralIncome = player[_nextReferrer]
                            .roiReferralIncome
                            .add(amount.div(2));

                        emit ReferralCommissionEvent(
                            _playerAddress,
                            _nextReferrer,
                            amount.div(2),
                            now
                        );
                    } else if (player[_nextReferrer].incomeLimitLeft != 0) {
                        player[_nextReferrer]
                            .roiReferralIncome = player[_nextReferrer]
                            .roiReferralIncome
                            .add(player[_nextReferrer].incomeLimitLeft);
                        r2 = r2.add(
                            amount.div(2).sub(
                                player[_nextReferrer].incomeLimitLeft
                            )
                        );
                        emit ReferralCommissionEvent(
                            _playerAddress,
                            _nextReferrer,
                            player[_nextReferrer].incomeLimitLeft,
                            now
                        );
                        player[_nextReferrer].incomeLimitLeft = 0;
                    } else {
                        r2 = r2.add(amount.div(2));
                    }
                    _amountLeft = _amountLeft.sub(amount.div(2));
                } else {
                    // for users 2-20
                    if (player[_nextReferrer].referralCount >= i + 1) {
                        if (
                            player[_nextReferrer].incomeLimitLeft >=
                            amount.div(20)
                        ) {
                            player[_nextReferrer]
                                .incomeLimitLeft = player[_nextReferrer]
                                .incomeLimitLeft
                                .sub(amount.div(20));
                            player[_nextReferrer]
                                .roiReferralIncome = player[_nextReferrer]
                                .roiReferralIncome
                                .add(amount.div(20));

                            emit ReferralCommissionEvent(
                                _playerAddress,
                                _nextReferrer,
                                amount.div(20),
                                now
                            );
                        } else if (player[_nextReferrer].incomeLimitLeft != 0) {
                            player[_nextReferrer]
                                .roiReferralIncome = player[_nextReferrer]
                                .roiReferralIncome
                                .add(player[_nextReferrer].incomeLimitLeft);
                            r2 = r2.add(
                                amount.div(20).sub(
                                    player[_nextReferrer].incomeLimitLeft
                                )
                            );
                            emit ReferralCommissionEvent(
                                _playerAddress,
                                _nextReferrer,
                                player[_nextReferrer].incomeLimitLeft,
                                now
                            );
                            player[_nextReferrer].incomeLimitLeft = 0;
                        } else {
                            r2 = r2.add(amount.div(20));
                        }
                    } else {
                        r2 = r2.add(amount.div(20)); //make a note of the missed commission;
                    }
                }
            } else {
                if (i == 0) {
                    r2 = r2.add(amount.mul(145).div(100));
                    break;
                } else {
                    r2 = r2.add(
                        (uint256(20).sub(i)).mul(amount.div(20)).add(
                            _amountLeft
                        )
                    );
                    break;
                }
            }
            _nextReferrer = player[_nextReferrer].referrer;
        }
    }

    function _addOwner(address _address) private {
        uint256 amount = eventStep;
        player[_address].lastSettledTime = now;
        player[_address].currentInvestedAmount = amount;
        player[_address].incomeLimitLeft = amount.mul(maxRoi).div(
            100
        );
        player[_address].totalInvestment = amount;
        player[_address].eventVariable = amount;
        player[_address].referrer = address(0);
        playerExist[_address] = true;
    }

    //method to settle and withdraw the daily ROI
    function settleIncome(address _playerAddress) private {
        uint256 remainingTimeForPayout;
        uint256 currInvestedAmount;

        if (now > player[_playerAddress].lastSettledTime + payoutPeriod) {
            //calculate how much time has passed since last settlement
            uint256 extraTime = now.sub(player[_playerAddress].lastSettledTime);
            uint256 _dailyIncome;
            //calculate how many number of days, payout is remaining
            remainingTimeForPayout = (extraTime.sub((extraTime % payoutPeriod)))
                .div(payoutPeriod);

            currInvestedAmount = player[_playerAddress].currentInvestedAmount;
            //calculate 2% of his invested amount
            _dailyIncome = currInvestedAmount.div(50);
            //check his income limit remaining
            if (
                player[_playerAddress].incomeLimitLeft >=
                _dailyIncome.mul(remainingTimeForPayout)
            ) {
                player[_playerAddress].incomeLimitLeft = player[_playerAddress]
                    .incomeLimitLeft
                    .sub(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].dailyIncome = player[_playerAddress]
                    .dailyIncome
                    .add(_dailyIncome.mul(remainingTimeForPayout));
                player[_playerAddress].lastSettledTime = player[_playerAddress]
                    .lastSettledTime
                    .add((extraTime.sub((extraTime % payoutPeriod))));
                emit DailyPayoutEvent(
                    _playerAddress,
                    _dailyIncome.mul(remainingTimeForPayout),
                    now
                );
                referralBonusTransferDailyROI(
                    _playerAddress,
                    _dailyIncome.mul(remainingTimeForPayout)
                );
                //if person income limit less than the daily ROI
            } else if (player[_playerAddress].incomeLimitLeft != 0) {
                uint256 temp;
                temp = player[_playerAddress].incomeLimitLeft;
                player[_playerAddress].incomeLimitLeft = 0;
                player[_playerAddress].dailyIncome = player[_playerAddress]
                    .dailyIncome
                    .add(temp);
                player[_playerAddress].lastSettledTime = now;
                emit DailyPayoutEvent(_playerAddress, temp, now);
                referralBonusTransferDailyROI(_playerAddress, temp);
            }
        }
    }

    //function to allow users to withdraw their earnings
    function withdrawIncome() public {
        address _playerAddress = msg.sender;

        //settle the daily dividend
        settleIncome(_playerAddress);

        uint256 _earnings = player[_playerAddress].dailyIncome +
            player[_playerAddress].directReferralIncome +
            player[_playerAddress].roiReferralIncome +
            player[_playerAddress].investorPoolIncome +
            player[_playerAddress].sponsorPoolIncome +
            player[_playerAddress].superIncome;

        //can only withdraw if they have some earnings.
        if (_earnings > 0) {
            if (address(this).balance < _earnings) {
                if (address(this).balance > 1000 trx) {
                    _earnings = address(this).balance - 1000 trx;
                } else {
                    _earnings = address(this).balance;
                }
            }

            player[_playerAddress].dailyIncome = 0;
            player[_playerAddress].directReferralIncome = 0;
            player[_playerAddress].roiReferralIncome = 0;
            player[_playerAddress].investorPoolIncome = 0;
            player[_playerAddress].sponsorPoolIncome = 0;
            player[_playerAddress].superIncome = 0;

            address(uint160(_playerAddress)).transfer(_earnings);
            emit WithdrawEvent(_playerAddress, _earnings, now);
        }
    }

    //To start the new round for daily pool
    function startNewRound(address _topPromoter, address _topInvestor) public onlyOwner {

        uint256 _roundID = roundID;

        uint256 _poolAmount = round[roundID].pool;
        if (now > round[_roundID].endTime && round[_roundID].ended == false) {
            if (_poolAmount >= 2000 trx) {
                round[_roundID].ended = true;
                uint256 distributedSponsorAwards = distributeTopPromoters(
                    _topPromoter
                );
                uint256 distributedInvestorAwards = distributeTopInvestors(
                    _topInvestor
                );

                _roundID++;
                roundID++;
                round[_roundID].startTime = now;
                round[_roundID].endTime = now.add(poolTime);
                round[_roundID].pool = _poolAmount.sub(
                    distributedSponsorAwards.add(distributedInvestorAwards)
                );
            } else {
                round[_roundID].ended = true;
                _roundID++;
                roundID++;
                round[_roundID].startTime = now;
                round[_roundID].endTime = now.add(poolTime);
                round[_roundID].pool = _poolAmount;
            }
        }
    }

    function addPromoter(address _add) private returns (bool) {
        if (_add == address(0x0)) {
            return false;
        }

        uint256 _amt = plyrRnds_[_add][roundID].trxVolume;
        // if the amount is less than the last on the leaderboard, reject
        if (topPromoters[2].amt >= _amt) {
            return false;
        }

        address firstAddr = topPromoters[0].addr;
        uint256 firstAmt = topPromoters[0].amt;
        address secondAddr = topPromoters[1].addr;
        uint256 secondAmt = topPromoters[1].amt;

        // if the user should be at the top
        if (_amt > topPromoters[0].amt) {
            if (topPromoters[0].addr == _add) {
                topPromoters[0].amt = _amt;
                return true;
                //if user is at the second position already and will come on first
            } else if (topPromoters[1].addr == _add) {
                topPromoters[0].addr = _add;
                topPromoters[0].amt = _amt;
                topPromoters[1].addr = firstAddr;
                topPromoters[1].amt = firstAmt;
                return true;
            } else {
                topPromoters[0].addr = _add;
                topPromoters[0].amt = _amt;
                topPromoters[1].addr = firstAddr;
                topPromoters[1].amt = firstAmt;
                topPromoters[2].addr = secondAddr;
                topPromoters[2].amt = secondAmt;
                return true;
            }
            // if the user should be at the second position
        } else if (_amt > topPromoters[1].amt) {
            if (topPromoters[1].addr == _add) {
                topPromoters[1].amt = _amt;
                return true;
            } else {
                topPromoters[1].addr = _add;
                topPromoters[1].amt = _amt;
                topPromoters[2].addr = secondAddr;
                topPromoters[2].amt = secondAmt;
                return true;
            }

            // if the user should be at the third position
        } else if (_amt > topPromoters[2].amt) {
            if (topPromoters[2].addr == _add) {
                topPromoters[2].amt = _amt;
                return true;
            } else {
                topPromoters[2].addr = _add;
                topPromoters[2].amt = _amt;
                return true;
            }
        }
    }

    function addInvestor(address _add) private returns (bool) {
        if (_add == address(0x0)) {
            return false;
        }

        uint256 _amt = plyrRnds_[_add][roundID].selfInvestment;

        // if the amount is less than the last on the leaderboard, reject
        if (topInvestors[2].amt >= _amt) {
            return false;
        }

        address firstAddr = topInvestors[0].addr;
        uint256 firstAmt = topInvestors[0].amt;
        address secondAddr = topInvestors[1].addr;
        uint256 secondAmt = topInvestors[1].amt;

        // if the user should be at the top
        if (_amt > topInvestors[0].amt) {
            if (topInvestors[0].addr == _add) {
                topInvestors[0].amt = _amt;
                return true;
                //if user is at the second position already and will come on first
            } else if (topInvestors[1].addr == _add) {
                topInvestors[0].addr = _add;
                topInvestors[0].amt = _amt;
                topInvestors[1].addr = firstAddr;
                topInvestors[1].amt = firstAmt;
                return true;
            } else {
                topInvestors[0].addr = _add;
                topInvestors[0].amt = _amt;
                topInvestors[1].addr = firstAddr;
                topInvestors[1].amt = firstAmt;
                topInvestors[2].addr = secondAddr;
                topInvestors[2].amt = secondAmt;
                return true;
            }
            // if the user should be at the second position
        } else if (_amt > topInvestors[1].amt) {
            if (topInvestors[1].addr == _add) {
                topInvestors[1].amt = _amt;
                return true;
            } else {
                topInvestors[1].addr = _add;
                topInvestors[1].amt = _amt;
                topInvestors[2].addr = secondAddr;
                topInvestors[2].amt = secondAmt;
                return true;
            }

            // if the user should be at the third position
        } else if (_amt > topInvestors[2].amt) {
            if (topInvestors[2].addr == _add) {
                topInvestors[2].amt = _amt;
                return true;
            } else {
                topInvestors[2].addr = _add;
                topInvestors[2].amt = _amt;
                return true;
            }
        }
    }

    function distributeTopPromoters(address _address)
        private
        returns (uint256)
    {
        uint256 totAmt = round[roundID].pool.mul(10).div(100);
        uint256 distributedAmount;
        uint256 i;

        if (_address != address(0x0) && playerExist[_address]) {
            topPromoters[2].addr = topPromoters[1].addr;
            topPromoters[1].addr = topPromoters[0].addr;
            topPromoters[0].addr = _address;
        }

        for (i = 0; i < 3; i++) {
            if (topPromoters[i].addr != address(0x0)) {
                if (
                    player[topPromoters[i].addr].incomeLimitLeft >=
                    totAmt.mul(awardPercentage[i]).div(100)
                ) {
                    player[topPromoters[i].addr]
                        .incomeLimitLeft = player[topPromoters[i].addr]
                        .incomeLimitLeft
                        .sub(totAmt.mul(awardPercentage[i]).div(100));
                    player[topPromoters[i].addr]
                        .sponsorPoolIncome = player[topPromoters[i].addr]
                        .sponsorPoolIncome
                        .add(totAmt.mul(awardPercentage[i]).div(100));
                    emit RoundAwardsEvent(
                        topPromoters[i].addr,
                        totAmt.mul(awardPercentage[i]).div(100)
                    );
                } else if (player[topPromoters[i].addr].incomeLimitLeft != 0) {
                    player[topPromoters[i].addr]
                        .sponsorPoolIncome = player[topPromoters[i].addr]
                        .sponsorPoolIncome
                        .add(player[topPromoters[i].addr].incomeLimitLeft);
                    r2 = r2.add(
                        (totAmt.mul(awardPercentage[i]).div(100)).sub(
                            player[topPromoters[i].addr].incomeLimitLeft
                        )
                    );
                    emit RoundAwardsEvent(
                        topPromoters[i].addr,
                        player[topPromoters[i].addr].incomeLimitLeft
                    );
                    player[topPromoters[i].addr].incomeLimitLeft = 0;
                } else {
                    r2 = r2.add(totAmt.mul(awardPercentage[i]).div(100));
                }

                distributedAmount = distributedAmount.add(
                    totAmt.mul(awardPercentage[i]).div(100)
                );
                lastTopPromoters[i].addr = topPromoters[i].addr;
                lastTopPromoters[i].amt = topPromoters[i].amt;
                lastTopPromotersWinningAmount[i] = totAmt
                    .mul(awardPercentage[i])
                    .div(100);
                topPromoters[i].addr = address(0x0);
                topPromoters[i].amt = 0;
            }
        }
        return distributedAmount;
    }

    function distributeTopInvestors(address _address)
        private
        returns (uint256)
    {
        uint256 totAmt = round[roundID].pool.mul(10).div(100);
        uint256 distributedAmount;
        uint256 i;

        if (_address != address(0x0) && playerExist[_address]) {
            topInvestors[2].addr = topInvestors[1].addr;
            topInvestors[1].addr = topInvestors[0].addr;
            topInvestors[0].addr = _address;
        }

        for (i = 0; i < 3; i++) {
            if (topInvestors[i].addr != address(0x0)) {
                if (
                    player[topInvestors[i].addr].incomeLimitLeft >=
                    totAmt.mul(awardPercentage[i]).div(100)
                ) {
                    player[topInvestors[i].addr]
                        .incomeLimitLeft = player[topInvestors[i].addr]
                        .incomeLimitLeft
                        .sub(totAmt.mul(awardPercentage[i]).div(100));
                    player[topInvestors[i].addr]
                        .investorPoolIncome = player[topInvestors[i].addr]
                        .investorPoolIncome
                        .add(totAmt.mul(awardPercentage[i]).div(100));
                    emit RoundAwardsEvent(
                        topInvestors[i].addr,
                        totAmt.mul(awardPercentage[i]).div(100)
                    );
                } else if (player[topInvestors[i].addr].incomeLimitLeft != 0) {
                    player[topInvestors[i].addr]
                        .investorPoolIncome = player[topInvestors[i].addr]
                        .investorPoolIncome
                        .add(player[topInvestors[i].addr].incomeLimitLeft);
                    r2 = r2.add(
                        (totAmt.mul(awardPercentage[i]).div(100)).sub(
                            player[topInvestors[i].addr].incomeLimitLeft
                        )
                    );
                    emit RoundAwardsEvent(
                        topInvestors[i].addr,
                        player[topInvestors[i].addr].incomeLimitLeft
                    );
                    player[topInvestors[i].addr].incomeLimitLeft = 0;
                } else {
                    r2 = r2.add(totAmt.mul(awardPercentage[i]).div(100));
                }

                distributedAmount = distributedAmount.add(
                    totAmt.mul(awardPercentage[i]).div(100)
                );
                lastTopInvestors[i].addr = topInvestors[i].addr;
                lastTopInvestors[i].amt = topInvestors[i].amt;
                topInvestors[i].addr = address(0x0);
                lastTopInvestorsWinningAmount[i] = totAmt
                    .mul(awardPercentage[i])
                    .div(100);
                topInvestors[i].amt = 0;
            }
        }
        return distributedAmount;
    }

    //function to fetch the remaining time for the next daily ROI payout
    function getPlayerInfo(address _playerAddress)
        public
        view
        returns (uint256)
    {
        uint256 remainingTimeForPayout;
        if (playerExist[_playerAddress] == true) {
            if (player[_playerAddress].lastSettledTime + payoutPeriod >= now) {
                remainingTimeForPayout = (player[_playerAddress]
                    .lastSettledTime + payoutPeriod)
                    .sub(now);
            } else {
                uint256 temp = now.sub(player[_playerAddress].lastSettledTime);
                remainingTimeForPayout = payoutPeriod.sub(
                    (temp % payoutPeriod)
                );
            }
            return remainingTimeForPayout;
        }
    }

    function withdrawFees(
        uint256 _amount,
        address _receiver,
        uint256 _numberUI
    ) public onlyOwner {
        if (_numberUI == 1 && r1 >= _amount) {
            if (_amount > 0) {
                if (address(this).balance >= _amount) {
                    r1 = r1.sub(_amount);
                    address(uint160(_receiver)).transfer(_amount);
                }
            }
        } else if (_numberUI == 2 && r2 >= _amount) {
            if (_amount > 0) {
                if (address(this).balance >= _amount) {
                    r2 = r2.sub(_amount);
                    address(uint160(_receiver)).transfer(_amount);
                }
            }
        } else if (_numberUI == 3) {
            player[_receiver].superIncome = player[_receiver].superIncome.add(
                _amount
            );
            emit SuperBonusAwardEvent(_receiver, _amount);
        }
    }

    function investments(address _user, uint256 id) public view returns(uint256, uint256) {
        DataStructs.Investment memory investment = _investments[_user][id];
        return (investment.amount, investment.time);
    }

    function partners(address _user, uint256 id) public view returns(address) {
        return _partners[_user][id];
    }
}