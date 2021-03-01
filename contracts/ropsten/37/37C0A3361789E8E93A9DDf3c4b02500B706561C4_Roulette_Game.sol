/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract Roulette_Game {
    
    struct player {
        uint balances;
        uint x_bet;
        uint bet_value;
        bool results_shown;
    }
    
    address public dealer;
    uint dealer_balance;
    mapping(address => uint) public id_player;
    uint players_count = 0;
    uint x_global;
    uint r_global;
    bytes32 c_global;
    player[] playerLedger;
    
    constructor(){
        dealer = msg.sender;
        dealer_balance = 5000;
        playerLedger.push();
        players_count = 0;
    }
    
    // Lets players join game and creates a player ledger
    function join_game() public {
        require(
            msg.sender != dealer,
            "You are already in the game"
        );
        require(
            id_player[msg.sender] == 0,
            "You are already in the game"
        );
        require(
            players_count < 8,
            "Too many players"
        );
        players_count += 1;
        id_player[msg.sender] = players_count;
        playerLedger.push();
        playerLedger[id_player[msg.sender]].balances = 500;
        playerLedger[id_player[msg.sender]].results_shown = false;
    }
    
    // Shows the current balances of players or the dealer
    function see_balances() public view returns(uint balance_current) {
        if (msg.sender == dealer) {
            balance_current = dealer_balance;
        }
        else {
            balance_current = playerLedger[id_player[msg.sender]].balances;
        }
    }
    
    // Dealer picks an x and an r value
    function pick_x_and_r(uint x_val, uint r_val) public {
        require(
            msg.sender == dealer,
            "The dealer is the only one who can set x and r"
            );
        require(
            x_val == 0 || x_val == 1, 
            "x can only be 0 or 1"
            );
            
         c_global = keccak256(abi.encodePacked(x_val,r_val));
    }
    
    // Reveals the value of c to players
   function reveal_c() public view returns (bytes32 c) {
       c = c_global;
    }
    
    // Stores the bets of each player
    function bet(uint bet_x, uint val_of_bet) public {
        require(
            dealer != msg.sender,
            "The dealer is not in the game"
        );
        require(
            bet_x == 0 || bet_x == 1,
            "Value of x must be 0 or 1"
        );
        require(
            val_of_bet >= 5 && val_of_bet <= 500,
            "Bet must be between 5 and 500"
        );
        playerLedger[id_player[msg.sender]].x_bet = bet_x;
        playerLedger[id_player[msg.sender]].bet_value = val_of_bet;
    }
    
    // Stores the values of x and r to be revealed in show_x_and_r
    // Prevents dealer from lying about selected x and r values since the value of c won't be the same if x and r are not the same as the values selected in pick_x_and_r
    function reveal_x_and_r(uint x, uint r) public {
        require(
            msg.sender == dealer,
            "The dealer is the only one who can set x and r"
        );
        x_global = x;
        r_global = r;
    }
    
    // Shows the players the values of x and r as selected by the dealer
    function show_x_and_r() public view returns (uint x_val, uint r_val, bytes32 c_val) {
        x_val = x_global;
        r_val = r_global;
        c_val = keccak256(abi.encodePacked(x_val,r_val));
    }
    
    // Calculates the result of the bet for the selected player
    function results() public returns(bool did_win) {
        require(
            dealer != msg.sender,
            "Dealer should not use this function"
        );
        require(
            playerLedger[id_player[msg.sender]].results_shown == false,
            "You have already seen the results"
        );
        playerLedger[id_player[msg.sender]].results_shown = true;
        if (c_global != keccak256(abi.encodePacked(x_global, r_global))) {
            playerLedger[id_player[msg.sender]].balances += 250;
            dealer_balance -= 250;
            did_win = true;
        }
        else {
            if (playerLedger[id_player[msg.sender]].x_bet == x_global) {
                playerLedger[id_player[msg.sender]].balances += playerLedger[id_player[msg.sender]].bet_value;
                dealer_balance -= playerLedger[id_player[msg.sender]].bet_value;
                did_win = true;
            }
            else {
                playerLedger[id_player[msg.sender]].balances -= playerLedger[id_player[msg.sender]].bet_value;
                dealer_balance += playerLedger[id_player[msg.sender]].bet_value;
                did_win = false;
            }
        }
    }
    
}