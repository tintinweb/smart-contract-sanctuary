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

contract FLAME_Token is BEP20, Ownable {
    constructor() BEP20("FLAME", "$FLAME") {
        _mint(msg.sender, 1000000 *10**2);
    }
    
    function mint(address _to, uint256 amount) public onlyOwner {
        _mint(_to, amount);
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