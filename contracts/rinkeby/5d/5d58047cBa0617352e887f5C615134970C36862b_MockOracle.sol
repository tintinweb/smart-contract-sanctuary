/**
 *Submitted for verification at Etherscan.io on 2021-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract MockOracle {

    uint256 price = uint(blockhash(block.number-1)) % 18;


    function getLatestPrice() external view returns (uint256) {
        return price;
    }


    function setPrice(uint256 _price) external {
        price = _price;
    }
}