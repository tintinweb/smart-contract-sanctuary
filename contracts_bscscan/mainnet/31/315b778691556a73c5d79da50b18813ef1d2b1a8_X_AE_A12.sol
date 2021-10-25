pragma solidity ^0.8.0;

import"./ERC20.sol";
contract X_AE_A12 is ERC20 {
    constructor(uint256 initialSupply) public ERC20 ("X_AE_A12", "XAEA12"){
        _mint(msg.sender,initialSupply);
    }
}