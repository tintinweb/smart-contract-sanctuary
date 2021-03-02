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
    
    //In the game room
    event commitment(bytes32);
    
    function flip_coin(bool x, bytes32 r) public returns(bool){
        require(dealer.adr == msg.sender);
        bytes32 hashed;
        hashed = keccak256(append(x,r));
        emit commitment(hashed);
        return true;
    }
    function append(bool a, bytes32 b) internal pure returns (bytes memory) {
    return abi.encodePacked(a, b);
    }
}