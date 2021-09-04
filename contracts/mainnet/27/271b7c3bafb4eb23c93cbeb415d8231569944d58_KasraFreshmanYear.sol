// contracts/KasraFreshmanYear.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC1155.sol";
import "./Ownable.sol";

contract KasraFreshmanYear is ERC1155, Ownable {
    uint256 public constant CLASSIC = 5;
    uint256 public constant GRAY = 6;
    uint256 public constant NEPTUNE = 7;
    uint256 public constant LIME = 8;
    uint256 public constant SAKURA = 9;
    uint256 public constant CYBER = 10;
    uint256 public constant BOUNCEY = 20;

    string public name = "Freshman Math Class";

    // creates a semi-fungible token represented by metadata found at the following address: 
    constructor() ERC1155("https://cloudflare-ipfs.com/ipfs/QmeWMXdMHrVHC1xGg73zKfx7awK5R3baFwdrDJbfmH16dA/{id}.json") {
        _mint(msg.sender, CLASSIC, 5, "");
        _mint(msg.sender, GRAY, 5, "");
        _mint(msg.sender, NEPTUNE, 5, "");
        _mint(msg.sender, LIME, 5, "");
        _mint(msg.sender, SAKURA, 5, "");
        _mint(msg.sender, CYBER, 5, "");
        _mint(msg.sender, BOUNCEY, 1, "");
    }
}