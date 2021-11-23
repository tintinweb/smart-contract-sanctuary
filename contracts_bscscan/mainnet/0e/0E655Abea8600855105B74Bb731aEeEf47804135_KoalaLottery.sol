// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//  .----------------.  .----------------.  .----------------.  .----------------.  .----------------. 
// | .--------------. || .--------------. || .--------------. || .--------------. || .--------------. |
// | |  ___  ____   | || |     ____     | || |      __      | || |   _____      | || |      __      | |
// | | |_  ||_  _|  | || |   .'    `.   | || |     /  \     | || |  |_   _|     | || |     /  \     | |
// | |   | |_/ /    | || |  /  .--.  \  | || |    / /\ \    | || |    | |       | || |    / /\ \    | |
// | |   |  __'.    | || |  | |    | |  | || |   / ____ \   | || |    | |   _   | || |   / ____ \   | |
// | |  _| |  \ \_  | || |  \  `--'  /  | || | _/ /    \ \_ | || |   _| |__/ |  | || | _/ /    \ \_ | |
// | | |____||____| | || |   `.____.'   | || ||____|  |____|| || |  |________|  | || ||____|  |____|| |
// | |              | || |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' || '--------------' |
// '----------------'  '----------------'  '----------------'  '----------------'  '----------------' 

// website : https://koaladefi.finance/
// twitter : https://twitter.com/KoalaDefi

import "./AccessControlEnumerable.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./Counters.sol";
import "./IERC721.sol";
import "./IBEP20.sol";


contract KoalaLottery is Context, AccessControlEnumerable {
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    event LotteryStatusChange(uint256 round, bytes32 status);

    using Counters for Counters.Counter;

    mapping(uint256 => Round) public lotteryRounds;
    Counters.Counter private roundCounter;

    struct Round {
        address poster;
        address paymentToken;
        uint256 item;
        uint256 ticketCost;
        bytes32 status; // Open, Executed, Cancelled, Drawing
        uint startTime;
        uint endTime;
        address winner;
        mapping(uint256 => address) entries;
        mapping(address => uint256) entriesByAddress;
        uint256 entryCount;
        IERC721 itemToken;
    }

    constructor ()
    {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @dev Returns the details for a round.
     * @param _round The id for the _round.
     */
    function getRound(uint256 _round)
        public
        virtual
        view
        returns(address, uint256, uint256, bytes32, address, uint, uint, address, uint256)
    {
        Round storage round = lotteryRounds[_round];
        return (round.poster, round.item, round.ticketCost, round.status, round.paymentToken, round.startTime, round.endTime, round.winner, round.entryCount);
    }

    /**
     * @dev Opens a new round. Puts _item in escrow.
     * @param _item The id for the item.
     * @param _price Ticket Cost.
     */

    function startRound(address itemToken, uint256 _item, uint256 _price, address _paymentToken, uint _startTime, uint _endTime)
        public
        virtual
    {
        require(hasRole(ADMIN_ROLE, _msgSender()), "Must have role admin");

        Round storage round = lotteryRounds[roundCounter.current()];
        round.poster = _msgSender();
        round.item = _item;
        round.ticketCost = _price;
        round.status = "Open";
        round.paymentToken = _paymentToken;
        round.startTime = _startTime;
        round.endTime = _endTime;
        round.entryCount = 0;
        round.itemToken = IERC721(itemToken);
        round.itemToken.transferFrom(_msgSender(), address(this), _item);
       
        roundCounter.increment();
        emit LotteryStatusChange(roundCounter.current() - 1, "Open");
    }

    function purchaseTickets(uint256 _round, uint256 _ticketCount)
        public
        virtual
    {
        Round storage round = lotteryRounds[_round];
        require(round.status == "Open", "Round is not Open.");
        require(round.startTime < block.timestamp, "Round is not Open.");
        require(round.endTime > block.timestamp, "Round is over.");
        IBEP20(round.paymentToken).transferFrom(_msgSender(), round.poster, round.ticketCost * _ticketCount);

        for (uint i=0; i < _ticketCount; i++) {
            round.entries[round.entryCount] = _msgSender();
            round.entryCount++;
        }
        round.entriesByAddress[_msgSender()] = round.entriesByAddress[_msgSender()] + _ticketCount;
    }

    /**
     * @dev Executes a round. Must have approved this contract to transfer the
     * amount of currency specified to the poster. Transfers ownership of the
     * item to the filler.
     * @param _round The id of an existing trade
     */
    function pickWinner(uint256 _round, uint256 _winnerIndex) public virtual
    {
        require(hasRole(ORACLE_ROLE, _msgSender()), "Must have role oracle");
        Round storage round = lotteryRounds[_round];
        require(round.status == "Open", "Round is not Open.");
        require(round.endTime < block.timestamp, "Round still running.");
        round.status = "Winner";
        round.winner = getEntryByIndex(_round, _winnerIndex);
        emit LotteryStatusChange(_round, "Winner");
    }

    function claim(uint256 _round) public virtual
    {   
        Round storage round = lotteryRounds[_round];
        require(round.status == "Winner", "Round Winner has not been picked");
        require(round.winner == msg.sender, "You are not the winner.");
        round.status = "Claimed";
        round.itemToken.transferFrom(address(this), _msgSender(), round.item);
    }

    /**
     * @dev Cancels a round by the poster.
     * @param _round The round to be cancelled.
     */
    function cancelRound(uint256 _round)
        public
        virtual
    {   
        require(hasRole(ADMIN_ROLE, _msgSender()), "Must have role admin");
        Round storage round = lotteryRounds[_round];
        require(
            msg.sender == round.poster,
            "Round can be cancelled only by poster."
        );
        require(round.status == "Open", "Trade is not Open.");
        round.itemToken.transferFrom(address(this), round.poster, round.item);
        lotteryRounds[_round].status = "Cancelled";
        emit LotteryStatusChange(_round, "Cancelled");
    }

    function getRoundCounter() public view returns (uint256){
        return roundCounter.current();
    }

    function getEntryByIndex(uint256 _round, uint256 _index) public view returns (address){
        Round storage round = lotteryRounds[_round];
        return round.entries[_index];
    }

    function getEntryCount(uint256 _round) public view returns (uint256){
        Round storage round = lotteryRounds[_round];
        return round.entryCount;
    }
    function getUserEntryCount(uint256 _round, address _user) public view returns (uint256){
        Round storage round = lotteryRounds[_round];
        return round.entriesByAddress[_user];
    }
}