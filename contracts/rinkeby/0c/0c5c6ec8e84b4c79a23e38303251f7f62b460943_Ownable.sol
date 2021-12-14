/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: Unlicense

pragma solidity =0.6.11;

contract Ownable {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner cannot be the zero address");
        owner = newOwner;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
}