// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import { ERC20 } from './ERC20.sol';
import { Ownable } from './Ownable.sol';

contract MintableCappedERC20 is ERC20, Ownable {
    uint256 public cap;

    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 capacity
    ) ERC20(name, symbol, decimals) Ownable() {
        cap = capacity;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        uint256 capacity = cap;
        require(capacity == 0 || totalSupply + amount <= capacity, 'CAP_EXCEEDED');

        _mint(account, amount);
    }
}