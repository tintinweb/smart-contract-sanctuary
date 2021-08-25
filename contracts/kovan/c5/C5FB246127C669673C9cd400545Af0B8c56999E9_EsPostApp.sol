/**
 *Submitted for verification at Etherscan.io on 2021-08-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.5 <0.9.0;

struct TInfo {
    string idTransaccion;
    string duenioActual;
    string hashAnterior;
    string comentario;
}

contract EsPostApp {
    mapping(string => TInfo) public productoDuenio;
    address owner;

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Solo EsPostApp puede llamar esta funcion"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    event Transaccion(
        string producto,
        string duenioActual,
        string idTransaccion
    );

    function getDuenio(string memory producto)
        public
        view
        returns (TInfo memory)
    {
        return productoDuenio[producto];
    }

    function setDuenio(
        string memory producto,
        string memory idTransaccion,
        string memory duenioActual,
        string memory hashAnterior,
        string memory comentario
    ) public onlyOwner returns (bool success) {
        TInfo storage ti = productoDuenio[producto];

        ti.idTransaccion = idTransaccion;
        ti.duenioActual = duenioActual;
        ti.hashAnterior = hashAnterior;
        ti.comentario = comentario;

        emit Transaccion(producto, duenioActual, idTransaccion);
        return true;
    }
}