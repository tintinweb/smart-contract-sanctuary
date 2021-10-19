// SPDX-License-Identifier: MIT
pragma solidity ~0.8.0;

import "./Lockable.sol";

/// @title EcoWay Smart Contract
contract EcoWay is Lockable {
    
    string TokenName = "EcoWay"; // Smart contract name
    string TokenSymbol = "ECY"; // Smart Cotract Symbol up to 4 char
    uint8 TokenDecimals = 18; // The number of digits that come after the decimal place
    uint256 TokeninitialSupply = 6000000000000000000000000; // for 18 decimal 6 000 000 + 18 x 0 


	constructor(
    ) ERC20(TokenName, TokenSymbol, TokenDecimals) {
        _mint(msg.sender, TokeninitialSupply);
    }
}