/**
 *Submitted for verification at Etherscan.io on 2021-04-30
*/

// SPDX-License-Identifier: MIT

// we need to specify which version of the EVM we accept 
// (since there are big different between different version)
pragma solidity >=0.7.6;

/**
 * @title Counter
 * @dev Handle a Counter
 */
contract Counter {

    uint public count;
    
    /*
     * in public Ethereum there is no concept of private variable. 
     * The code of the smart contract is public so also the state is public 
     * Any node in the network can know the value of this variable
     */ 
    uint myPrivateInt; 

    /**
     * Function to get the current count
     */ 
    function get() public view returns (uint) {
        return count;
    }
    
    /**
     * Function to increment the counter by 1
     */
    function inc() public {
        count += 1;
    }
    
    /**
     * Function to decrement the counter by 1
     */
    function dec() public {
        count -= 1;
    }

}