/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity 0.8.4;

contract Exemplo {
    uint numeroGuardado;

    address public owner;

    constructor() {
        owner = address(msg.sender);
    }

    function guardarNumero(uint numero) external {
        require(owner == address(msg.sender), "erro de nao dono");
        numeroGuardado = numero;
    }

    function pegarNumero() external view returns (uint) {
        return numeroGuardado;
    }
}