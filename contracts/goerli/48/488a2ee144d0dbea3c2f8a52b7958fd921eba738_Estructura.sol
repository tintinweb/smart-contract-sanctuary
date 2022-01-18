/**
 *Submitted for verification at Etherscan.io on 2022-01-18
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Estructura {
    
    struct Alumno{
        string nombre;
        uint documento;

    }

    Alumno[] public alumnos;

    constructor(){
        alumnos.push(Alumno({nombre: "Juan", documento: 12345}));
    }
}