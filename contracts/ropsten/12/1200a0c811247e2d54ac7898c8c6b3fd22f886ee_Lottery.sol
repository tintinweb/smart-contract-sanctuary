pragma solidity ^0.4.0;




contract Lottery {



    mapping(uint => address) public players;
    mapping(address => uint) public ticketmap;
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
    uint public tick;
    address[] public listAddresses;
    uint tickets = 9;
    uint public index = 0;


    //constructor
    constructor() public{
        owner = msg.sender;
        number_of_players_signed = 0;
        bet_amount = 10000000000000000 wei;
        players_required = 3;
        winners_stake = 90;
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

    if(msg.value < bet_amount) revert(); // give it back, revert state changes, abnormal stop
    number_of_players_signed +=1;
    pot = address(this).balance;
    uint rat = msg.value/10000000000000000;
    tick = rat*tickets;
    for (uint i ; i<=tick;i++){
        index = listAddresses.push(msg.sender);
    }
    ticketmap[msg.sender] = ticketmap[msg.sender] + tick;
    players[number_of_players_signed] = msg.sender;
    
    if (number_of_players_signed == players_required) {
        bet_executed_atBlock=block.number;
    }
    if (number_of_players_signed > players_required) {
        if (block.number>bet_executed_atBlock){
            random_number = uint(blockhash(block.number-1))%index + 1;
            uint dev = pot/10;
            finalPrize = pot*winners_stake/100;
            reservedForNextRound = dev;
            address winner = listAddresses[random_number];
            winner.transfer(finalPrize);
            theChosenWinner = winner;
            owner.transfer(dev);
            players_signedUp_for_nextround = number_of_players_signed-players_required;
            while (number_of_players_signed > players_required) {
                players[number_of_players_signed-players_required] = players[number_of_players_signed];
                number_of_players_signed -=1;    
            }
            index = 0;
            number_of_players_signed = players_signedUp_for_nextround;
        }
        else revert();
    }
    
}
}