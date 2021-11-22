pragma solidity ^0.8.0;

import "./ERC20.sol";

contract DarkMetaNFT is ERC20 {
    constructor(uint256 initialSupply) public ERC20 ("DarkMetaNFT", "DMNFT"){
        _mint(msg.sender,initialSupply);
    }
}