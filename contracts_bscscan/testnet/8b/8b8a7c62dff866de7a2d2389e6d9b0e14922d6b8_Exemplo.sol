/**
 *Submitted for verification at BscScan.com on 2021-07-23
*/

pragma solidity 0.8.4;

contract Exemplo {
    
    uint numeroGuardado;
    
    function guardarNumero(uint a) external {
        numeroGuardado = a;
    }
    
    function pegarNumero() external view returns (uint) {
        return numeroGuardado;
    }
}