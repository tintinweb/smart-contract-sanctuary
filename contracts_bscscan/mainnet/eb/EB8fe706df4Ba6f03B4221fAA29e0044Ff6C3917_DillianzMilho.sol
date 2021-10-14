/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address sender, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed sender, address indexed spender, uint256 value);
}


contract DillianzMilho is IERC20 {

    string public constant name = "Dillianz Milho";
    string public constant symbol = "DLZMILHO";
    uint8 public constant decimals = 18;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Mine(address indexed to, uint tokens);


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;
    address owner_;

    using SafeMath for uint256;

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

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        return _transfer(msg.sender, receiver, numTokens);
    }
    
    function transferFrom(address sender, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[sender]);
        require(numTokens <= allowed[sender][msg.sender]);

        balances[sender] = balances[sender].sub(numTokens);
        allowed[sender][msg.sender] = allowed[sender][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(sender, buyer, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address sender, address delegate) public override view returns (uint) {
        return allowed[sender][delegate];
    }
    
    function _transfer(address from, address to, uint256 amount) private returns (bool) {
        require(amount <= balances[from]);
        balances[from] = balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, to, amount);
        return true;
    }
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}