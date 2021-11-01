// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20.sol";

contract BMBToken is ERC20 {
    constructor() ERC20("BMBToken", "BMB") {
        _mint(msg.sender, 150e6 ether);
    }

    function mint(address userAddress, uint256 amount) external {
        _mint(userAddress, amount);
    }
}