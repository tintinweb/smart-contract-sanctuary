/**
 *Submitted for verification at Etherscan.io on 2021-03-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.8.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    address col;
    uint48 expiry;
    uint256 mintRatio;
    function store(uint256 num) public {
        number = num;
    }
    
    function repay(
    address _col,
    uint48 _expiry,
    uint256 _mintRatio) public {
    col = _col;
    expiry = _expiry;
    mintRatio = _mintRatio;
    
  }
  

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }
}