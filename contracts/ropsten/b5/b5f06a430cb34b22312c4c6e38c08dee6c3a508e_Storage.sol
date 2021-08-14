/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    uint256 totalPayed;

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num + 3;
    }
    
    function payableStore(uint256 num) public payable {
        require(msg.value > 0, "You should pay");
        totalPayed += msg.value;
        number = num + 9;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
    
    function getTotalPayed() public view returns (uint256){
        return totalPayed;
    }
}