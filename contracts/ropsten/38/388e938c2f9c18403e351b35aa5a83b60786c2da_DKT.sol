// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "./ERC20.sol";

contract DKT is ERC20 {
    address public admin;

    constructor() ERC20("DKT", "DKT") {
        _mint(msg.sender, 1000000 * 10**18);
        admin = msg.sender;
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == admin, "Only Admin Access");
        _mint(to, amount);
    }

    function burn(uint256 amount) external {
        _mint(msg.sender, amount);
    }
}