/**
 *Submitted for verification at Etherscan.io on 2021-12-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    address[] direcciones;
    Persona per;

    struct Persona {
        string nombre;
        uint edad;
    }

    event Store(Persona);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num, Persona memory _per) public {
        number = num;
        emit Store(_per);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    function prueba(address[] calldata _direcciones) public {
        
    }
}