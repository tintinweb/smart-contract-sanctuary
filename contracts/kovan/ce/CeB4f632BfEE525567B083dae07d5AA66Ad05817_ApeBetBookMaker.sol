/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-18
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: -- 🎲 --

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


interface IApeBetPool {
    function depositUserETH() external payable;

    function depositETH(address _sender, uint256 amount) external payable;

    function depositBetToken(address _sender, uint256 amount) external;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
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
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ApeBetBookMaker is Ownable {
    using SafeMath for uint256;

    struct SportEvent {
        uint256 event_status;
        uint256 winner;
        string name_home;
        string name_away;
        uint256 score_home;
        uint256 score_away;
        int256 moneyline_home;
        int256 moneyline_away;
        int256 moneyline_draw;
        string event_date;
    }

    struct Bet {
        SportEvent eventInfo;
        uint256 bet_winner;
        uint256 bet_amount;
        uint256 bet_payout;
        uint256 bet_timestamp;
        bool bet_claimed;
    }

    IApeBetPool private betPool;
    address payable public betPoolAddress;
    uint256 public affiliate_id;
    uint256 public maxPoolPayout;

    mapping(bytes16 => mapping(uint256 => SportEvent)) public events;
    mapping(bytes16 => mapping(uint256 => mapping(address => Bet)))
        private bets;
    mapping(address => Bet[]) public userBetData;
    bytes16[] public availableEvents;

    event EventUpdated(
        bytes16 _bet_event_id,
        uint256 _payout,
        uint256 _event_status,
        uint256 _score_away,
        uint256 _score_home
    );

    modifier onlyPoolOwner() {
        require(msg.sender == betPoolAddress, "You have no permission");
        _;
    }

    modifier hasEnoughBalance(
        bytes16[] memory _bet_event_ids,
        uint256[] memory winners,
        uint256[] memory amounts
    ) {
        // Check if pool has enough eth to give payouts to users
        uint256 maxPayout = 0;
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            maxPayout = maxPayout
                .add(getPayoutEst(_bet_event_ids[i], winners[i], amounts[i]))
                .sub(amounts[i]);
        }
        require(maxPayout < maxPoolPayout, "Not enough eth to payout your bet");
        _;
    }

    modifier isEventAvailable(bytes16[] memory _bet_event_ids) {
        //Fetch latest fetch info and check if the event is available
        fetchEventInfo(); //this function is not available till we have a solution for fetching event info from third part apis using chainlink.
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            require(
                events[_bet_event_ids[i]][affiliate_id].event_status == 1,
                "Event is not available."
            );
        }
        _;
    }

    modifier hasAlreadyBets(bytes16[] memory _bet_event_ids) {
        // Check if the user has already bets for specific event id
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            require(
                bets[_bet_event_ids[i]][affiliate_id][msg.sender].bet_amount ==
                    0,
                "You already have bets for this event."
            );
        }
        _;
    }

    constructor() {
        affiliate_id = 0;
        maxPoolPayout = 0;
    }

    function fetchEventInfo() internal {}

    function changeAffiliate(uint256 _affiliate_id) external onlyOwner {
        affiliate_id = _affiliate_id;
    }

    function changeBetPool(address payable _betPoolAddress) external onlyOwner {
        betPool = IApeBetPool(_betPoolAddress);
        betPoolAddress = _betPoolAddress;
        maxPoolPayout = address(betPool).balance;
    }

    function getUserBetHistory(address user)
        external
        view
        returns (Bet[] memory)
    {
        return userBetData[user];
    }

    function removePayout(
        bytes16 _event_id,
        uint256 _affiliate_id,
        address _user
    ) external onlyPoolOwner {
        Bet storage bet = bets[_event_id][_affiliate_id][_user];
        bet.bet_claimed = true;
    }

    // This function is used for converting only American format to European format
    function convertOddsFormat(int256 odds) internal pure returns (uint256) {
        uint256 payout = 0;
        uint256 bet = 0;
        if (odds < 0) {
            payout = uint256(100 - odds);
            bet = uint256(-odds);
        } else {
            payout = uint256(100 + odds);
            bet = 100;
        }

        return payout.mul(1e4).div(bet);
    }

    // for temporary use till chainlink is available to use
    function updateEvents(
        bytes16[] memory _event_ids,
        uint256[] memory _event_statuss,
        uint256[] memory _winners,
        string[] memory _name_homes,
        string[] memory _name_aways,
        uint256[] memory _score_aways,
        uint256[] memory _score_homes,
        int256[] memory _moneyline_homes,
        int256[] memory _moneyline_aways,
        int256[] memory _moneyline_draws,
        string[] memory _dates
    ) external {
        fetchEventInfo();

        for (uint256 i = 0; i < _event_ids.length; i++) {
            if (events[_event_ids[i]][affiliate_id].event_status == 0)
                availableEvents.push(_event_ids[i]);

            events[_event_ids[i]][affiliate_id] = SportEvent({
                event_status: _event_statuss[i],
                winner: _winners[i],
                name_away: _name_aways[i],
                name_home: _name_homes[i],
                score_away: _score_aways[i],
                score_home: _score_homes[i],
                moneyline_home: _moneyline_homes[i],
                moneyline_away: _moneyline_aways[i],
                moneyline_draw: _moneyline_draws[i],
                event_date: _dates[i]
            });
        }
    }

    function getAvailableEvents()
        external
        view
        returns (SportEvent[] memory evts)
    {
        evts = new SportEvent[](availableEvents.length);
        uint256 idx = 0;
        for (uint256 i = 0; i < availableEvents.length; i++) {
            if (events[availableEvents[i]][affiliate_id].event_status == 1)
                evts[idx++] = events[availableEvents[i]][affiliate_id];
        }
        return evts;
    }

    function getTotalPayouts(bytes16[] memory _bet_event_ids) external {
        uint256 totalPayouts = 0;
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            uint256 odd = 0;
            SportEvent memory ev = events[_bet_event_ids[i]][affiliate_id];
            Bet storage bet = bets[_bet_event_ids[i]][affiliate_id][msg.sender];

            if (ev.winner == 1) odd = convertOddsFormat(ev.moneyline_home);
            else if (ev.winner == 2) odd = convertOddsFormat(ev.moneyline_away);
            else odd = convertOddsFormat(ev.moneyline_draw);

            if (ev.event_status == 2 && ev.winner == bet.bet_winner) {
                bet.bet_payout = bet.bet_amount.mul(odd).div(1e4);
                totalPayouts = totalPayouts.add(bet.bet_payout);

                emit EventUpdated(
                    _bet_event_ids[i],
                    bet.bet_payout,
                    ev.event_status,
                    ev.score_away,
                    ev.score_home
                );
            }
        }
    }

    function getPayoutEst(
        bytes16 _bet_event_id,
        uint256 winner,
        uint256 amount
    ) public view returns (uint256) {
        uint256 maxPayout;

        // winner: 1 (home),  winner: 2(away),   winner: 3(draw)

        SportEvent memory ev = events[_bet_event_id][affiliate_id];
        if (winner == 1) {
            maxPayout = convertOddsFormat(ev.moneyline_home).mul(amount).div(
                1e4
            );
        } else if (winner == 2) {
            maxPayout = convertOddsFormat(ev.moneyline_away).mul(amount).div(
                1e4
            );
        } else {
            maxPayout = convertOddsFormat(ev.moneyline_draw).mul(amount).div(
                1e4
            );
        }
        return maxPayout;
    }

    receive() external payable {}

    function updateMaxPoolPayout(uint256 addAmount, uint256 removeAmount)
        external
        onlyPoolOwner
    {
        if (addAmount > 0) maxPoolPayout = maxPoolPayout.add(addAmount);
        else maxPoolPayout = maxPoolPayout.sub(removeAmount);
    }

    function createBets(
        bytes16[] memory _bet_event_ids,
        uint256[] memory _bet_winners,
        uint256[] memory _bet_amounts
    )
        external
        payable
        isEventAvailable(_bet_event_ids)
        hasAlreadyBets(_bet_event_ids)
        hasEnoughBalance(_bet_event_ids, _bet_winners, _bet_amounts)
    {
        for (uint256 i = 0; i < _bet_event_ids.length; i++) {
            bets[_bet_event_ids[i]][affiliate_id][msg.sender] = Bet({
                eventInfo: events[_bet_event_ids[i]][affiliate_id],
                bet_winner: _bet_winners[i],
                bet_amount: _bet_amounts[i],
                bet_timestamp: block.timestamp,
                bet_payout: 0,
                bet_claimed: false
            });

            userBetData[msg.sender].push(
                bets[_bet_event_ids[i]][affiliate_id][msg.sender]
            );

            maxPoolPayout = maxPoolPayout.add(_bet_amounts[i]).sub(
                getPayoutEst(
                    _bet_event_ids[i],
                    _bet_winners[i],
                    _bet_amounts[i]
                )
            );
        }
        betPool.depositUserETH{value: msg.value}();
    }
}