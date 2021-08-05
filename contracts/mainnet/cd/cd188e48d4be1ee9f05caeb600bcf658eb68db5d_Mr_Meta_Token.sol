/**
 *Submitted for verification at Etherscan.io on 2020-05-24
*/

pragma solidity >=0.4.22 <0.7.0;

/**
 * @title Mr Meta Token
 * @dev Creary . V.NOS
 */
 

contract Mr_Meta_Token {

    string public symbol ;
    string public name ;
    uint256 public totalSupply ;
    string public info ;

    
        constructor (

        ) public {
        name = "Mr Meta Token";
        symbol = "MMETA";
        totalSupply=13572468;
        info = "El orden de las piezas del crypto puzzle está en el total supply del token 13572468";
    }
    
}