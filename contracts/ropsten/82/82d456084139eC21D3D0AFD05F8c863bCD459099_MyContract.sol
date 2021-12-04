/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract MyContract  {
    mapping(address => uint8) players;

    function throw_coin(uint8 _predict)public {
        require(_predict == 1 || _predict == 2);
            uint hashBlock = uint(blockhash(block.number - 1));
            uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
            uint hashCoin = uint(keccak256(abi.encode(_predict)));

            uint8 res = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000))) % 2 + 1);

            if(res == _predict){
                players[msg.sender] = 1;
            }
            else{
                players[msg.sender] = 2;
            }
    }

    function result()public view returns(string memory){
        
        if(players[msg.sender] == 1){
            return "You won! :)";
        }
        if(players[msg.sender] == 2){
            return "You lose. :(";
        }
        else{
            return "You didn't play. :|";
        }
    }

    
}