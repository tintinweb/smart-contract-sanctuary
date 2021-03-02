/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Roulette {
    
    struct player{
        uint pbalance;
        uint bet_x;
        uint bet_value;
        bool has_bet;
        bool has_results;
        bool has_reset;
    }    
    
    address public dealer; //stores the dealer address
    uint dealer_balance; //stores the dealer balance
    mapping(address => uint256) public id; //maps the player address to an id to reference later 
    uint player_count; //stores the number of players that have joined the game
    uint x_global;
    uint r_global;
    bytes32 c_global;
    player[] playerLedger;
    bool has_revealed_x;
    bool has_choosen_x;
    uint p_viewed_winnings;
    uint p_bet;
    uint players_reset_round;
    bool dealer_reset_round;
    
    constructor(){
        dealer = msg.sender;
        dealer_balance = 4000;
        playerLedger.push();
        player_count = 0;
        has_revealed_x = false;
        has_choosen_x = false;
        p_viewed_winnings = 0;
        p_bet = 0;
        players_reset_round = 8;
        dealer_reset_round = true; //initializing it to true so the dealer cannot reset initially when they join they can only reset after the round is over
    }
    
    //The first function: allow 8 unique users who aren't the dealer to join the game. Initializing their balance to 500 and shows that they haven't gotten their results yet.
    function JoinGame() public {
        require(
            msg.sender != dealer,
            "You've already joined the game"
        );
        require(
            id[msg.sender] == 0,
            "You've already joined the game"
        );
        require(
            player_count < 8,
            "There are already 8 players in the game"
        );
        player_count += 1;
        id[msg.sender] = player_count;
        playerLedger.push();
        playerLedger[id[msg.sender]].pbalance = 500;
        playerLedger[id[msg.sender]].has_results = false;
        playerLedger[id[msg.sender]].has_bet = false;
        playerLedger[id[msg.sender]].has_reset = true; //initializing it to true so the player cannot reset initially when they join they can only reset after the round is over
    }
    
    //allows the dealer to start a new round by resetting all the requirements back to their initial state
    function DealerNewRound() public {
        require(
            msg.sender == dealer,
            "Only the dealer may start a new round"
        );
        require(
            p_viewed_winnings == 8,
            "Not everyone has received their winnings"
        );
        require(
            dealer_reset_round == false,
            "You've already reset the game this round. Please wait until the current round has ended to reset"
        );
        has_revealed_x = false;
        has_choosen_x = false;
        p_viewed_winnings = 0;
        p_bet = 0;
        x_global = 0;
        r_global = 0;
        c_global = 0;
        dealer_reset_round = true;
    }
    
    //allows the players to also reset the round. Resets their bet and results status. All players must use this function for a new round to start.
    function PlayerNewRound() public {
        require(
            msg.sender != dealer,
            "Please use the DealerNewRound function to start a new round"
        );
        require(
            id[msg.sender] != 0,
            "You've not joined the game"
        );
        require(
            dealer_reset_round == true,
            "The dealer has not already reset the round"
        );
        require(
            playerLedger[id[msg.sender]].has_reset == false,
            "You've already reset this round please wait until the round is over to reset"
        );
        playerLedger[id[msg.sender]].bet_x = 0;
        playerLedger[id[msg.sender]].bet_value = 0;
        playerLedger[id[msg.sender]].has_bet = false;
        playerLedger[id[msg.sender]].has_results = false;
        playerLedger[id[msg.sender]].has_reset = true;
        players_reset_round += 1;
    }
    

    
    //allows anyone, dealer or player, to view their current balance
    function view_balance() public view returns(uint current_balance){
        if(msg.sender == dealer){
            current_balance = dealer_balance;
        }
        else{
            current_balance = playerLedger[id[msg.sender]].pbalance;
        }
    }
    
    //allows the dealer to choose x and r and then hashes these to c which becomes publically available with the view_c function
    function choose_X_and_R(uint x, uint r) public {
        require(
            msg.sender == dealer, //make sure its the dealers address who's trying to use the function
            "Only the dealer can set x and R"
        );
        require(
            has_choosen_x == false,
            "You've already chosen x you may not cheat and change it"
        );
        require(
            player_count == 8,
            "The game may not begin until all 8 players have joined"
        );
        require(
            players_reset_round == 8,
            "You must wait until all players have reset to start a round"
        );
        require(
            x == 0 || x == 1,
            "X may only be 0 or 1"
        );
        has_choosen_x = true;
        c_global = keccak256(abi.encodePacked(x,r));
        players_reset_round = 0;
    }
    
    //allows anyone to view what the hash of x and r that the dealer selected is
    function view_c() public view returns (bytes32 c){
        require(
            has_choosen_x == true,
            "You may not view c since the dealer hasn't selected x and r yet"
        );
        c = c_global;
    }
    
    //allows the user to bet with x and the ammount they would like to bet. They can only do this if x has not already been revealed, and if they haven't already bet this round.
    function bet(uint x_value, uint bet_amount) public {
        require(
            dealer != msg.sender,
            "The dealer may not bet you must choose x and r instead"
        ); 
        require(
            id[msg.sender] != 0,
            "You have no joined the game you may not bet"
        );
        require(
            playerLedger[id[msg.sender]].has_bet == false,
            "You've already bet this round you may not change it"
        );
        require(
            has_choosen_x == true,
            "You may only bet after the dealer has already chosen x"
        );
        require(
            has_revealed_x == false,
            "You cannot cheat by betting after x is revealed"
        );
        require(
            x_value == 0 || x_value == 1,
            "The x value must be 0 or 1"
        );
        require(
            bet_amount >= 50 && bet_amount <= 500,
            "You must bet between 50 and 500 tokens"
        );
        playerLedger[id[msg.sender]].bet_x = x_value;
        playerLedger[id[msg.sender]].bet_value = bet_amount;
        playerLedger[id[msg.sender]].has_bet = true;
        p_bet += 1;
        
    }
    
    //allows the dealer to reveal x and r that he initially used or cheat and input a new x and r (however he will have to pay each player a fine if he does this)
    function reveal(uint x, uint r) public{
        require(
            msg.sender == dealer, //make sure its the dealers address who's trying to use the function
            "Only the dealer can set x and R"
        );
        require(
            has_choosen_x == true,
            "You must select x and r before you can reveal them"
        );
        require(
            p_bet == 8,
            "Not everyone has bet yet, please be patient"
        );
        x_global = x;
        r_global = r;
        has_revealed_x = true;
        dealer_reset_round = false; //since this is the last function the dealer calls this allows him to reset the game. However, there is still the restriction that all 8 players must have gotten their winnings for the 
        //game to reset so we don't have to worry about the dealer cheating and resetting early.
    }
    
    //allows anyone to view the x and r that the dealer revealed, as well as the new c value that this hashes to. If this c and the c shown in the c_view function are different the user knows the dealer cheated and they
    //will be compenstated depending on the build in fine (250 tokens)
    function view_X_and_R() public view returns (uint x, uint r, bytes32 c){
        require(
            has_revealed_x == true,
            "You may only view x and r once the dealer has revealed them to you"
        );
        x = x_global;
        r = r_global;
        c = keccak256(abi.encodePacked(x,r));
    }
    
    //allows the players to see the results of the bet. Depending on if they won or lost their balance will go up or down 
    function results() public{
        require(
            msg.sender != dealer,
            "The dealer cannot use the results function"
        );
        require(
            has_revealed_x == true,
            "The dealer hasn't revealed x yet"
        );
        require(
            playerLedger[id[msg.sender]].has_results == false,
            "You've already received your winnings"
        );
        require(
            id[msg.sender] != 0,
            "You are not in the game"
        );
        playerLedger[id[msg.sender]].has_results = true;
        if(c_global != keccak256(abi.encodePacked(x_global, r_global))){
            playerLedger[id[msg.sender]].pbalance += 250;
            dealer_balance -= 250;
        }
        else{
            if(playerLedger[id[msg.sender]].bet_x == x_global){
                playerLedger[id[msg.sender]].pbalance += playerLedger[id[msg.sender]].bet_value;
                dealer_balance -= playerLedger[id[msg.sender]].bet_value;
            }
            else{
               playerLedger[id[msg.sender]].pbalance -= playerLedger[id[msg.sender]].bet_value;
                dealer_balance += playerLedger[id[msg.sender]].bet_value; 
            }
        }
        p_viewed_winnings += 1;
        playerLedger[id[msg.sender]].has_reset = false; //allows the player to reset the round since it has now ended.
    }
    
}