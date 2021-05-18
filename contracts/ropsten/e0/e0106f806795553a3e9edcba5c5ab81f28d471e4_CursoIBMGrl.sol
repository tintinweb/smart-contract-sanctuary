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

contract CursoIBMGrl {
    string public curso = unicode"curso";
    string public carpetaDocumentacion = "edicion-curso";
    string public instructor = unicode"Domingo Victoria Martínez";
    string public edicionFechas = unicode"IBM. fechaInicial - fechaFinal. Modo";
    uint256 public precio = 0.25 ether;
    uint256 public selloTemporalCreacionContrato;
    address payable public direccionOrigen;
    address payable public direccionOrigenTransaccion;
    address payable public direccionCreadora;
    address payable public direccionAdministradora;
    event EventoDireccionAdministradora(address indexed direccionAdministradora);
    event EventoDestruirContrato(address indexed _direccion, uint256 _saldo, string _mensaje);

    constructor() {
        direccionOrigenTransaccion = payable(tx.origin);
        direccionOrigen = payable(msg.sender);
        direccionCreadora = direccionOrigen;
        direccionAdministradora = direccionOrigen;
        selloTemporalCreacionContrato = block.timestamp;
    }

    modifier soloDireccionCreadora() {
        direccionOrigen = payable(msg.sender);
        require (direccionOrigen == direccionCreadora,
        unicode"Error. Acceso denegado. Solo direccionCreadora");
        _;
    }

    modifier soloDireccionesCreadoraAdministradora() {
        direccionOrigen = payable(msg.sender);
        require ((direccionOrigen == direccionCreadora) || (direccionOrigen == direccionAdministradora),
        unicode"Error. Acceso denegado. Solo direccionesCreadoraAdministradora");
        _;
    }

    function setDireccionAdministradora(address _direccionAdministradora) public soloDireccionCreadora {
        direccionAdministradora = payable(_direccionAdministradora);
        emit EventoDireccionAdministradora(direccionAdministradora);
    }

   receive() external payable {
    }

    function setCurso(string memory _curso) public soloDireccionesCreadoraAdministradora {
        curso = _curso;
    }

    function setCarpetaDocumentacion(string memory _carpetaDocumentacion) public soloDireccionesCreadoraAdministradora {
        carpetaDocumentacion = _carpetaDocumentacion;
    }

    function setInstructor(string memory _instructor) public soloDireccionesCreadoraAdministradora {
        instructor = _instructor;
    }

    function setPrecio(uint256 _precio) public soloDireccionesCreadoraAdministradora {
        precio = _precio;
    }

    function setEdicionFechas(string memory _edicionFechas) public soloDireccionesCreadoraAdministradora {
        edicionFechas = _edicionFechas;
    }

    function setDatosIBMCurso (
        string memory _curso,
        string memory _carpetaDocumentacion,
        string memory _instructor,
        string memory _edicionFechas,
        uint256 _precio
    ) public soloDireccionesCreadoraAdministradora
    {
        curso = _curso;
        carpetaDocumentacion = _carpetaDocumentacion;
        instructor = _instructor;
        edicionFechas = _edicionFechas;
        precio = _precio;    
    }

    function getDatosIBMCurso() public view returns (string memory, string memory,
        string memory, string memory, uint256) {
        return (curso, carpetaDocumentacion, instructor, edicionFechas, precio);
    }

    function destruirContrato() public soloDireccionCreadora {
    emit EventoDestruirContrato(direccionCreadora, address(this).balance,
    unicode"Función: destruirContrato. Control. Destrucción del contrato realizada correctamente");
    selfdestruct(direccionCreadora);
    }
}