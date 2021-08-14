/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {
    
    function transfer(address _to) external payable{
        address payable chosenOne = payable(_to); 
        chosenOne.transfer(1 ether);
    }
    
    receive() external payable {}
}