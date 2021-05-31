/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

contract JuegoDeUrnaConBolas{
    address payable propietario;
    
    uint bolas_negras;
    uint bola_extraida;
    uint beneficio;
    
    event Partida(string, uint beneficio);
    
    constructor() payable{
        propietario = msg.sender;
    }
    
    function getFondosEther() public view returns(uint fondos) {
        fondos = address(this).balance / (10**18);
        return fondos;
    }
    
    function getFondosWei() public view returns(uint fondos) {
        fondos = address(this).balance;
        return fondos;
    }
    
    
    function juego(uint _bolas_negras) public payable {
        bolas_negras = _bolas_negras;
        require(bolas_negras == 3 || bolas_negras == 5 || bolas_negras == 7 || bolas_negras == 9, "Numero de bolas negras incorrecto: Elige entre 3, 5, 7 o 9 bolas negras");
        require(msg.value >= 0.1 * 10**18, "Coste del juego: 0.1 ether");
        /// @title "GANANCIAS"
        /// "Con 3 bolas negras: 0.125 ether"
        /// "Con 5 bolas negras: 0.25 ether"
        /// "Con 7 bolas negras: 0.35 ether"
        /// "Con 9 bolas negras: 0.45 ether"
        
        if (msg.sender != propietario){  // Si el que juega es el dueño es que quiere introducir fondos al juego (introduce el valor que ha puesto en value al contrato)
            propietario.transfer(msg.value);
        }
        
        
        if(bolas_negras == 3){
            beneficio = 0.125 * 10**18;
        }
        else{
            if(bolas_negras == 5){
                beneficio = 0.25 * 10**18;
            }
            else{
                if(bolas_negras == 7){
                    beneficio = 0.35 * 10**18;
                }
                else{  // bolas_negras == 9
                    beneficio = 0.45 * 10**18;
                }
            }
        }
        
        require(address(this).balance >= beneficio, "No hay fondos suficientes para cubrir una posible perdida con este numero de bolas");
        
        bola_extraida = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % (bolas_negras + 1);
        // Si bola extraida == 0   -->  Es la bola blanca   -->  Ganas
        
        if (bola_extraida == 0){
            msg.sender.transfer(beneficio);
            emit Partida("Enhorabuena! La bola extraida ha sido la blanca. Has ganado: ", beneficio);
        }
        else{
            beneficio = 0;
            emit Partida("Lo siento, la bola extraida ha sido una negra. No has ganado nada :(", beneficio);
        }
    }
}