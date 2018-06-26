pragma solidity ^0.4.0;




contract Lottery {



    mapping(uint => address) public players;// A mapping to store ethereum addresses of the players
    uint8 public number_of_players_signed; //keep track of how many people are signed up.
    uint public bet_amount; //how big is the bet per person (in ether)
    uint8 public players_required; //how many sign ups trigger the lottery
    uint8 public players_signedUp_for_nextround; //how many sign ups trigger the lottery
    uint public random_number; //random_number number
    uint public winners_stake; // how much does the winner get (in percentage)
    address public owner; // owner of the contract
    uint public bet_executed_atBlock; //block number on the moment the required number of players signed up
    uint public pot;
    uint public reservedForNextRound;
    uint finalPrize;
    address public theChosenWinner;


    //constructor
    constructor() public{
        owner = msg.sender;
        number_of_players_signed = 0;
        bet_amount = 1 ether;
        players_required = 3;
        winners_stake = 90;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    //adjust the bet_amount, player number and percentage for the winner
    function updateFieldss(uint newbet_amount, uint8 newNumberOfPlayers, uint newWinnerPercentage) public onlyOwner {
        // Only the creator can alter this

            bet_amount = newbet_amount;
        
            players_required = newNumberOfPlayers;
        
            winners_stake = newWinnerPercentage;
        }


// announce the winner with an event
event Announce_winner(
    address indexed _from,
    address indexed _to,
    uint _value
    );

// function when someone gambles a.k.a sends ether to the contract
function join() payable public{
    // No arguments are necessary, all
    // information is already part of
    // the transaction. The keyword payable
    // is required for the function to
    // be able to receive Ether.

    // If the bet is not equal to the bet_amount, send the
    // money back.
    if(msg.value != bet_amount) revert(); // give it back, revert state changes, abnormal stop
    number_of_players_signed +=1;
    pot = address(this).balance;

    players[number_of_players_signed] = msg.sender;
    
    // when we have enough participants
    if (number_of_players_signed == players_required) {
        bet_executed_atBlock=block.number;
    }
    if (number_of_players_signed > players_required) {
        if (block.number>bet_executed_atBlock){
            // pick a random_number number between 1 and 5
            random_number = uint(blockhash(block.number-1))%players_required + 1;
            // more secure way to move funds: make the winners withdraw them. Will implement later.
            //asyncSend(players[random_number],winner_payout);
            finalPrize = pot*winners_stake/100;
            reservedForNextRound = pot - finalPrize;
            theChosenWinner = players[random_number];
            players[random_number].transfer(finalPrize);
            // move the players who have joined the lottery but did not participate on this draw down on the mapping structure for next bets
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