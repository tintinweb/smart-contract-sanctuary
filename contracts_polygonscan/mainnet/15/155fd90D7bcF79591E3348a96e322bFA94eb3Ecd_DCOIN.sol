// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./FullERC20.sol";

contract DCOIN is ERC20 {

    constructor() ERC20("DystopiaCoin", "DCOIN") {
    }

    uint256 private MAX_CURRENT_SUPPLY = 1000 * 1000 * 1000;  //1 billion

    function mintCoin() external {
        require(super.totalSupply() < MAX_CURRENT_SUPPLY, "cannot mint anymore coins");
        require(super.balanceOf(_msgSender()) == 0, "address cannot mint anymore coins");
        _mint(_msgSender(), 100);
    }
}