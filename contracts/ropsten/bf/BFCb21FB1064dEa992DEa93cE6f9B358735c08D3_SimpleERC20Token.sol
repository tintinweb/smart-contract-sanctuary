/**
 *Submitted for verification at Etherscan.io on 2021-09-23
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SimpleERC20Token {
    
    mapping (address => uint256) public balanceOf;

    string public name = "Simple ERC20 Token";
    string public symbol = "SFT";

    uint256 public totalSupply = 1000000;

    event Transfer(address indexed from, address indexed to, uint256 value);

    function ERC20Token() public {
        
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
}