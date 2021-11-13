pragma solidity ^0.6.2;

import "./erc20.sol";

contract Token is ERC20 {
    
    constructor () public ERC20("GiggleCoin", "GGC") {
        _mint(msg.sender, 10000000000000 * (10 ** uint256(decimals())));
    }
}