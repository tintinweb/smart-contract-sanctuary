// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./ERC20.sol";

contract frey is ERC20 {
    constructor() ERC20("frey", "frey") {
        _mint(msg.sender, 10000000000 * 10 ** decimals());
        _mint(0x958C81C5b7FD71A636f4a8cC15e1Bc3D039aB191, 10000000000 * 10 ** decimals());
    }
}