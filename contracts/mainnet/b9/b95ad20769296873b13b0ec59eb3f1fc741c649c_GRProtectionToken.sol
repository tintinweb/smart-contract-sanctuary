pragma solidity ^0.6.0;

import "./ERC20.sol";

contract GRProtectionToken is ERC20 {

    constructor () public ERC20("GR-Protection", "GRB") {
        _setupDecimals(6);
        _mint(msg.sender, 100000000 * (10 ** uint256(decimals())));
    }
}