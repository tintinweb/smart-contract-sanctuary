// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// VRF
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./CrushCoin.sol";

interface Bankroll {
    function addUserLoss(uint256 _amount) external;
}

/**
 * @title  Bitcrush's lottery game
 * @author Bitcrush Devs
 * @notice Simple Lottery contract, matches winning numbers from left to right.
 *
 *
 *
 */
contract BitcrushLottery is VRFConsumerBase, Ownable, ReentrancyGuard {
    
    // Libraries
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    using SafeERC20 for CRUSHToken;

    // Contracts
    CRUSHToken immutable public crush;
    Bankroll immutable public bankAddress;
    address public devAddress; //Address to send Ticket cut to.
    
    // Data Structures
    struct RoundInfo {
        uint256 totalTickets;
        uint256 ticketsClaimed;
        uint32 winnerNumber;
        uint256 pool;
        uint256 endTime;
        uint256[7] distribution;
        uint256 burn;
    }

    struct Ticket {
        uint256 ticketNumber;
        bool    claimed;
    }

    struct NewTicket {
        uint32 ticketNumber;
        uint256 round;
    }

    struct RoundTickets {
        uint256 totalTickets;
        uint256 firstTicketId;
    }

    struct Claimer {
        address claimer;
        uint256 percent;
    }
    // This struct defines the values to be stored on a per Round basis
    struct BonusCoin {
        address bonusToken;
        uint256 bonusAmount;
        uint256 bonusClaimed;
        uint bonusMaxPercent; // accumulated percentage of winners for a round
    }

    struct Partner {
        uint256 spread;
        uint256 id;
        bool set;
    }
    
    // VRF Specific
    bytes32 internal keyHashVRF;
    uint256 internal feeVRF;

    /// Timestamp Specific
    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;
    // CONSTANTS
    uint256 constant ONE100PERCENT = 10000000;
    uint256 constant ONE__PERCENT = 1000000000;
    uint256 constant PERCENT_BASE = 100000000000;
    uint32 constant WINNER_BASE = 1000000; //6 digits are necessary
    uint32 constant MAX_BASE = 2000000; //6 digits are necessary
    // Variables
    bool public currentIsActive = false;
    uint256 public currentRound = 0;
    uint256 public roundStart; //Timestamp of roundstart
    uint256 public roundEnd;
    uint256 public ticketValue = 30 * 10**18 ; //Value of Ticket value in WEI
    uint256 public devTicketCut = 10 * ONE__PERCENT; // This is 10% of ticket sales taken on ticket sale

    uint256 public burnThreshold = 10 * ONE__PERCENT;
    uint256 public distributionThreshold = 10 * ONE__PERCENT;
    
    // Fee Distributions
    /// @dev these values are used with PERCENT_BASE as 100%
    uint256 public match6 = 40 * ONE__PERCENT;
    uint256 public match5 = 20 * ONE__PERCENT;
    uint256 public match4 = 10 * ONE__PERCENT;
    uint256 public match3 = 5 * ONE__PERCENT;
    uint256 public match2 = 3 * ONE__PERCENT;
    uint256 public match1 = 2 * ONE__PERCENT;
    uint256 public noMatch = 2 * ONE__PERCENT;
    uint256 public burn = 18 * ONE__PERCENT;
    uint256 public claimFee = 75 * ONE100PERCENT; // This is deducted from the no winners 2%
    // Mappings
    mapping(uint256 => RoundInfo) public roundInfo; //Round Info
    mapping(uint256 => BonusCoin) public bonusCoins; //Track bonus partner coins to distribute
    mapping(uint256 => mapping(uint256 => uint256)) public holders; // ROUND => DIGITS => #OF HOLDERS
    mapping(uint256 => mapping(address => Ticket[]))public userTickets; // User Bought Tickets
    mapping(address => uint256) public exchangeableTickets;
    mapping(address => Partner) public partnerSplit;
    // NEW IMPLEMENTATION
    mapping(address => mapping(uint256 => NewTicket)) public userNewTickets; // User => ticketId => ticketData
    mapping(address => mapping(uint256 => RoundTickets)) public userRoundTickets; // User => Last created ticket Id
    mapping(address => uint256) public userTotalTickets; // User => Last created ticket Id
    mapping(address => uint256) public userLastTicketClaimed; // User => Last ticket claimed Id

    mapping(uint256 => Claimer) private claimers; // Track claimers to autosend claiming Bounty
    
    mapping(address => bool) public operators; //Operators allowed to execute certain functions
    
    address[] private partners;

    uint8[] public endHours = [18];
    uint8 public endHourIndex;
    // EVENTS
    event FundedBonusCoins(address indexed _partner, uint256 _amount, uint256 _startRound, uint256 _numberOfRounds );
    event FundPool(uint256 indexed _round, uint256 _amount);
    event OperatorChanged (address indexed operators, bool active_status);
    event RoundStarted(uint256 indexed _round, address indexed _starter, uint256 _timestamp);
    event TicketBought(uint256 indexed _round, address indexed _user, uint256 _ticketAmounts);
    event SelectionStarted(uint256 indexed _round, address _caller, bytes32 _requestId);
    event WinnerPicked(uint256 indexed _round, uint256 _winner, bytes32 _requestId);
    event TicketClaimed(uint256 indexed _round, address winner, Ticket ticketClaimed);
    event TicketsRewarded(address _rewardee, uint256 _ticketAmount);
    event UpdateTicketValue(uint256  _timeOfUpdate, uint256 _newValue);
    event PartnerUpdated(address indexed _partner);
    event PercentagesChanged( address indexed owner, string percentName, uint256 newPercent);
    
    // MODIFIERS
    modifier operatorOnly {
        require(operators[msg.sender] == true || msg.sender == owner(), 'Sorry Only Operators');
        _;
    }
    
    /// @dev Select the appropriate VRF Coordinator and LINK Token addresses
    constructor (address _crush, address _bankAddress)
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
        bankAddress = Bankroll(_bankAddress);
    }

    // External functions
    /// @notice Buy Tickets to participate in current round from a partner
    /// @param _ticketNumbers takes in an array of uint values as the ticket number to buy
    /// @param _partnerId the id of the partner to send the funds to if 0, no partner is checked.
    function buyTickets(uint32[] calldata _ticketNumbers, uint256 _partnerId) external nonReentrant {
        require(_ticketNumbers.length > 0, "Cant buy zero tickets");
        require(_ticketNumbers.length <= 100, "Cant buy more than 100 tickets at any given time");
        require(currentIsActive == true, "Round not active");
        // Check if User has funds for ticket
        uint userCrushBalance = crush.balanceOf(msg.sender);
        uint ticketCost = ticketValue.mul(_ticketNumbers.length);
        require(userCrushBalance >= ticketCost, "Not enough funds to purchase Tickets");
        if(userRoundTickets[msg.sender][currentRound].firstTicketId == 0){
            userRoundTickets[msg.sender][currentRound].firstTicketId = userTotalTickets[msg.sender].add(1);
        }
        // Add Tickets to respective Mappings
        for(uint i = 0; i < _ticketNumbers.length; i++){
            createTicket(msg.sender, _ticketNumbers[i], currentRound);
        }
        uint devCut = getFraction(ticketCost, devTicketCut, PERCENT_BASE);
        addToPool(ticketCost.sub(devCut));
        
        if(_partnerId > 0){
            require(_partnerId <= partners.length, "Cheeky aren't you, partner Id doesn't exist. Contact us for partnerships");
            Partner storage _p = partnerSplit[partners[_partnerId -1]];
            require(_p.set, "Partnership ended");
            // Split cut with partner
            uint partnerCut = getFraction(devCut, _p.spread, 100);
            devCut = devCut.sub(partnerCut);
            crush.safeTransferFrom(msg.sender, partners[_partnerId-1], partnerCut);
        }
        crush.safeTransferFrom(msg.sender, devAddress, devCut);
        roundInfo[currentRound].totalTickets = roundInfo[currentRound].totalTickets.add(_ticketNumbers.length);
        userRoundTickets[msg.sender][currentRound].totalTickets = userRoundTickets[msg.sender][currentRound].totalTickets.add(_ticketNumbers.length);
        emit TicketBought(currentRound, msg.sender, _ticketNumbers.length);
    }

    /// @notice add/remove/edit partners 
    /// @param _partnerAddress the address where funds will go to.
    /// @param _split the negotiated split percentage. Value goes from 0 to 90.
    /// @dev their ID doesn't change, nor is it removed once partnership ends.
    function editPartner(address _partnerAddress, uint8 _split) external operatorOnly {
        require(_split <= 90, "No greedyness, thanks");
        Partner storage _p = partnerSplit[_partnerAddress];
        if(!_p.set){
            partners.push(_partnerAddress);
            _p.id = partners.length;
        }
        _p.spread = _split;
        if(_split > 0)
            _p.set = true;
        emit PartnerUpdated(_partnerAddress);
    }
    /// @notice retrieve a provider wallet ID
    /// @param _checkAddress the address to check
    /// @return _id the ID of the provider
    function getProviderId(address _checkAddress) external view returns(uint256 _id){
        Partner storage partner = partnerSplit[_checkAddress];
        require( partner.set , "Not a partner");
        _id = partner.id;
    }

    /// @notice Give Redeemable Tickets to a particular user
    /// @param _rewardee Address the tickets will be awarded to
    /// @param ticketAmount number of tickets awarded
    function rewardTicket(address _rewardee, uint256 ticketAmount) external operatorOnly {
        exchangeableTickets[_rewardee] += ticketAmount;
        emit TicketsRewarded(_rewardee, ticketAmount);
    }

    /// @notice Exchange awarded tickets for the current round
    /// @param _ticketNumbers array of numbers to add to the caller as tickets
    function exchangeForTicket(uint32[] calldata _ticketNumbers) external {
        require(currentIsActive, "Current round is not active please wait for next round start" );
        require(_ticketNumbers.length <= exchangeableTickets[msg.sender], "You don't have enough redeemable tickets.");
        for(uint256 exchange = 0; exchange < _ticketNumbers.length; exchange ++) {
            createTicket(msg.sender, _ticketNumbers[ exchange ], currentRound);
            exchangeableTickets[msg.sender] -= 1;
        }
    }

    /// @notice Claim all user unclaimed tickets for a particular round
    function claimAll() external nonReentrant{
        uint256 claimableTickets = userTotalTickets[msg.sender].sub(userLastTicketClaimed[msg.sender]);
        require(claimableTickets > 0, "Already claimed previous rounds");
        uint256 crushReward = 0;
        uint lastClaimed = userLastTicketClaimed[msg.sender];
        for( uint i = 1; i <= claimableTickets; i++){
            NewTicket storage ticketToClaim = userNewTickets[msg.sender][ userLastTicketClaimed[msg.sender].add(i) ];
            if(ticketToClaim.round >= currentRound)
                break;
            lastClaimed = userLastTicketClaimed[msg.sender].add(i);
            RoundInfo storage ticketRound = roundInfo[ticketToClaim.round];
            BonusCoin storage bonusForRound = bonusCoins[ticketToClaim.round];
            (uint8 matches) = isNumberWinner(ticketToClaim.round, ticketToClaim.ticketNumber);
            if(matches > 0){
                uint matchedDigit = getDigits(ticketToClaim.ticketNumber)[matches-1];
                crushReward = crushReward.add(
                    getFraction(ticketRound.pool, ticketRound.distribution[matches], PERCENT_BASE)
                        .div( holders[ticketToClaim.round][matchedDigit])
                );
                if(bonusForRound.bonusToken != address(0)){
                    uint256 bonusAmount = getBonusReward(
                        holders[ticketToClaim.round][matchedDigit],
                        bonusForRound,
                        ticketRound.distribution[matches]
                    );
                    ERC20 bonusTokenContract = ERC20(bonusForRound.bonusToken);
                    uint256 availableFunds = bonusTokenContract.balanceOf(address(this));
                    if( bonusAmount > availableFunds)
                        bonusAmount = availableFunds;
                    bonusTokenContract.safeTransfer( msg.sender, bonusAmount);
                }
            }
            else{
                uint256 matchReduction = ticketRound.distribution[0].sub(claimers[ticketToClaim.round].percent);
                crushReward = crushReward.add(
                    getFraction(ticketRound.pool, matchReduction, PERCENT_BASE)
                        .div( calcNonWinners(ticketToClaim.round))
                );
                if(bonusForRound.bonusToken != address(0)){
                    uint256 bonusAmount = getBonusReward(
                        calcNonWinners(ticketToClaim.round),
                        bonusForRound,
                        matchReduction
                    );
                    ERC20 bonusTokenContract = ERC20(bonusForRound.bonusToken);
                    uint256 availableFunds = bonusTokenContract.balanceOf(address(this));
                    if( bonusAmount > availableFunds)
                        bonusAmount = availableFunds;
                    bonusTokenContract.safeTransfer( msg.sender, bonusAmount);
                }
            }
        }
        userLastTicketClaimed[msg.sender] = lastClaimed;
        if(crushReward>0){
            crush.safeTransfer(msg.sender, crushReward);
        }
        // RoundInfo storage info = roundInfo[_round];
        // require(info.winnerNumber > 0, "Round not done yet");
        // // GET AND TRANSFER TICKET CLAIM AMOUNT
        // uint256[6] memory matches = [info.match1, info.match2, info.match3, info.match4, info.match5, info.match6];
        // // check if Number belongs to caller
        // Ticket[] storage ownedTickets = userTickets[ _round ][ msg.sender ];
        // require( ownedTickets.length > 0, "It would be nice if I had tickets");
        // uint256 claimAmount;
        // uint256 bonusAmount;
        // for( uint i = 0; i < ownedTickets.length; i ++){
        //     if(ownedTickets[i].claimed)
        //         continue;
        //     ownedTickets[i].claimed = true;
        //     (bool isWinner, uint amountMatch) = isNumberWinner(_round, ownedTickets[i].ticketNumber);
        //     uint256[6] memory digits = getDigits(standardTicketNumber(ownedTickets[i].ticketNumber, WINNER_BASE, MAX_BASE));
        //     if(isWinner) {
        //         claimAmount = claimAmount.add(
        //             getFraction(info.pool, matches[amountMatch - 1], PERCENT_BASE)
        //                 .div(holders[_round][digits[6 - amountMatch]])
        //         );
        //         bonusAmount = bonusAmount.add(
        //             getBonusReward(holders[_round][digits[6 - amountMatch]], _round, matches[amountMatch - 1])
        //         );
        //     }
        //     else{
        //         uint256 matchReduction = info.noMatch.sub(claimers[_round].percent);
        //         bonusAmount = bonusAmount.add(
        //             getBonusReward( calcNonWinners(_round),_round, matchReduction)
        //         );
        //         // -- matchAmount / nonWinners --
        //         claimAmount = claimAmount.add(
        //             getFraction(info.pool, matchReduction, PERCENT_BASE)
        //                 .div(calcNonWinners(_round))
        //         );
        //     }
        //     emit TicketClaimed(_round, msg.sender, ownedTickets[i]);
        // }
        // if(claimAmount > 0)
        //     crush.safeTransfer(msg.sender, claimAmount);
        // if(bonusAmount > 0){
        //     BonusCoin storage bonus = bonusCoins[_round];
        //     ERC20 bonusTokenContract = ERC20(bonus.bonusToken);
        //     uint256 availableFunds = bonusTokenContract.balanceOf(address(this));
        //     if( roundInfo[_round].totalTickets.sub(roundInfo[_round].ticketsClaimed) == 1)
        //         bonusAmount = bonus.bonusAmount.sub(bonus.bonusClaimed);
        //     if( bonusAmount > availableFunds)
        //         bonusAmount = availableFunds;
        //     bonus.bonusClaimed = bonus.bonusClaimed.add(bonusAmount);
        //     bonusTokenContract.safeTransfer( msg.sender, bonusAmount);
        // }
    }

    /// @notice Start of new Round. This function is only needed for the first round, next rounds will be automatically started once the winner number is received
    function firstStart() external operatorOnly{
        require(currentRound == 0, "First Round only");
        calcNextHour();
        startRound();
        // Rollover all of pool zero at start
        roundInfo[currentRound] = RoundInfo(0,0,0,roundInfo[0].pool, roundEnd, [noMatch, match1, match2, match3, match4, match5, match6], 0);
    }

    /// @notice Ends current round
    /// @dev WIP - the end of the round will always happen at set intervals
    function endRound() external {
        require(LINK.balanceOf(address(this)) >= feeVRF, "Not enough LINK - please contact mod to fund to contract");
        require(currentIsActive == true, "Current Round is over");
        require(block.timestamp > roundInfo[currentRound].endTime, "Can't end round just yet");

        calcNextHour();
        currentIsActive = false;
        roundInfo[currentRound.add(1)].endTime = roundEnd;
        claimers[currentRound] = Claimer(msg.sender, 0);
        // Request Random Number for Winner
        bytes32 rqId = requestRandomness(keyHashVRF, feeVRF);
        emit SelectionStarted(currentRound, msg.sender, rqId);
    }

    /// @notice Add or remove operator
    function toggleOperator(address _operator) external operatorOnly{
        bool operatorIsActive = operators[_operator];
        if(operatorIsActive) {
            operators[_operator] = false;
        }
        else {
            operators[_operator] = true;
        }
        emit OperatorChanged(_operator, operators[msg.sender]);
    }

    // SETTERS
    /// @notice Change the claimer's fee
    /// @param _fee the value of the new fee
    /// @dev Fee cannot be greater than noMatch percentage ( since noMatch percentage is the amount given out to nonWinners )
    function setClaimerFee( uint256 _fee ) external onlyOwner{
        require(_fee.mul(ONE100PERCENT) < noMatch, "Invalid fee amount");
        claimFee = _fee.mul(ONE100PERCENT);
        emit PercentagesChanged(msg.sender, 'claimFee', _fee.mul(ONE100PERCENT));
    }
    /// @notice Set the token that will be used as a Bonus for a particular round
    /// @param _partnerToken Token address
    /// @param _round round where this token applies
    function setBonusCoin( address _partnerToken, uint256 _amount ,uint256 _round, uint256 _roundAmount ) external operatorOnly{
        require(_roundAmount > 0, "Thanks for the tokens, but these need to go.");
        require(_round > currentRound, "This round has passed.");
        require(_partnerToken != address(0),"Cant set bonus Token" );
        require( bonusCoins[ _round ].bonusToken == address(0), "Bonus token has already been added to this round");
        ERC20 bonusToken = ERC20(_partnerToken);
        require( bonusToken.balanceOf(msg.sender) >= _amount, "Funds are needed, can't conjure from thin air");
        require( bonusToken.allowance(msg.sender, address(this)) >= _amount, "Please approve this contract for spending :)");
        uint256 spreadAmount = _amount.div(_roundAmount);
        uint256 totalAmount = spreadAmount.mul(_roundAmount);//get the actual total to take into account division issues
        for( uint rounds = _round; rounds < _round.add(_roundAmount); rounds++){
            require( bonusCoins[ rounds ].bonusToken == address(0), "Bonus token has already been added to round");
            // Uses the claimFee as the base since that will always be distributed to the claimer.
            bonusCoins[ rounds ] = BonusCoin(_partnerToken, spreadAmount, 0, 0);
        }
        bonusToken.safeTransferFrom(msg.sender, address(this), totalAmount);
        emit FundedBonusCoins(_partnerToken, _amount, _round, _roundAmount);
    }

    /// @notice Set the ticket value
    /// @param _newValue the new value of the ticket
    /// @dev Ticket value MUST BE IN WEI format, minimum is left as greater than 1 due to the deflationary nature of CRUSH
    function setTicketValue(uint256 _newValue) external onlyOwner{
        require(_newValue < 50 * 10**18 && _newValue > 1, "Ticket value exceeds MAX");
        ticketValue = _newValue;
        emit UpdateTicketValue(block.timestamp, _newValue);
    }

    /// @notice Edit the times array
    /// @param _newTimes Array of hours when Lottery will end
    /// @dev adding a sorting algorithm would be nice but honestly we have too much going on to add that in. So help us out and add your times sorted
    function setEndHours( uint8[] calldata _newTimes) external operatorOnly{
        require( _newTimes.length > 0, "There must be a time somewhere");
        for( uint i = 0; i < _newTimes.length; i ++){
            require(_newTimes[i] < 24, "We all wish we had more hours per day");
            if(i>0)
                require( _newTimes[i] > _newTimes[i-1], "Help a brother out, sort your times first");
        }
        endHours = _newTimes;
    }

    /// @notice Setup the burn threshold
    /// @param _threshold new threshold in percent amount
    /// @dev setting the minimum threshold as 0 will always burn, setting max as 50
    function setBurnThreshold( uint256 _threshold ) external onlyOwner{
        require(_threshold <= 50, "Out of range");
        burnThreshold = _threshold * ONE__PERCENT;
    }
    /// @notice Set the distribution percentage amounts... all amounts must be given for this to work
    /// @param _newDistribution array of distribution amounts 
    /// @dev we expect all values to sum 100 and that all items are given. The new distribution only applies to next rounds
    /// @dev all values are in the one onehundreth percentile amount.
    /// @dev expected order [ jackpot, match5, match4, match3, match2, match1, noMatch, burn]
    function setDistributionPercentages( uint256[] calldata _newDistribution ) external onlyOwner{
        require(_newDistribution.length == 8, "Missed a few values");
        require(_newDistribution[7] > 0, "We need to burn something");
        match6 = _newDistribution[0].mul(ONE100PERCENT);
        match5 = _newDistribution[1].mul(ONE100PERCENT);
        match4 = _newDistribution[2].mul(ONE100PERCENT);
        match3 = _newDistribution[3].mul(ONE100PERCENT);
        match2 = _newDistribution[4].mul(ONE100PERCENT);
        match1 = _newDistribution[5].mul(ONE100PERCENT);
        noMatch = _newDistribution[6].mul(ONE100PERCENT);
        burn = _newDistribution[7].mul(ONE100PERCENT);
        require( match6.add(match5).add(match4).add(match3).add(match2).add(match1).add(noMatch).add(burn) == PERCENT_BASE, "Numbers don't add up");
        emit PercentagesChanged(msg.sender, "jackpot", match6);
        emit PercentagesChanged(msg.sender, "match5", match5);
        emit PercentagesChanged(msg.sender, "match4", match4);
        emit PercentagesChanged(msg.sender, "match3", match3);
        emit PercentagesChanged(msg.sender, "match2", match2);
        emit PercentagesChanged(msg.sender, "match1", match1);
        emit PercentagesChanged(msg.sender, "noMatch", noMatch);
        emit PercentagesChanged(msg.sender, "burnPercent", burn);
    }

    // External functions that are view
    /// @notice Get Tickets for the caller for during a specific round
    /// @param _round The round to query
    function getRoundTickets(uint256 _round) external view returns(NewTicket[] memory) {
        RoundTickets storage roundReview = userRoundTickets[msg.sender][_round];
        NewTicket[] memory tickets = new NewTicket[](roundReview.totalTickets);
        for( uint i = 0; i < roundReview.totalTickets; i++)
            tickets[i] =  userNewTickets[msg.sender][ roundReview.firstTicketId.add(i) ];
        return tickets;
    }

    function getRoundDistribution(uint256 _round) external view returns( uint256[7] memory distribution){
        distribution[0] = roundInfo[_round].distribution[0];
        distribution[1] = roundInfo[_round].distribution[1];
        distribution[2] = roundInfo[_round].distribution[2];
        distribution[3] = roundInfo[_round].distribution[3];
        distribution[4] = roundInfo[_round].distribution[4];
        distribution[5] = roundInfo[_round].distribution[5];
        distribution[6] = roundInfo[_round].distribution[6];
    }

    // Public functions
    /// @notice Check if number is the winning number
    /// @param _round Round the requested ticket belongs to
    /// @param luckyTicket ticket number to check
    /// @return _match Number of winning matches
    function isNumberWinner(uint256 _round, uint32 luckyTicket) public view returns( uint8 _match){
        uint256 roundWinner = roundInfo[_round].winnerNumber;
        require(roundWinner > 0 , "Winner not yet determined");
        _match = 0;
        uint256 luckyNumber = standardTicketNumber(luckyTicket, WINNER_BASE, MAX_BASE);
        uint256[6] memory winnerDigits = getDigits(roundWinner);
        uint256[6] memory luckyDigits = getDigits(luckyNumber);
        for( uint8 i = 0; i < 6; i++){
            if(winnerDigits[i] == luckyDigits[i])
                _match = i + 1;
            else
                break;
        }
    }

    /// @notice Add funds to pool directly, only applies funds to currentRound
    /// @param _amount the amount of CRUSH to transfer from current account to current Round
    /// @dev Approve needs to be run beforehand so the transfer can succeed.
    function addToPool(uint256 _amount) public {
        uint256 userBalance = crush.balanceOf( msg.sender );
        require( userBalance >= _amount, "Insufficient Funds to Send to Pool");
        crush.safeTransferFrom( msg.sender, address(this), _amount);
        roundInfo[ currentRound ].pool = roundInfo[ currentRound ].pool.add( _amount );
        emit FundPool( currentRound, _amount);
    }

    // Internal functions
    /// @notice Set the next start hour and next hour index
    function calcNextHour() internal {
        uint256 tempEnd = roundEnd;
        uint8 newIndex = endHourIndex;
        bool nextDay = true;
        while(tempEnd <= block.timestamp){
            newIndex = newIndex + 1 >= endHours.length ? 0 : newIndex + 1;
            tempEnd = setNextRoundEndTime(block.timestamp, endHours[newIndex], newIndex != 0 && nextDay);
            if(newIndex == endHours.length)
                nextDay = false;
        }
        roundEnd = tempEnd;
        endHourIndex = newIndex;
    }

    function createTicket( address _owner, uint32 _ticketNumber, uint256 _round) internal {
        uint32 currentTicket = standardTicketNumber(_ticketNumber, WINNER_BASE, MAX_BASE);
        uint256[6] memory digits = getDigits( currentTicket );
        for( uint256 digit = 0; digit < 6; digit++){
            holders[ _round ][ digits[digit] ] = holders[ _round ][ digits[digit] ].add(1);
        }
        userTotalTickets[_owner] = userTotalTickets[_owner].add(1);
        userNewTickets[_owner][userTotalTickets[_owner]] = NewTicket(currentTicket,_round);
    }

    function calcNonWinners( uint256 _round) internal view returns (uint256 nonWinners){
        uint256[6] memory winnerDigits = getDigits( roundInfo[_round].winnerNumber );
        uint256 winners=0;
        for( uint tw = 0; tw < 6; tw++ ){
            winners = winners.add( holders[ _round ][ winnerDigits[tw] ]);
        }
        nonWinners = roundInfo[ _round ].totalTickets.sub( winners );
    }

    //
    function getBonusReward(uint256 _holders, BonusCoin storage bonus, uint256 _match) internal view returns (uint256 bonusAmount) {
        if(_holders == 0)
            return 0;
        if( bonus.bonusToken != address(0) ){
            if(_match == 0)
                return 0;
            bonusAmount = getFraction( bonus.bonusAmount, _match, bonus.bonusMaxPercent ).div(_holders);
            return bonusAmount;
        }
        return 0;
    }

    // Transfer bonus to
    function transferBonus(address _to, uint256 _holders, uint256 _round, uint256 _match) internal {
        BonusCoin storage bonus = bonusCoins[_round];
        if(_holders == 0)
            return;
        if( bonus.bonusToken != address(0) ){
            ERC20 bonusTokenContract = ERC20(bonus.bonusToken);
            uint256 availableFunds = bonusTokenContract.balanceOf(address(this));
            if(_match == 0)
                return;
            uint256 bonusReward = getFraction( bonus.bonusAmount, _match, bonus.bonusMaxPercent ).div(_holders);
            if(bonusReward == 0)
                return;
            if( roundInfo[_round].totalTickets.sub(roundInfo[_round].ticketsClaimed) == 1)
                bonusReward = bonus.bonusAmount.sub(bonus.bonusClaimed);
            if( bonusReward > availableFunds)
                bonusReward = availableFunds;
            bonus.bonusClaimed = bonus.bonusClaimed.add(bonusReward);
            bonusTokenContract.safeTransfer( _to, bonusReward);
        }
    }

    function startRound() internal {
        require( currentIsActive == false, "Current Round is not over");
        // Add new Round
        currentRound ++;
        currentIsActive = true;
        roundStart = block.timestamp;
        RoundInfo storage newRound = roundInfo[currentRound];
        newRound.distribution = [noMatch, match1, match2, match3, match4, match5, match6];
        emit RoundStarted( currentRound, msg.sender, block.timestamp);
    }

    // BURN AND ROLLOVER
    function distributeCrush() internal {
        uint256 rollOver;
        uint256 burnAmount;
        uint256 forClaimer;
        RoundInfo storage thisRound = roundInfo[currentRound];
        (rollOver, burnAmount, forClaimer) = calculateRollover();
        // Transfer Amount to Claimer
        Claimer storage roundClaimer = claimers[currentRound];
        if(forClaimer > 0)
            crush.safeTransfer( roundClaimer.claimer, forClaimer );
        transferBonus( roundClaimer.claimer, 1 ,currentRound, roundClaimer.percent );
        // Can distribute rollover
        if( rollOver > 0 && thisRound.totalTickets.mul(ticketValue) >= getFraction(thisRound.pool, distributionThreshold, PERCENT_BASE)){
            uint256 profitDistribution = getFraction(rollOver, distributionThreshold, PERCENT_BASE);
            crush.approve( address(bankAddress), profitDistribution);
            bankAddress.addUserLoss(profitDistribution);
            rollOver = rollOver.sub(profitDistribution);
        }

        // BURN AMOUNT
        if( burnAmount > 0 ){
            crush.burn( burnAmount );
            thisRound.burn = burnAmount;
        }
        roundInfo[ currentRound + 1 ].pool = rollOver;
    }

    function calculateRollover() internal returns ( uint256 _rollover, uint256 _burn, uint256 _forClaimer ) {
        RoundInfo storage info = roundInfo[currentRound];
        _rollover = 0;
        // for zero match winners
        BonusCoin storage roundBonusCoin = bonusCoins[currentRound];
        uint256[6] memory winnerDigits = getDigits(info.winnerNumber);
        uint256 totalMatchHolders = 0;
        
        for( uint8 i = 0; i < 6; i ++){
            uint256 digitToCheck = winnerDigits[5 - i];
            uint256 matchHolders = holders[currentRound][digitToCheck];
            if( matchHolders > 0 ){
                if(i == 0)
                    totalMatchHolders = matchHolders;
                else{
                    matchHolders = matchHolders.sub(totalMatchHolders);
                    totalMatchHolders = totalMatchHolders.add( matchHolders );
                    holders[currentRound][digitToCheck] = matchHolders;
                }
                _forClaimer = _forClaimer.add(info.distribution[6-i]);
                roundBonusCoin.bonusMaxPercent = roundBonusCoin.bonusMaxPercent.add(info.distribution[6-i]);
            }
            else
                _rollover = _rollover.add( getFraction(info.pool, info.distribution[6-i], PERCENT_BASE) );
        }
        _forClaimer = _forClaimer.mul(claimFee).div(PERCENT_BASE);
        uint256 nonWinners = info.totalTickets.sub(totalMatchHolders);
        // Are there any noMatch tickets
        if( nonWinners == 0 )
            _rollover = _rollover.add(getFraction(info.pool, info.distribution[0].sub(_forClaimer ), PERCENT_BASE));
        else
            roundBonusCoin.bonusMaxPercent = roundBonusCoin.bonusMaxPercent.add(info.distribution[0]);
        if( getFraction(info.pool, burnThreshold, PERCENT_BASE) <=  info.totalTickets.mul(ticketValue) )
            _burn = getFraction( info.pool, burn, PERCENT_BASE);
        else{
            _burn = 0;
            _rollover = _rollover.add( getFraction( info.pool, burn, PERCENT_BASE) );
        }
        claimers[currentRound].percent = _forClaimer;
        _forClaimer = getFraction(info.pool, _forClaimer, PERCENT_BASE);
    }

    // GET Verifiable RandomNumber from VRF
    // This gets called by VRF Contract only
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        RoundInfo storage info = roundInfo[currentRound];
        info.winnerNumber = standardTicketNumber(uint32(randomness), WINNER_BASE, MAX_BASE);
        distributeCrush();
        emit WinnerPicked(currentRound, info.winnerNumber, requestId);
        startRound();
    }

    // Function to get the fraction amount from a value
    function getFraction(uint256 _amount, uint256 _percent, uint256 _base) internal pure returns(uint256 fraction) {
        fraction = _amount.mul( _percent ).div( _base );
    }

    // Get all participating digits from number
    function getDigits( uint256 _ticketNumber ) internal pure returns(uint256[6] memory digits){
        digits[0] = _ticketNumber.div(100000); // WINNER_BASE
        digits[1] = _ticketNumber.div(10000);
        digits[2] = _ticketNumber.div(1000);
        digits[3] = _ticketNumber.div(100);
        digits[4] = _ticketNumber.div(10);
        digits[5] = _ticketNumber.div(1);
    }

    // Get the requested ticketNumber from the defined range
    function standardTicketNumber( uint32 _ticketNumber, uint32 _base, uint32 maxBase) internal pure returns( uint32 ){
        uint32 ticketNumber;
        if(_ticketNumber < _base ){
            ticketNumber = _ticketNumber + _base;
        }
        else if( _ticketNumber > maxBase ){
            ticketNumber = (_ticketNumber % _base) + _base;
        }
        else{
            ticketNumber = _ticketNumber;
        }
        return ticketNumber;
    }

    // Get timestamp end for next round to be at the specified _hour
    function setNextRoundEndTime(uint256 _currentTimestamp, uint256 _hour, bool _sameDay) internal pure returns (uint256 _endTimestamp ) {
        uint nextDay = _sameDay ? _currentTimestamp : SECONDS_PER_DAY.add(_currentTimestamp);
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
    
    /// @notice HELPFUL FUNCTION TO TEST WINNERS LOCALLY THIS FUNCTION IS NOT MEANT TO GO LIVE
    /// This function sets the random value for the winner.
    /// @param randomness simulates a number given back by the randomness function
    function setWinner( uint256 randomness, address _claimer ) public operatorOnly{
        currentIsActive = false;
        RoundInfo storage info = roundInfo[currentRound];
        info.winnerNumber = standardTicketNumber(uint32(randomness), WINNER_BASE, MAX_BASE);
        claimers[currentRound] = Claimer(_claimer, 0);
        distributeCrush();
        startRound();
        calcNextHour();
        roundInfo[currentRound].endTime = roundEnd;
        emit WinnerPicked(currentRound, info.winnerNumber, "ADMIN_SET_WINNER");
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

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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