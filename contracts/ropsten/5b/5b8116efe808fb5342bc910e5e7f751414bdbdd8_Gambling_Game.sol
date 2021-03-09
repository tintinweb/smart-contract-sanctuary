/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

pragma solidity ^0.7.4;

struct Player{
    uint256 bal;
    bool has_bet;
    uint256 bet_amount;
    uint8 bet_x;
}

contract Gambling_Game{
    bool paid_out;
    Player[] player_list;
    
    address dealer;
    uint256 player_count;
    
    uint256 starting_balance = 500;
    uint256 MAX_BET = 500;
    uint256 MIN_BET = 5;
    
    bool game_running = false;
    bool valid_reveal;
    
    uint8 game_x;
    uint256 game_r;
    bytes32 game_c;
    
    mapping(address => uint256) id;
    
    constructor(){
        paid_out = false;
        dealer = msg.sender;
        player_list.push();
        player_count = 0;
    }
    
    function join_game() public returns( uint256 player_num)
    {
        require( id[msg.sender] == 0, "join_game error: this address is already associated to a player." );
        
        player_count += 1;
        id[msg.sender] = player_count;
        
        player_list.push();
        player_list[ player_count ].bal = starting_balance;
        player_list[ player_count ].has_bet = false;
        player_num = player_count;
    }
    
    function get_my_player_num() public view returns( uint256 player_num)
    {
        player_num = id[ msg.sender ];
    }
    
    function dealer_commit(uint8 x, uint256 r) public
    {
        require( dealer == msg.sender, "dealer_commit error: only the dealer can commit." );
        require( x == 0 || x == 1);
        require(game_running == false); //prevents changing commitment during game.
        
        game_running = true;
        game_c = keccak256( abi.encodePacked(r,x) );
    }
    
    
    //Verify Dealer has committed!
    function make_bet(uint256 bet, uint8 x) public
    {
        require( id[msg.sender] != 0, "make_bet error: only a player may bet." );
        require( game_running == true, "make_bet error: the game is not running" );
        require( player_list[ id[msg.sender] ].has_bet == false, "make_bet error: player has already made their bet" );
        
        require( (x == 0) || (x == 1), "make_bet error: x must be either 0 or 1." );
        require( player_list[ id[msg.sender] ].bal > bet, "make_bet error: bet exceeds player's balance." );
        
        player_list[ id[msg.sender] ].bet_x = x;
        player_list[ id[msg.sender] ].bet_amount = bet;
        player_list[ id[msg.sender] ].has_bet = true;
    }
    
    function pay_out() public
    {
        require(game_running == false, "pay_out error: Dealer is still taking bets.");
        
        if(valid_reveal == false) //Dealer tried cheating
        {
            //Pay out to everyone
            for(uint i = 1; i <= player_count; i++)
            {
                player_list[ i ].bal += player_list[ i ].bet_amount;
                player_list[ i ].bet_amount = 0;
                player_list[ i ].has_bet = false;
            }
        }
        else{
            for(uint i = 1; i <= player_count; i++)
            {
                if( player_list[ i ].bet_x == game_x)
                { player_list[ i ].bal += player_list[ i ].bet_amount; }
                else{
                    player_list[ i ].bal -= player_list[ i ].bet_amount;
                }
                
                player_list[ i ].has_bet = false;
                player_list[ i ].bet_amount = 0;
            }
        }
    }
    
    function dealer_reveal(uint8 x, uint256 r) public
    {
        require( dealer == msg.sender, "dealer_reveal error: only the dealer may reveal." );
        require( game_running == true, "dealer_reveal error: game must be running for dealer to reveal.");
        
        game_x = x;
        game_r = r;
        game_running = false;       

        if( keccak256( abi.encodePacked(r,x) ) == game_c ){ 
            valid_reveal = true;
        }
        else{
            valid_reveal = false;
        }
    }
    
    function check_commit() public returns(bool commit_matches)
    {
        if( keccak256( abi.encodePacked(game_r,game_x) ) == game_c ){ 
            valid_reveal = true;
        }
        else{
            valid_reveal = false;
        }        
        
        commit_matches = valid_reveal;
    }
    
    function view_player(uint256 account) public view returns(uint256 balance, bool status, uint256 wager, uint8 x)
    {
        require( account > 0, "view_player error: invalid player number");
        require( account <= player_count, "view_player error: invalid player number");
        
        balance = player_list[ account ].bal;
        status = player_list[ account ].has_bet;
        wager = player_list[ account ].bet_amount;
        x = player_list[ account ].bet_x;
    }
    
    
    function view_commit() public view returns(bool game_status, uint8 x, uint256 r, bytes32 c, bool matches)
    {
        game_status = game_running;
        x = game_x;
        r = game_r;
        c = game_c;
        matches = valid_reveal;
    }

}