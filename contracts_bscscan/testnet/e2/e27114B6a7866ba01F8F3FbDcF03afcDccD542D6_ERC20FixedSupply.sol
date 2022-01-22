pragma solidity ^0.8.0;
import "./ERC20.sol";
contract ERC20FixedSupply is ERC20 {
    constructor() ERC20("TIME","TIME"){
        _mint(msg.sender, 100000000000 * (10**18));
    }
}