pragma solidity ^0.4.25;

///@title Gambling with ether
contract Gamble {
    
    struct Player {
        address addr;
        uint wager;
    }
    
    Player[5] public players;
    uint total_wager;
    uint num_players;
    
    constructor() public {
        total_wager = 0;
        num_players = 0;
    }
    
    function bid() public payable {
        require(
            num_players < 5,
            "There are already 5 players. The game will reset soon"
        );
        
        address addr = msg.sender;
        uint wager = msg.value;
        players[num_players] = Player(addr, wager);
        total_wager += wager;
        num_players++;
        
        if (num_players == 5) {
            uint index = random() % num_players;
            log0(bytes32(index));
            address winner = players[index].addr;
            winner.transfer(total_wager);
            
            total_wager = 0;
            num_players = 0;
        }
            
    }
    
    function getWager() public view returns (uint tot_wager) {
            return total_wager;
    }
        
    
    function random () private view returns(uint) {
        return uint(keccak256(block.difficulty, now, players.length));
    }
}