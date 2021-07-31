pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";
import "./Context.sol";
import "./IERC20.sol";
import "./SafeMath.sol";


contract NikiToken is Context, ERC20, ERC20Detailed {
    constructor (
        string memory name,
        string memory symbol,
        uint256 initialSupply
        
    ) public ERC20Detailed(name, symbol, 18) {
        _mint(_msgSender(), initialSupply);
    }
}