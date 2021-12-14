/**
 *Submitted for verification at Etherscan.io on 2021-12-14
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.9.0;

contract GnosisTestContract {

    uint price;

    function setPrice(uint _price) public {
        price = _price;
    }

    function getPrice() public view returns (uint) {
        return price;
    }

}