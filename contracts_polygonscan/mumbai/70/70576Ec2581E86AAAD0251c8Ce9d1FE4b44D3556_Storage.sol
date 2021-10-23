/**
 *Submitted for verification at polygonscan.com on 2021-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number;
    
    event StoredNumber(uint256 indexed num);

    function store(uint256 num) public {
        emit StoredNumber(num);
        number = num;
    }


    function retrieve() public view returns (uint256){
        return number;
    }
}