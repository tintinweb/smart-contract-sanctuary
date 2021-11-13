pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Bidencoin  is ERC20 {
    constructor (uint256 initialSupply) public ERC20 ("Bidencoin", "BIDEN"){
        _mint(msg.sender, initialSupply);
    }
}