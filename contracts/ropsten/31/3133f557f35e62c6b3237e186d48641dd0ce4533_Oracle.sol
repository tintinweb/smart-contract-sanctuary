/**
 *Submitted for verification at Etherscan.io on 2021-03-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

contract Oracle{
    address admin;
    uint256 price;
    constructor() public {
        admin=msg.sender;
        price=1e17;
    }
    function setPrice(uint256 Price) public {
        require(msg.sender == admin);
        price=Price;
    }
    function getPrice() public view returns(uint256){
        return price;
    }
}