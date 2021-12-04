/**
 *Submitted for verification at Etherscan.io on 2021-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

contract ContractG  {
    
    mapping(address => uint8) players;

    function startGame(uint8 _i) public
    {
        require(_i == 1 || _i == 2);
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        uint hashI = uint(keccak256(abi.encode(_i)));
        uint8 result = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashI % 1000))) % 2 + 1);

        if(result == _i){
            players[msg.sender] = 1;
        }
        else{
            players[msg.sender] = 2;
        }
    }

    function resultGame() public view returns(string memory)
    {
        if (players[msg.sender] == 0){
            return "You didn't play";
        }
        if (players[msg.sender] == 1){
            return "You won";
        }
        if (players[msg.sender] == 2){
            return "You lose";
        }
    }
}