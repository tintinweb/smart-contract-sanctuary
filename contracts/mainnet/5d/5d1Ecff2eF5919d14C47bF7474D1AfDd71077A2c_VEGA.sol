pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract VEGA is ERC20, ERC20Detailed {
    constructor(uint256 initialSupply) ERC20Detailed("VEGA", "VEGA", 18) public {
        _mint(msg.sender, initialSupply);
    }
}