pragma solidity ^0.8.0;

import "./ERC20.sol";

contract TKB is ERC20 {
    constructor(uint256 initialSupply) public ERC20 ("TKB", "TKB") {
        _mint(msg.sender, initialSupply);
    }
}