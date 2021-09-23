/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0; // koja verzija sooliditi compilera se izvršava

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256[] public numbers;
    
    /**
     * @dev Store value in variable
     * @param num value to store
     * Ova funkcija opisuje store proceduru gdje sprema 256 int broj koji je dobula u number
     */
    function store(uint256 num) public payable { 
        require(msg.value >= 0.0001 ether);
        number = num;
        numbers.push(num);
        
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}