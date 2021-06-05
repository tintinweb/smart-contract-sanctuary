/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.4;

contract PagoEmpresa{
    address payable boss; //sera el que lanze el deploy
    address directivo = 0xA6e04dB2060f418AdDc6fda281293E3B3d4BD96D;
    address recursos_humanos = 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    address administrador = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB;
    address equipo_limpieza = 0x617F2E2fD72FD9D5503197092aC168c91465E7f2;
    
    uint sueldo_directivo = 400000000000000000; // "Sueldo del empleado, 0.4 ether"
    uint sueldo_recursos = 300000000000000000; // "Sueldo del empleado, 0.3 ether"
    uint sueldo_administrador = 200000000000000000; // "Sueldo del empleado, 0.2 ether"
    uint sueldo_limpieza = 100000000000000000; // "Sueldo del empleado, 0.1 ether"

    
    event Pago(string, uint);
    event increaseBalance(string, uint);
    
    constructor() payable{
        boss = msg.sender;
    }
    
    function getBalance() public view returns(uint fondos) {
        return address(this).balance;
    }
    
    function GananciasEmpresa() public payable {
        if (msg.sender == boss){
            emit increaseBalance("Se han ingresado a la cuenta de la empresa: ", msg.value);
        }
    }
     
    function Pagar() public payable {
        if (msg.sender == directivo){
            require(msg.value >= 50000000000000000, "Coste minimo para realizar la operacion: 0.05 ether");
            boss.transfer(msg.value);

            require(address(this).balance >= sueldo_directivo, "No hay fondos para realizar el pago");
            
            msg.sender.transfer(sueldo_directivo);
            emit Pago("Se ha ingresado su sueldo mensual a nuestro directivo. Sueldo ingresado: ", sueldo_directivo);
        }
        
        if (msg.sender == recursos_humanos){
            require(msg.value >= 50000000000000000, "Coste minimo para realizar la operacion: 0.05 ether");
            boss.transfer(msg.value);

            require(address(this).balance >= sueldo_recursos, "No hay fondos para realizar el pago");
            
            msg.sender.transfer(sueldo_recursos);
            emit Pago("Se ha ingresado su sueldo mensual a nuestro recursos humanos. Sueldo ingresado: ", sueldo_recursos);
        }
        
        if (msg.sender == administrador){
            require(msg.value >= 50000000000000000, "Coste minimo para realizar la operacion: 0.05 ether");
            boss.transfer(msg.value);

            require(address(this).balance >= sueldo_administrador, "No hay fondos para realizar el pago");
            
            msg.sender.transfer(sueldo_administrador);
            emit Pago("Se ha ingresado su sueldo mensual a nuestro administrador. Sueldo ingresado: ", sueldo_administrador);
        }
        
        if (msg.sender == equipo_limpieza){
            require(msg.value >= 50000000000000000, "Coste minimo para realizar la operacion: 0.05 ether");
            boss.transfer(msg.value);

            require(address(this).balance >= sueldo_limpieza, "No hay fondos para realizar el pago");
            
            msg.sender.transfer(sueldo_limpieza);
            emit Pago("Se ha ingresado su sueldo mensual a nuestro empleado de limpieza. Sueldo ingresado: ", sueldo_limpieza);
        }
    }
        
}