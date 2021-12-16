/**
 *Submitted for verification at Etherscan.io on 2021-12-15
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract severalFunctions { 
    //definicion de variables
    address public owner; //0x634C65e9cFb609F4D0b73dF26a9E4ACe869B532c
    string public text;
    uint256 public balance;
    string public greeting;
    
    //constructor del contrato
    constructor(string memory _greeting) {
        owner = msg.sender; // guardamos la direccion de quien crea el contrato
        greeting = _greeting;
    }
    
    // contrato capaz de recibir pagos externos
    receive() payable external {
        balance = balance + msg.value; // mostrar el balance del contrato (en WEI)
    }
    
    //funcion para retirar fondos del contrato
    function withdraw(uint amount, address payable destAddr) public {
        // solo puede retirar fondos el owner
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount); // mandar cantidad de ETH a la direccion de destino
        balance -= amount; // restamos la cantidad retirada del balance
    }
    
    // funcion para mostrar el nombre del propietario del contrato
    function getOwner() external view returns (address) {
        return owner;
    }

    // funcion para almacenar cadena de texto
    function storeText(string memory txt) public {
        text = txt;
    }

    // funcion para mostrar cadena de texto almacenada previamente
    function getText() public view returns (string memory){
        return text;
    }
    
     // funcion para mostrar saludo introducido en memoria en el constructor del contrato
    function greet() public view returns (string memory) {
        return greeting;
 }
}