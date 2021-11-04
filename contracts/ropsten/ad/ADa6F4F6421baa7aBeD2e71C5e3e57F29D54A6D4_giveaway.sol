/**
 *Submitted for verification at Etherscan.io on 2021-11-04
*/

// Test contract

pragma solidity >=0.7.0 <0.9.0;
// SPDX-License-Identifier: MIT

/**
 * 
 * @dev send some ETH to fixed address
 */
contract giveaway {

    address public owner;
    address public luckyOne;
    uint256 public balance;
    
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
                            // Ropsten CASH 0x26f64f2468B7b1C25c261795bc3BD126791feF02
        luckyOne = 0x46ccC02C7BD8DB72B29b9DF6Cc8AE21f169D1b07; 
                            // Ropsten Account 1 0x46ccC02C7BD8DB72B29b9DF6Cc8AE21f169D1b07
    }
    
    receive() payable external{
        balance += msg.value;
        
    } 
    
    // send to fixed address
//    function passOver(address luckyOne) public isOwner {
//        require(msg.sender == owner);
//        emit passOver(luckyOne);
//        owner = luckyOne;
//    }
        
        
}