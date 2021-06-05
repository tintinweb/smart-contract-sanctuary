/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.4;

contract Roulette{
    address payable boss;
    
    uint nPlayer;
    uint nRoulette;
    uint prize;
    
    event Game(string, uint, string, uint, string, uint);
    event increaseBalance(string, uint);
    
    constructor() payable{
        boss = msg.sender;
    }
    
    function getBalance() public view returns(uint fondos) {
        return address(this).balance;
    }
    
    function juego(uint _nPlayer) public payable {
        if (msg.sender == boss){
            emit increaseBalance("Agregamos fondos: ", msg.value);
        }
        else{
            nPlayer = _nPlayer;
            require(nPlayer < 37, "Numero incorrecto, este debe ser menor de 37");
            require(msg.value >= 50000000000000000, "Coste de minimo de juego: 0.05 ether");
            
            boss.transfer(msg.value);
            
            prize = 200000000000000000;  // 0.2 ether
            require(address(this).balance >= prize, "No esta disponible el juego por falta de fondos");
            
            nRoulette = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 37;
    
            if (nPlayer == nRoulette){
                msg.sender.transfer(prize);
                emit Game("Tu numero: ", nPlayer, "Ha salido: ", nRoulette, "Has ganado: ", prize);
            }
            else{
                emit Game("Tu numero: ", nPlayer, "Ha salido: ", nRoulette, "Has ganado: ", 0);
            }
            
        }
    }
}