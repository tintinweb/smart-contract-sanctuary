pragma solidity ^0.6.0;

import "./ERC20.sol";

contract TANK is ERC20 {
    constructor(uint256 initialSupply) public ERC20("TANK", "TNK") {
        _mint(msg.sender, initialSupply);
    }
}