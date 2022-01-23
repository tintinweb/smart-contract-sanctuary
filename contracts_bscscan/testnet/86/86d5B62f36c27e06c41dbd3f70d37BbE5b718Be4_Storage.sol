/**
 *Submitted for verification at BscScan.com on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
    uint256 number;
    
    event Storage(uint oldNumber_,uint newNumber_, address indexed sender_);

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        uint oldNumber_ = number;
        number = num;
        emit Storage(oldNumber_,num,msg.sender);
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}