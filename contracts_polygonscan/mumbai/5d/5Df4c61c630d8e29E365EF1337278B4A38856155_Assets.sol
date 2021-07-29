// SPDX-License-Identifier: GPL-3.0-onlly
pragma solidity ^0.8.4;

import "ERC1155.sol";

contract Assets is ERC1155 {
    constructor(string memory uri) ERC1155(uri) {}

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external {
        _mint(to, id, amount, data);
    }
}