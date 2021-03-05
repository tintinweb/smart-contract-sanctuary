/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;

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

contract APING is IERC20 {
    using SafeMath for uint256;

    string public constant name = "ApingGames";
    string public constant symbol = "APING";
    uint8 public constant decimals = 18;  
    uint256 private supply = 13370 * 10 ** 18;

    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    constructor() public {
        balances[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }

    function totalSupply() public override view returns (uint256) {
        return supply;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(receiver != address(0));
        require(numTokens <= balances[msg.sender]);
    
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
    
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        require(delegate != address(0));
    
        allowed[msg.sender][delegate] = numTokens;
    
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address tokenOwner, address delegate) public override view returns (uint256) {
        return allowed[tokenOwner][delegate];
    }
    
    function burn(uint256 numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
    
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        supply = supply.sub(numTokens);
    
        emit Transfer(msg.sender, address(0), numTokens);
        return true;
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
    
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}