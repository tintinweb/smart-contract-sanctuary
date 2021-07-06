pragma solidity 0.8.0;

import "./ERC20.sol";

contract WCS_Token is ERC20 {
    constructor(uint valeur) ERC20("EduToken", "WCS") {
        _mint(msg.sender, valeur );
    }
}