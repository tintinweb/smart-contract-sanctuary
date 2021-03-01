/**
 *Submitted for verification at Etherscan.io on 2021-03-01
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
        bool has_results;
    }    
    
    address public dealer;
    uint dealer_balance;
    mapping(address => uint256) public id; 
    uint player_count;
    uint x_global;
    uint r_global;
    bytes32 c_global;
    player[] playerLedger;
    bool has_revealed_x;
    bool has_choosen_x;
    
    constructor(){
        dealer = msg.sender;
        dealer_balance = 4000;
        playerLedger.push();
        player_count = 0;
        has_revealed_x = false;
        has_choosen_x = false;
    }
    
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
    }
    
    function view_balance() public view returns(uint current_balance){
        if(msg.sender == dealer){
            current_balance = dealer_balance;
        }
        else{
            current_balance = playerLedger[id[msg.sender]].pbalance;
        }
    }
    
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
            x == 0 || x == 1,
            "X may only be 0 or 1"
        );
        has_choosen_x = true;
        c_global = keccak256(abi.encodePacked(x,r));
    }
    
    function view_c() public view returns (bytes32 c){
        c = c_global;
    }
    
    function bet(uint x_value, uint bet_amount) public {
        require(
            dealer != msg.sender,
            "You aren't in the game"
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
        
    }
    
    function reveal(uint x, uint r) public{
        require(
            msg.sender == dealer, //make sure its the dealers address who's trying to use the function
            "Only the dealer can set x and R"
        );
        x_global = x;
        r_global = r;
        has_revealed_x = true;
    }
    
    function view_X_and_R() public view returns (uint x, uint r, bytes32 c){
        x = x_global;
        r = r_global;
        c = keccak256(abi.encodePacked(x,r));
        
    }
    
    function results() public returns (bool win_or_lost){
        require(
            msg.sender != dealer,
            "The dealer cannot use the results function"
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
            win_or_lost = true;
        }
        else{
            if(playerLedger[id[msg.sender]].bet_x == x_global){
                playerLedger[id[msg.sender]].pbalance += playerLedger[id[msg.sender]].bet_value;
                dealer_balance -= playerLedger[id[msg.sender]].bet_value;
                win_or_lost = true;
            }
            else{
               playerLedger[id[msg.sender]].pbalance -= playerLedger[id[msg.sender]].bet_value;
                dealer_balance += playerLedger[id[msg.sender]].bet_value; 
                win_or_lost = false;
            }
        }
    }
    
}