/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;

    string [541] ruku;
   
    function store(string  memory _data, uint256 _index) public {
        ruku[_index] = _data;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve(uint256 _index) public view returns (string memory){
        return ruku[_index];
    }
}