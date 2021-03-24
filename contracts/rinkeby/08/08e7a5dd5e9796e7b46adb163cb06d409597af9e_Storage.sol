/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 public balance;
    
    constructor() payable {
    }
    
    function getBalance(address _token) public view returns (uint256) {
        return address(this).balance;
    }

    function deposit() public payable {
        
    }
}