// contracts/Zap.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC1155.sol";

contract Zap is ERC1155 {
    uint256 public constant GOLD = 0;
    uint256 public constant ZAP = 2;

    constructor() ERC1155("https://techlord.net/api/item/{id}.json") {
        _mint(msg.sender, GOLD, 10**18, "");
        _mint(msg.sender, ZAP, 1, "");
    }
}