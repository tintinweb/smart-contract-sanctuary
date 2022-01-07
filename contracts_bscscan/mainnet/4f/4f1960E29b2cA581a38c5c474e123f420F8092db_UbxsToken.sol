// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "./ERC20.sol";

contract UbxsToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("UBXS Token", "UBXS") {
        _mint(msg.sender, initialSupply);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }
}