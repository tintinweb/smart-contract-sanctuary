pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CoffeeCoin is ERC20 {
    constructor(uint256 initialsupply) public ERC20 ("CoffeeCoin", "COFE"){
        _mint(msg.sender,initialsupply);
    }
}