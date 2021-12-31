// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces.sol";


contract RisingTideToken is ERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    constructor() public ERC20("RisingTideToken", "RTT") {
        uint256 initialSupply = 100000000;
        mint(initialSupply);
        burn(initialSupply.div(3));
    }

    function mint(uint256 amount) public onlyOwner {
        _mint(msg.sender, amount);
    }

    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}