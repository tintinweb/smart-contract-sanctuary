/**
 *Submitted for verification at Etherscan.io on 2021-08-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract GummyBear {
    uint256 public supply;
    uint256 public limit;

    event Mint(uint256 what);

    constructor() {
        supply = 0;
        limit = 50;
    }

    function setLimit(uint256 l) public {
        limit = l;
    }

    function clearSupply() public {
        limit = 0;
    }

    function mintBears() public payable {
        require(supply < limit, 'sold out');
        supply += 1;
        emit Mint(1);
    }
}