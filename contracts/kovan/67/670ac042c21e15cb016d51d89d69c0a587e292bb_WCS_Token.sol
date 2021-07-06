pragma solidity 0.8.0;

import "./ERC20.sol";

contract WCS_Token is ERC20 {
    constructor(uint valeur) ERC20("Name", "TRIGRAMM") {
        _mint(msg.sender, valeur );
    }
}