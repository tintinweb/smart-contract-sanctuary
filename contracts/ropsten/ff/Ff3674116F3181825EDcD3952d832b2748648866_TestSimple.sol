/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function decimals() external view returns (uint8);
}

contract TestSimple {
    
    uint public test_num = 12;
    
    function getDecimals(address _token) public view returns(uint8) {
        
        return IERC20(_token).decimals();
    }
}