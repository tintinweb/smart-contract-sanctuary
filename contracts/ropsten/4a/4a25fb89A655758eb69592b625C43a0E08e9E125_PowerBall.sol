/**
 *Submitted for verification at Etherscan.io on 2021-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity>=0.7.0 <0.8.0;

contract PowerBall {
    
    uint apuesta_requerida;         // Apuesta requerida para participar 
    uint jackpot;                   // Premio si se gana y se va acumulando
    struct Cuenta {                 // Una estructura cuenta para gestionar el contrato
        uint fondos;               // Eth actual del contrato
        address payable des_dir;   // Direccion cuenta creador del contrato
    }
    Cuenta cuenta;
    
    struct Power_nums {
        uint b1_num1;
        uint b1_num2;
        uint b1_num3;
        uint b1_num4;
        uint b1_num5;
        uint b1_num6;
        uint b1_num7;
        uint b2_num;
    }
    Power_nums power_nums;
    
    struct Jugador_nums {
        uint b1_num1;
        uint b1_num2;
        uint b1_num3;
        uint b1_num4;
        uint b1_num5;
        uint b1_num6;
        uint b1_num7;
        uint b2_num;
    }
    Jugador_nums pj_nums;

    constructor() {                 // Damos un valor inicial a las variables.
        apuesta_requerida = 8*10**12;         // 8 szabo
        jackpot = 1*10**18;         // 1 Ether
        cuenta.fondos = 0;          // Inicialmente el contrato no tiene fondos
        cuenta.des_dir = msg.sender;    // Guardamos la direccion del creador
    }
    
    // Para generar los numeros pseudoaleatorios del contrato usaremos block.difficulty
    
    function powerball_num_alea_barril_1 (uint semilla) private returns(uint) {     // Generar numeros pseudoaleatorios
        uint num = uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, semilla)));
        return num % 35 + 1;
    }
    
    function powerball_num_alea_barril_2 (uint semilla) private returns(uint) {     // Generar numeros pseudoaleatorios
        uint num = uint(keccak256(abi.encodePacked(block.difficulty, msg.sender, semilla)));
        return num % 20 + 1;
    }
    
    // Apuesta quick_pick. Se escogen de forma aleatoria 7 numeros del primer barril y 1 numero del segundo barrill
    // Si coincide con los numeros generados se gana el jackpot, sino, el jugador pierde y 
    // se acumula 1 szabo al jackpot.
    
    function quick_pick() payable public {
        require(cuenta.fondos >= jackpot, 'El contrato no tiene fondos suficientes');
        require(msg.value == apuesta_requerida, 'Apuesta incorrecta, la apuesta permitida son 8 szabo');
        // Numeros generados para el jugador
        pj_nums.b1_num1 = powerball_num_alea_barril_1(1);
        pj_nums.b1_num2 = powerball_num_alea_barril_1(2);
        pj_nums.b1_num3 = powerball_num_alea_barril_1(3);
        pj_nums.b1_num4 = powerball_num_alea_barril_1(4);
        pj_nums.b1_num5 = powerball_num_alea_barril_1(5);
        pj_nums.b1_num6 = powerball_num_alea_barril_1(6);
        pj_nums.b1_num7 = powerball_num_alea_barril_1(7);
        pj_nums.b2_num = powerball_num_alea_barril_2(1);
        // Numeros generados para el contrato
        power_nums.b1_num1 = powerball_num_alea_barril_1(1000001);
        power_nums.b1_num2 = powerball_num_alea_barril_1(1000002);
        power_nums.b1_num3 = powerball_num_alea_barril_1(1000003);
        power_nums.b1_num4 = powerball_num_alea_barril_1(1000004);
        power_nums.b1_num5 = powerball_num_alea_barril_1(1000005);
        power_nums.b1_num6 = powerball_num_alea_barril_1(1000006);
        power_nums.b1_num7 = powerball_num_alea_barril_1(1000007);
        power_nums.b2_num = powerball_num_alea_barril_2(1000001);
        // Comprobacion de la apuesta
        if (pj_nums.b1_num1 == power_nums.b1_num1 && pj_nums.b1_num2 == power_nums.b1_num2 && 
            pj_nums.b1_num3 == power_nums.b1_num3 && pj_nums.b1_num4 == power_nums.b1_num4 &&
            pj_nums.b1_num5 == power_nums.b1_num5 && pj_nums.b1_num6 == power_nums.b1_num6 &&
            pj_nums.b1_num7 == power_nums.b1_num7 && pj_nums.b2_num == power_nums.b2_num){
            // jugador gana
            msg.sender.transfer(jackpot);
            cuenta.fondos -= jackpot;
        } else {
            // jugador pierde
            cuenta.fondos += apuesta_requerida;
            jackpot += 1*10**12; // Se suma al jackpot 1 szabo
        }
    }
    // Apuesta standart_pick. El jugador escoge 7 numeros del primer barril y 1 numero del segundo barrill
    // Si coincide con los numeros generados se gana el jackpot, sino, el jugador pierde y 
    // se acumula 1 szabo al jackpot.
    
    function standart_pick(uint num1, uint num2, uint num3, uint num4, uint num5, uint num6, uint num7, uint num8) payable public {
        require(cuenta.fondos >= jackpot, 'El contrato no tiene fondos suficientes');
        require(msg.value == apuesta_requerida, 'Apuesta incorrecta, la apuesta permitida son 8 szabo');
        require(1 <= num1 && num1 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num2 && num2 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num3 && num3 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num4 && num4 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num5 && num5 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num6 && num6 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num7 && num7 <= 35, 'Error, el numero escogido del barril uno debe estar entre 1 y 35 incluidos');
        require(1 <= num8 && num8 <= 20, 'Error, el numero escogido del barril dos debe estar entre 1 y 20 incluidos');
        // Numeros escogidos por el jugador
        pj_nums.b1_num1 = num1;
        pj_nums.b1_num2 = num2;
        pj_nums.b1_num3 = num3;
        pj_nums.b1_num4 = num4;
        pj_nums.b1_num5 = num5;
        pj_nums.b1_num6 = num6;
        pj_nums.b1_num7 = num7;
        pj_nums.b2_num = num8;
        // Numeros generados para el contrato
        power_nums.b1_num1 = powerball_num_alea_barril_1(1000001);
        power_nums.b1_num2 = powerball_num_alea_barril_1(1000002);
        power_nums.b1_num3 = powerball_num_alea_barril_1(1000003);
        power_nums.b1_num4 = powerball_num_alea_barril_1(1000004);
        power_nums.b1_num5 = powerball_num_alea_barril_1(1000005);
        power_nums.b1_num6 = powerball_num_alea_barril_1(1000006);
        power_nums.b1_num7 = powerball_num_alea_barril_1(1000007);
        power_nums.b2_num = powerball_num_alea_barril_2(1000001);
        // Comprobacion de la apuesta
        if (pj_nums.b1_num1 == power_nums.b1_num1 && pj_nums.b1_num2 == power_nums.b1_num2 && 
            pj_nums.b1_num3 == power_nums.b1_num3 && pj_nums.b1_num4 == power_nums.b1_num4 &&
            pj_nums.b1_num5 == power_nums.b1_num5 && pj_nums.b1_num6 == power_nums.b1_num6 &&
            pj_nums.b1_num7 == power_nums.b1_num7 && pj_nums.b2_num == power_nums.b2_num){
            // jugador gana
            msg.sender.transfer(jackpot);
            cuenta.fondos -= jackpot;
        } else {
            // jugador pierde
            cuenta.fondos += apuesta_requerida;
            jackpot += 1*10**12; // Se suma al jackpot 1 szabo
        }
    }
    
    function retirar_fondos(uint fondos) public payable {   // Permite retirar fondos al creador del contrato
        if (cuenta.des_dir == msg.sender) { // Solo el creador del contrato puede retirar fondos
            if (fondos <= cuenta.fondos){   // Comprobamos que tenemos mas fondos de los que queremos retirar
                cuenta.des_dir.transfer(fondos);    // Transferimos fondos a la cuenta del creador
                cuenta.fondos -= fondos;         // Restamos los fondos retirados para cuadrar el balance
            }
        }
    }
    
    function depositar_fondos() public payable {        // Permite depositar fondos en el contrato
        cuenta.fondos += msg.value;
    }
    
}