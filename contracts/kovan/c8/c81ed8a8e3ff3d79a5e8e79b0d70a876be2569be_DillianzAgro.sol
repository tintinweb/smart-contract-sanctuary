/**
 *Submitted for verification at Etherscan.io on 2021-04-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

contract DillianzAgro {

    string public constant name = "DillianzAgro";
    string public constant symbol = "DLZ";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Mine(address indexed to, uint tokens);


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    address owner_;

    constructor(uint256 totalSupply) public {
        totalSupply_ = totalSupply * (10 ** uint256(decimals));
        owner_ = msg.sender;
        balances[owner_] = totalSupply_;
    }
    
    function changeOwner(address newOwner) public returns (bool) {
        require(msg.sender == owner_, "Apenas o dono do contrato pode realizar a alteração.");
        require(owner_ != newOwner, "Dono é o mesmo.");

        address oldOwner = owner_;
        owner_ = newOwner;

        return _transfer(oldOwner, newOwner, balances[oldOwner]);
    }

    function mine(uint256 amount) public returns (bool) {
        require(msg.sender == owner_, "Apenas o dono do contrato pode realizar a mineração.");

        balances[owner_] = balances[owner_] + (amount * (10 ** uint256(decimals)));
        totalSupply_ = totalSupply_ + (amount * (10 ** uint256(decimals)));
        
        return true;
    }

    function owner() public view returns (address) {
        return owner_;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public returns (bool) {
        return _transfer(msg.sender, receiver, numTokens);
    }
    
    function transferFrom(address sender, address buyer, uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[sender]);
        require(numTokens <= allowed[sender][msg.sender]);

        balances[sender] -= numTokens;
        allowed[sender][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(sender, buyer, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address sender, address delegate) public view returns (uint) {
        return allowed[sender][delegate];
    }
    
    function _transfer(address from, address to, uint256 amount) private returns (bool) {
        require(amount <= balances[from]);
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}