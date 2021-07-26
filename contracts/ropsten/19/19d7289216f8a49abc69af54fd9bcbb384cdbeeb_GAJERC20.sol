// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./ERC20 Burnable.sol";

contract GAJERC20 is ERC20, ERC20Burnable {
    // 8 decimals
    constructor() ERC20("GAJ Coin", "GAJ") {
        _mint(_msgSender(), 210_000_000 * (10 ** uint256(decimals())));
    }
    function batchTransfer(address[] calldata destinations, uint256[] calldata amounts) public {
        uint256 n = destinations.length;
        address sender = _msgSender();
        require(n == amounts.length, "GAJERC20: Invalid BatchTransfer");
        for(uint256 i = 0; i < n; i++)
            _transfer(sender, destinations[i], amounts[i]);
    }
}