pragma solidity ^0.6.0;

import "./ERC20.sol";

contract BitlesToken is ERC20 {

    constructor () public ERC20("Bitles Token", "BTL") {
        _setupDecimals(6);
        _mint(msg.sender, 88895678 * (10 ** uint256(decimals())));
    }
}