/**
 *Submitted for verification at Etherscan.io on 2021-06-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract HlinkStorage {

    uint256 number;
    string name;

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
    
    function storeName(string memory _name) public {
        name = _name;
    }
    
    function getName() public view returns (string memory){
        return name;
    }
    
    
}