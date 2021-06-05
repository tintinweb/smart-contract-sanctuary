/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity > 0.7.0 < 0.8.0;

contract Tragaperras{
    
    address payable creador;
    
    constructor() payable{
        creador = msg.sender;
    }
    
    bool private ocupado = false;
    
    event Numeros(uint, uint, uint);
    
    function rand1() private view returns(uint){ //Genera un numero aleatorio impredecible
        uint seed = uint(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit +
            ((uint(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
        return (seed - ((seed / 10) * 10));
    }
    
    function rand2() private view returns(uint){ //Genera un numero aleatorio impredecible
        uint seed = uint(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint(keccak256(abi.encodePacked(block.coinbase))) * 7) / (block.timestamp)) +
            block.gaslimit +
            ((uint(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
        
        return (seed - ((seed / 10) * 10));
    }
    
    function rand3() private view returns(uint){ //Genera un numero aleatorio impredecible
        uint seed = uint(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint(keccak256(abi.encodePacked(block.coinbase))) * 9) / (block.timestamp)) +
            block.gaslimit +
            ((uint(keccak256(abi.encodePacked(msg.sender)))) / (block.timestamp)) +
            block.number
        )));
    
    return (seed - ((seed / 10) * 10));
    }
    
    function retirarDinero(uint dinero) public payable {
        if (msg.sender == creador){
            creador.transfer(dinero);
        }
    }
    
    function Partida() public payable {
        
        require(msg.value >= 10000000000000000, "Inserte 0.01 ether");
        require(!ocupado, "Espere a que la tragaperras este libre");
        
        uint random1 = rand1();
        uint random2 = rand2();
        uint random3 = rand3();
        
        uint premio = 0;
        
        if(random1 == random2 && random2 == random3){
            if (random1 == 7){
                premio = 1000000000000000000;
            }
            else{
                premio = 2 * (random1 + 1) * 10000000000000000;
            }
            msg.sender.transfer(premio);
            }
            
        emit Numeros(random1, random2, random3);
        
    }
    
}