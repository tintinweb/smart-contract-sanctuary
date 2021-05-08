/**
 *Submitted for verification at Etherscan.io on 2021-05-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract SimpleStorageContract {
    uint256 number;
    uint256 _creationFeeETH = 1000; //wei
    
    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) external payable {
        require(msg.value == _creationFeeETH, "ETH sent are not enough to update the number.");
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