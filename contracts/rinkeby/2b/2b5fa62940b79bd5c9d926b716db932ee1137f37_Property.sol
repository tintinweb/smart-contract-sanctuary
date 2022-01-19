/**
 *Submitted for verification at Etherscan.io on 2022-01-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Property{
    int public price;
    string constant public location = "NL";

    function setPrice(int _price) public{
        price = _price;
    }

    function getPrice() public view returns(int){
        return price;
    }
}