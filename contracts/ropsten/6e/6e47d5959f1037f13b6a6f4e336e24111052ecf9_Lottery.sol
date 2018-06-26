pragma solidity ^0.4.0;




contract Lottery {



    mapping(uint => address) public players;
    uint8 public number_of_players_signed; 
    uint public bet_amount; 
    uint8 public players_required; 
    uint8 public players_signedUp_for_nextround; 
    uint public random_number; 
    uint public winners_stake; 
    address public owner; 
    uint public bet_executed_atBlock; 
    uint public pot;
    uint public reservedForNextRound;
    uint finalPrize;
    address public theChosenWinner;


    constructor() public{
        owner = msg.sender;
        number_of_players_signed = 0;
        bet_amount = 10000000000000000 wei;
        players_required = 2;
        winners_stake = 80;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    function updateFieldss(uint newbet_amount, uint8 newNumberOfPlayers, uint newWinnerPercentage) public onlyOwner {

            bet_amount = newbet_amount;
        
            players_required = newNumberOfPlayers;
        
            winners_stake = newWinnerPercentage;
        }


event Announce_winner(
    address indexed _from,
    address indexed _to,
    uint _value
    );

function join() payable public{

    if(msg.value != bet_amount) revert(); 
    number_of_players_signed +=1;
    pot = address(this).balance;

    players[number_of_players_signed] = msg.sender;
    
    if (number_of_players_signed == players_required) {
        bet_executed_atBlock=block.number;
    }
    if (number_of_players_signed > players_required) {
        if (block.number>bet_executed_atBlock){
            random_number = uint(blockhash(block.number-1))%players_required + 1;
            uint dev = pot/10;
            finalPrize = pot*winners_stake/100;
            reservedForNextRound = dev;
            theChosenWinner = players[random_number];
            players[random_number].transfer(finalPrize);
            owner.transfer(dev);
            players_signedUp_for_nextround = number_of_players_signed-players_required;
            while (number_of_players_signed > players_required) {
                players[number_of_players_signed-players_required] = players[number_of_players_signed];
                number_of_players_signed -=1;    
            }
            number_of_players_signed = players_signedUp_for_nextround;
        }
        else revert();
    }
    
}
}