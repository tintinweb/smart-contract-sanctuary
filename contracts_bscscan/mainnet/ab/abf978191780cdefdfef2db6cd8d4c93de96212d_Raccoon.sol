pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Raccoon  is ERC20 {
    constructor (uint256 initialSupply) public ERC20 ("Raccoon", "COON"){
        _mint(msg.sender, initialSupply);
    }
}