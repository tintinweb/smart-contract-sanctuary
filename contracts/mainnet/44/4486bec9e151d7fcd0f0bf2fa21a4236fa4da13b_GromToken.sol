pragma solidity ^0.6.0;

import "./ERC20.sol";

contract GromToken is ERC20 {

    constructor () public ERC20("GROM", "GR") {
        _setupDecimals(6);
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}