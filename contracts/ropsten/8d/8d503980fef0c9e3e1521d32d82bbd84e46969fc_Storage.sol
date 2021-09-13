/**
 *Submitted for verification at Etherscan.io on 2021-09-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    
    mapping(address => uint) public balances;
    
    // balances[0xf0a42116fBA2257AD3dc29Aa3b1eEe4dDd039352] = 10000000;
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
    /**
     * 
     */
    function transfer(address addr, uint256 value) public{
        balances[msg.sender] -= value;
        balances[addr] += value;
    }
}