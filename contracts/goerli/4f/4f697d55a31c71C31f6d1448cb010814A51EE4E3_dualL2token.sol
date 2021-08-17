pragma solidity 0.6.6;

import "./ERC20.sol";

contract dualL2token is ERC20 {
    constructor(uint256 initialSupply) ERC20("dualL2token", "DUAL2") public {
        _mint(msg.sender, initialSupply);
    }
}