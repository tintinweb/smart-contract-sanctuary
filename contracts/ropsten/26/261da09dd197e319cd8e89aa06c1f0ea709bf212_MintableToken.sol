// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;


import "./Ownable.sol";
import "./Token.sol";


contract MintableToken is Token, Ownable {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 supply,
        address owner,
        address feeWallet
    )
    public
    Token(name, symbol, decimals, supply, owner, feeWallet) 
    {

    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}