/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract CountTwo {
    uint    public count;
    address public owner;

    constructor() public {
        count = 0;
        owner = msg.sender;
    }

    function increaseCount() public {
        require(count + 1 > count,"add is overflow");
        count += 1;
    }

    function decreaseCount() public {
        require(count >= 1,"sub is overflow");
        count -= 1;
    }

    function clearCount() public onlyOwner {
        count = 0;
    }

    modifier onlyOwner() {
        require(owner == msg.sender,"info: caller is not owner");
        _;
    }

}