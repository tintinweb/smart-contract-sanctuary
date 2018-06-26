pragma solidity ^0.4.24;

contract Exam
{
    address public judge;
    uint public prize_money;
    uint public join_money;
    
    uint public game_count;
    
    uint public best_score;
    address[] public winnerlist;
    
    uint[39] public correct;
    
    struct player
    {
        uint[39] game;
        uint score;
        bool can;
    }
    
    mapping (address => player) public players;
    address[] public player_addresss;
    
    
    constructor() public
    {
        judge = msg.sender;
        game_count = 0;
        prize_money = 0;
        join_money = 0.1 ether;
    }

    function () payable
    {
        require(msg.value >= join_money);
        players[msg.sender].can= true;
        prize_money = prize_money + msg.value;
        player_addresss.push(msg.sender);
    }
    
    // 0 : win , 1 : draw, 2 : lose, 3 : giveup
    function bat_match (uint[39] a) public
    {
        require(players[msg.sender].can);
        for(game_count=0; game_count<39 ; game_count++)
        {
            players[msg.sender].game[game_count] = a[game_count];
        }
    }
    
    function correct_check_match  (uint[39] a) public
    {
        require(msg.sender == judge);
        for(uint i=0; i<39; i++)
        {
            correct[i] = a[i];
        }        
    }
    
    function socoreCheck() public
    {
        for(uint i = 0; i < player_addresss.length ; i++)
        {
            for(uint j=0; j<39 ; j++)
            {
                if(players[player_addresss[i]].game[j]==3)
                {
                    
                }
                else if(players[player_addresss[i]].game[j] ==correct[j])
                {
                    players[player_addresss[i]].score = players[player_addresss[i]].score+1;
                }
                else if(players[player_addresss[i]].game[j] !=correct[j])
                {
                    players[player_addresss[i]].score = players[player_addresss[i]].score-1;
                }
            }
            
            if(best_score<=players[player_addresss[i]].score)
            {
                best_score = players[player_addresss[i]].score;
            }
        }
    }
    
    function findWinner() public
    {
         for(uint i = 0; i < player_addresss.length ; i++)
        {
            if( players[player_addresss[i]].score==best_score)
            {
                winnerlist.push(player_addresss[i]);
            }
            
        }
    }
    
    
    function reward() public payable
    {
        require(msg.sender==judge);
        
        prize_money = prize_money / winnerlist.length;
        
        for(uint i=0; i<winnerlist.length; i++)
        {
            winnerlist[i].transfer(prize_money);
        }
        
    }
    
    
    
    
    
}