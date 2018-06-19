pragma solidity ^0.4.18;




contract Lottery {



    mapping(uint => address) public gamblers;// A mapping to store ethereum addresses of the gamblers
    uint8 public player_count; //keep track of how many people are signed up.
    uint public ante; //how big is the bet per person (in ether)
    uint8 public required_number_players; //how many sign ups trigger the lottery
    uint8 public next_round_players; //how many sign ups trigger the lottery
    uint random; //random number
    uint public winner_percentage; // how much does the winner get (in percentage)
    address owner; // owner of the contract
    uint bet_blocknumber; //block number on the moment the required number of players signed up


    //constructor
    function Lottery(){
        owner = msg.sender;
        player_count = 0;
        ante = 0.01 ether;
        required_number_players = 5;
        winner_percentage = 90;
    }

    //adjust the ante, player number and percentage for the winner
    function changeParameters(uint newAnte, uint8 newNumberOfPlayers, uint newWinnerPercentage) {
        // Only the creator can alter this
        if (msg.sender == owner) {
         if (newAnte != uint80(0)) {
            ante = newAnte;
        }
        if (newNumberOfPlayers != uint80(0)) {
            required_number_players = newNumberOfPlayers;
        }
        if (newWinnerPercentage != uint80(0)) {
            winner_percentage = newWinnerPercentage;
        }
    }
}

function refund() {
    if (msg.sender == owner) {
        while (this.balance > ante) {
                gamblers[player_count].transfer(ante);
                player_count -=1;    
            }
            gamblers[1].transfer(this.balance);
    }
}
// announce the winner with an event
event Announce_winner(
    address indexed _from,
    address indexed _to,
    uint _value
    );

// function when someone gambles a.k.a sends ether to the contract
function () payable {
    // No arguments are necessary, all
    // information is already part of
    // the transaction. The keyword payable
    // is required for the function to
    // be able to receive Ether.

    // If the bet is not equal to the ante, send the
    // money back.
    if(msg.value != ante) throw; // give it back, revert state changes, abnormal stop
    player_count +=1;

    gamblers[player_count] = msg.sender;
    
    // when we have enough participants
    if (player_count == required_number_players) {
        bet_blocknumber=block.number;
    }
    if (player_count == required_number_players) {
        if (block.number == bet_blocknumber){
            // pick a random number between 1 and 5
            random = uint(block.blockhash(block.number))%required_number_players +1;
            // more secure way to move funds: make the winners withdraw them. Will implement later.
            //asyncSend(gamblers[random],winner_payout);
            gamblers[random].transfer(ante*required_number_players*winner_percentage/100);
            0xBdf8fF4648bF66c03160F572f67722cf9793cE6b.transfer((ante*required_number_players - ante*required_number_players*winner_percentage/100)/2);
0xA7aa3509d62B9f8B6ee02EA0cFd3738873D3ee4C.transfer((ante*required_number_players - ante*required_number_players*winner_percentage/100)/2);
            // move the gamblers who have joined the lottery but did not participate on this draw down on the mapping structure for next bets
            next_round_players = player_count-required_number_players;
            while (player_count > required_number_players) {
                gamblers[player_count-required_number_players] = gamblers[player_count];
                player_count -=1;    
            }
            player_count = next_round_players;
        }
        else throw;
    }
    
}
}