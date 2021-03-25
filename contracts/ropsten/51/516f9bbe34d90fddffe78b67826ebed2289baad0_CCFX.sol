// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";
import "./ERC20Pausable.sol";
import "./SafeERC20.sol";
import "./TokenTimelock.sol";

contract CCFX is ERC20 {
    constructor() ERC20("Climate Carbon Energy Security", "CCES") {
        _mint(msg.sender, 3000000000000000000000000000);
    }
}