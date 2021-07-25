// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TensaiStudioToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("TensaiStudioToken", "TST") {
        _mint(msg.sender, initialSupply);
    }
}

//0xe1929f1ce36d7b2c246dc31d8e026e5a74d10634