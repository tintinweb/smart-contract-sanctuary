// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./Ownable.sol";

contract KaijuScales is ERC20("KaijuScales", "KS"), Ownable {
    function decimals() public view virtual override returns (uint8) {
        return 0;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }
}