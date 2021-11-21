/**
 *Submitted for verification at Etherscan.io on 2021-11-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract GasBurner {
    event Burn(address sender, uint256 gas);
    uint256 constant GAS_REQUIRED_TO_FINISH_EXECUTION = 60;

    /**
    * A fallback function is executed if no one of the opposite functions macthed the function identifier.
    * Has no name. Has no arguments. Can’t return anything.
    *  
    */
    fallback() external {
        emit Burn(msg.sender, gasleft());
        while(gasleft() > GAS_REQUIRED_TO_FINISH_EXECUTION) {
            // do nothing
        }
    }
}