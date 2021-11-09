/**
 *Submitted for verification at Etherscan.io on 2021-11-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract CondorCoin {

    string texto;

    /**
     * @dev escribir value in variable
     * @param _texto value to escribir
     */
    function escribir(string calldata _texto) public {
        texto = _texto;
    }

    /**
     * @dev Return value 
     * @return value of 'texto'
     */
    function leer() public view returns (string memory){
        return texto;
    }
}