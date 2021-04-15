// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <=0.8.0;

import "./ERC20.sol";

contract SDT is ERC20 {

    constructor (string memory name, string memory symbol) ERC20(name, symbol) {}

    /// @dev Give free tokens to anyone
    /// @ TODO adjust access privileges
    function mint(address receiver, uint256 value) external {
        _mint(receiver, value);
    }
}