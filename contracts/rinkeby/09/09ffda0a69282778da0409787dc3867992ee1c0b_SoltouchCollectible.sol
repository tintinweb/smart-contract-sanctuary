pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "./ERC1155.sol";
import "./Ownable.sol";

contract SoltouchCollectible is ERC1155, Ownable {
    string public name;
    string public symbol;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory _url
    ) ERC1155(_url) {
        name = name_;
        symbol = symbol_;
        _mint(msg.sender, 1, 100, "");
        _mint(msg.sender, 2, 200, "");
    }

    function mintTokens(
        address account,
        uint256 id,
        uint256 amount
    ) public onlyOwner {
        _mint(account, id, amount, "");
    }
}