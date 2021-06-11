/**
 *Submitted for verification at Etherscan.io on 2021-06-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Loop
 * @dev Loop an unpredictable number of times then perform save
 */
contract ContractLoop {

    uint256 public number;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
        uint256 count = 0;
        while (count < block.number){
            
            count = count + 100000;
        }
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
     * @dev Return value 
     * @return value of 'number'
     */
    function blockNumber() public view returns (uint256){
        return block.number;
    }
}