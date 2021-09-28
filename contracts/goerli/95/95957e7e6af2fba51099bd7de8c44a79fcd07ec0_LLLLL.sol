/**
 *Submitted for verification at Etherscan.io on 2021-09-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract LLLLL {
    
    uint256 private degisken;
    
    function multiply(uint256 num1, uint256 num2) public pure returns(uint256) {
        return num1*num2;
    }
    
    function duzread() public view returns(uint256) {
        return degisken;
    }
    
    function write(uint256 _degisken) public {
        degisken = _degisken;
    }
}