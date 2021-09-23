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
    uint256 current_fee = 0.0001 ether;
    uint256 max_fee = 0.01 ether;
    
    struct NumberOwner{
        uint256 number;
        address owner;
    }
    
    NumberOwner new_number_owner;
    
    NumberOwner[] number_owners;

    
    uint256[] public numbers;
    
    /**
     * @dev Store value in variable
     * @param num value to store
     * Ova funkcija opisuje store proceduru gdje sprema 256 int broj koji je dobula u number
     */
    function store(uint256 num, uint256 new_fee) public payable { 
        require(msg.value >= current_fee);
        require(new_fee <= max_fee);
        
        current_fee = new_fee;
        
        new_number_owner.number = num;
        
        new_number_owner.owner = msg.sender;
        
        number = num;
        
        number_owners.push(new_number_owner);
        
        
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}