/**
 *Submitted for verification at Etherscan.io on 2021-10-09
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.7.0 <0.9.0;

contract Child1 {
    function get() external pure returns(uint256) {
        return 1;
    }
    
    function go() external {
        selfdestruct(payable(address(0)));
    }
}