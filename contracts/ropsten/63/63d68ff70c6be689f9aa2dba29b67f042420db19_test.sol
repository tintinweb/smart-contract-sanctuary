/**
 *Submitted for verification at Etherscan.io on 2021-10-22
*/

pragma solidity 0.8.7;

contract test {
    
    uint nombre;
    
    function getnombre() public view returns(uint){
        return nombre;
    }
    
    function setnombre(uint _nombre) public {
        nombre = _nombre;
    }
}