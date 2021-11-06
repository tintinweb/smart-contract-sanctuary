pragma solidity 0.8.9;

// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IBEP20.sol";
import "./BEP20.sol";

interface Token {
    function transfer(address, uint256) external returns (bool);
}

contract Shiba_Platinum is BEP20, Ownable {
    
    constructor() BEP20("Shiba Platinum", "SHIBA") {
        _mint(address(0x7EbD8F7227c4C63137A5a2EFa2215397Aeef8113), 1e30);
        transferOwnership(address(0x7EbD8F7227c4C63137A5a2EFa2215397Aeef8113));
    }
    
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "BEP20: amount must be greater than 0");
        require(recipient != address(0), "BEP20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
}