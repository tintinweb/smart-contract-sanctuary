/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

pragma solidity ^0.4.17;

contract Contador{
    
    uint256 kontador;
    
    constructor( uint256 _kontador) public{
        kontador = _kontador;
    }
    
    
    function setKontador(uint256 _kontador) public{
        kontador = _kontador;
    }
    
    
    function inkrementa() public{
        kontador += 1;
    }
    
    /**
     * Palabra clave "view" indica que va a leer pero
     * no a esribir estado del contrato (no usa gas)
     */
    function getKontador() public view returns(uint256) {
        return kontador;
    }
    

    /**
     * Palabra clave "pure" indica que no va a leer
     * ni a escribir estado del contrato (no usa gas)
     */
    function getNumber() public pure returns(uint256){
        return 666;
    }
}