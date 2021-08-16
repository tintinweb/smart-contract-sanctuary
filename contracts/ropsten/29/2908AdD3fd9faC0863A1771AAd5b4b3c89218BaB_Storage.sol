/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    string data;
    address owner;
    
    
   constructor(uint256 _num, string memory _data, address _owner) public {
        number = _num;
        data = _data;
        owner = _owner;
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