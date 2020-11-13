pragma solidity ^0.5.0;

import "./ERC20Detailed.sol";
import "./ERC20Burnable.sol";
import "./ERC20Capped.sol";

contract CLIQ is ERC20Detailed, ERC20Burnable, ERC20Capped {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 cap,
        uint256 initialSupply
    ) public ERC20Capped(cap) ERC20Detailed(name, symbol, decimals) {
        _mint(_msgSender(), initialSupply * (10**uint256(decimals)));
    }
}
