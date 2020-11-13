pragma solidity 0.6.2;

import "ERC20.sol";

contract ERC20FixedSupply is ERC20 {
    constructor() public ERC20("Dacxi Platinum Token", "DXPT") {
        _mint(msg.sender, 25000 * 1e18);
    }
}

