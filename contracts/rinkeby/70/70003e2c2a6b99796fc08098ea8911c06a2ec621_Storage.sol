/**
 *Submitted for verification at Etherscan.io on 2021-04-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    string name;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num,string memory _name) public {
        require(num == 100, "num is error");
        number = num;
        name = _name;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}