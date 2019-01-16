pragma solidity ^0.4.25;
contract Lottery {
        
        // must be 5 players to start 
        // uint public playerCount; 
        // uint public index;
        
        struct Player {
            // string name;
            address id;
            uint wager;
        }
        
        // array of address of the players 
        // address[] players;
        
        Player[] public players;
      
        function chooseWinner() private {
            require(players.length == 5, "The Lottery requires 5 players to start");
            uint index = random() % players.length;
            Player storage winner = players[index];
            uint totalReward = 0;
            for (uint i = 0; i < players.length; i++) {
                totalReward += players[i].wager;
               
            }
            (winner.id).transfer(totalReward);
            resetContract();
        }
    
        function addNewPlayer() payable public {
            require(players.length < 5, "The Lottery is already full");
            players.push(Player({id: msg.sender, wager: msg.value})); 
            if (players.length == 5) {
                chooseWinner();
            }  
        }
        
        function resetContract() private {
            delete players;
        }
        
        function random () private view returns (uint) {
            return uint(keccak256(block.difficulty, now, players.length));
        }
}