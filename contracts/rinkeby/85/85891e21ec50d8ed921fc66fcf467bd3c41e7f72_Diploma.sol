/**
 *Submitted for verification at Etherscan.io on 2021-06-01
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

contract Diploma {

        string apellidoNombre; 
        string documentoTipoNro; 
        string tallerTitulo; 
        string tallerCargaHoraria; 
        string tallerFecha; 

    function escribirDiploma(
        string calldata _apellidoNombre, 
        string calldata _documentoTipoNro, 
        string calldata _tallerTitulo, 
        string calldata _tallerCargaHoraria, 
        string calldata _tallerFecha) public {
            apellidoNombre = _apellidoNombre;
            documentoTipoNro = _documentoTipoNro;
            tallerTitulo = _tallerTitulo;
            tallerCargaHoraria = _tallerCargaHoraria;
            tallerFecha = _tallerFecha;
    }


    function leerDiploma() public view returns (
        string memory, 
        string memory, 
        string memory, 
        string memory, 
        string memory){
            return (
                apellidoNombre, 
                documentoTipoNro, 
                tallerTitulo, 
                tallerCargaHoraria, 
                tallerFecha); 
    }
}