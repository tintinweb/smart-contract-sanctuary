pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

import "ERC20.sol";
import "Ownable.sol";
import "SafeMath.sol";

contract MyToken is ERC20, Ownable {
    using SafeMath for uint256;

    constructor() ERC20("PUTinCoinETH", "EPUT") {}

    function mint(address to, uint256 value) public onlyOwner {
        _mint(to, value);
    }

    function burn(address from, uint256 value) public onlyOwner {
        _burn(from, value);
    }
}