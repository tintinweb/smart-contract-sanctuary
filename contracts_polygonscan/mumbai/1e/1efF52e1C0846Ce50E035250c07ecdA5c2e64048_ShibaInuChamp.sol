// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./ERC20.sol";
contract ShibaInuChamp is ERC20 {
    constructor() ERC20( "Shiba Inu Champion", "SHIBCHAMP") {
        _mint(msg.sender, (10*1000*1000*1000) * (10 ** uint256(decimals())));
    }
}