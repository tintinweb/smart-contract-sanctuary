pragma solidity 0.4.25;

import "./ERC20Detailed.sol";
import "./ERC20.sol";


contract TestERC20 is ERC20Detailed, ERC20 {

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint _initialSupply
    ) public ERC20Detailed(_name, _symbol, _decimals) {
        _mint(msg.sender, _initialSupply);
    }
}