pragma solidity ^0.8.0;

import "ERC20.sol";

contract ParioCash is ERC20 {
    constructor(uint256 initialSupply) public ERC20 ("ParioCash", "PARIO"){
        _mint(msg.sender,initialSupply);
    }
}