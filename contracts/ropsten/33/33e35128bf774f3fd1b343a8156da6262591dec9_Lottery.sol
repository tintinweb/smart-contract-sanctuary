pragma solidity ^0.4.25;

contract Lottery {
    
    address [5]  players; // array to store five current players
    uint currentPlayer; // keep track of how many players have entered into the lottery
    uint funds; // keeps track of the current funds; not completely necessary but added it just because

    constructor () public // constructor that sets currentPlayer and funds to 0
    {
        currentPlayer = 0;
        funds = 0;
    }
    
    function play() public payable{ // function that players call to play in lottery
    
        require(msg.value > 0 ether, "No ether sent"); // requires players to send more than 0 ether
        require(currentPlayer < 5, "Reached player limit"); // checks to make sure more than 5 players do not enter into lottery
        
        players[currentPlayer] = msg.sender; // adds current player to list of players
        funds += msg.value; // adds funds sent to funds
        currentPlayer += 1; // increment the current player
        
        if(currentPlayer == 5) // checks if 5 players have entered into lottery
        {
            require(currentPlayer == 5, "Lottery has not ended!"); // makes sure that 5 players have entered into lottery before sending funds
            uint winner = (random() % players.length); // calculates index of random winner in the array of players
            players[winner].transfer(address(this).balance); // transfers the funds from the contract to the winner
            funds = address(this).balance; // sets funds back to 0 (this should be the value after the transfer)
            currentPlayer = 0; // sets current player back to 0
        } 
    }
    
    
    function random () private view returns(uint) { // function that returns a random value
        return uint(keccak256(block.difficulty, now, players));
    }
}