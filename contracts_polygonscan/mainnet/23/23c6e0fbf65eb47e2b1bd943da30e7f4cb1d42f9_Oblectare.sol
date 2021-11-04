pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Oblectare is ERC20 {
    constructor(uint256 initialSupply) ERC20("Oblectare", "OBLEC") {
        _mint(msg.sender, initialSupply);
    }
}