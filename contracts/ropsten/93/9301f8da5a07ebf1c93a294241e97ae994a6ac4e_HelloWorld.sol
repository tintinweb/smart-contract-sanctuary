/**
 *Submitted for verification at Etherscan.io on 2021-03-01
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.7.6 and less than 0.8.0
pragma solidity ^0.7.6;

contract HelloWorld {
    struct player { 
        int256 balance;
        string bet_x;
        int256 bet_value;
        bool bet_status;
        string Start_Roll;
        string Current_Roll;
    }
    uint256 num_players;
    address[8] adr;
    constructor() {
        num_players=0;
    }
   
   function Join_GameRoom(bool join_or_not) public returns(string memory) {
       if (num_players < 9 && join_or_not) {
            adr[num_players] = msg.sender;
            num_players+=1;
            string memory respond;
            respond = "y";
            return respond;
       }
   }
}