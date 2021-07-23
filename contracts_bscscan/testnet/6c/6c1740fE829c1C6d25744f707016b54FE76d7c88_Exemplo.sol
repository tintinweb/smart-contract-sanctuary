/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity 0.8.4;

contract Exemplo {
    
    uint numeroGuardado;
    
    address owner;
    
    constructor() {
        owner = address(msg.sender);
    }
    
    function guardarNumero(uint a) external {
        require(owner == address(msg.sender), "ERRO: so o dono consegue executar");
        numeroGuardado = a;
    }
    
    function pegarNumero() external view returns (uint) {
        return numeroGuardado;
    }
}