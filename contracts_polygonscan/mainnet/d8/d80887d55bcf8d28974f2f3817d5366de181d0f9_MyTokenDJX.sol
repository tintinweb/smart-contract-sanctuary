// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";
import "./Ownable.sol";

contract MyTokenDJX is ERC20, Ownable {
    constructor() ERC20("MyTokenDJX", "MTK") {
        _mint(msg.sender, 100000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}