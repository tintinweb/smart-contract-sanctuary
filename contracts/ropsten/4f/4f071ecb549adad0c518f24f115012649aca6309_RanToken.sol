// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;
import "./ERC20.sol";

contract RanToken is ERC20 {
    constructor() ERC20("Ran Token", "RW") {
        _mint(msg.sender, 90000000000000000000000000);
    }
}