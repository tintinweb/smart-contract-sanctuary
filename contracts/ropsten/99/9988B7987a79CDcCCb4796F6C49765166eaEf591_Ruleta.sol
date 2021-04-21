/**
 *Submitted for verification at Etherscan.io on 2021-04-21
*/

// Documentacion
// Se trata del juego de la ruleta europea (un solo 0 y 1 al 36 numeros)
// La apuesta minimo es de 0.5 finney y la maxima es 1 finney
// Hay 5 tipos de apuestas distintas con el siguiente formato (el output tiene el mismo formato que el input):
//   - apostar_en_numero
//      - input: entero (0, ... ,36)
//      - output: {string que muestra si ganas o pierdes, numero elegido, numero generado en la ruleta}
//      - se paga la apuesta 36 a 1
//   - apostar_en_color 
//      - input: 0 para rojo y 1 para negro
//      - output: {string que muestra si ganas o pierdes, color elegido, color generado en la ruleta}
//      - se paga la apuesta 2 a 1
//   - apostar_en_par_impar 
//      - input: 0 para par y 1 para impar
//      - output: {string que muestra si ganas o pierdes, paridad elegida, paridad generada en la ruleta}
//      - se paga la apuesta 2 a 1
//   - apostar_en_bajo_alto 
//      - input: 0 para bajo y 1 para alto
//      - output: {string que muestra si ganas o pierdes, elegido, generado en la ruleta}
//      - se paga la apuesta 2 a 1
//   - apostar_en_docena. 
//      - input: 0 para primera docena, 1 para segunda docena y 2 para tercera docena
//      - output: {string que muestra si ganas o pierdes, docena elegida, docena generado en la ruleta}
//      - se paga la apuesta 3 a 1
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
// Se recomientda al desarrollador que los fondos de casino sean al menos 720 finney que es el calculo de 
// multiplicar la apuesta maxima por el pago maximo (hacertar numero) por 20. El 20 representa el numero de veces
// que el casino debe perder seguidos para quedarse sin fondos. El 20 es un numero orientativo. Esta programado
// que para poder apostar los fondos del casino deben ser al menos la mitad de los fondos recomendados.
 


// SPDX-License-Identifier: MIT

pragma solidity>=0.7.0 <0.8.0;

contract Ruleta {
    
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
        casino.apuesta_min = 0.5*10**15; // 0.5 finney aprox. 1.15 $ (21.04.21)
        casino.apuesta_max = 1*10**15; // 1 finney aprox. 2.3 $ (21.04.21)
        // deposito_recomendado = maximo_multiplicador * lim_estadistico * apuesta_max  = 0.72 ether
        casino.deposito_recomendado = 36 * 20 * casino.apuesta_max;
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
        return num_aleatorio % 37;
    }

    // Apostar en numero
    function apostar_en_numero(uint numero) payable public returns(string memory, uint, uint){
        address payable addr_jugador = msg.sender; 
        uint apuesta_jugador = msg.value;
        // Se requiere que el deposito en el casino sea al menos la mitad del recomendado
        require(2 * casino.balance >= casino.deposito_recomendado, 'Error, por favor intentelo mas tarde');
        require(casino.addr_dev != addr_jugador, 'Error, cuenta incorrecta');
        require(apuesta_jugador >= casino.apuesta_min, 'Error, por favor apuesta inferior a la minima aceptada');
        require(apuesta_jugador <= casino.apuesta_max, 'Error, por favor apuesta superior a la maxima aceptada');
        require(numero >= 0 || numero <= 36, 'Error, por favor elige un numero entre 0 y 36');
        
        uint num_ruleta = genera_num(priv_seed);
        if (numero == num_ruleta) {
            uint cantidad_ganada = apuesta_jugador * 36;
            casino.balance -= (cantidad_ganada - apuesta_jugador);
            addr_jugador.transfer(cantidad_ganada);
            return ('Enhorabuena, has ganado', numero, num_ruleta);
        } else {
            casino.balance += apuesta_jugador;
            return ('Lo siento has perdido', numero, num_ruleta);
        }
    }
    
    // Apostar en color
    function apostar_en_color(uint color) payable public returns(string memory, uint, uint){
        address payable addr_jugador = msg.sender; 
        uint apuesta_jugador = msg.value;
        // Se requiere que el deposito en el casino sea al menos la mitad del recomendado
        require(2 * casino.balance >= casino.deposito_recomendado, 'Error, por favor intentelo mas tarde');
        require(casino.addr_dev != addr_jugador, 'Error, cuenta incorrecta');
        require(apuesta_jugador >= casino.apuesta_min, 'Error, por favor apuesta inferior a la minima aceptada');
        require(apuesta_jugador <= casino.apuesta_max, 'Error, por favor apuesta superior a la maxima aceptada');
        require(color == 0 || color == 1, 'Error, por favor elige 0 para rojo y 1 para negro');
        
        uint num_ruleta = genera_num(priv_seed);
        uint color_ruleta; // 0 = rojo , 1 = negro
        uint8[18] memory color_rojo = [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36];
        
        for (uint i = 0; i <= color_rojo.length; i++) {
            if (num_ruleta == color_rojo[i]) {
                color_ruleta = 0; // rojo
                break;
            }
            color_ruleta = 1;   // negro
        }
        
        if (num_ruleta == 0 || color != color_ruleta) {
            casino.balance += apuesta_jugador;
            return ('Lo siento has perdido', color, color_ruleta);
        } else {
            uint cantidad_ganada = apuesta_jugador * 2;
            casino.balance -= apuesta_jugador;
            addr_jugador.transfer(cantidad_ganada);
            return ('Enhorabuena, has ganado', color, color_ruleta);
        }
    }
    
    // Apostar en par o impar
    function apostar_en_par_impar(uint impar) payable public returns(string memory, uint, uint){
        address payable addr_jugador = msg.sender; 
        uint apuesta_jugador = msg.value;
        // Se requiere que el deposito en el casino sea al menos la mitad del recomendado
        require(2 * casino.balance >= casino.deposito_recomendado, 'Error, por favor intentelo mas tarde');
        require(casino.addr_dev != addr_jugador, 'Error, cuenta incorrecta');
        require(apuesta_jugador >= casino.apuesta_min, 'Error, por favor apuesta inferior a la minima aceptada');
        require(apuesta_jugador <= casino.apuesta_max, 'Error, por favor apuesta superior a la maxima aceptada');
        require(impar == 0 || impar == 1, 'Error, por favor elige 0 para par y 1 para impar');
        
        uint num_ruleta = genera_num(priv_seed);
        uint impar_ruleta; // 0 = par , 1 = impar
        
        if (num_ruleta % 2 == 0) {
            impar_ruleta = 0;
        } else {
            impar_ruleta = 1;
        }
        
        if (num_ruleta == 0 || impar != impar_ruleta) {
            casino.balance += apuesta_jugador;
            return ('Lo siento has perdido', impar, impar_ruleta);
        } else {
            uint cantidad_ganada = apuesta_jugador * 2;
            casino.balance -= apuesta_jugador;
            addr_jugador.transfer(cantidad_ganada);
            return ('Enhorabuena, has ganado', impar, impar_ruleta);
        }
    }
    
    // Apostar en docena
    function apostar_en_docena(uint docena) payable public returns(string memory, uint, uint){
        address payable addr_jugador = msg.sender; 
        uint apuesta_jugador = msg.value;
        // Se requiere que el deposito en el casino sea al menos la mitad del recomendado
        require(2 * casino.balance >= casino.deposito_recomendado, 'Error, por favor intentelo mas tarde');
        require(casino.addr_dev != addr_jugador, 'Error, cuenta incorrecta');
        require(apuesta_jugador >= casino.apuesta_min, 'Error, por favor apuesta inferior a la minima aceptada');
        require(apuesta_jugador <= casino.apuesta_max, 'Error, por favor apuesta superior a la maxima aceptada');
        require(docena == 0 || docena == 1 || docena == 2, 'Error, por favor elige 0 para la priemra docena, 1\
        para la segunda docena y 2 para la tercera docena');
        
        uint num_ruleta = genera_num(priv_seed);
        uint docena_ruleta; // 0 = 1->12 , 1 = 13->24, 2 = 25->36
        
        if (1 <= num_ruleta && num_ruleta <= 12) {
            docena_ruleta = 0;
        }
        if (13 <= num_ruleta && num_ruleta <= 24) {
            docena_ruleta = 1;
        }
        if (24 <= num_ruleta && num_ruleta <= 36) {
            docena_ruleta = 2;
        }        

        
        if (num_ruleta == 0 || docena != docena_ruleta) {
            casino.balance += apuesta_jugador;
            return ('Lo siento has perdido', docena, docena_ruleta);
        } else {
            uint cantidad_ganada = apuesta_jugador * 3;
            casino.balance -= (cantidad_ganada - apuesta_jugador);
            addr_jugador.transfer(cantidad_ganada);
            return ('Enhorabuena, has ganado', docena, docena_ruleta);
        }
    }
    
    // Apostar en bajo o alto
    function apostar_en_bajo_alto(uint alto) payable public returns(string memory, uint, uint){
        address payable addr_jugador = msg.sender; 
        uint apuesta_jugador = msg.value;
        // Se requiere que el deposito en el casino sea al menos la mitad del recomendado
        require(2 * casino.balance >= casino.deposito_recomendado, 'Error, por favor intentelo mas tarde');
        require(casino.addr_dev != addr_jugador, 'Error, cuenta incorrecta');
        require(apuesta_jugador >= casino.apuesta_min, 'Error, por favor apuesta inferior a la minima aceptada');
        require(apuesta_jugador <= casino.apuesta_max, 'Error, por favor apuesta superior a la maxima aceptada');
        require(alto == 0 || alto == 1, 'Error, por favor elige 0 para bajo y 1 para alto');
        
        uint num_ruleta = genera_num(priv_seed);
        uint alto_ruleta; // 0 = bajo, 1 = alto
        
        if (1 <= num_ruleta && num_ruleta <= 18) {
            alto_ruleta = 0;
        } else {
            alto_ruleta = 1;
        }

        
        if (num_ruleta == 0 || alto != alto_ruleta) {
            casino.balance += apuesta_jugador;
            return ('Lo siento has perdido', alto, alto_ruleta);
        } else {
            uint cantidad_ganada = apuesta_jugador * 2;
            casino.balance -= apuesta_jugador;
            addr_jugador.transfer(cantidad_ganada);
            return ('Enhorabuena, has ganado', alto, alto_ruleta);
        }
    }
}