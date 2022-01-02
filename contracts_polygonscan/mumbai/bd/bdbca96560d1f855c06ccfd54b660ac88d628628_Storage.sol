/**
 *Submitted for verification at polygonscan.com on 2022-01-01
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Storage {

    uint256 number_;
    address address_;

     constructor(uint256 num) {
        number_ = num;
        address_ = msg.sender;
     }
    function storeNumber(uint256 num) public {
        number_ = num;
    }

    function storeAddress() public {
        address_ = msg.sender;
    }

    function retrieve() public view returns (uint256 number, address addr){
        number = number_;
        addr = address_; 
    }
}