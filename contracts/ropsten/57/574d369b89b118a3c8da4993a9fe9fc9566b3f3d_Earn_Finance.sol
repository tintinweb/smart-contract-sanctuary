pragma solidity 0.8.7;

// SPDX-License-Identifier: MIT

import "./Context.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./ERC20.sol";

interface Token {
    function transfer(address, uint256) external returns (bool);
}

contract Earn_Finance is ERC20, Ownable {
    constructor() ERC20("Earn-Finance", "EARN") {
        _mint(msg.sender, 10000000 *10**18);
    }
    
    // function to allow admin to transfer *any* ERC20 tokens from this contract
    function transferAnyERC20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "ERC20: amount must be greater than 0");
        require(recipient != address(0), "ERC20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
}