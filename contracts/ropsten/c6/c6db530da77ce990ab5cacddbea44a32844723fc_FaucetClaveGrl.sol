/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

// SPDX-License-Identifier: MIT

/*
Curso: FTB: Fundamentos tecnológicos de Blockchain
Curso: BPSCES: Blockchain públicas: Smart Contracts con Ethereum y Solidity
(C) Copyright. Obra docente. Cursos impartidos en IBM: International Business Machines
(C) Copyright. Documentación del curso protegida por la propiedad intelectual
(C) Copyright. Domingo Victoria Martínez
(C) Copyright. BASE-10 COMUNICACIÓN, S. L.
(C) Copyright. Todos los derechos reservados. All rights reserved
*/

pragma solidity 0.8.*;

contract FaucetClaveGrl {
    address payable public direccionCreadora;
    bytes32 public claveHash;
    string private claveString;
    uint256 public selloTemporalCreacionContrato;
    event EventoDotarFondosContrato(address indexed _direccion, uint256 _importe, string _mensaje);
    event EventoSolicitarEther(address indexed _direccion, uint256 _importe, string _mensaje);
    event EventoDestruirContrato(address indexed _direccion, uint256 _saldo, string _mensaje);

    constructor() {
        direccionCreadora = payable(msg.sender);
        selloTemporalCreacionContrato = block.timestamp;
     }

    modifier soloDireccionCreadora() {
        require (msg.sender == direccionCreadora,
        unicode"Error. Acceso denegado. Solo direccionCreadora");
        _;
    }

   receive() external payable {
        emit EventoDotarFondosContrato(msg.sender, msg.value,
        unicode"Función: receive. Control. Dotación realizada correctamente");
        // ...
    }

    fallback() external payable {
        emit EventoDotarFondosContrato(msg.sender, msg.value,
        unicode"Función: fallback. Control. Dotación realizada correctamente");
        // ...
    }

    function setClave(string memory _claveString) public soloDireccionCreadora {
        claveString = _claveString;
        claveHash = keccak256(abi.encodePacked(_claveString));
    }

    function getClaves() public view soloDireccionCreadora returns (string memory, bytes32) {
        return (claveString, claveHash);
    }

    function solicitarEther(string memory _claveString) public {
        require((address(this).balance) >= 0.2 ether,
        unicode"Función: solicitarEther. Control. Error. Saldo del contrato insuficiente");
        require(keccak256(abi.encodePacked(_claveString)) == claveHash,
        unicode"Función: solicitarEther. Control. Error. Acceso denegado. Clave incorrecta");
        payable(msg.sender).transfer(0.1 ether);
        emit EventoSolicitarEther(msg.sender, 0.1 ether,
        unicode"Función: solicitarEther. Control. Solicitud realizada correctamente");
    }

    function dotarFondosContrato() public payable {
        emit EventoDotarFondosContrato(msg.sender, msg.value,
        unicode"Función: dotarFondosContrato. Control. Dotación realizada correctamente");
    }

    function getSaldoContrato() public view soloDireccionCreadora returns (uint256) {
        return (address(this).balance);
    }

    function destruirContrato() public soloDireccionCreadora {
        emit EventoDestruirContrato(direccionCreadora, address(this).balance,
        unicode"Función: destruirContrato. Control. Destrucción del contrato realizada correctamente");
        selfdestruct(direccionCreadora);
    }
}