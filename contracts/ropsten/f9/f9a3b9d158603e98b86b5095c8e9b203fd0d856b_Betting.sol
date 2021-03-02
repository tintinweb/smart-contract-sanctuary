/**
 *Submitted for verification at Etherscan.io on 2021-03-02
*/

// SPDX-License-Identifier: MIT
// compiler version must be greater than or equal to 0.7.6 and less than 0.8.0
pragma solidity ^0.7.6;

contract Betting {
    struct player { 
        uint balance;
        bool bet_x;
        uint bet_value;
        bool bet_status;
        uint Start_Roll;
        uint Current_Roll;
        address adr;
    }
    uint256 num_players=0;
    player[] PP;
    player dealer;
    bytes32 hashed;
    constructor() {
        dealer.adr = msg.sender;
        dealer.balance = 3000;
    }
    function JoinGameRoom() public returns(bool){
        require (num_players<8);
         PP[num_players].adr = msg.sender;
         PP[num_players].balance = 3000;
         num_players+=1;
         return true;
    }
    
    //In the game room
    event commitment(bytes32);
    
    function compute_hashed(bool x, bytes32 r) public returns(bytes32){
        require(dealer.adr == msg.sender);
        hashed = keccak256(append(x,r));
        emit commitment(hashed);
        return hashed;
    }
    function append(bool a, bytes32 b) internal pure returns (bytes memory) {
    return abi.encodePacked(a, b);
    }
    function bet (bool x, uint v) public returns(bool){
        require(v>=5 && v<=500);
        uint j=0;
        while (PP[j].adr != msg.sender && j < num_players){
            j++;
        }
        if (v<= PP[j].balance){
        PP[j].bet_x =x;
        PP[j].bet_value = v;
        }
        else {
            PP[j].bet_value = PP[j].balance;
        }
        for (j = 0; j < num_players; j++){
            PP[j].balance -= PP[j].bet_value;
            dealer.balance += PP[j].bet_value;
        }
        return true;
    }
    function dealer_reveal (bool x, bytes32 r) public returns(bool){
        uint j;
        if(keccak256(append(x,r))!=hashed){
            for (j = 0; j < num_players; j++){
            PP[j].balance += PP[j].bet_value;
            dealer.balance -= PP[j].bet_value;
            }
            dealer.balance -= 200;
        }
        else{
            for (j = 0; j < num_players; j++){
            if (PP[j].bet_x == x){
                PP[j].balance += 2*PP[j].bet_value;
                dealer.balance -= 2*PP[j].bet_value;
            }
            }
        }
        return true;
    }
}