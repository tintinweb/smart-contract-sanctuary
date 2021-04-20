// SPDX-License-Identifier: F-F-F-FIAT!!!
pragma solidity ^0.7.4;

import "./ERC20.sol";
import "./TokensRecoverable.sol";

contract Fiat is ERC20, TokensRecoverable {
    
    mapping(address => bool) public approvedMinters;

    constructor() ERC20("Fiat", "FIAT") {}   

    function setMinter(address minter, bool canMint) public ownerOnly() {
        approvedMinters[minter] = canMint;
    }

    function mint(address account, uint256 amount) public {
        require (approvedMinters[msg.sender], "Not an approved minter");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public {
        require (approvedMinters[msg.sender], "Not an approved minter");
        _burn(account, amount);
    }

    function publicBurn(uint amount) public {
        _burn(msg.sender, amount);
    }
}