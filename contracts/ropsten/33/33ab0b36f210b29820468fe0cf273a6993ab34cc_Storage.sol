/**
 *Submitted for verification at Etherscan.io on 2021-11-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


//DEVOPS --> FUERZA LAS PRUEBAS 

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

//CHAIN CODE

    uint256 number;  // Lata de refrescos
    
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function almacenar(uint256 num) public  {
        /* Esto es un comentario */
        number = num;
    }
    
    function sumar(uint256 num) public {
        if (num > 10) { // SENTENCIAS LOGICA 
            number = number + num + 5;
        } else {
            number = number + num + 10;
        }
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function devolver() public view returns (uint256){
        return number;
    }

    
}