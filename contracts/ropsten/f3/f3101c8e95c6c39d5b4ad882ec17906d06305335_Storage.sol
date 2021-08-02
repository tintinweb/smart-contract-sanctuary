/**
 *Submitted for verification at Etherscan.io on 2021-08-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    
    /**
     * @dev Allows contract to receive funds
     */
    receive () external payable {}

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store (uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve () public view returns (uint256){
        return number;
    }
    
    /**
     * @dev Allows caller to receive all contract funds
     */
    function withdraw (uint256 amount) public payable {
        require(amount <= address(this).balance, 'Insufficient contract balance.');
        payable(msg.sender).transfer(amount);
    }
}