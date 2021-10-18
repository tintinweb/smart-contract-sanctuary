// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./CrushCoin.sol";


contract BitcrushLottery is VRFConsumerBase, Ownable {
    
    // Libraries
    using SafeMath for uint256;
    
    // Contracts
    CRUSHToken public crush;
    address public devAddress; //Address to send Ticket cut to.
    
    // Data Structures
    struct Ticket {
        uint256 ticketNumber;
        bool    claimed;
    }

    struct Claimer {
        address claimer;
        uint256 percent;
    }
    
    // VRF Specific
    bytes32 internal keyHashVRF;
    uint256 internal feeVRF;
    
    // CONSTANTS
    uint256 constant PERCENT_BASE = 100000;
    uint256 constant WINNER_BASE = 1000000; //6 digits are necessary
    uint256 constant MAX_BASE = 2000000; //6 digits are necessary
    // Variables
    
    bool public currentIsActive = false;
    uint256 public currentRound = 0;
    uint256 public duration; // ROUND DURATION
    uint256 public roundStart; //Timestamp of roundstart
    uint256 public roundEnd;
    uint256 public ticketValue = 30 ; //Value of Ticket
    uint256 public devTicketCut = 10000; // This is 10% of ticket sales taken on ticket sale
    uint256 public endHour= 18; // Time when Lottery ends. Default time is 18:00Z = 12:00 GMT-6
    
    // Fee Distributions
    // @dev these are all percentages so should always be divided by 100 when used
    uint256 public match6 = 40000;
    uint256 public match5 = 20000;
    uint256 public match4 = 10000;
    uint256 public match3 =  5000;
    uint256 public match2 =  3000;
    uint256 public match1 =  2000;
    uint256 public noMatch = 2000;
    uint256 public burn =   18000;
    uint256 public claimFee = 750;
    // Mappings
    mapping( uint256 => uint256 ) public totalTickets; //Total Tickets emmited per round
    mapping( uint256 => uint256 ) public roundPool; // Winning Pool
    mapping( uint256 => uint256 ) public winnerNumbers; // record of winner Number per round
    mapping( uint256 => address ) public bonusCoins; //Track bonus partner coins to distribute
    mapping( uint256 => uint256 ) public bonusTotal; //Track bonus partner coins to distribute
    mapping( uint256 => mapping( uint256 => uint256 ) ) public holders; // ROUND => DIGITS => #OF HOLDERS
    mapping( uint256 => mapping( address => Ticket[] ) )public userTickets; // User Bought Tickets
    mapping( address => uint256 ) public exchangeableTickets;

    mapping( uint256 => Claimer ) private claimers; // Track claimers to autosend claiming Bounty
    
    mapping( address => bool ) public operators; //Operators allowed to execute certain functions
    
    
    // EVENTS
    event FundPool( uint256 indexed _round, uint256 _amount);
    event OperatorChanged ( address indexed operators, bool active_status );
    event RoundStarted(uint256 indexed _round, address indexed _starter, uint256 _timestamp );
    event TicketBought(uint256 indexed _round, address indexed _user, uint256 _ticketStandardNumber );
    event SelectionStarted( uint256 indexed _round, address _caller, bytes32 _requestId);
    event WinnerPicked(uint256 indexed _round, uint256 _winner, bytes32 _requestId);
    event TicketClaimed( uint256 indexed _round, address winner, Ticket ticketClaimed );
    event TicketsRewarded( address _rewardee, uint256 _ticketAmount );
    
    // MODIFIERS
    modifier operatorOnly {
        require( operators[msg.sender] == true || msg.sender == owner(), 'Sorry Only Operators');
        _;
    }
    
    // CONSTRUCTOR
    constructor (address _crush)
        VRFConsumerBase(
            // BSC MAINNET
            // 0x747973a5A2a4Ae1D3a8fDF5479f1514F65Db9C31, //VRFCoordinator
            // 0x404460C6A5EdE2D891e8297795264fDe62ADBB75,  //LINK Token
            // BSC TESTNET
            0xa555fC018435bef5A13C6c6870a9d4C11DEC329C, // VRF Coordinator
            0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06  // LINK Token
        ) 
    {
        // VRF Init
        // keyHash = 0xc251acd21ec4fb7f31bb8868288bfdbaeb4fbfec2df3735ddbd4f7dc8d60103c; //MAINNET HASH
        keyHashVRF = 0xcaf3c3727e033261d383b315559476f48034c13b18f8cafed4d871abe5049186; //TESTNET HASH
        // fee = 0.2 * 10 ** 18; // 0.2 LINK (MAINNET)
        feeVRF = 0.1 * 10 ** 18; // 0.1 LINK (TESTNET)
        crush = CRUSHToken(_crush);
        devAddress = msg.sender;
        operators[msg.sender] = true;
    }
    
    // USER FUNCTIONS
    // Buy Tickets to participate in current Round
    // @args takes in an array of uint values as the ticket IDs to buy
    // @dev max bought tickets at any given time shouldn't be more than 10
    function buyTickets( uint256[] calldata _ticketNumbers ) external {
        require(_ticketNumbers.length > 0, "Cant buy zero tickets");
        require(currentIsActive == true, "Round not active");
        
        // Check if User has funds for ticket
        uint userCrushBalance = crush.balanceOf( msg.sender );
        uint ticketCost = ticketValue.mul( _ticketNumbers.length ).mul( 10 **18 );
        require( userCrushBalance >= ticketCost, "Not enough funds to purchase Tickets" );
        
        // Add Tickets to respective Mappings
        for( uint i = 0; i < _ticketNumbers.length; i++ ){
            createTicket(msg.sender, _ticketNumbers[i], currentRound);
        }
        
        uint devCut = getFraction( ticketCost, devTicketCut, PERCENT_BASE );
        addToPool(ticketCost.sub(devCut));
        crush.transferFrom( msg.sender, devAddress, devCut );
        totalTickets[currentRound] += _ticketNumbers.length;
    }

    function createTicket( address _owner, uint256 _ticketNumber, uint256 _round) internal {
        uint256 currentTicket = standardTicketNumber(_ticketNumber, WINNER_BASE, MAX_BASE);
        uint[6] memory digits = getDigits( currentTicket );
        
        for( uint digit = 0; digit < digits.length; digit++){
            holders[ _round ][ digits[digit] ] += 1;
        }
        Ticket memory ticket = Ticket( currentTicket, false);
        userTickets[ _round ][ _owner ].push(ticket);
        emit TicketBought( _round, _owner, currentTicket );
    }
    // Reward Tickets to a particular user
    function rewardTicket( address _rewardee, uint256 ticketAmount ) external operatorOnly{
        exchangeableTickets[_rewardee] += ticketAmount;
        emit TicketsRewarded( _rewardee, ticketAmount );
    }

    // EXCHANGE TICKET FOR THIS ROUND
    function exchangeForTicket( uint256[] calldata _ticketNumbers) external{
        require( _ticketNumbers.length <= exchangeableTickets[msg.sender], "You don't have enough redeemable tickets.");
        for( uint256 exchange = 0; exchange < _ticketNumbers.length; exchange ++ ){
            createTicket( msg.sender, _ticketNumbers[ exchange ], currentRound);
            exchangeableTickets[msg.sender] -= 1;
        }
    }

    // Get Tickets for a specific round
    function getRoundTickets(uint256 _round) public view returns( Ticket[] memory tickets) {
      return userTickets[ _round ][ msg.sender ];
    }

    // ClaimReward
    function isNumberWinner( uint256 _round, uint256 luckyTicket ) public view returns( bool _winner, uint8 _match){
        uint256 roundWinner = winnerNumbers[ _round ];
        require( roundWinner > 0 , "Winner not yet determined" );
        _match = 0;
        uint256 luckyNumber = standardTicketNumber( luckyTicket, WINNER_BASE, MAX_BASE);
        uint[6] memory winnerDigits = getDigits( roundWinner );
        uint[6] memory luckyDigits = getDigits( luckyNumber );
        for( uint8 i = 0; i < 6; i++){
            if( !_winner ){
                if( winnerDigits[i] == luckyDigits[i] ){
                    _match = 6 - i;
                    _winner = true;
                }
            }
        }
        if(!_winner)
            _match = 0;
    }

    function claimNumber(uint256 _round, uint256 luckyTicket) public {
        // Check if round is over
        require( winnerNumbers[_round] > 0, "Round not done yet");
        // check if Number belongs to caller
        Ticket[] memory ownedTickets = userTickets[ _round ][ msg.sender ];
        require( ownedTickets.length > 0, "It would be nice if I had tickets");
        uint256 ticketCheck = standardTicketNumber(luckyTicket, WINNER_BASE, MAX_BASE);
        bool ownsTicket = false;
        uint256 ticketIndex = 0;
        for( uint i = 0; i < ownedTickets.length; i ++){
            if( ownedTickets[i].ticketNumber == ticketCheck ){
                ownsTicket = true;
                ticketIndex = i;
            }
        }
        require( ownsTicket, "This ticket doesn't belong to you.");
        require( ownedTickets[ ticketIndex ].claimed == false, "Ticket already claimed");
        // GET AND TRANSFER TICKET CLAIM AMOUNT
        uint256[6] memory matches = [ match1, match2, match3, match4, match5, match6];
        (bool isWinner, uint amountMatch) = isNumberWinner(_round, luckyTicket);
        uint256 claimAmount = 0;
        uint[6] memory digits = getDigits( ticketCheck );

        uint256 currentPool = roundPool[_round];
        
        if(isWinner){
            uint256 matchAmount = getFraction( currentPool, matches[ amountMatch - 1 ], PERCENT_BASE);
            claimAmount = matchAmount.div( holders[ _round ][ digits[ 6 - amountMatch ] ] );
            transferBonus( msg.sender, _round, matches[ amountMatch - 1 ] );
        }
        else{
            uint256 matchReduction = noMatch.sub(claimers[_round].percent);
            uint256 matchAmount = getFraction( currentPool, matchReduction, PERCENT_BASE);
            transferBonus( msg.sender, _round, matchReduction );
            // matchAmount / nonWinners
            claimAmount = matchAmount.div( calcNonWinners( _round ) );
        }
        crush.transfer( msg.sender, claimAmount );
        userTickets[ _round ][ msg.sender ][ ticketIndex ].claimed = true;
        emit TicketClaimed(_round, msg.sender, ownedTickets[ ticketIndex ] );
    }

    function calcNonWinners( uint256 _round) internal view returns (uint256 nonWinners){
        uint256[6] memory winnerDigits = getDigits( winnerNumbers[_round] );
        uint256 winners=0;
        for( uint tw = 0; tw < 6; tw++ ){
            winners = winners.add( holders[ _round ][ winnerDigits[tw] ]);
        }
        uint256 ticketsSold = totalTickets[ _round ];
        nonWinners = ticketsSold.sub( winners );
    }
    // AddToPool
    function addToPool(uint256 _amount) public {
        uint256 userBalance = crush.balanceOf( msg.sender );
        require( userBalance >= _amount, "Insufficient Funds to Send to Pool");
        crush.transferFrom( msg.sender, address(this), _amount);
        roundPool[ currentRound ] = roundPool[ currentRound ].add( _amount );
        emit FundPool( currentRound, _amount);
    }

    // Transfer bonus to
    function transferBonus(address _to, uint256 _round, uint256 _match) internal {
        if( bonusCoins[_round] != address(0) ){
            ERC20( bonusCoins[_round] )
                .transfer(
                    _to,
                    getFraction( bonusTotal[_round], _match, PERCENT_BASE )
                );
        }
    }

    // OPERATOR FUNCTIONS
    // Starts a new Round
    // @dev only applies if current Round is over
    function firstStart() public operatorOnly{
        require(currentRound == 0, "First Round only");
        startRound();
        roundEnd = setNextRoundEndTime( block.timestamp, endHour);
    }

    function startRound() internal {
        require( currentIsActive == false, "Current Round is not over");
        // Add new Round
        currentRound ++;
        currentIsActive = true;
        roundStart = block.timestamp;
        emit RoundStarted( currentRound, msg.sender, block.timestamp);
    }
    
    // Ends current round This will always be after 12pm GMT -6 (6pm UTC)
    function endRound() public{
        require( LINK.balanceOf(address(this)) >= feeVRF, "Not enough LINK - please contact mod to fund to contract" );
        require( currentIsActive == true, "Current Round is over");
        // require ( block.timestamp > roundEnd, "Can't end round immediately");

        roundEnd = setNextRoundEndTime( block.timestamp, endHour);
        currentIsActive = false;
        claimers[ currentRound ] = Claimer( msg.sender, 0);
        // Request Random Number for Winner
        bytes32 rqId = requestRandomness( keyHashVRF, feeVRF);
        emit SelectionStarted(currentRound, msg.sender, rqId);
    }
    // BURN AND ROLLOVER
    function distributeCrush() internal {
        uint256 rollOver;
        uint256 burnAmount;
        uint256 forClaimer;

        (rollOver, burnAmount, forClaimer) = calculateRollover();
        // Transfer Amount to Claimer
        Claimer memory roundClaimer = claimers[currentRound];
        crush.transfer( roundClaimer.claimer, forClaimer );
        transferBonus( roundClaimer.claimer, currentRound, roundClaimer.percent );
        // BURN AMOUNT
        crush.burn( burnAmount );
        roundPool[ currentRound + 1 ] = rollOver;
    }

    function calculateRollover() internal returns( uint256 _rollover, uint256 _burn, uint256 _forClaimer ) {
        uint totalPool = roundPool[currentRound];
        _rollover = 0;
        // for zero match winners
        uint roundTickets = totalTickets[currentRound];
        uint256 currentWinner = winnerNumbers[currentRound];
        uint256[6] memory winnerDigits = getDigits(currentWinner);
        uint256[6] memory matchPercents = [ match6, match5, match4, match3, match2, match1 ];
        uint256[6] memory matchHolders;
        uint256 totalMatchHolders = 0;
        uint256 bonusRollOver = 0;
        
        if( bonusCoins[ currentRound ] != address(0) ){
            bonusTotal[ currentRound ] = ERC20(bonusCoins[currentRound]).balanceOf( address(this) );
        }
        for( uint8 i = 0; i < 6; i ++){
            uint256 digitToCheck = winnerDigits[i];
            matchHolders[i] = holders[currentRound][digitToCheck];
            if( matchHolders[i] > 0 ){
                if(i == 0){
                    totalMatchHolders = matchHolders[i];
                }
                else{
                    matchHolders[i] = matchHolders[i].sub(totalMatchHolders);
                    totalMatchHolders = totalMatchHolders.add( matchHolders[i] );
                    holders[currentRound][digitToCheck] = matchHolders[i];
                }
            }
            // single check to remove duplicate code
            if(matchHolders[i] == 0){
                _rollover = _rollover.add( getFraction(totalPool, matchPercents[i], PERCENT_BASE) );
                if( bonusCoins[ currentRound ] != address(0) ){
                    bonusRollOver += getFraction( bonusTotal[currentRound], matchPercents[i], PERCENT_BASE);
                }
            }
            else{
                _forClaimer = _forClaimer.add( matchPercents[i] );
            }
        }
        _forClaimer = _forClaimer.mul(claimFee).div(PERCENT_BASE);
        uint256 nonWinners = roundTickets.sub(totalMatchHolders);
        // Are there any noMatch tickets
        if( nonWinners == 0 ){
            _rollover += getFraction(totalPool, noMatch.sub(_forClaimer ), PERCENT_BASE);
            if( bonusCoins[ currentRound ] != address(0) ){
                bonusRollOver += getFraction( bonusTotal[currentRound], noMatch, PERCENT_BASE);
            }
        }

        // Transfer bonus coin excedent to devAddress
        if(bonusRollOver > 0){
            ERC20(bonusCoins[currentRound]).transfer(devAddress, bonusTotal[currentRound].sub(bonusRollOver) );
        }
        _burn = getFraction( totalPool, burn, PERCENT_BASE);
        
        claimers[currentRound].percent = _forClaimer;
        _forClaimer = getFraction(totalPool, _forClaimer, PERCENT_BASE);
    }
    
    // Add or remove operator
    function toggleOperator( address _operator) public operatorOnly{
        bool operatorIsActive = operators[ _operator ];
        if(operatorIsActive){
            operators[ _operator ] = false;
        }
        else {
            operators[ _operator ] = true;
        }
        emit OperatorChanged(_operator, operators[msg.sender] );
    }
    
    // GET Verifiable RandomNumber from VRF
    // This gets called by VRF Contract only
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        uint winnerNumber = standardTicketNumber(randomness, WINNER_BASE, MAX_BASE);
        winnerNumbers[currentRound] = winnerNumber;
        distributeCrush();
        emit WinnerPicked(currentRound, winnerNumber, requestId);
        startRound();
    }
    // SETTERS
    function setEndHour(uint256 _newHour) external onlyOwner{
        endHour = _newHour;
    }

    function setClaimerFee( uint256 _fee ) external onlyOwner{
        require(_fee < 2000 && _fee > 0, "Invalid fee amount");
        claimFee = _fee;
    }

    function setBonusCoin( address _partnerToken, uint256 _round ) external operatorOnly{
        require( _partnerToken != address(0),"Cant set bonus Token" );
        bonusCoins[ _round ] = _partnerToken;
    }
    
    // HELPFUL FUNCTION TO TEST WITHOUT GOING LIVE
    // REMEMBER TO COMMENT IT OUT
    function setWinner( uint256 randomness ) public operatorOnly{
        uint winnerNumber = standardTicketNumber(randomness, WINNER_BASE, MAX_BASE);
        winnerNumbers[currentRound] = winnerNumber;
        emit WinnerPicked(currentRound, winnerNumber, "ADMIN_SET_WINNER");
        distributeCrush();
        startRound();
    }

    function rewriteCurrentEndTime(uint256 _endedTime) public operatorOnly{
        roundEnd = setNextRoundEndTime( _endedTime , endHour);
    }
    
    // PURE FUNCTIONS
    // Function to get the fraction amount from a value
    function getFraction(uint256 _amount, uint256 _percent, uint256 _base) internal pure returns(uint256 fraction) {
        return _amount.mul( _percent ).div( _base );
    }
   
    // Get all participating digits from number
    function getDigits( uint256 _ticketNumber ) internal pure returns(uint256[6] memory digits){
        digits[5] = _ticketNumber.div(100000); // WINNER_BASE
        digits[4] = _ticketNumber.div(10000);
        digits[3] = _ticketNumber.div(1000);
        digits[2] = _ticketNumber.div(100);
        digits[1] = _ticketNumber.div(10);
        digits[0] = _ticketNumber.div(1);
    }
    // Get the requested ticketNumber from the defined range
    function standardTicketNumber( uint256 _ticketNumber, uint256 _base, uint256 maxBase) internal pure returns( uint256 ){
        uint256 ticketNumber;
        if(_ticketNumber < _base ){
            ticketNumber = _ticketNumber.add( _base );
        }
        else if( _ticketNumber > maxBase ){
            ticketNumber = _ticketNumber.mod( _base ).add( _base );
        }
        else{
            ticketNumber = _ticketNumber;
        }
        return ticketNumber;
    }
    // Get timestamp end for next round to be at the specified _hour
    function setNextRoundEndTime(uint256 _currentTimestamp, uint256 _hour) internal pure returns (uint256 _endTimestamp ) {
        uint nextDay = SECONDS_PER_DAY.add(_currentTimestamp);
        (uint year, uint month, uint day) = timestampToDateTime(nextDay);
        _endTimestamp = timestampFromDateTime(year, month, day, _hour, 0, 0);
    }

    // -------------------------------------------------------------------`
    // Timestamp fns taken from BokkyPooBah's DateTime Library
    //
    // Gas efficient Solidity date and time library
    //
    // https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
    //
    // Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
    //
    // GNU Lesser General Public License 3.0
    // https://www.gnu.org/licenses/lgpl-3.0.en.html
    // ----------------------------------------------------------------------------
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {

  function allowance(
    address owner,
    address spender
  )
    external
    view
    returns (
      uint256 remaining
    );

  function approve(
    address spender,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function balanceOf(
    address owner
  )
    external
    view
    returns (
      uint256 balance
    );

  function decimals()
    external
    view
    returns (
      uint8 decimalPlaces
    );

  function decreaseApproval(
    address spender,
    uint256 addedValue
  )
    external
    returns (
      bool success
    );

  function increaseApproval(
    address spender,
    uint256 subtractedValue
  ) external;

  function name()
    external
    view
    returns (
      string memory tokenName
    );

  function symbol()
    external
    view
    returns (
      string memory tokenSymbol
    );

  function totalSupply()
    external
    view
    returns (
      uint256 totalTokensIssued
    );

  function transfer(
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  )
    external
    returns (
      bool success
    );

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    external
    returns (
      bool success
    );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {

  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  )
    internal
    pure
    returns (
      uint256
    )
  {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(
    bytes32 _keyHash,
    uint256 _vRFInputSeed
  )
    internal
    pure
    returns (
      bytes32
    )
  {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constuctor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    internal
    virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 constant private USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(
    bytes32 _keyHash,
    uint256 _fee
  )
    internal
    returns (
      bytes32 requestId
    )
  {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface immutable internal LINK;
  address immutable private vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(
    address _vrfCoordinator,
    address _link
  ) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(
    bytes32 requestId,
    uint256 randomness
  )
    external
  {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract CRUSHToken is ERC20 ("Crush Coin", "CRUSH"), Ownable {

  using SafeMath for uint256;
  // Constants
  uint256 constant public MAX_SUPPLY = 30 * 10 ** 24; //30 million tokens are the max Supply
  
  // Variables
  uint256 public tokensBurned = 0;

  function mint(address _benefactor,uint256 _amount) public onlyOwner {
    uint256 draftSupply = _amount.add( totalSupply() );
    uint256 maxSupply = MAX_SUPPLY.sub( tokensBurned );
    require( draftSupply <= maxSupply, "can't mint more than max." );
    _mint(_benefactor, _amount);
  }

  function burn(uint256 _amount) public {
    tokensBurned = tokensBurned.add( _amount ) ;
    _burn( msg.sender, _amount );
  }

}