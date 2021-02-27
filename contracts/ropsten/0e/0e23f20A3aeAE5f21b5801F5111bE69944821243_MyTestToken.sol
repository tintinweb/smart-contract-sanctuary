pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./ERC20.sol";

contract MyTestToken is ERC20 {
    address owner;

    constructor() public ERC20("TestTokenNe", "TTN") {
        owner = msg.sender;
        super._mint(_msgSender(), 800000000 * 10 ** 18);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
          owner = newOwner;
        }
    }

    function multisend(address[] memory dests, uint256[] memory values) public onlyOwner
        returns (uint256) {
        uint256 i = 0;
        while (i < dests.length) {
            ERC20(_msgSender()).transfer(dests[i], values[i]);
            i += 1;
        }
        return(i);
    }
}