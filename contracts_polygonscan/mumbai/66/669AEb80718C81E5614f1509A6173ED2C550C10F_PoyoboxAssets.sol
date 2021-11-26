// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "ERC1155.sol";
import "Counters.sol";

contract PoyoboxAssets is ERC1155 {
    using Counters for Counters.Counter;

    Counters.Counter internal _idCounter;

    constructor() ERC1155("https://poyobox-assets.com/metadata/{id}.json") {}

    function mint(address owner, uint256 amount) external returns (uint256) {
        _idCounter.increment();

        uint256 id = _idCounter.current();
        _mint(owner, id, amount, "");

        return id;
    }
}