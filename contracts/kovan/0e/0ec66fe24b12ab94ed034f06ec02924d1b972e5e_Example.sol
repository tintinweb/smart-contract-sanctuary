/**
 *Submitted for verification at Etherscan.io on 2021-05-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Example {
    uint stored_result;

    function doSomething(uint n) public {
        uint x = 0;
        for(uint i = 0; i <= n; i++) {
            x += i;
        }
        stored_result = x;
    }
    
    function doSomethingBetter(uint n) public {
        uint x = (n*(n+1))/2;
        stored_result = x;
    }
    
    function getResult() public view returns(uint) {
        return stored_result;
    }
}