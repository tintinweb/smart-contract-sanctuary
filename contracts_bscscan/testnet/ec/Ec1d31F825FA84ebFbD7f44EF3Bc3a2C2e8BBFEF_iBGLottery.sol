/**
 *Submitted for verification at BscScan.com on 2021-09-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IIBGBooster.sol";
import  "./Ownable.sol";

contract iBGLottery is Ownable {
    // Constants
    uint256 private FIRST_WINNER_PRIZE = 5000 * 1e18; // 1,000 iBG
    uint256 private SECOND_WINNER_PRIZE = 5000 * 1e18; // 500 iBG
    //uint256 public DURATION = 7 * 24 * 3600; // 1 week
    uint256 private DURATION = 3600; // 1 hour
    uint256 private TICKET_BASE_PRICE = 5 * 1e18; // 5 iBG per ticket
    uint256 private DISCOUNT_TIER_1 = 5; // 5% discount for 1st tier
    uint256 private DISCOUNT_TIER_2 = 10; // 10% discount for 2st tier
    uint256 private DISCOUNT_TIER_3 = 20; // 20% discount for 3st tier
    uint256 private SUPER_STAKER_PRICE = 1000 * 1e18; // 1000 iBG staked to claim a ticket

    // Global Variables
    IERC20 private ibg;
    IIBGBooster private booster;
    uint256 public immutable startTime; 
    bool public closed;

    // Per Round Variables
    mapping(uint256 => address[]) private tickets;
    mapping(uint256 => mapping(address => uint256)) public numTicketsOf;
    mapping(uint256 => mapping(address => uint256)) public claimed;
    mapping(uint256 => Stats) private stats;
    
    struct Stats {
        uint256 sales;
        uint256 numParticipants;
        bool finalized;
        address firstWinner;
        address secondWinner;
    }

    event Ticket(uint256 indexed round, address indexed _player, uint256 _numTicket, uint256 _price);
    event Winner(uint256 indexed round, address _winner, uint256 _prize);

    constructor(address _ibgTokenAddress, address _boosterAddress, uint256 _startTime) {
        ibg = IERC20(_ibgTokenAddress);
        booster = IIBGBooster(_boosterAddress);
        startTime = _startTime;
    }

    function getCurrentRound() public view returns (uint256) {
        return (block.timestamp - startTime) / DURATION;
    }
    
    function getTicketPrice(uint256 _numTicket) private view returns (uint256) {
        if(_numTicket >= 1000) {
            return TICKET_BASE_PRICE * _numTicket * (100 - DISCOUNT_TIER_3) / 100;
        } else if(_numTicket >= 100) {
            return TICKET_BASE_PRICE * _numTicket * (100 - DISCOUNT_TIER_2) / 100;
        } else if(_numTicket >= 10) {
            return TICKET_BASE_PRICE * _numTicket * (100 - DISCOUNT_TIER_1) / 100;
        } else {
            return TICKET_BASE_PRICE * _numTicket;
        }
    }

    function purchaseTicket(uint256 _numTicket) external returns (bool) {
        require(block.timestamp > startTime, "Lottery did not started yet");
        require(!closed, "Lottery has already closed");

        uint256 round = getCurrentRound();
        uint256 price = getTicketPrice(_numTicket);
        ibg.transferFrom(msg.sender, address(this), price);
        ibg.burn(price); // Issue in production

        for(uint256 i = 0; i < _numTicket; i++) {
            tickets[round].push(msg.sender);
        }

        if(numTicketsOf[round][msg.sender] == 0) stats[round].numParticipants++;

        numTicketsOf[round][msg.sender] += _numTicket;
        stats[round].sales += price;

        emit Ticket(round, msg.sender, _numTicket, price);
        return true;
    }

    function claimTicket() external returns (bool) {
        require(!closed, "Lottery has already closed");

        uint256 staked = getSuperStaked(msg.sender);
        require(staked >= SUPER_STAKER_PRICE, "need super stake more than 1000 iBG");

        uint256 round = getCurrentRound();
        require(claimed[round][msg.sender] == 0, "tickets already claimed");

        uint256 numTicket = staked / SUPER_STAKER_PRICE;
        for(uint256 i = 0; i < numTicket; i++) {
            tickets[round].push(msg.sender);
        }
        claimed[round][msg.sender] = numTicket;

        if(numTicketsOf[round][msg.sender] == 0) stats[round].numParticipants++;

        numTicketsOf[round][msg.sender] += numTicket;

        emit Ticket(round, msg.sender, numTicket, 0);
        return true;
    }

    function finalize(uint256 _round) external onlyOwner returns (bool) {
        require(!closed, "Lottery has already closed");
        require(!stats[_round].finalized, "Lottery already finalized");
        require(block.timestamp > startTime + (_round + 1) * DURATION, "Specified round has not been ended");

        uint256 numTickets = tickets[_round].length;

        uint256 random1 = uint256(keccak256(abi.encodePacked(msg.sender, numTickets, block.timestamp)));
        uint256 firstWinner = random1 % numTickets;
        ibg.mint(tickets[_round][firstWinner], FIRST_WINNER_PRIZE);
        
        uint256 random2 = uint256(keccak256(abi.encodePacked(firstWinner, numTickets, block.timestamp)));
        uint256 secondWinner = random2 % numTickets;
        require(firstWinner != secondWinner, "The same address won 2 places. Try again");
        ibg.mint(tickets[_round][secondWinner], SECOND_WINNER_PRIZE);
        stats[_round].finalized = true;
        
        emit Winner(_round, tickets[_round][firstWinner], FIRST_WINNER_PRIZE);
        emit Winner(_round, tickets[_round][secondWinner], SECOND_WINNER_PRIZE);
        
        return true;
    }

    function getStats(uint256 _round) external view returns (uint256 _numTotalTickets, uint256 _numParticipants, uint256 _sales, bool _finalized, address _firstWinner, address _secondWinner) {
        Stats memory stat = stats[_round];
        return (tickets[_round].length, stat.numParticipants, stat.sales, stat.finalized, stat.firstWinner, stat.secondWinner);
    }

    function getSuperStaked(address _addr) public view returns (uint256) {
        uint256 totalStaked;
        for(uint256 i = 0; i < 3; i++) {
            (uint256 staked, , ) = booster.userInfo(i, _addr);
            totalStaked += staked;
        }
        return totalStaked;
    }
}