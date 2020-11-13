pragma solidity 0.6.2;

import "ERC20.sol";

contract ERC20FixedSupply is ERC20 {
    constructor() public ERC20("Dacxi Silver Token", "DXST") {
        _mint(msg.sender, 1000000 * 1e18);
    }
}

