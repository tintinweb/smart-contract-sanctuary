// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC20.sol";
import "ERC20Burnable.sol";
import "Ownable.sol";

contract Cribini is ERC20, ERC20Burnable, Ownable {
    constructor() ERC20("Cribini", "CRIB") {
        _mint(msg.sender, 8888888888888 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}