/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.7.6 and less than 0.8.0
pragma solidity ^0.7.6;

contract HelloWorld {
    struct player { 
        uint256 balance;
        uint bet_x;
        uint256 bet_value;
        bool bet_status;
        uint Start_Roll;
        uint Current_Roll;
        address adr;
    }
    uint256 num_players=0;
    player[] PP;
    player dealer;
    mapping(address => uint) public balances;
    constructor() {
        dealer.adr = msg.sender;
        dealer.balance = 3000;
    }
    function JoinGameRoom() public returns(bool){
         PP[num_players].adr = msg.sender;
         PP[num_players].balance = 3000;
         num_players+=1;
         return true;
    }
}