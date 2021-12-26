// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "ECDSA.sol";
import "ERC20.sol";
import "Ownable.sol";

contract Coloniium is ERC20, Ownable {
    constructor() ERC20("TestNeT", "TNT") {
        _mint(msg.sender, 3000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}