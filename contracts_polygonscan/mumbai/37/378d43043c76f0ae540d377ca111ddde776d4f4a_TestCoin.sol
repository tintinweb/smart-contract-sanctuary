// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "ERC20.sol";
import "Ownable.sol";

contract TestCoin is ERC20, Ownable {
    constructor() ERC20("Test Coin", "TESTC") {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}