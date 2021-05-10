// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.6.0 <0.8.0;

import "./Consulado.sol";
import "./ConstructorAplicante.sol";
import "./ConstructorVisa.sol";
import "./ConstructorAgente.sol";
import "./AplicacionesAplicante.sol";
import "./DocumentosAplicante.sol";

contract ConstructorConsulado is Consulado,
ConstructorAplicante,
AplicacionesAplicante,DocumentosAplicante,
ConstructorVisa,
ConstructorAgente {
    constructor()  {
        owner = msg.sender;
    }
}