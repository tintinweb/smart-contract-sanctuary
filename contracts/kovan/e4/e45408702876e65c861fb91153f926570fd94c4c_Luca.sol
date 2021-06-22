// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./token.sol";

//support for poxry
contract Luca is Token {
    function initialize(string memory name, string memory symbol, uint256 totalSupply) public {
        initializeToken(name, symbol, 18, totalSupply);
    }
}