/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract CoinGame{
    mapping(address => uint8)players;

    function coinFlip (uint _coin)public{
        require(_coin == 1 || _coin == 2);
        uint  hashBlock = uint(blockhash(block.number));
        uint  hashAdr   = uint(keccak256(abi.encode(msg.sender)));
        uint  hashCoin  = uint(keccak256(abi.encode(_coin)));
        uint8 result   =  uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000)))% 2 + 1);

        if(result == _coin){
            players[msg.sender] = 1;
        }
        else{
            players[msg.sender] = 2;
        }
    }

    function gameResult()public view returns(string memory){
        if(players[msg.sender] == 0){
            return "You didn't play";
        }
        if(players[msg.sender] == 1){
            return "You won ";
        }
        if(players[msg.sender] == 2){
            return "You lost";
        }
    }
}