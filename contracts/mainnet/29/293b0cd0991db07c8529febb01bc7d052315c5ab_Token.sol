pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";

contract Token is ERC20, ERC20Detailed {
    constructor () public ERC20Detailed("InTime", "ITO", 18) {
        _mint(msg.sender, 3000000000000 * (10 ** uint256(decimals())));
    }
}