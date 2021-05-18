/**
 *Submitted for verification at Etherscan.io on 2021-05-18
*/

pragma solidity ^0.4.24;
//


contract helloRamiro{
    string public saludo;
    
    constructor()public{
        saludo = 'helloRamiro';
    }
    
    function setter(string memory _variabletemporal)public{
        saludo = _variabletemporal;
    }
    
    function getter()public view returns(string memory _resultado){
        _resultado = saludo;
    }
}