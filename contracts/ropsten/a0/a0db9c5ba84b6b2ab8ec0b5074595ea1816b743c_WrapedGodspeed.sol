// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

import "base20tok.sol";

contract WrapedGodspeed is Base20Token {
    
    // Global variables
    
    address public governence;
    
    // only admin or only governance access modifier
    
    modifier onlyGovernance() {
      require(msg.sender == governence, "only governance can call this");      
      _;
    }
    
    constructor(string memory _name, string memory _symbol)
        Base20Token(0, 8, _name, _symbol)
    {
        governence = msg.sender;
    }

    function buy(uint256 amount, address to) external onlyGovernance {
        balanceOf[to] += amount;
        totalSupply += amount;

        emit Transfer(address(0), to, amount);
    }

    function sell(uint256 amount, address to, address _from) external onlyGovernance {
        require(balanceOf[_from] >= amount, "Insufficient balance.");

        // balanceOf[_from] -= amount;
        totalSupply -= amount;
        // msg.sender.transfer(amount);
        payable(to).transfer(amount);

        emit Transfer(_from, to, amount);
    }
}