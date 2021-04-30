/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

// Es poco seguro.

/*  Casa de apuestas:
    1 - Para desplegado este contrato debes pagar 0.1 ether a los mineros
    2 - Una vez desplegado la persona que quiera concursar debe pagar 0.2 ETH por jugar(entrar en la sala)
        PREMIOS:
        0 dados : 0 ETH
        1 dado  : 0.1 ETH
        2 dados : 0.2 ETH
    (max. 1 persona)
*/


contract AdivinaNumero {
    address private jugador;        // Direccion del jugador.
    uint premio;                    
    uint dice1;                     // Numero de cada dado.
    uint dice2;

    uint private constant costoJuego = 2000000000000000;        // Pagar 0.2 ETH
    address payable owner;          // Dueño del contrato
    uint balance;

//    event Numero(string, uint dado1, string, uint dado2, string, uint premio); 
        
    // event: Almacena los argumentos recibidos en los registros de transacciones
    // que se almacenan dentro de la blockchain.
    // Para acceder: Utilizando direccion del contrato cuando este presente en la blockchain. (nos servira para ver su estado)

    // Para conseguir que el contrato se despliegue rapidamente por la red ethereum ofrecemos 0'1 Ether a los mineros   --> NO ENTIENDO
    
    // Costructor
     constructor(){
        owner = msg.sender;
        balance = 0;
    }

    function deposit() public payable {
        if (msg.sender == owner) {
            balance += msg.value;
        }
    }
    
    function withdraw(uint quantity) public payable {
        if (msg.sender == owner && quantity <= balance) {
            balance -= quantity;
            owner.transfer(quantity);
        }
    }
        
    function adivina(uint dice1Adivina, uint dice2Adivina) public payable {          // Del 1 al 6
        // Tipo payable: Si lo adivina podra cobrar.
        address payable player = msg.sender;
        // Si quieres jugar paga esto y que no haya nadie jugando.
        require(msg.value == 2000000000000000, "El costo del juego es de 0.2 Ether.");
     
        require(dice1Adivina >= 1, "Numero introducido incorrecto.");               
        require(dice2Adivina >= 1, "Numero introducido incorrecto.");               
        require(dice1Adivina <= 6, "Numero introducido incorrecto.");               
        require(dice2Adivina <= 6, "Numero introducido incorrecto.");               

        balance += msg.value;

        dice1 = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 6 + 1;     // Numero dado 1
        dice2 = uint(keccak256(abi.encodePacked(block.timestamp + 1, msg.sender))) % 6 + 1;     // Numero dado 2

        if (( dice1Adivina == dice1 && dice2Adivina == dice2 ) || ( dice1Adivina == dice2 && dice2Adivina == dice1 )){
            premio = 220000000000000;
            balance -= premio;
            player.transfer(premio);
        }
        else if(dice1Adivina == dice1 || dice1Adivina == dice2 || dice2Adivina == dice1 || dice2Adivina == dice2){
            premio = 50000000000000;    // premio es un Ether.
            balance -= premio;
            player.transfer(premio);

        }
        else{
            jugador = msg.sender;       
            premio = 0; 
        }
            

//        emit Numero("El numero generado fue: ",dice1, ", ", dice2, "Ganaste: ", premio);     // Verificar el estado de este contrato.

    }

    // Desplegar el contrato.
    // Red de prueba de Ropsten, usamos metamask(cryptowallet con todas las cuentas)
}