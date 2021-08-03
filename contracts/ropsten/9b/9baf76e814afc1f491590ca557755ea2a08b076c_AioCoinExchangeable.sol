// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract AioCoinExchangeable is IERC20, Ownable {

    string public constant name = "ExchangeablAioCoin";
    string public constant symbol = "EAIO";

    uint256 public constant decimals = 18;
    uint256 public constant conversionRate = 10e15; // 1 token = 1 finney (1/1000 ETH),
    uint256 totalSupply_;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    using SafeMath for uint256;

    event EarnMoney(address indexed _transferTo, uint256 amount);

    constructor() {
        totalSupply_ = 10 ** decimals * 10e6;
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function tokenExchange(address payable beneficiary) public payable onlyOwner returns (bool) {
        uint256 tokensAmount = balances[beneficiary];   
        uint256 etherAmount = tokensAmount * conversionRate;
        address owner = msg.sender;

        require(tokensAmount > 0, "User's balance is empty");
        require(allowed[owner][beneficiary] > tokensAmount, "Transfer amount exceeds allowance");
        require(owner.balance > etherAmount, "The owner does not own enough money");

        transferFrom(beneficiary, owner, tokensAmount);
        beneficiary.transfer(etherAmount);
        emit EarnMoney(beneficiary, etherAmount);

        return true;
    }

    function transfer(address receiver, uint256 numTokens) public override onlyOwner returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override onlyOwner returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
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