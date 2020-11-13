pragma solidity 0.6.2;

import "ERC20.sol";

contract ERC20FixedSupply is ERC20 {
    constructor() public ERC20("Dacxi Gold Token", "DXGT") {
        _mint(msg.sender, 100000 * 1e18);
    }
}

