/**
 *Submitted for verification at Etherscan.io on 2021-10-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    
    event Log(address indexed sender, string message);

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

	function multiply(uint a, uint b) public pure returns (uint) {
        return a*b;
    }

    function returnCallData() public {
        address hi = msg.sender;
        emit Log(hi, "hey");
    }
}