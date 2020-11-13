pragma solidity ^0.6.0;

import "./ERC20.sol";

contract Blink is ERC20 {
    constructor(uint256 initialSupply) public ERC20("Blink", "BNK") {
        _mint(msg.sender, initialSupply);
    }
}