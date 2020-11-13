pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Meta is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Meta", "META") {
        _mint(msg.sender, initialSupply);
    }
}