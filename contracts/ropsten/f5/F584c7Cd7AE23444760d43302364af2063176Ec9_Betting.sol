/**
 *Submitted for verification at Etherscan.io on 2021-10-31
*/

pragma solidity ^0.5.16;

contract Betting{
    uint public minimumBet; // minimum bet allowed
    uint public totalBetOne; //stakes of team one
    uint public totalBetTwo; //stakes of team two
    uint public numberOfBets; //total amount of bets
    uint public maxAmountOfBets = 1000;

    //list of players that made a bet
    address payable[] public players;

    //Information about a player
    struct Player {
        uint amountBet; //the amount a player is betting
        uint8 teamSelected; //the team a player wants to win values:1 or 2
    }

    //address of the player => player info
    mapping(address => Player) public playerInfo;

    constructor() public{
        minimumBet = 100000000000000;
    }

    //check if the player exists or not 
    function checkPlayerExists(address player) public view returns (bool){
        for(uint16 i = 0; i < players.length; i++){
            if(players[i] == player) return true;
        }
        return false;
    }

    function bet(uint8 _teamSelected) public payable{
        //check if the player has already made a bet
        require(!checkPlayerExists(msg.sender));

        //check if the betting amount is equal or greater than the minimum
        require(msg.value >= minimumBet);
        
        //set the information about the bet
        playerInfo[msg.sender].amountBet = msg.value;
        playerInfo[msg.sender].teamSelected = _teamSelected;

        //adding the player to the players array
        players.push(msg.sender);

        //incrementing the stakes of the teams according to player selection
        if(_teamSelected == 1){
            totalBetOne += msg.value;
        } else {
            totalBetTwo += msg.value;
        }
    }

    //distribution of the winnings
    function distributePrizes(uint8 teamWinner) public {
        //creation of a in memory array with the winners
        address payable[1000] memory winners;

        uint16 count = 0;
        uint loserBet = 0; //the count of all loser bet
        uint winnerBet = 0; //the count of all winnert bet

        address add;
        uint bet;
        address payable playerAddress;

        //we look for the winners
        for(uint16 i = 0; i<players.length; i++){
            playerAddress = players[i];
            //if the player won we add the address to the winners array
            if(playerInfo[playerAddress].teamSelected == teamWinner){
                winners[count] = playerAddress;
                count++;
            }
        }

        //definition of the winning and losing sum
        if(teamWinner == 1) {
            loserBet = totalBetTwo;
            winnerBet = totalBetOne;
        } else {
            loserBet = totalBetOne;
            winnerBet = totalBetTwo;
        }

        //we give the prizes to the winners
        for(uint16 i = 0; i < count; i++){
            //check that the address in this array is not empty
            if(winners[i] != address(0)){
                add = winners[i];
                bet = playerInfo[add].amountBet;
                //transfer the money to the user
                winners[i].transfer((bet*(10000 +(loserBet*10000/winnerBet)))/10000);
            }
        }
        delete playerInfo[playerAddress]; //delete all the players
        delete players; //delete the players array
        loserBet = 0; //reinitialize the bets
        winnerBet = 0;
        totalBetOne = 0;
        totalBetTwo = 0;
    }

    //functions to be used by the UI returns the amount of stakes
    function amountOne() public view returns(uint){
        return totalBetOne;
    }

    function amountTwo() public view returns(uint){
        return totalBetTwo;
    }
}