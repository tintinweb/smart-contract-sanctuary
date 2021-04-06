pragma solidity ^0.6.0;

import "./ERC20.sol";

contract GR2ProtectionToken is ERC20 {

    constructor () public ERC20("GR2-Protection", "GRB2") {
        _setupDecimals(6);
        _mint(msg.sender, 300000000 * (10 ** uint256(decimals())));
    }
}