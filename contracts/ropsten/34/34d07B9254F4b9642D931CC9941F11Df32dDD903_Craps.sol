/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// Documentacion
// Se trata del juego de craps, el juego original se puede requerir infinitas tiradas para finalizar el juego
// como tenemso que tener en cuenta el coste computacional se limitara a 10 tiradas.
// Como funciona el juego
// Si en la primera tirada de dados la suma de los dados es:
//      - gana jugador --> 7 o 11
//      - pierde jugador --> 2, 3 o 12
//      - empate -> 1, 4, 5, 6, 8, 9, 10
// En tiradas posteriores la suma de los dados:
//      - gana jugador --> que la suma de los dados sea la misma que la que saco en la primera tirada
//      - pierde jugador --> 7
// Ganar se paga 2 a 1.
// La apuesta minimo es de 1 finney y la maxima es 20 finney.
// Hay solo un tipos de apuesta con el siguiente formato (el output tiene el mismo formato que el input):
//   - tirar_dados
//      - input: no se requiere
//      - output: {string que muestra si ganas o pierdes, suma de dados generada}
// 
// Para comprobar los fondos del casino se puede usar la funcion casino_balance.
// 
// Desarrollador
// El desarrollador es que el puede utilizar las siguientes funciones 
//   - casino_depositar. Permite depositar ether en el balance del casino, en caso de que alguien que no sea el 
//                       desarrollador se le devolvera automaticamente.
//   - casino_retirar. Permite retirar ether del balance del casino, en caso de que alguien que no sea el 
//                     desarrollador no se le permitira.
//   - destruir_contrato. Permite eliminar el contrato y devuelve los fondos del casino al desarrollador, en caso de 
//                        que alguien que no sea el desarrollador no se le permitira.
// 
//
// Se recomientda al desarrollador que los fondos de casino sean al menos 800 finney que es el calculo de 
// multiplicar la apuesta maxima por el pago maximo por 20. El 20 representa el numero de veces
// que el casino debe perder seguidos para quedarse sin fondos. El 20 es un numero orientativo. Esta programado
// que para poder apostar los fondos del casino deben ser al menos la mitad de los fondos recomendados.
 


// SPDX-License-Identifier: MIT

pragma solidity>=0.7.0 <0.8.0;

contract Craps {
    
    // Variables globales
    uint priv_seed;
    struct Casino {
        address payable addr_dev;   // cuenta desarrollador
        uint balance;
        uint deposito_recomendado;
        uint apuesta_min;
        uint apuesta_max;
    }
    Casino casino;

    // Constructor, inicia el casino
    constructor() {
        priv_seed = 1;
        casino.addr_dev = msg.sender;
        casino.balance = 0;
        casino.apuesta_min = 1*10**15; // 1 finney aprox. 2.3 $ (21.04.21)
        casino.apuesta_max = 20*10**15; // 25 finney aprox. 46 $ (21.04.21)
        // deposito_recomendado = maximo_multiplicador * lim_estadistico * apuesta_max  = 0.8 ether
        casino.deposito_recomendado = 2 * 20 * casino.apuesta_max;
    }
    
    // Permite ver los fondos del cliente en el casino
    function casino_balance() public view returns(uint){
        return casino.balance;
    }
    
    // Permite al cliente despositar fondos en el casino
    function casino_depositar() public payable {
        if (msg.sender == casino.addr_dev){
            casino.balance += msg.value;
        } else {
            msg.sender.transfer(msg.value);
        }
    }
    
    // Permite al cliente retirar fondos del casino
    function casino_retirar(uint cantidad) public payable {
        if (msg.sender == casino.addr_dev && cantidad <= casino.balance) {
            casino.balance -= cantidad;
            casino.addr_dev.transfer(cantidad);
        }
    }
    
    // Destruye el contrato y recupera los fondos de la cuenta en el contrato
    function destruir_contracto() public{
        if (msg.sender == casino.addr_dev) {
            selfdestruct(casino.addr_dev);
        }
    }
    
    // Generar numero pseudoaleatorio
    function genera_num(uint seed) private returns(uint) {
        // uint hash_aleatorio = uint(keccak256(block.difficulty, block.timestamp));
        uint start_seed = 1;
        seed = seed + uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, start_seed)));
        uint num_aleatorio = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed)));
        return num_aleatorio % 5 + 1;
    }
    
    // Apostar en numero
    function tirar_dados() payable public returns(string memory, uint){
        address payable addr_jugador = msg.sender; 
        uint apuesta_jugador = msg.value;
        // Se requiere que el deposito en el casino sea al menos la mitad del recomendado
        require(2 * casino.balance >= casino.deposito_recomendado, 'Error, por favor intentelo mas tarde');
        require(casino.addr_dev != addr_jugador, 'Error, cuenta incorrecta');
        require(apuesta_jugador >= casino.apuesta_min, 'Error, por favor apuesta inferior a la minima aceptada');
        require(apuesta_jugador <= casino.apuesta_max, 'Error, por favor apuesta superior a la maxima aceptada');
        
        uint dado1 = genera_num(priv_seed);
        uint dado2 = genera_num(priv_seed);
        uint suma_dados = dado1 + dado2;
        uint suma_primera_tirada = suma_dados;
        bool ganador; 
        uint8 tiradas = 10;
        
        while (tiradas > 0) {
            if (tiradas == 10) {                                    // primera tirada
                if (suma_dados == 7 || suma_dados == 11) {
                    ganador = true;
                    break;
                }
                if (suma_dados == 2 || suma_dados == 3 || suma_dados == 12) {
                    ganador = false;
                    break;
                }
            } else {                                                // tiradas posteriores
                dado1 = genera_num(priv_seed); 
                dado2 = genera_num(priv_seed);
                suma_dados = dado1 + dado2;
                
                if (suma_dados == suma_primera_tirada) {
                    ganador = true;
                    break;
                }
                if (suma_dados == 7) {
                    ganador = false;
                    break;
                }
            }
            tiradas--;
        }
        
        if (tiradas == 0) {                                             // empate
            addr_jugador.transfer(apuesta_jugador);
            return ('Ha sido empate', suma_dados);
        }
        
        if (ganador == true) {                                          // ganar
            uint cantidad_ganada = apuesta_jugador * 2;
            casino.balance -= (cantidad_ganada - apuesta_jugador);
            addr_jugador.transfer(cantidad_ganada);
            return ('Enhorabuena, has ganado', suma_dados);
        } else {                                                        // perder
            casino.balance += apuesta_jugador;
            return ('Lo siento has perdido', suma_dados);
        }
    }
}