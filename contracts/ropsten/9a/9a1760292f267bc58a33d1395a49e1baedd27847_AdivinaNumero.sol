/**
 *Submitted for verification at Etherscan.io on 2021-05-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Es poco seguro.

/*  Casa de apuestas:
    1 - Para desplegado este contrato debes pagar 0.1 ether a los mineros
    2 - Una vez desplegado la persona que quiera concursar debe pagar 0.2 ETH por jugar(entrar en la sala)
        PREMIOS:
        0 dados : 0 ETH
        1 dado  : 0.5 ETH
        2 dados : 2.2 ETH
    (max. 1 persona)
*/


contract AdivinaNumero {
    address private jugador;        // Direccion del jugador.
    uint premio;
    uint dice1;                     // Numero de cada dado.
    uint dice2;

    address public owner;          // Dueño del contrato
    uint balance;

    // event: Almacena los argumentos recibidos en los registros de transacciones
    // que se almacenan dentro de la blockchain.
    // Para acceder: Utilizando direccion del contrato cuando este presente en la blockchain. (nos servira para ver su estado)

    // Para conseguir que el contrato se despliegue rapidamente por la red ethereum ofrecemos 0'1 Ether a los mineros   --> NO ENTIENDO

    // Costructor
     constructor(){
        owner = msg.sender;
        balance = 0;
    }

    event Deposit(string, uint balance);


    function getDeposit() public{
        if (msg.sender == owner){
            emit Deposit("Fondo actual: ", balance);
        }
    }

    function deposit() public payable {
        if (msg.sender == owner) {
            balance += msg.value;
        }
    }

    function withdraw(uint quantity) public payable {
        if (msg.sender == owner && quantity <= balance) {
            address payable newOwner;
            balance -= quantity;
            newOwner = payable(owner);
            newOwner.transfer(quantity);
        }
    }
    
    event Plot(string, uint dado1, string, uint dado2, string, uint premio);

    function adivina(uint dice1Adivina, uint dice2Adivina) public payable {          

        address player_np = msg.sender;
       
        require(msg.value >= 200000000000000000, "El costo del juego es de 0.2 Ether.");

        require(dice1Adivina >= 1, "Numero introducido incorrecto.");
        require(dice2Adivina >= 1, "Numero introducido incorrecto.");
        require(dice1Adivina <= 6, "Numero introducido incorrecto.");
        require(dice2Adivina <= 6, "Numero introducido incorrecto.");

        balance += msg.value;

        dice1 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 6 + 1; 
        dice2 = uint(keccak256(abi.encodePacked(block.timestamp + 1, msg.sender))) % 6 + 1;
        
        address payable player = payable(player_np);

        if (( dice1Adivina == dice1 && dice2Adivina == dice2 ) || ( dice1Adivina == dice2 && dice2Adivina == dice1 )){
            premio = 2200000000000000000;
            balance -= premio;
            player.transfer(premio);
        }
        else if(dice1Adivina == dice1 || dice1Adivina == dice2 || dice2Adivina == dice1 || dice2Adivina == dice2){
            premio = 500000000000000000;    
            balance -= premio;
            player.transfer(premio);

        }
        else{
            jugador = msg.sender;
            premio = 0;
        }
        
        emit Plot("Dado 1: ", dice1, "\nDado2: ", dice2, "\nPremio: ", premio);

    }
}