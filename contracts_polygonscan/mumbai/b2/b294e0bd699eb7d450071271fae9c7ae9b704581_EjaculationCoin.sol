// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "ERC20.sol";
import "Ownable.sol";

contract EjaculationCoin is ERC20, Ownable {
    constructor() ERC20("Ejaculation Coin", "EJC") {
        _mint(msg.sender, 1000000000000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) private onlyOwner {
        _mint(to, amount);
    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }
}