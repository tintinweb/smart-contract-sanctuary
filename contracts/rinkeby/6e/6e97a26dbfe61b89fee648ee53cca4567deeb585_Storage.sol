/**
 *Submitted for verification at Etherscan.io on 2021-05-30
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;


    address[] cryptonAcademyReaders; 

    function cryptonAcademy () public {
	    cryptonAcademyReaders.push(msg.sender); 
    } 

    function getcryptonAcademyReaders() public view returns (address[] memory) { 	return cryptonAcademyReaders; 
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}