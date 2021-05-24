/**
 *Submitted for verification at Etherscan.io on 2021-05-24
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title StorageXY
 * @dev Store & retrieve value in a variable
 */
contract StorageXY {

    uint256 numberX;
    uint256 numberY;
    

    /**
     * @dev Store value in variable
     * @param numX value to store
     * @param numY value to store      
     */
    function storeXY(uint256 numX, uint256 numY) public {
        numberX = numX;
        numberY = numY;
    }
 
    function retrieveXY() public view returns (uint256 X , uint256 Y){
        return (numberX, numberY);
    }
}