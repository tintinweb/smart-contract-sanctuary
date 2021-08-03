/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Contrac {

    uint256 number;
    uint256 numb;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function Enviar(uint256 num) public {
        number = num;
        numb = number * 15 /100;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function Descuento() public view returns (uint256){
        return number - numb;
    }
}