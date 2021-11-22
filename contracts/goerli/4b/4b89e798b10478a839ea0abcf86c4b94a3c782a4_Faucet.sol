/**
 *Submitted for verification at Etherscan.io on 2021-11-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface ERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint tokens) external returns (bool success);
    function balanceOf(address beneficiary) view external returns (uint balance);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {


    ERC20 public pinakion;
    
    mapping(address => bool) public withdrewAlready;
    
    constructor(ERC20 _pinakion) public {
        pinakion = _pinakion;
    }
    
    function balance() view public returns(uint balance)  {
        return pinakion.balanceOf(address(this));
    }

    function request() public {
        require(!withdrewAlready[msg.sender], "You have used this faucet already. If you need more tokens, please use another address.");
        pinakion.transfer(msg.sender, 10000000000000000000000);
        withdrewAlready[msg.sender] = true;
    }

}