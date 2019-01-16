pragma solidity ^0.4.0;

contract Lottery {
    
    address private owner;
    uint public pot;
    address[] private players;
    uint public entries;
    uint public maxEntries;
    
    mapping(uint => address) private bets;
    uint private numBets;
    uint private minBet;
    
    constructor () public payable {
        owner = msg.sender;
        maxEntries = 5;
        minBet = 1 ether;
        players.length = maxEntries;
        entries = 0;
        pot = 0;
        numBets = 0;
    }
    
    function random () private view returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, now, entries)));
    }
    
    function enter() public payable {
        assert(entries < maxEntries);
        pot += msg.value;
        if (msg.value >= minBet) {
            players[entries] = msg.sender;
            entries++;
        }
        for (uint value = msg.value; value >= 1 ether; value -= 1 ether)
        {
            bets[numBets] = msg.sender;
            numBets++;
        }
        if (entries == maxEntries) {
            selectWinner();
        }
    }
    
    function selectWinner() private {
        address winner = bets[random()%entries];
        winner.transfer(pot - (10 finney));
        owner.transfer(10 finney);
        pot = 0;
        numBets = 0;
        entries = 0;
    }
    
}